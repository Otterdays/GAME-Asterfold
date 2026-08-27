extends Node

const CAPTURE_ROOT: String = "res://builds/captures/m1"
const OUTPUT_SIZE: Vector2i = Vector2i(1920, 1080)

@onready var _app: Node = %App


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_size(OUTPUT_SIZE)
	for frame: int in 4:
		await get_tree().process_frame
	await _capture("title_100")
	_app.call(&"_open_settings")
	await get_tree().process_frame
	await _capture("settings_100")
	var settings: AccessibilitySettings = _app.get("_settings") as AccessibilitySettings
	settings.set_text_scale(1.5)
	_app.call(&"_on_settings_changed")
	var settings_screen: Control = _app.find_child("SettingsScreen", true, false) as Control
	settings_screen.call(&"_refresh_values")
	await get_tree().process_frame
	await _capture("settings_150")
	settings.set_text_scale(1.0)
	_app.call(&"_on_settings_changed")
	_app.call(&"_close_settings")
	_app.call(&"_start_diorama")
	for frame: int in 30:
		await get_tree().process_frame
	var help_panel: Control = _app.find_child("HelpPanel", true, false) as Control
	if help_panel != null:
		help_panel.visible = false
	await _capture("brindlewick_center")
	var zone: Node = GameFlow.get_active_world()
	var camera_rig: WorldCameraRig = zone.get("camera_rig") as WorldCameraRig
	var player: PlayerActor = zone.get("player") as PlayerActor
	print("[CAPTURE] Player world position: %s" % player.global_position)
	print("[CAPTURE] Camera world position: %s" % camera_rig.get_camera().global_position)
	print("[CAPTURE] Player screen position: %s" % camera_rig.get_camera().unproject_position(player.global_position + Vector3(0.0, 0.9, 0.0)))
	await _capture_peek(camera_rig, Vector2(-24.0, 8.0), "peek_left_up")
	await _capture_peek(camera_rig, Vector2(24.0, -8.0), "peek_right_down")
	for mode: int in [
		AccessibilitySettings.CameraMotionMode.FULL,
		AccessibilitySettings.CameraMotionMode.REDUCED,
		AccessibilitySettings.CameraMotionMode.MINIMAL,
	]:
		settings.set_camera_motion_mode(mode)
		camera_rig.apply_accessibility_settings(settings)
		var model: CameraPeekModel = camera_rig.get("_peek_model") as CameraPeekModel
		model.reset()
		var sample: Vector2 = model.advance(Vector2(0.8, 0.0), 0.12)
		camera_rig.call(&"_apply_peek_transform", sample)
		await _capture("motion_%s" % AccessibilitySettings.motion_mode_label(mode).to_lower())
	camera_rig.reset_peek_immediately()
	var gameplay_hud: Control = _app.find_child("GameplayHUD", true, false) as Control
	if gameplay_hud != null:
		gameplay_hud.visible = false
	var fixture_scene: PackedScene = load("res://scenes/debug/sprite_direction_fixture.tscn") as PackedScene
	var fixture: Control = fixture_scene.instantiate() as Control
	add_child(fixture)
	await get_tree().process_frame
	await _capture("sprite_direction_spin")
	fixture.queue_free()
	await get_tree().process_frame
	_write_metadata()
	get_tree().quit(0)


func _capture_peek(camera_rig: WorldCameraRig, degrees: Vector2, file_stem: String) -> void:
	var model: CameraPeekModel = camera_rig.get("_peek_model") as CameraPeekModel
	model.current_degrees = degrees
	model.target_degrees = degrees
	camera_rig.call(&"_apply_peek_transform", degrees)
	await _capture(file_stem)


func _capture(file_stem: String) -> void:
	await RenderingServer.frame_post_draw
	var directory_path: String = ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(directory_path)
	var image: Image = get_viewport().get_texture().get_image()
	var output_path: String = "%s/%s.png" % [directory_path, file_stem]
	var save_error: Error = image.save_png(output_path)
	if save_error != OK:
		push_error("[CAPTURE] Failed to save %s: error %d." % [output_path, save_error])
	else:
		print("[CAPTURE] %s" % output_path)


func _write_metadata() -> void:
	var directory_path: String = ProjectSettings.globalize_path(CAPTURE_ROOT)
	var metadata: Dictionary = {
		"engine": Engine.get_version_info().get("string", "unknown"),
		"build": ProjectSettings.get_setting("application/config/version", "unknown"),
		"renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"internal_resolution": [640, 360],
		"output_resolution": [OUTPUT_SIZE.x, OUTPUT_SIZE.y],
		"zone": "zone.brindlewick_square",
		"facet": "north",
		"motion_modes": ["full", "reduced", "minimal"],
	}
	var file: FileAccess = FileAccess.open("%s/capture_metadata.json" % directory_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(metadata, "  ") + "\n")
