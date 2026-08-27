extends TestCase


func suite_name() -> String:
	return "map_maker"


func run() -> void:
	_test_history_round_trip()
	_test_history_depth_cap()
	_test_history_branch_clears_redo()
	_test_grid_builds_over_zone_bounds()
	_test_theme_styles()


func _test_history_round_trip() -> void:
	var history: MapMakerHistory = MapMakerHistory.new()
	_check(not history.can_undo(), "A fresh history has nothing to undo.")
	_check(history.undo({"step": 1}).is_empty(), "Undo on an empty history returns no snapshot.")
	history.record({"step": 0})
	history.record({"step": 1})
	var restored: Dictionary = history.undo({"step": 2})
	_check(int(restored["step"]) == 1, "Undo returns the most recently recorded snapshot.")
	_check(history.can_redo(), "Undo makes a redo available.")
	var redone: Dictionary = history.redo({"step": 1})
	_check(int(redone["step"]) == 2, "Redo returns the state captured when undo ran.")
	_check(history.undo_depth() == 2, "Redo pushes the pre-redo state back onto the undo stack.")


func _test_history_depth_cap() -> void:
	var history: MapMakerHistory = MapMakerHistory.new()
	for index: int in MapMakerHistory.MAX_DEPTH + 12:
		history.record({"step": index})
	_check(history.undo_depth() == MapMakerHistory.MAX_DEPTH, "History never grows past its depth cap.")
	var oldest_kept: Dictionary = {}
	while history.can_undo():
		oldest_kept = history.undo({"step": -1})
	_check(int(oldest_kept["step"]) == 12, "The depth cap drops the oldest snapshots first.")


func _test_history_branch_clears_redo() -> void:
	var history: MapMakerHistory = MapMakerHistory.new()
	history.record({"step": 0})
	history.undo({"step": 1})
	_check(history.can_redo(), "Undo leaves a redo entry.")
	history.record({"step": 5})
	_check(not history.can_redo(), "A new edit after undo discards the stale redo branch.")


func _test_grid_builds_over_zone_bounds() -> void:
	var grid: MapMakerGrid = MapMakerGrid.new()
	tree.root.add_child(grid)
	await tree.process_frame
	_check(not grid.visible, "The authoring grid stays hidden until it is asked for.")
	grid.rebuild(AABB(Vector3(-4.0, 0.0, -4.0), Vector3(8.0, 2.0, 8.0)), 0.5)
	var mesh_instances: Array[Node] = grid.find_children("*", "MeshInstance3D", true, false)
	_check(mesh_instances.size() == 1, "Rebuilding the grid produces one mesh instance.")
	if not mesh_instances.is_empty():
		var mesh: Mesh = (mesh_instances[0] as MeshInstance3D).mesh
		_check(mesh != null and mesh.get_surface_count() == 1, "The grid mesh holds a single line surface.")
	_check(grid.toggle(), "Toggling the grid shows it.")
	_check(not grid.toggle(), "Toggling the grid again hides it.")
	grid.queue_free()


func _test_theme_styles() -> void:
	var theme: Theme = MapMakerTheme.build()
	_check(theme.has_stylebox(&"panel", &"PanelContainer"), "The tool theme styles panel surfaces.")
	_check(theme.has_stylebox(&"focus", &"Button"), "The tool theme draws a visible keyboard focus ring.")
	var pressed: StyleBoxFlat = theme.get_stylebox(&"pressed", &"Button") as StyleBoxFlat
	_check(pressed != null and pressed.bg_color == MapMakerTheme.ACCENT_COLOR, "Selected buttons use the accent fill.")
