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
	&"fold_left",
	&"fold_right",
]
const REQUIRED_SCENES: Array[String] = [
	"res://scenes/app/app.tscn",
	"res://scenes/debug/metrics_scene.tscn",
]

var _failures: Array[String] = []
var _checks: int = 0


func _init() -> void:
	_run()


func _run() -> void:
	_check(
		str(ProjectSettings.get_setting("application/config/version", "")) == "0.1.0-dev",
		"The development build version is configured."
	)

	for action: StringName in REQUIRED_ACTIONS:
		_check(InputMap.has_action(action), "Semantic input action '%s' exists." % action)

	for scene_path: String in REQUIRED_SCENES:
		_check(ResourceLoader.exists(scene_path, "PackedScene"), "Scene '%s' exists." % scene_path)
		var packed_scene: PackedScene = load(scene_path) as PackedScene
		_check(packed_scene != null, "Scene '%s' loads." % scene_path)
		if packed_scene != null:
			var instance: Node = packed_scene.instantiate()
			_check(instance != null, "Scene '%s' instantiates." % scene_path)
			instance.free()

	if _failures.is_empty():
		print("[TEST] PASS: %d checks." % _checks)
		quit(0)
		return

	for failure: String in _failures:
		push_error("[TEST] %s" % failure)
	print("[TEST] FAIL: %d of %d checks failed." % [_failures.size(), _checks])
	quit(1)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
