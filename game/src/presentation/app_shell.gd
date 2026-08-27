extends Node

const BRINDLEWICK_ZONE_ID: StringName = &"zone.brindlewick_square"
const BRINDLEWICK_SPAWN_ID: StringName = &"spawn.brindlewick_square.south_gate"
const METRICS_SCENE_PATH: String = "res://scenes/debug/metrics_scene.tscn"
const BASE_FONT_SIZE: int = 16

@onready var _world_root: Node3D = %WorldRoot
@onready var _ui_root: Control = %UIRoot
@onready var _title_screen: Control = %TitleScreen
@onready var _settings_screen: Control = %SettingsScreen
@onready var _gameplay_hud: Control = %GameplayHUD
@onready var _build_label: Label = %BuildLabel
@onready var _help_panel: PanelContainer = %HelpPanel
@onready var _instructions: Label = %Instructions
@onready var _error_panel: PanelContainer = %ErrorPanel
@onready var _error_label: Label = %ErrorLabel

var _settings: AccessibilitySettings = AccessibilitySettings.new()


func _ready() -> void:
	_connect_interfaces()
	_load_settings()
	GameFlow.bind_world_host(_world_root)
	var build_version: String = str(ProjectSettings.get_setting("application/config/version", "unknown"))
	_title_screen.call(&"configure_version", build_version)
	_title_screen.call(
		&"set_start_available",
		ContentDB.is_valid(),
		ContentDB.get_validation_summary()
	)
	_update_prompt_text()
	_apply_accessibility_settings()
	GameFlow.show_title()


func _unhandled_input(event: InputEvent) -> void:
	if _error_panel.visible and event.is_action_pressed(&"cancel"):
		_error_panel.visible = false
		_show_title_screen()
		get_viewport().set_input_as_handled()
		return
	if GameFlow.state != GameFlow.FlowState.FIELD and GameFlow.state != GameFlow.FlowState.DEBUG:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			_set_field_mouse_captured(true)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed(&"menu"):
		_help_panel.visible = not _help_panel.visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cancel"):
		GameFlow.show_title()
		get_viewport().set_input_as_handled()


func _connect_interfaces() -> void:
	_title_screen.connect(&"start_diorama_requested", _start_diorama)
	_title_screen.connect(&"metrics_requested", _open_metrics_room)
	_title_screen.connect(&"settings_requested", _open_settings)
	_title_screen.connect(&"quit_requested", _quit_game)
	_settings_screen.connect(&"back_requested", _close_settings)
	_settings_screen.connect(&"settings_changed", _on_settings_changed)
	_settings_screen.call(&"configure", _settings)
	GameFlow.state_changed.connect(_on_flow_state_changed)
	GameFlow.active_world_changed.connect(_on_active_world_changed)
	GameFlow.flow_failed.connect(_show_error)
	InputRouter.active_device_changed.connect(_on_active_device_changed)


func _load_settings() -> void:
	var stored: Dictionary = SettingsStore.load_data()
	var accessibility_data: Variant = stored.get("accessibility", {})
	if accessibility_data is Dictionary:
		_settings.apply_dictionary(accessibility_data as Dictionary)
	var binding_data: Variant = stored.get("bindings", {})
	if binding_data is Dictionary and not (binding_data as Dictionary).is_empty():
		InputRouter.apply_serialized_bindings(binding_data as Dictionary)
	elif _settings.confirm_cancel_swapped:
		InputRouter.swap_confirm_cancel()


func _save_settings() -> void:
	SettingsStore.save_data(_settings.to_dictionary(), InputRouter.serialize_bindings())


func _start_diorama() -> void:
	_hide_frontend()
	if not GameFlow.load_zone(BRINDLEWICK_ZONE_ID, BRINDLEWICK_SPAWN_ID):
		return
	_apply_settings_to_active_world()


func _open_metrics_room() -> void:
	_hide_frontend()
	GameFlow.load_debug_scene(METRICS_SCENE_PATH)


func _open_settings() -> void:
	_title_screen.call(&"hide_screen")
	_settings_screen.call(&"show_screen")


func _close_settings() -> void:
	_settings_screen.call(&"hide_screen")
	_title_screen.call(&"show_screen")


func _quit_game() -> void:
	get_tree().quit()


func _hide_frontend() -> void:
	_title_screen.call(&"hide_screen")
	_settings_screen.call(&"hide_screen")
	_error_panel.visible = false


func _show_title_screen() -> void:
	_gameplay_hud.visible = false
	_help_panel.visible = false
	_settings_screen.call(&"hide_screen")
	_title_screen.call(&"show_screen")


func _on_flow_state_changed(_previous_state: int, current_state: int) -> void:
	if current_state == GameFlow.FlowState.TITLE:
		_set_field_mouse_captured(false)
		_show_title_screen()
	elif current_state == GameFlow.FlowState.FIELD or current_state == GameFlow.FlowState.DEBUG:
		_gameplay_hud.visible = true
		_help_panel.visible = true
		_title_screen.call(&"hide_screen")
		_settings_screen.call(&"hide_screen")
		_set_field_mouse_captured(true)


func _on_active_world_changed(_active_world: Node) -> void:
	_apply_settings_to_active_world()


func _on_active_device_changed(_device_type: StringName) -> void:
	_update_prompt_text()


func _on_settings_changed() -> void:
	_apply_accessibility_settings()
	_save_settings()


func _apply_accessibility_settings() -> void:
	_apply_text_scale(_settings.text_scale)
	_apply_settings_to_active_world()


func _apply_settings_to_active_world() -> void:
	var active_world: Node = GameFlow.get_active_world()
	if active_world != null and active_world.has_method(&"apply_accessibility_settings"):
		active_world.call(&"apply_accessibility_settings", _settings)


func _apply_text_scale(text_scale: float) -> void:
	if _ui_root.theme != null:
		_ui_root.theme.default_font_size = roundi(float(BASE_FONT_SIZE) * text_scale)
	_scale_explicit_font_sizes(_ui_root, text_scale)


func _set_field_mouse_captured(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func _scale_explicit_font_sizes(node: Node, text_scale: float) -> void:
	if node is Control:
		var control: Control = node as Control
		if control.has_theme_font_size_override(&"font_size"):
			if not control.has_meta(&"asterfold_base_font_size"):
				control.set_meta(&"asterfold_base_font_size", control.get_theme_font_size(&"font_size"))
			var base_size: int = int(control.get_meta(&"asterfold_base_font_size"))
			control.add_theme_font_size_override(&"font_size", roundi(float(base_size) * text_scale))
	for child: Node in node.get_children():
		_scale_explicit_font_sizes(child, text_scale)


func _update_prompt_text() -> void:
	_build_label.text = "ASTERFOLD  •  %s\nBRINDLEWICK WALKING DIORAMA" % str(
		ProjectSettings.get_setting("application/config/version", "unknown")
	)
	_instructions.text = "MOVE  —  %s\nPEEK  —  MOUSE / %s / RIGHT STICK\nHELP  —  %s\nRETURN TO TITLE  —  %s" % [
		InputRouter.get_prompt(&"move_forward"),
		InputRouter.get_prompt(&"peek"),
		InputRouter.get_prompt(&"menu"),
		InputRouter.get_prompt(&"cancel"),
	]


func _show_error(message: String) -> void:
	push_warning("[FLOW] %s" % message.replace("\n", " "))
	_set_field_mouse_captured(false)
	_hide_frontend()
	_gameplay_hud.visible = false
	_error_label.text = "ASTERFOLD COULD NOT CONTINUE\n\n%s\n\nPress %s to return to title." % [
		message,
		InputRouter.get_prompt(&"cancel"),
	]
	_error_panel.visible = true
