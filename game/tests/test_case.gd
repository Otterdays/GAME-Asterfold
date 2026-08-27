class_name TestCase
extends RefCounted

## One discovered suite. Override `suite_name` and `run`. Await tree frames from `run`.

var tree: SceneTree
var input_router: Node
var content_db: Node
var game_flow: Node
var checks: int = 0
var failures: Array[String] = []


func suite_name() -> String:
	return get_script().resource_path.get_file().get_basename()


func run() -> void:
	push_error("TestCase.run must be overridden.")
	_check(false, "Suite '%s' did not override run()." % suite_name())


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)


func _check_vector2(actual: Vector2, expected: Vector2, description: String) -> void:
	_check(actual.is_equal_approx(expected), "%s Expected %s, got %s." % [description, expected, actual])


func _check_vector3(actual: Vector3, expected: Vector3, description: String) -> void:
	_check(actual.is_equal_approx(expected), "%s Expected %s, got %s." % [description, expected, actual])


func _errors_mention(errors: Array[String], fragment: String) -> bool:
	for message: String in errors:
		if message.contains(fragment):
			return true
	return false


func _facing_at_degrees(degrees: float) -> Vector3:
	var radians: float = deg_to_rad(degrees)
	return Vector3(sin(radians), 0.0, -cos(radians))


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
