extends Control

signal back_requested
signal settings_changed

const CAPTURE_DELAY_MSEC: int = 180
const JOY_CAPTURE_THRESHOLD: float = 0.75

@onready var _camera_motion: OptionButton = %CameraMotionOption
@onready var _text_scale: OptionButton = %TextScaleOption
@onready var _swap_confirm_cancel: CheckButton = %SwapConfirmCancel
@onready var _bindings_list: VBoxContainer = %BindingsList
@onready var _reset_bindings: Button = %ResetBindingsButton
@onready var _back_button: Button = %BackButton
@onready var _capture_panel: PanelContainer = %CapturePanel
@onready var _capture_label: Label = %CaptureLabel
@onready var _conflict_dialog: ConfirmationDialog = %ConflictDialog

var _settings: AccessibilitySettings
var _binding_buttons: Dictionary[StringName, Button] = {}
var _capture_action: StringName = &""
var _capture_started_msec: int = 0
var _pending_event: InputEvent
var _capture_button: Button


func _ready() -> void:
	_camera_motion.add_item("Full", AccessibilitySettings.CameraMotionMode.FULL)
	_camera_motion.add_item("Reduced", AccessibilitySettings.CameraMotionMode.REDUCED)
	_camera_motion.add_item("Minimal", AccessibilitySettings.CameraMotionMode.MINIMAL)
	_text_scale.add_item("100%", 100)
	_text_scale.add_item("125%", 125)
	_text_scale.add_item("150%", 150)
	_camera_motion.item_selected.connect(_on_camera_motion_selected)
	_text_scale.item_selected.connect(_on_text_scale_selected)
	_swap_confirm_cancel.toggled.connect(_on_swap_toggled)
	_reset_bindings.pressed.connect(_on_reset_bindings_pressed)
	_back_button.pressed.connect(_request_back)
	_conflict_dialog.confirmed.connect(_on_conflict_confirmed)
	_conflict_dialog.canceled.connect(_cancel_capture)
	_build_binding_rows()


func configure(settings: AccessibilitySettings) -> void:
	_settings = settings
	_refresh_values()


func show_screen() -> void:
	visible = true
	_refresh_values()
	_camera_motion.call_deferred(&"grab_focus")


func hide_screen() -> void:
	_cancel_capture()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not _capture_action.is_empty():
		_handle_capture_input(event)
		return
	if event.is_action_pressed(&"cancel"):
		_request_back()
		get_viewport().set_input_as_handled()


func _build_binding_rows() -> void:
	for action: StringName in InputRouter.get_bindable_actions():
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var action_label: Label = Label.new()
		action_label.text = InputRouter.get_action_label(action)
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_label.custom_minimum_size.x = 210.0
		var binding_button: Button = Button.new()
		binding_button.custom_minimum_size = Vector2(210.0, 38.0)
		binding_button.pressed.connect(_begin_capture.bind(action, binding_button))
		row.add_child(action_label)
		row.add_child(binding_button)
		_bindings_list.add_child(row)
		_binding_buttons[action] = binding_button


func _refresh_values() -> void:
	if _settings == null or not is_node_ready():
		return
	_camera_motion.select(_settings.camera_motion_mode)
	var text_index: int = 0
	if is_equal_approx(_settings.text_scale, 1.25):
		text_index = 1
	elif is_equal_approx(_settings.text_scale, 1.5):
		text_index = 2
	_text_scale.select(text_index)
	_swap_confirm_cancel.set_pressed_no_signal(_settings.confirm_cancel_swapped)
	for action: StringName in _binding_buttons:
		_binding_buttons[action].text = InputRouter.get_prompt(action)


func _begin_capture(action: StringName, button: Button) -> void:
	_capture_action = action
	_capture_button = button
	_capture_started_msec = Time.get_ticks_msec()
	_capture_label.text = "Press a new input for %s\n\nCancel keeps the current binding." % InputRouter.get_action_label(action)
	_capture_panel.visible = true


func _handle_capture_input(event: InputEvent) -> void:
	if Time.get_ticks_msec() - _capture_started_msec < CAPTURE_DELAY_MSEC:
		return
	if event is InputEventMouseMotion:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
	elif event is InputEventJoypadButton:
		if not (event as InputEventJoypadButton).pressed:
			return
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) < JOY_CAPTURE_THRESHOLD:
			return
	elif event is InputEventMouseButton:
		if not (event as InputEventMouseButton).pressed:
			return
	else:
		return

	if event.is_action_pressed(&"cancel"):
		_cancel_capture()
		get_viewport().set_input_as_handled()
		return

	_pending_event = event.duplicate() as InputEvent
	if _pending_event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = _pending_event as InputEventJoypadMotion
		motion.axis_value = signf(motion.axis_value)
	var conflicts: Array[StringName] = InputRouter.find_conflicts(_pending_event, _capture_action)
	if conflicts.is_empty():
		_commit_capture(false)
	else:
		var conflict_names: Array[String] = []
		for conflict: StringName in conflicts:
			conflict_names.append(InputRouter.get_action_label(conflict))
		_capture_panel.visible = false
		_conflict_dialog.dialog_text = "That input is already used by %s. Replace it?" % ", ".join(conflict_names)
		_conflict_dialog.popup_centered()
	get_viewport().set_input_as_handled()


func _commit_capture(replace_conflicts: bool) -> void:
	if _pending_event != null and InputRouter.rebind_action(_capture_action, _pending_event, replace_conflicts):
		settings_changed.emit()
	_cancel_capture()
	_refresh_values()


func _cancel_capture() -> void:
	_capture_panel.visible = false
	_capture_action = &""
	_pending_event = null
	if _capture_button != null and is_instance_valid(_capture_button) and visible:
		_capture_button.call_deferred(&"grab_focus")
	_capture_button = null


func _on_conflict_confirmed() -> void:
	_commit_capture(true)


func _on_camera_motion_selected(index: int) -> void:
	if _settings == null:
		return
	_settings.set_camera_motion_mode(_camera_motion.get_item_id(index))
	settings_changed.emit()


func _on_text_scale_selected(index: int) -> void:
	if _settings == null:
		return
	_settings.set_text_scale(float(_text_scale.get_item_id(index)) / 100.0)
	settings_changed.emit()


func _on_swap_toggled(enabled: bool) -> void:
	if _settings == null or _settings.confirm_cancel_swapped == enabled:
		return
	InputRouter.swap_confirm_cancel()
	_settings.set_confirm_cancel_swapped(enabled)
	_refresh_values()
	settings_changed.emit()


func _on_reset_bindings_pressed() -> void:
	InputRouter.reset_default_bindings()
	if _settings != null:
		_settings.set_confirm_cancel_swapped(false)
	_refresh_values()
	settings_changed.emit()


func _request_back() -> void:
	back_requested.emit()
