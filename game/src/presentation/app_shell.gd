extends Node

const BRINDLEWICK_ZONE_ID: StringName = &"zone.brindlewick_square"
const BRINDLEWICK_SPAWN_ID: StringName = &"spawn.brindlewick_square.south_gate"
const METRICS_SCENE_PATH: String = "res://scenes/debug/metrics_scene.tscn"
const MAP_MAKER_SCENE_PATH: String = "res://tools/map_maker/map_maker.tscn"
const BASE_FONT_SIZE: int = 16

@onready var _world_root: Node3D = %WorldRoot
@onready var _world_viewport: SubViewport = %WorldViewport
@onready var _ui_root: Control = %UIRoot
@onready var _title_screen: Control = %TitleScreen
@onready var _settings_screen: Control = %SettingsScreen
@onready var _equipment_screen: Control = %EquipmentScreen
@onready var _gameplay_hud: Control = %GameplayHUD
@onready var _scout: FirstPersonScout = %FirstPersonScout
@onready var _build_label: Label = %BuildLabel
@onready var _help_panel: PanelContainer = %HelpPanel
@onready var _instructions: Label = %Instructions
@onready var _error_panel: PanelContainer = %ErrorPanel
@onready var _error_label: Label = %ErrorLabel
@onready var _quit_prompt: PanelContainer = %QuitPrompt
@onready var _quit_confirm_button: Button = %QuitConfirmButton
@onready var _quit_cancel_button: Button = %QuitCancelButton
@onready var _world_load_blocker: Control = %WorldLoadBlocker
@onready var _title_audio: Node = %TitleShellAudio
@onready var _button_feedback: UiButtonFeedback = %UiButtonFeedback

var _settings: AccessibilitySettings = AccessibilitySettings.new()
var _display: DisplaySettings = DisplaySettings.new()
## Session-scoped: the loadout is discarded on return to title until campaign saves exist.
var _inventory: PartyInventory
var _roster: CharacterRoster = CharacterRoster.new()
var _active_character: CharacterRecord
## True from the title click until the first idle field frame so a second
## click cannot hit another menu or fall through into the world.
var _world_load_busy: bool = false


func _ready() -> void:
	_connect_interfaces()
	_load_settings()
	_load_roster()
	GameFlow.bind_world_host(_world_root)
	var build_version: String = str(ProjectSettings.get_setting("application/config/version", "unknown"))
	_title_screen.call(&"configure_version", build_version)
	_title_screen.call(
		&"configure_play",
		_roster,
		load("res://content/actors/mara_layer_kit.tres") as ActorLayerKit,
		_settings.camera_motion_mode != AccessibilitySettings.CameraMotionMode.FULL
	)
	_title_screen.call(
		&"set_start_available",
		ContentDB.is_valid(),
		ContentDB.get_validation_summary()
	)
	_update_prompt_text()
	_apply_accessibility_settings()
	GameFlow.show_title()


## Window shortcuts run ahead of gameplay and menus, except while the settings
## screen is capturing an input so those keys stay rebindable.
func _input(event: InputEvent) -> void:
	if _settings_screen.call(&"is_capturing"):
		return
	if _world_load_busy:
		if event.is_action_pressed(&"toggle_fullscreen"):
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"toggle_fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if _quit_prompt.visible:
		if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"quit_prompt"):
			_close_quit_prompt()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"quit_prompt"):
		_open_quit_prompt()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _error_panel.visible and event.is_action_pressed(&"cancel"):
		_error_panel.visible = false
		_show_title_screen()
		get_viewport().set_input_as_handled()
		return
	if _world_load_busy:
		get_viewport().set_input_as_handled()
		return
	if GameFlow.state != GameFlow.FlowState.FIELD and GameFlow.state != GameFlow.FlowState.DEBUG:
		return
	if bool(_equipment_screen.call(&"is_open")):
		if event.is_action_pressed(&"equipment"):
			_close_equipment_screen()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"equipment") and not _scout.consumes_cancel():
		_open_equipment_screen()
		get_viewport().set_input_as_handled()
		return
	if _scout.consumes_cancel() and event.is_action_pressed(&"cancel"):
		_scout.exit_to_field()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		if _scout.is_picking():
			return
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
	_title_screen.connect(&"character_play_requested", _play_character)
	_title_screen.connect(&"roster_changed", _save_roster)
	_title_screen.connect(&"metrics_requested", _open_metrics_room)
	_title_screen.connect(&"map_maker_requested", _open_map_maker)
	_title_screen.connect(&"settings_requested", _open_settings)
	_title_screen.connect(&"quit_requested", _quit_game)
	_settings_screen.connect(&"back_requested", _close_settings)
	_settings_screen.connect(&"settings_changed", _on_settings_changed)
	_settings_screen.call(&"configure", _settings, _display)
	_equipment_screen.connect(&"closed", _on_equipment_closed)
	GameFlow.state_changed.connect(_on_flow_state_changed)
	GameFlow.active_world_changed.connect(_on_active_world_changed)
	GameFlow.flow_failed.connect(_show_error)
	InputRouter.active_device_changed.connect(_on_active_device_changed)
	_scout.mouse_capture_changed.connect(_on_scout_mouse_capture_changed)
	_quit_confirm_button.pressed.connect(_quit_game)
	_quit_cancel_button.pressed.connect(_close_quit_prompt)
	_world_load_blocker.gui_input.connect(_on_world_load_blocker_gui_input)
	_button_feedback.rescan()


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
	var video_data: Variant = stored.get("video", {})
	if video_data is Dictionary:
		_display.apply_dictionary(video_data as Dictionary)


func _save_settings() -> void:
	SettingsStore.save_data(
		_settings.to_dictionary(),
		InputRouter.serialize_bindings(),
		_display.to_dictionary()
	)


func is_world_load_busy() -> bool:
	return _world_load_busy


func _start_diorama() -> void:
	if not _begin_world_load("Loading the walking diorama."):
		return
	if not GameFlow.load_zone(BRINDLEWICK_ZONE_ID, BRINDLEWICK_SPAWN_ID):
		return
	_apply_settings_to_active_world()
	_ensure_inventory()
	_bind_equipment_screen()
	_apply_actor_presentation()
	await _hold_world_load_until_idle()


func _play_character(slot_index: int) -> void:
	if _roster == null:
		return
	var record: CharacterRecord = _roster.get_record(slot_index)
	if record == null:
		return
	_active_character = record
	_start_diorama()


func _load_roster() -> void:
	_roster = CharacterRosterStore.load_data()


func _save_roster() -> void:
	var build_version: String = str(ProjectSettings.get_setting("application/config/version", "unknown"))
	CharacterRosterStore.save_data(_roster, build_version)


func _active_appearance() -> CharacterAppearance:
	if _active_character != null and _active_character.appearance != null:
		return _active_character.appearance
	return CharacterAppearance.starter()


func _apply_actor_presentation() -> void:
	var appearance: CharacterAppearance = _active_appearance()
	var equipped: Array[ItemDefinition] = []
	if _inventory != null:
		equipped = _inventory.equipped_definitions()
	var active_world: Node = GameFlow.get_active_world()
	if active_world != null and active_world.has_method(&"apply_presentation"):
		active_world.call(&"apply_presentation", equipped, appearance)
	elif active_world != null and active_world.has_method(&"apply_equipment"):
		active_world.call(&"apply_equipment", equipped)


func _ensure_inventory() -> void:
	if _inventory != null:
		return
	_inventory = PartyInventory.create_from_catalog(ContentDB.get_item_catalog())
	_inventory.loadout_changed.connect(_on_loadout_changed)


func _bind_equipment_screen() -> void:
	if _inventory == null:
		return
	_equipment_screen.call(&"configure", _inventory, _active_world_compositor(), _active_appearance())
	_apply_actor_presentation()


func _active_world_compositor() -> SpriteLayerCompositor:
	var active_world: Node = GameFlow.get_active_world()
	if active_world == null or not active_world.has_method(&"get_sprite_compositor"):
		return null
	return active_world.call(&"get_sprite_compositor") as SpriteLayerCompositor


func _open_equipment_screen() -> void:
	_ensure_inventory()
	_bind_equipment_screen()
	_help_panel.visible = false
	_set_field_player_input_enabled(false)
	_set_field_mouse_captured(false)
	_equipment_screen.call(&"show_screen")


func _close_equipment_screen() -> void:
	_equipment_screen.call(&"hide_screen")
	_on_equipment_closed()


func _on_equipment_closed() -> void:
	_set_field_player_input_enabled(true)
	var in_world: bool = (
		GameFlow.state == GameFlow.FlowState.FIELD
		or GameFlow.state == GameFlow.FlowState.DEBUG
	)
	_set_field_mouse_captured(in_world and not _scout.is_picking())


func _set_field_player_input_enabled(enabled: bool) -> void:
	var active_world: Node = GameFlow.get_active_world()
	if active_world != null and active_world.has_method(&"set_player_input_enabled"):
		active_world.call(&"set_player_input_enabled", enabled)


func _on_loadout_changed() -> void:
	_apply_actor_presentation()


func _open_metrics_room() -> void:
	if not _begin_world_load("Opening the metrics room."):
		return
	if not GameFlow.load_debug_scene(METRICS_SCENE_PATH):
		return
	await _hold_world_load_until_idle()


func _open_map_maker() -> void:
	if not _begin_world_load("Opening the map maker."):
		return
	var scene_error: Error = get_tree().change_scene_to_file(MAP_MAKER_SCENE_PATH)
	if scene_error != OK:
		_end_world_load()
		_show_error("Map maker could not be opened.")


func _open_settings() -> void:
	if _world_load_busy:
		return
	_title_screen.call(&"hide_screen")
	_settings_screen.call(&"show_screen")
	_button_feedback.rescan()


func _close_settings() -> void:
	_settings_screen.call(&"hide_screen")
	_title_screen.call(&"show_screen")


func _quit_game() -> void:
	if _world_load_busy:
		return
	get_tree().quit()


func _toggle_fullscreen() -> void:
	_display.toggle_fullscreen()
	_apply_display_settings()
	_settings_screen.call(&"refresh_from_settings")
	_save_settings()


func _open_quit_prompt() -> void:
	if _world_load_busy or _quit_prompt.visible:
		return
	_quit_prompt.visible = true
	_set_field_mouse_captured(false)
	_quit_confirm_button.call_deferred(&"grab_focus")


func _close_quit_prompt() -> void:
	if not _quit_prompt.visible:
		return
	_quit_prompt.visible = false
	var in_world: bool = (
		GameFlow.state == GameFlow.FlowState.FIELD
		or GameFlow.state == GameFlow.FlowState.DEBUG
	)
	_set_field_mouse_captured(in_world and not _scout.is_picking())


func _hide_frontend() -> void:
	_title_screen.call(&"hide_screen")
	_settings_screen.call(&"hide_screen")
	_error_panel.visible = false


func _show_title_screen() -> void:
	_end_world_load()
	_gameplay_hud.visible = false
	_help_panel.visible = false
	_settings_screen.call(&"hide_screen")
	_title_screen.call(&"show_screen")


func _on_flow_state_changed(_previous_state: int, current_state: int) -> void:
	if current_state == GameFlow.FlowState.TITLE:
		_active_character = null
		_scout.set_hud_visible(false)
		_equipment_screen.call(&"hide_screen")
		_set_field_mouse_captured(false)
		_show_title_screen()
		_title_audio.call(&"set_menu_music_active", true)
	elif current_state == GameFlow.FlowState.FIELD or current_state == GameFlow.FlowState.DEBUG:
		_title_audio.call(&"set_menu_music_active", false)
		_gameplay_hud.visible = true
		_help_panel.visible = true
		_title_screen.call(&"hide_screen")
		_settings_screen.call(&"hide_screen")
		_bind_scout_to_active_world()
		_scout.set_hud_visible(true)
		if _world_load_busy:
			_set_field_player_input_enabled(false)
			_set_field_mouse_captured(false)
		else:
			_set_field_mouse_captured(not _scout.is_picking())


func _on_active_world_changed(_active_world: Node) -> void:
	_apply_settings_to_active_world()
	if GameFlow.state == GameFlow.FlowState.FIELD or GameFlow.state == GameFlow.FlowState.DEBUG:
		_bind_scout_to_active_world()
		_bind_equipment_screen()


func _bind_scout_to_active_world() -> void:
	var zone: Node = GameFlow.get_active_world()
	if zone == null:
		return
	var manifest: ZoneManifest = ContentDB.get_zone(BRINDLEWICK_ZONE_ID)
	_scout.bind_world(_world_viewport, zone, manifest)


func _on_scout_mouse_capture_changed(captured: bool) -> void:
	if _world_load_busy:
		return
	if GameFlow.state == GameFlow.FlowState.FIELD or GameFlow.state == GameFlow.FlowState.DEBUG:
		_set_field_mouse_captured(captured)


func _on_active_device_changed(_device_type: StringName) -> void:
	_update_prompt_text()


func _on_settings_changed() -> void:
	_apply_accessibility_settings()
	_save_settings()


func _apply_accessibility_settings() -> void:
	_apply_text_scale(_settings.text_scale)
	_apply_presentation_quality()
	_apply_display_settings()
	_apply_settings_to_active_world()
	_title_screen.call(
		&"set_reduced_motion",
		_settings.camera_motion_mode != AccessibilitySettings.CameraMotionMode.FULL
	)


func _apply_presentation_quality() -> void:
	var scale: float = 1.0
	match _settings.presentation_quality:
		AccessibilitySettings.PresentationQuality.LOW:
			scale = 640.0 / 1920.0
		AccessibilitySettings.PresentationQuality.MEDIUM:
			scale = 1280.0 / 1920.0
		_:
			scale = 1.0
	_world_viewport.scaling_3d_scale = scale
	if _settings.presentation_quality == AccessibilitySettings.PresentationQuality.HIGH:
		_world_viewport.msaa_3d = Viewport.MSAA_4X
	else:
		_world_viewport.msaa_3d = Viewport.MSAA_2X
	_title_screen.call(&"apply_canvas_size", AccessibilitySettings.CANVAS_HIGH)


func _apply_display_settings() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if DisplayServer.get_name() == "headless":
		screen_size = Vector2i(1920, 1080)
	var window: Window = get_window()
	if window != null:
		window.content_scale_size = Vector2i(DisplaySettings.REFERENCE_SIZE)
	_display.apply_to_window(window, screen_size)
	_apply_ui_scale()


func _apply_ui_scale() -> void:
	var canvas: Vector2 = DisplaySettings.REFERENCE_SIZE
	var scale: float = _display.ui_scale
	_ui_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_ui_root.anchor_right = 0.0
	_ui_root.anchor_bottom = 0.0
	_ui_root.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_ui_root.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ui_root.position = Vector2.ZERO
	_ui_root.scale = Vector2(scale, scale)
	_ui_root.size = _display.layout_size(canvas)


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
	var traveler: String = _active_character.display_name if _active_character != null else "Wanderer"
	_build_label.text = "ASTERFOLD  •  %s\n%s  •  BRINDLEWICK WALKING DIORAMA" % [
		str(ProjectSettings.get_setting("application/config/version", "unknown")),
		traveler,
	]
	_instructions.text = "MOVE  —  %s\nPEEK  —  MOUSE / %s / RIGHT STICK\nLOOK AROUND  —  %s\nEQUIPMENT  —  %s\nHELP  —  %s\nRETURN TO TITLE  —  %s\nFULLSCREEN  —  F11 / ALT+ENTER\nQUIT  —  F10" % [
		InputRouter.get_prompt(&"move_forward"),
		InputRouter.get_prompt(&"peek"),
		InputRouter.get_prompt(&"scout"),
		InputRouter.get_prompt(&"equipment"),
		InputRouter.get_prompt(&"menu"),
		InputRouter.get_prompt(&"cancel"),
	]


func _on_world_load_blocker_gui_input(_event: InputEvent) -> void:
	_world_load_blocker.accept_event()


func _begin_world_load(reason: String) -> bool:
	if _world_load_busy:
		return false
	_world_load_busy = true
	_title_screen.call(&"set_busy", true, reason)
	_world_load_blocker.visible = true
	_world_load_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	return true


func _hold_world_load_until_idle() -> void:
	await get_tree().process_frame
	while is_inside_tree() and _activation_hold_active():
		await get_tree().process_frame
	if is_inside_tree():
		_end_world_load()


func _activation_hold_active() -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		return true
	if Input.is_action_pressed(&"confirm"):
		return true
	if Input.is_action_pressed(&"cancel"):
		return true
	if Input.is_action_pressed(&"menu"):
		return true
	if Input.is_action_pressed(&"quit_prompt"):
		return true
	return false


func _end_world_load() -> void:
	if not _world_load_busy:
		return
	_world_load_busy = false
	_title_screen.call(&"set_busy", false)
	_world_load_blocker.visible = false
	_world_load_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var in_world: bool = (
		GameFlow.state == GameFlow.FlowState.FIELD
		or GameFlow.state == GameFlow.FlowState.DEBUG
	)
	if in_world:
		_set_field_player_input_enabled(true)
		_set_field_mouse_captured(not _scout.is_picking())


func _show_error(message: String) -> void:
	push_warning("[FLOW] %s" % message.replace("\n", " "))
	_end_world_load()
	_set_field_mouse_captured(false)
	_hide_frontend()
	_gameplay_hud.visible = false
	_error_label.text = "ASTERFOLD COULD NOT CONTINUE\n\n%s\n\nPress %s to return to title." % [
		message,
		InputRouter.get_prompt(&"cancel"),
	]
	_error_panel.visible = true
