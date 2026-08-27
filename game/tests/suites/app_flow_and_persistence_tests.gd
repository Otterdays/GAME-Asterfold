extends TestCase

const REQUIRED_SCENES: Array[String] = [
	"res://scenes/app/app.tscn",
	"res://scenes/debug/metrics_scene.tscn",
	"res://scenes/characters/mara_player.tscn",
	"res://scenes/world/world_camera_rig.tscn",
	"res://content/zones/brindlewick_square/brindlewick_square.tscn",
	"res://scenes/ui/character_select_screen.tscn",
	"res://scenes/ui/character_create_screen.tscn",
]
const TEST_SETTINGS_PATH: String = "user://asterfold_test_settings.cfg"


func suite_name() -> String:
	return "app_flow_and_persistence"


func run() -> void:
	_test_scene_resources()
	_test_settings_persistence()
	await _test_title_audio()
	await _test_title_busy_lock()
	await _test_app_flow_and_movement()


func _test_scene_resources() -> void:
	for scene_path: String in REQUIRED_SCENES:
		_check(ResourceLoader.exists(scene_path, "PackedScene"), "Scene '%s' exists." % scene_path)
		var packed_scene: PackedScene = load(scene_path) as PackedScene
		_check(packed_scene != null, "Scene '%s' loads." % scene_path)
		if packed_scene != null:
			var instance: Node = packed_scene.instantiate()
			_check(instance != null, "Scene '%s' instantiates." % scene_path)
			instance.free()


func _test_settings_persistence() -> void:
	var accessibility: Dictionary = {
		"camera_motion_mode": AccessibilitySettings.CameraMotionMode.REDUCED,
		"text_scale": 1.5,
		"confirm_cancel_swapped": true,
	}
	var video: Dictionary = {
		"window_mode": DisplaySettings.WindowModeOption.BORDERLESS,
		"resolution_x": 1920,
		"resolution_y": 1080,
		"ui_scale": 1.25,
	}
	var bindings: Dictionary = input_router.call(&"serialize_bindings") as Dictionary
	_check(SettingsStore.save_data_to_path(TEST_SETTINGS_PATH, accessibility, bindings, video) == OK, "Settings write through ConfigFile.")
	var loaded: Dictionary = SettingsStore.load_data_from_path(TEST_SETTINGS_PATH)
	_check(loaded.get("accessibility", {}) == accessibility, "Accessibility settings persist separately from game state.")
	_check(loaded.get("bindings", {}) == bindings, "Custom bindings persist with accessibility settings.")
	_check(loaded.get("video", {}) == video, "Video settings persist separately from accessibility settings.")
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))


func _test_title_audio() -> void:
	_check(FileAccess.file_exists("res://assets/audio/music/title_fold_between.wav"), "Title loop WAV exists.")
	_check(FileAccess.file_exists("res://assets/audio/ui/ui_hover_bling.wav"), "UI hover bling WAV exists.")
	_check(FileAccess.file_exists("res://assets/audio/ui/ui_click.wav"), "UI click WAV exists.")
	var hover: PackedFloat32Array = ProceduralFoley.hover_bling_samples()
	var click: PackedFloat32Array = ProceduralFoley.click_samples()
	var loop: PackedFloat32Array = ProceduralFoley.title_loop_samples()
	_check(hover.size() > 100, "Hover bling synthesis produces samples.")
	_check(click.size() > 50, "Click synthesis produces samples.")
	_check(
		loop.size() == int(ProceduralFoley.TITLE_DURATION_S * float(ProceduralFoley.SAMPLE_RATE)),
		"Title loop length matches the seeded duration."
	)
	var button := Button.new()
	button.custom_minimum_size = Vector2(80, 32)
	var feedback := UiButtonFeedback.new()
	tree.root.add_child(button)
	tree.root.add_child(feedback)
	feedback.call(&"_wire_button", button)
	feedback.call(&"_on_mouse_entered", button)
	_check(
		button.modulate.is_equal_approx(UiButtonFeedback.HOVER_MODULATE),
		"Hovering a UI button applies the highlight modulate."
	)
	_check(button.scale.is_equal_approx(UiButtonFeedback.HOVER_SCALE), "Hovering a UI button lifts scale.")
	feedback.call(&"_on_mouse_exited", button)
	_check(button.modulate.is_equal_approx(Color.WHITE), "Leaving a UI button restores modulate.")
	button.queue_free()
	feedback.queue_free()
	await tree.process_frame


func _test_title_busy_lock() -> void:
	var packed_scene: PackedScene = load("res://scenes/ui/title_screen.tscn") as PackedScene
	if packed_scene == null:
		_check(false, "Title screen loads for busy-lock testing.")
		return
	var title: Control = packed_scene.instantiate() as Control
	tree.root.add_child(title)
	await tree.process_frame
	var start_button: Button = title.find_child("StartButton", true, false) as Button
	var quit_button: Button = title.find_child("QuitButton", true, false) as Button
	var catcher: Control = title.find_child("InputCatcher", true, false) as Control
	_check(not bool(title.call(&"is_busy")), "Title starts interactive.")
	title.call(&"set_busy", true, "Loading the walking diorama.")
	_check(bool(title.call(&"is_busy")), "Busy lock is queryable.")
	_check(
		start_button != null and quit_button != null and start_button.disabled and quit_button.disabled,
		"Busy lock disables every title action."
	)
	_check(
		catcher != null and catcher.visible and catcher.mouse_filter == Control.MOUSE_FILTER_STOP,
		"Busy lock covers the title with an input sink."
	)
	_check(
		start_button != null and start_button.tooltip_text == "Loading the walking diorama.",
		"Disabled title actions explain the load lock."
	)
	var quit_emitted: bool = false
	title.connect(&"quit_requested", func() -> void: quit_emitted = true)
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"cancel"
	cancel_event.pressed = true
	title.call(&"_unhandled_input", cancel_event)
	_check(not quit_emitted, "Cancel does not quit while the title is busy.")
	title.call(&"set_busy", false)
	_check(not bool(title.call(&"is_busy")), "Clearing the lock restores interactivity.")
	_check(start_button != null and not start_button.disabled, "Clearing the lock restores Start.")
	title.queue_free()
	await tree.process_frame


func _test_app_flow_and_movement() -> void:
	var app_scene: PackedScene = load("res://scenes/app/app.tscn") as PackedScene
	if app_scene == null:
		_check(false, "App integration scene loads for flow testing.")
		return
	var app: Node = app_scene.instantiate()
	tree.root.add_child(app)
	await tree.process_frame
	await tree.process_frame
	_check(int(game_flow.get("state")) == 1, "Boot enters the title state.")
	var title_screen: Control = app.find_child("TitleScreen", true, false) as Control
	var start_button: Button = app.find_child("StartButton", true, false) as Button
	_check(title_screen != null and title_screen.visible, "Title screen is visible after boot.")
	_check(start_button != null and start_button.has_focus(), "Title screen assigns deterministic initial focus.")
	_check(start_button != null and start_button.text == "Play", "Title Play opens the adventurer roster.")
	var select_screen: Control = app.find_child("CharacterSelectScreen", true, false) as Control
	title_screen.call(&"_on_start_pressed")
	await tree.process_frame
	_check(select_screen != null and select_screen.visible, "Play shows the three-slot character select.")
	var locked_button: Button = null
	for child: Node in select_screen.find_children("*", "Button", true, false):
		var button: Button = child as Button
		if button != null and button.text == "Locked":
			locked_button = button
			break
	_check(
		locked_button != null and not locked_button.disabled and locked_button.tooltip_text.contains("later milestone"),
		"Two later character slots stay locked with a text reason."
	)
	title_screen.call(&"_show_menu")
	await tree.process_frame
	var title_audio: Node = app.find_child("TitleShellAudio", true, false)
	_check(
		title_audio != null and bool(title_audio.call(&"is_menu_music_active")),
		"Title music is armed on the title screen."
	)
	var feedback: UiButtonFeedback = app.find_child("UiButtonFeedback", true, false) as UiButtonFeedback
	_check(feedback != null, "Shell UI wires button hover and click feedback.")
	app.call(&"_start_diorama")
	_check(bool(app.call(&"is_world_load_busy")), "Title stays locked until the first idle field frame.")
	var zone_first: Node = game_flow.call(&"get_active_world") as Node
	app.call(&"_start_diorama")
	_check(
		game_flow.call(&"get_active_world") == zone_first,
		"A second start during the load lock does not rebuild the zone."
	)
	var load_blocker: Control = app.find_child("WorldLoadBlocker", true, false) as Control
	_check(
		load_blocker != null and load_blocker.visible and load_blocker.mouse_filter == Control.MOUSE_FILTER_STOP,
		"A full-screen sink covers the field until the load lock ends."
	)
	await tree.process_frame
	await tree.physics_frame
	_check(not bool(app.call(&"is_world_load_busy")), "The load lock releases after the field is idle.")
	_check(load_blocker != null and not load_blocker.visible, "The input sink hides when the lock ends.")
	_check(int(game_flow.get("state")) == 2, "Starting the diorama enters the field state.")
	_check(
		title_audio != null and not bool(title_audio.call(&"is_menu_music_active")),
		"Title music stops when the walking diorama starts."
	)
	var zone: Node = game_flow.call(&"get_active_world") as Node
	_check(zone != null and zone.name == "BrindlewickSquare", "The registered Brindlewick zone instantiates.")
	var player: CharacterBody3D = zone.get("player") as CharacterBody3D if zone != null else null
	_check(player != null, "Mara is present in the composed zone.")
	if player != null:
		_check(absf(player.global_position.z - 20.0) < 0.1, "Mara uses the stable south-gate spawn.")
		var start_x: float = player.global_position.x
		Input.action_press(&"move_right", 1.0)
		for frame: int in 8:
			await tree.physics_frame
		Input.action_release(&"move_right")
		_check(player.global_position.x > start_x, "Synthetic keyboard input moves Mara in the field.")
	var scout: FirstPersonScout = app.find_child("FirstPersonScout", true, false) as FirstPersonScout
	_check(scout != null, "Field HUD includes the first-person scout.")
	if scout != null and player != null:
		scout.open_picker()
		_check(scout.is_picking(), "Look around opens the top-down zone map.")
		scout.enter_at_world_xz(Vector3(0.0, 0.0, 0.0))
		_check(scout.is_looking(), "Map click enters first-person view.")
		_check(not player.visible, "First-person view hides Mara's body.")
		_check(scout.get_node("%Crosshair").visible, "First-person view shows a center crosshair.")
		scout.exit_to_field()
		_check(not scout.is_looking() and player.visible, "Leaving first person restores the diorama body.")
	var settings_screen: Control = app.find_child("SettingsScreen", true, false) as Control
	game_flow.call(&"show_title")
	await tree.process_frame
	app.call(&"_open_settings")
	await tree.process_frame
	_check(settings_screen != null and settings_screen.visible and not title_screen.visible, "Settings opens from title without overlapping focus layers.")
	var settings_pages: TabContainer = settings_screen.find_child("SettingsPages", true, false) as TabContainer
	_check(settings_pages != null and settings_pages.get_tab_count() == 3, "Settings uses Video, Accessibility, and Controls tabs.")
	_check(settings_pages.get_tab_title(0) == "Video" and settings_pages.get_tab_title(1) == "Accessibility" and settings_pages.get_tab_title(2) == "Controls", "Settings tab titles match page names.")
	settings_pages.current_tab = 2
	await tree.process_frame
	var controls_page: Control = settings_pages.get_current_tab_control()
	_check(controls_page != null and controls_page.name == "Controls" and controls_page.visible, "Selecting Controls shows the bindings page.")
	settings_pages.current_tab = 0
	await tree.process_frame
	var video_page: Control = settings_pages.get_current_tab_control()
	_check(video_page != null and video_page.name == "Video" and video_page.visible, "Selecting Video shows window, resolution, UI scale, and presentation quality options.")
	settings_pages.current_tab = 1
	await tree.process_frame
	var accessibility_page: Control = settings_pages.get_current_tab_control()
	_check(accessibility_page != null and accessibility_page.name == "Accessibility" and accessibility_page.visible, "Selecting Accessibility shows camera and text options.")
	app.call(&"_close_settings")
	await tree.process_frame
	await tree.process_frame
	_check(title_screen.visible and start_button.has_focus(), "Returning from settings restores title focus.")
	var failure_messages: Array[String] = []
	var capture_failure: Callable = func(message: String) -> void: failure_messages.append(message)
	game_flow.connect(&"flow_failed", capture_failure, CONNECT_ONE_SHOT)
	_check(not bool(game_flow.call(&"load_zone", &"zone.missing", &"spawn.missing")), "Missing content produces a structured flow failure.")
	await tree.process_frame
	_check(not failure_messages.is_empty() and not failure_messages[0].is_empty(), "Missing-content failure includes a readable message.")
	var error_panel: Control = app.find_child("ErrorPanel", true, false) as Control
	_check(error_panel != null and error_panel.visible, "The app presents load failures in its readable error panel.")
	game_flow.call(&"show_title")
	app.queue_free()
	await tree.process_frame
