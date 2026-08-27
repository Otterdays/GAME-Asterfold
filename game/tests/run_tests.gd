extends SceneTree

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_forward",
	&"move_back",
	&"confirm",
	&"cancel",
	&"menu",
	&"peek",
	&"peek_left",
	&"peek_right",
	&"peek_up",
	&"peek_down",
	&"fold_left",
	&"fold_right",
]
const REQUIRED_SCENES: Array[String] = [
	"res://scenes/app/app.tscn",
	"res://scenes/debug/metrics_scene.tscn",
	"res://scenes/characters/mara_player.tscn",
	"res://scenes/world/world_camera_rig.tscn",
	"res://content/zones/brindlewick_square/brindlewick_square.tscn",
]
const TEST_SETTINGS_PATH: String = "user://asterfold_test_settings.cfg"

var _failures: Array[String] = []
var _checks: int = 0
var _input_router: Node
var _content_db: Node
var _game_flow: Node


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_install_test_services()
	_test_project_contract()
	_test_camera_relative_movement()
	_test_direction_resolution()
	_test_peek_motion()
	_test_map_maker_camera_session()
	_test_accessibility_settings()
	_test_input_router()
	_test_zone_manifest()
	_test_dirt_road_network()
	_test_world_placements()
	_test_scene_resources()
	_test_settings_persistence()
	await _test_app_flow_and_movement()
	_finish()


func _test_project_contract() -> void:
	_check(
		str(ProjectSettings.get_setting("application/config/version", "")) == "0.1.0-dev",
		"The development build version is configured."
	)
	_check(
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility")) != "gl_compatibility",
		"The project does not opt into the compatibility renderer."
	)
	for action: StringName in REQUIRED_ACTIONS:
		_check(InputMap.has_action(action), "Semantic input action '%s' exists." % action)
	_check(is_equal_approx(InputMap.action_get_deadzone(&"move_left"), 0.2), "Movement dead zone is explicit.")


func _test_camera_relative_movement() -> void:
	_check_vector3(
		MovementMath.camera_relative_direction(Vector2(0.0, -1.0), 0.0),
		Vector3(0.0, 0.0, -1.0),
		"Forward input follows committed north."
	)
	_check_vector3(
		MovementMath.camera_relative_direction(Vector2(1.0, 0.0), 0.0),
		Vector3(1.0, 0.0, 0.0),
		"Right input follows committed east."
	)
	_check_vector3(
		MovementMath.camera_relative_direction(Vector2(0.0, -1.0), PI * 0.5),
		Vector3(-1.0, 0.0, 0.0),
		"Committed yaw rotates movement basis."
	)
	var diagonal: Vector3 = MovementMath.camera_relative_direction(Vector2(1.0, -1.0), 0.0)
	_check(is_equal_approx(diagonal.length(), 1.0), "Diagonal movement is normalized.")
	_check_vector3(
		MovementMath.camera_relative_direction(Vector2.ZERO, 1.1),
		Vector3.ZERO,
		"Zero input remains stationary."
	)


func _test_direction_resolution() -> void:
	_check(SpriteDirectionResolver.resolve(Vector3.FORWARD, 0.0) == SpriteDirectionResolver.Direction.NORTH, "North facing resolves north.")
	_check(SpriteDirectionResolver.resolve(Vector3.RIGHT, 0.0) == SpriteDirectionResolver.Direction.EAST, "East facing resolves east.")
	_check(SpriteDirectionResolver.resolve(Vector3.BACK, 0.0) == SpriteDirectionResolver.Direction.SOUTH, "South facing resolves south.")
	_check(SpriteDirectionResolver.resolve(Vector3.LEFT, 0.0) == SpriteDirectionResolver.Direction.WEST, "West facing resolves west.")
	_check(SpriteDirectionResolver.resolve(_facing_at_degrees(25.0), 0.0, SpriteDirectionResolver.Direction.NORTH) == SpriteDirectionResolver.Direction.NORTH, "Direction hysteresis retains the prior sector near a boundary.")
	_check(SpriteDirectionResolver.resolve(_facing_at_degrees(30.0), 0.0, SpriteDirectionResolver.Direction.NORTH) == SpriteDirectionResolver.Direction.NORTH_EAST, "Direction hysteresis releases after its retention band.")
	_check(SpriteDirectionResolver.resolve(Vector3.ZERO, 0.0, SpriteDirectionResolver.Direction.WEST) == SpriteDirectionResolver.Direction.WEST, "Stationary actors retain their displayed facing.")


func _test_peek_motion() -> void:
	var model: CameraPeekModel = CameraPeekModel.new()
	model.set_motion_mode(AccessibilitySettings.CameraMotionMode.MINIMAL)
	_check_vector2(model.advance(Vector2(1.0, 1.0), 0.016), Vector2(24.0, -8.0), "Minimal Peek snaps to default clamps.")
	model.set_limits(12.0, 4.0)
	_check_vector2(model.advance(Vector2(1.0, -1.0), 0.016), Vector2(12.0, 4.0), "Camera volumes constrain Peek clamps.")
	model.reset()
	model.set_motion_mode(AccessibilitySettings.CameraMotionMode.REDUCED)
	model.advance(Vector2(0.49, 0.0), 0.016)
	_check_vector2(model.target_degrees, Vector2.ZERO, "Reduced Peek ignores input below the discrete threshold.")
	model.advance(Vector2(0.5, 0.0), 0.016)
	_check_vector2(model.target_degrees, Vector2(12.0, 0.0), "Reduced Peek selects a discrete offset.")
	model.set_motion_mode(AccessibilitySettings.CameraMotionMode.MINIMAL)
	model.advance(Vector2.ZERO, 9.99)
	_check_vector2(model.current_degrees, Vector2(12.0, 0.0), "Peek does not recenter before 10 seconds.")
	model.advance(Vector2.ZERO, 0.02)
	_check_vector2(model.current_degrees, Vector2.ZERO, "Minimal Peek recenters instantly after 10 idle seconds.")
	model.reset()
	model.set_limits(24.0, 8.0)
	model.set_motion_mode(AccessibilitySettings.CameraMotionMode.MINIMAL)
	model.advance_activity(Vector2(1.0, 0.0), 0.016, true)
	model.advance_activity(Vector2(1.0, 0.0), 9.99, false)
	_check_vector2(model.current_degrees, Vector2(24.0, 0.0), "Held mouse Peek stays until idle timeout.")
	model.advance_activity(Vector2.ZERO, 0.02, false)
	_check_vector2(model.current_degrees, Vector2.ZERO, "Idle mouse Peek restores default vision at 10 seconds.")
	model.reset()
	model.set_motion_mode(AccessibilitySettings.CameraMotionMode.FULL)
	var first_step: Vector2 = model.advance(Vector2(1.0, 0.0), 0.016)
	_check(first_step.x > 0.0 and first_step.x < 24.0, "Full Peek uses a damped continuous response.")


func _test_map_maker_camera_session() -> void:
	var session_script: GDScript = load("res://tools/map_maker/map_maker_camera_session.gd") as GDScript
	_check(session_script != null, "Map maker camera session script loads.")
	var session: RefCounted = session_script.new() as RefCounted
	_check(bool(session.call(&"is_following")), "Map maker camera follows the cursor at start.")
	_check(not bool(session.call(&"advance", 9.99)), "Cursor follow does not reset before 10 seconds.")
	_check(bool(session.call(&"advance", 0.02)), "Idle follow restores default vision at 10 seconds.")
	_check(not bool(session.call(&"is_following")), "Restored vision stays parked until the cursor moves.")
	_check(not bool(session.call(&"advance", 20.0)), "Parked default vision does not keep retriggering.")
	session.call(&"note_cursor_moved")
	_check(bool(session.call(&"is_following")), "Cursor motion relocks the map maker camera.")
	session.call(&"note_manual_camera")
	_check(not bool(session.call(&"is_following")), "Orbit, pan, or zoom takes manual camera control.")
	_check(bool(session.call(&"advance", 10.0)), "Manual camera restores default vision after 10 idle seconds.")
	session.call(&"configure", false, true, 10.0)
	_check(not bool(session.call(&"is_following")), "Follow cursor is optional in map maker settings.")
	session.call(&"configure", true, false, 10.0)
	session.call(&"note_cursor_moved")
	_check(not bool(session.call(&"advance", 20.0)), "Idle restore can be disabled in map maker settings.")


func _test_accessibility_settings() -> void:
	var settings: AccessibilitySettings = AccessibilitySettings.new()
	settings.set_text_scale(1.44)
	_check(is_equal_approx(settings.text_scale, 1.5), "Text scale snaps to 150 percent.")
	settings.set_camera_motion_mode(99)
	_check(settings.camera_motion_mode == AccessibilitySettings.CameraMotionMode.MINIMAL, "Camera mode clamps to supported values.")
	settings.set_confirm_cancel_swapped(true)
	var restored: AccessibilitySettings = AccessibilitySettings.new()
	restored.apply_dictionary(settings.to_dictionary())
	_check(restored.camera_motion_mode == settings.camera_motion_mode, "Camera setting round-trips.")
	_check(is_equal_approx(restored.text_scale, settings.text_scale), "Text scale round-trips.")
	_check(restored.confirm_cancel_swapped, "Confirm/cancel preference round-trips.")


func _test_input_router() -> void:
	var w_key: InputEventKey = InputEventKey.new()
	w_key.physical_keycode = KEY_W
	_check((_input_router.call(&"find_conflicts", w_key) as Array).has(&"move_forward"), "Binding conflicts detect an occupied key.")
	_check(not (_input_router.call(&"find_conflicts", w_key, &"move_forward") as Array).has(&"move_forward"), "Conflict checks can exclude the edited action.")
	var original_bindings: Dictionary = _input_router.call(&"serialize_bindings") as Dictionary
	var test_key: InputEventKey = InputEventKey.new()
	test_key.physical_keycode = KEY_T
	_check(bool(_input_router.call(&"rebind_action", &"move_forward", test_key, false)), "A free keyboard binding can be captured.")
	_check(String(_input_router.call(&"get_prompt", &"move_forward")).contains("T"), "Prompt labels update after rebinding.")
	_input_router.call(&"apply_serialized_bindings", original_bindings)
	_input_router.call(&"swap_confirm_cancel")
	_check(String(_input_router.call(&"get_prompt", &"confirm")) == "Escape", "Confirm/cancel preference swaps semantic keyboard prompts.")
	_check(_actions_share_events(&"confirm", &"ui_accept"), "Swapped confirm bindings drive UI activation.")
	_check(_actions_share_events(&"cancel", &"ui_cancel"), "Swapped cancel bindings drive UI cancellation.")
	_input_router.call(&"swap_confirm_cancel")
	var router_script: Script = load("res://src/services/input_router.gd") as Script
	var tracker: Node = router_script.new() as Node
	var joy_event: InputEventJoypadButton = InputEventJoypadButton.new()
	joy_event.pressed = true
	tracker.call(&"consider_input_device", joy_event, 1000)
	_check(tracker.call(&"get_active_device") == &"gamepad", "Gamepad activity changes the active device.")
	var key_event: InputEventKey = InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_A
	tracker.call(&"consider_input_device", key_event, 1100)
	_check(tracker.call(&"get_active_device") == &"gamepad", "Device hysteresis rejects rapid prompt flicker.")
	tracker.call(&"consider_input_device", key_event, 1300)
	_check(tracker.call(&"get_active_device") == &"keyboard_mouse", "Device hysteresis accepts settled device changes.")
	tracker.call(&"consider_input_device", joy_event, 1600)
	tracker.call(&"_on_joy_connection_changed", 0, false)
	_check(tracker.call(&"get_active_device") == &"keyboard_mouse", "Disconnecting the active gamepad restores keyboard prompts.")
	tracker.free()


func _test_zone_manifest() -> void:
	_check(bool(_content_db.call(&"is_valid")), "The explicit content registry validates.")
	var manifest: ZoneManifest = _content_db.call(&"get_zone", &"zone.brindlewick_square") as ZoneManifest
	_check(manifest != null, "Brindlewick resolves by stable zone ID.")
	if manifest != null:
		_check(manifest.spawn_ids.has(&"spawn.brindlewick_square.south_gate"), "Brindlewick declares its south-gate spawn.")
		_check(manifest.validation_bounds.has_point(Vector3.ZERO), "Brindlewick validation bounds contain the authored center.")
	var invalid: ZoneManifest = ZoneManifest.new()
	invalid.id = &"Bad Display Name"
	invalid.default_facet = &"south"
	invalid.allowed_facets = [&"north"]
	_check(invalid.validate_definition().size() >= 4, "Manifest validation reports ID, scene, facet, and spawn failures.")


func _test_dirt_road_network() -> void:
	var road_scene: PackedScene = load("res://scenes/world/surfaces/brindlewick_dirt_road_surface.tscn") as PackedScene
	_check(road_scene != null, "Brindlewick dirt-road network scene loads.")
	if road_scene == null:
		return
	var road: DirtRoadNetwork3D = road_scene.instantiate() as DirtRoadNetwork3D
	_check(road != null, "Dirt-road surface uses the reusable network component.")
	if road == null:
		return
	_check(road.get_patch_count() == 6, "Brindlewick road network declares six authored patches.")
	_check(road.validate_configuration().is_empty(), "Brindlewick road network configuration validates.")
	_check(
		DirtRoadNetwork3D.rounded_box_distance(Vector2.ZERO, Vector4(0.0, 0.0, 1.6, 1.6), 1.35) < 0.0,
		"Rounded road patches contain their center."
	)
	_check(
		DirtRoadNetwork3D.rounded_box_distance(Vector2(1.55, 1.55), Vector4(0.0, 0.0, 1.6, 1.6), 1.35) > 0.0,
		"Rounded road patches trim their square corner."
	)
	_check(
		DirtRoadNetwork3D.smooth_union_distance(-0.1, -0.1, 0.55) < -0.1,
		"Road-patch unions soften connected joins."
	)
	road.rebuild_surface()
	var runtime_material: ShaderMaterial = road.material_override as ShaderMaterial
	var road_layout: Resource = road.get("layout") as Resource
	_check(road_layout != null and road.mesh is ArrayMesh and road.mesh.get_surface_count() == 1, "Road layout builds one batched patch surface.")
	_check(road.mesh.get_faces().size() == road.get_patch_count() * 6, "Each road patch contributes two triangles to the bounded surface.")
	_check(
		runtime_material != null and int(runtime_material.get_shader_parameter(&"patch_count")) == 6,
		"Road layout is transferred to an instance-local shader material."
	)
	road.free()


func _test_world_placements() -> void:
	_check(ZonePlacement.snap_meters(2.4, 0.5) == 5, "World positions snap to the 0.5 m grid.")
	_check(ZonePlacement.snap_meters(-0.24, 0.5) == 0, "Grid snap rounds toward the nearest cell.")
	var catalog: WorldPieceCatalog = load("res://content/pieces/piece_catalog.tres") as WorldPieceCatalog
	_check(catalog != null and catalog.validate_definition().is_empty(), "Shared piece catalog validates.")
	_check(catalog != null and catalog.get_piece_ids().size() == 11, "Catalog exposes the full beginner piece set.")
	if catalog != null:
		_check(catalog.has_piece(&"piece.crate_block"), "Crate component is catalogued.")
		_check(catalog.has_piece(&"piece.lamp_post"), "Lamp component is catalogued.")
		_check(catalog.has_piece(&"piece.planter_box"), "Planter component is catalogued.")
		_check(catalog.has_piece(&"piece.bell_tower"), "Bell tower is catalogued.")
		_check(catalog.has_piece(&"piece.shade_tree"), "Shade tree is catalogued.")
		_check(catalog.get_pieces_in_family(&"building").size() == 7, "Building family contains the town landmarks.")
	var crate_scene: PackedScene = load("res://scenes/world/pieces/crate_block.tscn") as PackedScene
	var lamp_scene: PackedScene = load("res://scenes/world/pieces/lamp_post.tscn") as PackedScene
	var planter_scene: PackedScene = load("res://scenes/world/pieces/planter_box.tscn") as PackedScene
	var crate: Node = crate_scene.instantiate() if crate_scene != null else null
	var lamp: Node = lamp_scene.instantiate() if lamp_scene != null else null
	var planter: Node = planter_scene.instantiate() if planter_scene != null else null
	_check(crate is CrateBlock, "Crate piece is its own component type.")
	_check(lamp is LampPost, "Lamp piece is its own component type.")
	_check(planter is PlanterBox, "Planter piece is its own component type.")
	if crate != null:
		crate.free()
	if lamp != null:
		lamp.free()
	if planter != null:
		planter.free()
	var layout: ZonePlacementList = ZonePlacementList.new()
	layout.zone_id = &"zone.brindlewick_square"
	layout.set_cell(&"piece.crate_block", 2, 4, 1)
	layout.set_cell(&"piece.crate_block", 2, 4, 2)
	_check(layout.placements.size() == 1, "Placing on an occupied cell replaces the previous piece.")
	_check(layout.placements[0].yaw_quarter_turns == 2, "Replacement stores the new quarter-turn yaw.")
	var bounds: AABB = AABB(Vector3(-34.0, -2.0, -29.0), Vector3(68.0, 24.0, 58.0))
	_check(layout.validate_definition(catalog, bounds).is_empty(), "Valid placements pass catalog and bounds checks.")
	layout.set_cell(&"piece.missing", 0, 0)
	_check(not layout.validate_definition(catalog, bounds).is_empty(), "Unknown piece IDs fail validation.")
	var authored: ZonePlacementList = load("res://content/zones/brindlewick_square/brindlewick_square_placements.tres") as ZonePlacementList
	_check(authored != null and authored.placements.size() == 13, "Brindlewick stores thirteen map-maker placements.")
	var layer_scene: PackedScene = load("res://scenes/world/placement_layer.tscn") as PackedScene
	_check(layer_scene != null, "PlacementLayer scene loads.")
	if layer_scene != null:
		var layer: PlacementLayer = layer_scene.instantiate() as PlacementLayer
		layer.rebuild()
		_check(layer.get_placed_count() == 13, "PlacementLayer instances every authored world piece.")
		_check(layer.find_child("cell_8_22", true, false) is CrateBlock, "Authored crate occupies its grid cell.")
		layer.free()
	_check(ResourceLoader.exists("res://tools/map_maker/map_maker.tscn", "PackedScene"), "Internal map maker scene exists outside the playable shell.")
	var title_source: String = FileAccess.get_file_as_string("res://src/ui/title_screen.gd")
	_check(not title_source.contains("map_maker"), "Playable title does not mention the map maker.")
	_check(MapMakerWorldCoverage.connectivity_percent() == 100, "Coverage model treats the live zone as fully connected.")
	_check(MapMakerWorldCoverage.control_percent() == 81, "Coverage model scores current writable world surfaces at 81 percent.")
	_check(String(MapMakerWorldCoverage.ranked_next_routes()[0]["id"]) == "spawns", "Highest remaining authoring weight is spawn data.")
	var tooltip_catalog: MapMakerTooltipCatalog = load("res://tools/map_maker/map_maker_tooltip_catalog.tres") as MapMakerTooltipCatalog
	_check(tooltip_catalog != null and tooltip_catalog.validate_definition().is_empty(), "Map maker tooltips validate as a separate catalog.")
	_check(tooltip_catalog != null and not tooltip_catalog.format_text(&"tooltip.action.save").is_empty(), "Save tooltip has beginner copy.")
	var road_layout: DirtRoadLayout = DirtRoadLayout.new()
	road_layout.network_size_m = Vector2(68.0, 58.0)
	road_layout.patches = [Vector4(0.0, 0.0, 1.6, 1.6)]
	road_layout.corner_radii_m = PackedFloat32Array([1.0])
	_check(road_layout.set_patch_center(0, Vector2(4.0, -3.0)), "Road centers can move on the authored network.")
	_check(is_equal_approx(road_layout.patches[0].x, 4.0), "Moved road patch stores the new center X.")
	var house: WorldPieceDefinition = catalog.get_definition(&"piece.civic_house") if catalog != null else null
	_check(house != null and house.covered_cells(0, 0).size() == 18 * 14, "Building footprints occupy every covered grid cell.")


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
	var bindings: Dictionary = _input_router.call(&"serialize_bindings") as Dictionary
	_check(SettingsStore.save_data_to_path(TEST_SETTINGS_PATH, accessibility, bindings) == OK, "Settings write through ConfigFile.")
	var loaded: Dictionary = SettingsStore.load_data_from_path(TEST_SETTINGS_PATH)
	_check(loaded.get("accessibility", {}) == accessibility, "Accessibility settings persist separately from game state.")
	_check(loaded.get("bindings", {}) == bindings, "Custom bindings persist with accessibility settings.")
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))


func _test_app_flow_and_movement() -> void:
	var app_scene: PackedScene = load("res://scenes/app/app.tscn") as PackedScene
	if app_scene == null:
		_check(false, "App integration scene loads for flow testing.")
		return
	var app: Node = app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	_check(int(_game_flow.get("state")) == 1, "Boot enters the title state.")
	var title_screen: Control = app.find_child("TitleScreen", true, false) as Control
	var start_button: Button = app.find_child("StartButton", true, false) as Button
	_check(title_screen != null and title_screen.visible, "Title screen is visible after boot.")
	_check(start_button != null and start_button.has_focus(), "Title screen assigns deterministic initial focus.")
	app.call(&"_start_diorama")
	await process_frame
	await physics_frame
	_check(int(_game_flow.get("state")) == 2, "Starting the diorama enters the field state.")
	var zone: Node = _game_flow.call(&"get_active_world") as Node
	_check(zone != null and zone.name == "BrindlewickSquare", "The registered Brindlewick zone instantiates.")
	var player: CharacterBody3D = zone.get("player") as CharacterBody3D if zone != null else null
	_check(player != null, "Mara is present in the composed zone.")
	if player != null:
		_check(absf(player.global_position.z - 20.0) < 0.1, "Mara uses the stable south-gate spawn.")
		var start_x: float = player.global_position.x
		Input.action_press(&"move_right", 1.0)
		for frame: int in 8:
			await physics_frame
		Input.action_release(&"move_right")
		_check(player.global_position.x > start_x, "Synthetic keyboard input moves Mara in the field.")
	var settings_screen: Control = app.find_child("SettingsScreen", true, false) as Control
	_game_flow.call(&"show_title")
	await process_frame
	app.call(&"_open_settings")
	await process_frame
	_check(settings_screen != null and settings_screen.visible and not title_screen.visible, "Settings opens from title without overlapping focus layers.")
	app.call(&"_close_settings")
	await process_frame
	await process_frame
	_check(title_screen.visible and start_button.has_focus(), "Returning from settings restores title focus.")
	var failure_messages: Array[String] = []
	var capture_failure: Callable = func(message: String) -> void: failure_messages.append(message)
	_game_flow.connect(&"flow_failed", capture_failure, CONNECT_ONE_SHOT)
	_check(not bool(_game_flow.call(&"load_zone", &"zone.missing", &"spawn.missing")), "Missing content produces a structured flow failure.")
	await process_frame
	_check(not failure_messages.is_empty() and not failure_messages[0].is_empty(), "Missing-content failure includes a readable message.")
	var error_panel: Control = app.find_child("ErrorPanel", true, false) as Control
	_check(error_panel != null and error_panel.visible, "The app presents load failures in its readable error panel.")
	_game_flow.call(&"show_title")
	app.queue_free()
	await process_frame


func _finish() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_forward")
	Input.action_release(&"move_back")
	_input_router.call(&"reset_default_bindings")
	if _failures.is_empty():
		print("[TEST] PASS: %d checks." % _checks)
		quit(0)
		return
	for failure: String in _failures:
		push_error("[TEST] %s" % failure)
	print("[TEST] FAIL: %d of %d checks failed." % [_failures.size(), _checks])
	quit(1)


func _facing_at_degrees(degrees: float) -> Vector3:
	var radians: float = deg_to_rad(degrees)
	return Vector3(sin(radians), 0.0, -cos(radians))


func _install_test_services() -> void:
	_input_router = _install_service("InputRouter", "res://src/services/input_router.gd")
	_content_db = _install_service("ContentDB", "res://src/services/content_db.gd")
	_game_flow = _install_service("GameFlow", "res://src/services/game_flow.gd")


func _install_service(service_name: String, script_path: String) -> Node:
	var existing: Node = root.get_node_or_null(NodePath(service_name))
	if existing != null:
		return existing
	var service_script: Script = load(script_path) as Script
	var service: Node = service_script.new() as Node
	service.name = service_name
	root.add_child(service)
	return service


func _actions_share_events(left_action: StringName, right_action: StringName) -> bool:
	var left_events: Array[InputEvent] = InputMap.action_get_events(left_action)
	var right_events: Array[InputEvent] = InputMap.action_get_events(right_action)
	if left_events.size() != right_events.size():
		return false
	for left_event: InputEvent in left_events:
		var matched: bool = false
		for right_event: InputEvent in right_events:
			if left_event.is_match(right_event, true):
				matched = true
				break
		if not matched:
			return false
	return true


func _check_vector2(actual: Vector2, expected: Vector2, description: String) -> void:
	_check(actual.is_equal_approx(expected), "%s Expected %s, got %s." % [description, expected, actual])


func _check_vector3(actual: Vector3, expected: Vector3, description: String) -> void:
	_check(actual.is_equal_approx(expected), "%s Expected %s, got %s." % [description, expected, actual])


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
