extends Node

signal active_device_changed(device_type: StringName)
signal bindings_changed
signal gamepad_connection_changed(device_id: int, connected: bool)

const DEVICE_KEYBOARD_MOUSE: StringName = &"keyboard_mouse"
const DEVICE_GAMEPAD: StringName = &"gamepad"
const DEVICE_CHANGE_COOLDOWN_MSEC: int = 250
const JOY_DETECTION_THRESHOLD: float = 0.35

const BINDABLE_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_forward",
	&"move_back",
	&"confirm",
	&"cancel",
	&"menu",
	&"peek",
	&"fold_left",
	&"fold_right",
]

const ACTION_LABELS: Dictionary = {
	&"move_left": "Move left",
	&"move_right": "Move right",
	&"move_forward": "Move forward",
	&"move_back": "Move back",
	&"confirm": "Confirm",
	&"cancel": "Cancel",
	&"menu": "Menu",
	&"peek": "Keyboard Peek modifier",
	&"fold_left": "World Turn left",
	&"fold_right": "World Turn right",
}

var _active_device: StringName = DEVICE_KEYBOARD_MOUSE
var _last_device_change_msec: int = 0
var _default_bindings: Dictionary[StringName, Array] = {}


func _ready() -> void:
	_capture_default_bindings()
	_synchronize_ui_actions()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	consider_input_device(event, Time.get_ticks_msec())


func consider_input_device(event: InputEvent, now_msec: int) -> void:
	var detected_device: StringName = &""
	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if absf(motion.axis_value) >= JOY_DETECTION_THRESHOLD:
			detected_device = DEVICE_GAMEPAD
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		detected_device = DEVICE_GAMEPAD
	elif event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			detected_device = DEVICE_KEYBOARD_MOUSE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		detected_device = DEVICE_KEYBOARD_MOUSE
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if motion.relative.length_squared() > 0.25:
			detected_device = DEVICE_KEYBOARD_MOUSE

	if not detected_device.is_empty():
		_request_device_change(detected_device, now_msec)


func get_move_vector() -> Vector2:
	if _active_device == DEVICE_KEYBOARD_MOUSE and Input.is_action_pressed(&"peek"):
		return Vector2.ZERO
	return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")


func get_peek_vector() -> Vector2:
	var peek_vector: Vector2 = Input.get_vector(
		&"peek_left",
		&"peek_right",
		&"peek_up",
		&"peek_down"
	)
	if _active_device == DEVICE_KEYBOARD_MOUSE and Input.is_action_pressed(&"peek"):
		peek_vector += Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	return peek_vector.limit_length(1.0)


func get_active_device() -> StringName:
	return _active_device


func get_bindable_actions() -> Array[StringName]:
	return BINDABLE_ACTIONS.duplicate()


func get_action_label(action: StringName) -> String:
	return str(ACTION_LABELS.get(action, String(action).capitalize()))


func get_prompt(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if _active_device == DEVICE_GAMEPAD and _is_gamepad_event(event):
			return _format_event(event)
		if _active_device == DEVICE_KEYBOARD_MOUSE and not _is_gamepad_event(event):
			return _format_event(event)
	return "Unbound"


func find_conflicts(event: InputEvent, excluded_action: StringName = &"") -> Array[StringName]:
	var conflicts: Array[StringName] = []
	for action: StringName in BINDABLE_ACTIONS:
		if action == excluded_action:
			continue
		for existing: InputEvent in InputMap.action_get_events(action):
			if existing.is_match(event, true):
				conflicts.append(action)
				break
	return conflicts


func rebind_action(action: StringName, event: InputEvent, replace_conflicts: bool) -> bool:
	if not BINDABLE_ACTIONS.has(action):
		return false
	var conflicts: Array[StringName] = find_conflicts(event, action)
	if not conflicts.is_empty() and not replace_conflicts:
		return false
	for conflicting_action: StringName in conflicts:
		for existing: InputEvent in InputMap.action_get_events(conflicting_action):
			if existing.is_match(event, true):
				InputMap.action_erase_event(conflicting_action, existing)
	for existing: InputEvent in InputMap.action_get_events(action):
		if _is_same_event_family(existing, event):
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, event)
	if action == &"confirm" or action == &"cancel":
		_synchronize_ui_actions()
	bindings_changed.emit()
	return true


func swap_confirm_cancel() -> void:
	var confirm_events: Array[InputEvent] = InputMap.action_get_events(&"confirm")
	var cancel_events: Array[InputEvent] = InputMap.action_get_events(&"cancel")
	InputMap.action_erase_events(&"confirm")
	InputMap.action_erase_events(&"cancel")
	for event: InputEvent in cancel_events:
		InputMap.action_add_event(&"confirm", event)
	for event: InputEvent in confirm_events:
		InputMap.action_add_event(&"cancel", event)
	_synchronize_ui_actions()
	bindings_changed.emit()


func reset_default_bindings() -> void:
	for action: StringName in BINDABLE_ACTIONS:
		InputMap.action_erase_events(action)
		for event: InputEvent in _default_bindings.get(action, []):
			InputMap.action_add_event(action, event.duplicate() as InputEvent)
	_synchronize_ui_actions()
	bindings_changed.emit()


func serialize_bindings() -> Dictionary:
	var serialized: Dictionary = {}
	for action: StringName in BINDABLE_ACTIONS:
		var serialized_events: Array[Dictionary] = []
		for event: InputEvent in InputMap.action_get_events(action):
			var event_data: Dictionary = _serialize_event(event)
			if not event_data.is_empty():
				serialized_events.append(event_data)
		serialized[String(action)] = serialized_events
	return serialized


func apply_serialized_bindings(serialized: Dictionary) -> void:
	for action: StringName in BINDABLE_ACTIONS:
		var action_key: String = String(action)
		if not serialized.has(action_key) or not serialized[action_key] is Array:
			continue
		var restored_events: Array[InputEvent] = []
		for event_data: Variant in serialized[action_key]:
			if event_data is Dictionary:
				var restored: InputEvent = _deserialize_event(event_data as Dictionary)
				if restored != null:
					restored_events.append(restored)
		if restored_events.is_empty():
			continue
		InputMap.action_erase_events(action)
		for restored: InputEvent in restored_events:
			InputMap.action_add_event(action, restored)
	_synchronize_ui_actions()
	bindings_changed.emit()


func _capture_default_bindings() -> void:
	_default_bindings.clear()
	for action: StringName in BINDABLE_ACTIONS:
		var events: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			events.append(event.duplicate() as InputEvent)
		_default_bindings[action] = events


func _synchronize_ui_actions() -> void:
	for ui_action: StringName in [&"ui_accept", &"ui_cancel"]:
		if not InputMap.has_action(ui_action):
			InputMap.add_action(ui_action)
		InputMap.action_erase_events(ui_action)
	var mappings: Dictionary[StringName, StringName] = {
		&"confirm": &"ui_accept",
		&"cancel": &"ui_cancel",
	}
	for source_action: StringName in mappings:
		var target_action: StringName = mappings[source_action]
		for event: InputEvent in InputMap.action_get_events(source_action):
			InputMap.action_add_event(target_action, event.duplicate() as InputEvent)


func _request_device_change(device_type: StringName, now_msec: int) -> void:
	if device_type == _active_device:
		return
	if now_msec - _last_device_change_msec < DEVICE_CHANGE_COOLDOWN_MSEC:
		return
	_active_device = device_type
	_last_device_change_msec = now_msec
	active_device_changed.emit(_active_device)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	gamepad_connection_changed.emit(device_id, connected)
	if not connected and _active_device == DEVICE_GAMEPAD:
		_active_device = DEVICE_KEYBOARD_MOUSE
		_last_device_change_msec = Time.get_ticks_msec()
		active_device_changed.emit(_active_device)


func _is_gamepad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


func _is_same_event_family(left: InputEvent, right: InputEvent) -> bool:
	return _is_gamepad_event(left) == _is_gamepad_event(right)


func _format_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
		return OS.get_keycode_string(keycode)
	if event is InputEventJoypadButton:
		var button: JoyButton = (event as InputEventJoypadButton).button_index
		const BUTTON_LABELS: Dictionary = {
			JOY_BUTTON_A: "Controller A",
			JOY_BUTTON_B: "Controller B",
			JOY_BUTTON_X: "Controller X",
			JOY_BUTTON_Y: "Controller Y",
			JOY_BUTTON_BACK: "Controller Back",
			JOY_BUTTON_START: "Controller Start",
			JOY_BUTTON_LEFT_SHOULDER: "Left bumper",
			JOY_BUTTON_RIGHT_SHOULDER: "Right bumper",
		}
		return str(BUTTON_LABELS.get(button, "Controller button %d" % button))
	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		const AXIS_LABELS: Dictionary = {
			JOY_AXIS_LEFT_X: "Left stick horizontal",
			JOY_AXIS_LEFT_Y: "Left stick vertical",
			JOY_AXIS_RIGHT_X: "Right stick horizontal",
			JOY_AXIS_RIGHT_Y: "Right stick vertical",
		}
		return str(AXIS_LABELS.get(motion.axis, "Controller axis %d" % motion.axis))
	if event is InputEventMouseButton:
		return "Mouse %d" % (event as InputEventMouseButton).button_index
	return event.as_text()


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		return {
			"type": "key",
			"keycode": key_event.keycode,
			"physical_keycode": key_event.physical_keycode,
			"shift": key_event.shift_pressed,
			"ctrl": key_event.ctrl_pressed,
			"alt": key_event.alt_pressed,
			"meta": key_event.meta_pressed,
		}
	if event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event as InputEventJoypadButton
		return {"type": "joy_button", "button": button_event.button_index}
	if event is InputEventJoypadMotion:
		var motion_event: InputEventJoypadMotion = event as InputEventJoypadMotion
		return {"type": "joy_motion", "axis": motion_event.axis, "value": signf(motion_event.axis_value)}
	if event is InputEventMouseButton:
		return {"type": "mouse_button", "button": (event as InputEventMouseButton).button_index}
	return {}


func _deserialize_event(data: Dictionary) -> InputEvent:
	match String(data.get("type", "")):
		"key":
			var key_event: InputEventKey = InputEventKey.new()
			key_event.keycode = int(data.get("keycode", 0)) as Key
			key_event.physical_keycode = int(data.get("physical_keycode", 0)) as Key
			key_event.shift_pressed = bool(data.get("shift", false))
			key_event.ctrl_pressed = bool(data.get("ctrl", false))
			key_event.alt_pressed = bool(data.get("alt", false))
			key_event.meta_pressed = bool(data.get("meta", false))
			return key_event
		"joy_button":
			var button_event: InputEventJoypadButton = InputEventJoypadButton.new()
			button_event.button_index = int(data.get("button", 0)) as JoyButton
			return button_event
		"joy_motion":
			var motion_event: InputEventJoypadMotion = InputEventJoypadMotion.new()
			motion_event.axis = int(data.get("axis", 0)) as JoyAxis
			motion_event.axis_value = float(data.get("value", 0.0))
			return motion_event
		"mouse_button":
			var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
			mouse_event.button_index = int(data.get("button", 1)) as MouseButton
			return mouse_event
	return null
