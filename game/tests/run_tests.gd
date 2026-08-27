extends SceneTree

const SUITE_DIRECTORY: String = "res://tests/suites"
const FILTER_PREFIX: String = "--suite="
const SERVICE_NAMES: Array[String] = ["InputRouter", "ContentDB", "GameFlow"]

var _failures: Array[String] = []
var _checks: int = 0
var _suites_run: int = 0
var _input_router: Node
var _content_db: Node
var _game_flow: Node
var _suite_filter: String = ""


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_parse_user_args()
	_install_test_services()
	var suite_paths: PackedStringArray = _discover_suite_paths()
	_check(not suite_paths.is_empty(), "At least one suite script exists under %s." % SUITE_DIRECTORY)
	if not _suite_filter.is_empty():
		_check(not suite_paths.is_empty(), "Filter '%s' matched a suite." % _suite_filter)
	for suite_path: String in suite_paths:
		await _run_suite(suite_path)
	_finish()


func _parse_user_args() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(FILTER_PREFIX):
			_suite_filter = argument.substr(FILTER_PREFIX.length())


func _discover_suite_paths() -> PackedStringArray:
	var paths: PackedStringArray = PackedStringArray()
	var directory: DirAccess = DirAccess.open(SUITE_DIRECTORY)
	if directory == null:
		return paths
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with("_tests.gd"):
			paths.append("%s/%s" % [SUITE_DIRECTORY, file_name])
		file_name = directory.get_next()
	directory.list_dir_end()
	paths.sort()
	if _suite_filter.is_empty():
		return paths
	var filtered: PackedStringArray = PackedStringArray()
	for path: String in paths:
		var loaded: GDScript = load(path) as GDScript
		if loaded == null:
			continue
		var probe: TestCase = loaded.new() as TestCase
		if probe != null and probe.suite_name() == _suite_filter:
			filtered.append(path)
	return filtered


func _run_suite(suite_path: String) -> void:
	var suite_script: GDScript = load(suite_path) as GDScript
	if suite_script == null:
		_check(false, "Suite '%s' loads." % suite_path)
		return
	var suite: TestCase = suite_script.new() as TestCase
	if suite == null:
		_check(false, "Suite '%s' is a TestCase." % suite_path)
		return
	suite.tree = self
	suite.input_router = _input_router
	suite.content_db = _content_db
	suite.game_flow = _game_flow
	var name: String = suite.suite_name()
	var before_children: PackedStringArray = _root_child_names()
	var before_connections: int = _service_connection_count()
	var before_objects: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var started_usec: int = Time.get_ticks_usec()
	print("[TEST] suite start: %s" % name)
	await suite.run()
	await process_frame
	await process_frame
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_usec) / 1000.0
	_checks += suite.checks
	_suites_run += 1
	for failure: String in suite.failures:
		_failures.append("%s: %s" % [name, failure])
	var leaked_children: PackedStringArray = _leaked_root_children(before_children)
	if not leaked_children.is_empty():
		_failures.append("%s: leaked root children %s" % [name, ", ".join(leaked_children)])
	var after_connections: int = _service_connection_count()
	if after_connections > before_connections:
		_failures.append(
			"%s: service signal connections grew from %d to %d" % [name, before_connections, after_connections]
		)
	var object_delta: int = int(Performance.get_monitor(Performance.OBJECT_COUNT)) - before_objects
	var failed_in_suite: int = suite.failures.size()
	if not leaked_children.is_empty():
		failed_in_suite += 1
	if after_connections > before_connections:
		failed_in_suite += 1
	print(
		"[TEST] suite done: %s checks=%d fail=%d ms=%.1f objects_delta=%d"
		% [name, suite.checks, failed_in_suite, elapsed_ms, object_delta]
	)


func _root_child_names() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for child: Node in root.get_children():
		names.append(String(child.name))
	names.sort()
	return names


func _leaked_root_children(before: PackedStringArray) -> PackedStringArray:
	var leaked: PackedStringArray = PackedStringArray()
	for name: String in _root_child_names():
		if not before.has(name) and not SERVICE_NAMES.has(name):
			leaked.append(name)
	return leaked


func _service_connection_count() -> int:
	var total: int = 0
	for service: Node in [_input_router, _content_db, _game_flow]:
		if service == null:
			continue
		for signal_info: Dictionary in service.get_signal_list():
			var signal_name: StringName = signal_info["name"]
			total += service.get_signal_connection_list(signal_name).size()
	return total


func _finish() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_forward")
	Input.action_release(&"move_back")
	if _input_router != null:
		_input_router.call(&"reset_default_bindings")
	if _failures.is_empty():
		print("[TEST] PASS: %d checks across %d suites." % [_checks, _suites_run])
		quit(0)
		return
	for failure: String in _failures:
		push_error("[TEST] %s" % failure)
	print("[TEST] FAIL: %d of %d checks failed across %d suites." % [_failures.size(), _checks, _suites_run])
	quit(1)


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


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
