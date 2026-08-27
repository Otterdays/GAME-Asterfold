extends TestCase


func suite_name() -> String:
	return "camera_and_peek"


func run() -> void:
	_test_camera_relative_movement()
	_test_direction_resolution()
	_test_peek_motion()
	_test_map_maker_camera_session()
	_test_first_person_look()


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


func _test_first_person_look() -> void:
	var bounds: AABB = AABB(Vector3(-34.0, -2.0, -29.0), Vector3(68.0, 24.0, 58.0))
	_check_vector3(
		FirstPersonLookModel.clamp_xz(Vector3(80.0, 4.0, -90.0), bounds),
		Vector3(34.0, 4.0, -29.0),
		"Scout clicks clamp to zone bounds."
	)
	_check_vector3(
		FirstPersonLookModel.map_uv_to_world(Vector2(0.5, 0.5), bounds),
		Vector3(0.0, 0.0, 0.0),
		"Map center maps to the zone origin."
	)
	_check_vector3(
		FirstPersonLookModel.map_uv_to_world(Vector2(0.5, 0.0), bounds),
		Vector3(0.0, 0.0, 29.0),
		"Map top maps toward world +Z."
	)
	var look: FirstPersonLookModel = FirstPersonLookModel.new()
	look.apply_mouse_delta(Vector2(100.0, 2000.0))
	_check(look.pitch_degrees == FirstPersonLookModel.MIN_PITCH_DEGREES, "First-person pitch clamps.")
	_check(look.yaw_degrees < 0.0, "Mouse look yaws the scout eye.")
	_check(ResourceLoader.exists("res://scenes/ui/first_person_scout.tscn", "PackedScene"), "First-person scout UI scene exists.")
