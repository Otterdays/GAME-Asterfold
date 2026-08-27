extends Node3D

const ZONE_ID: StringName = &"zone.brindlewick_square"
const SPAWN_ID: StringName = &"spawn.brindlewick_square.south_gate"
const TOOLTIP_CATALOG_PATH: String = "res://tools/map_maker/map_maker_tooltip_catalog.tres"
const ROAD_LAYOUT_PATH: String = "res://content/zones/brindlewick_square/brindlewick_dirt_road_layout.tres"
const GROUND_PLANE := Plane(Vector3.UP, 0.0)

@onready var _world_host: Node3D = %WorldHost
@onready var _camera: MapMakerCamera = %MapMakerCamera
@onready var _palette: MapMakerPalette = %Palette
@onready var _settings_panel: MapMakerSettingsPanel = %SettingsPanel
@onready var _tooltip: MapMakerTooltip = %Tooltip
@onready var _preview: MapMakerPreview = %Preview
@onready var _grid: MapMakerGrid = %Grid
@onready var _toast: MapMakerToast = %Toast

var _layout: ZonePlacementList
var _catalog: WorldPieceCatalog
var _placement_layer: PlacementLayer
var _road_network: DirtRoadNetwork3D
var _selected_piece_id: StringName = &""
var _selected_road_index: int = 0
var _dirty: bool = false
var _tool_settings: MapMakerSettings = MapMakerSettings.new()
var _history: MapMakerHistory = MapMakerHistory.new()
var _quit_armed: bool = false


func _ready() -> void:
	DisplayServer.window_set_title("Asterfold Map Maker")
	_fit_window_to_screen()
	var tooltip_catalog: MapMakerTooltipCatalog = load(TOOLTIP_CATALOG_PATH) as MapMakerTooltipCatalog
	_tooltip.configure(tooltip_catalog)
	if not _load_live_zone():
		return
	var road_count: int = _road_network.get_patch_count() if _road_network != null else 0
	_palette.configure(_catalog, _tooltip, road_count)
	_palette.family_selected.connect(_on_family_selected)
	_palette.piece_selected.connect(_on_piece_selected)
	_palette.road_selected.connect(_on_road_selected)
	_palette.save_requested.connect(save_world)
	_palette.settings_requested.connect(_toggle_settings)
	_palette.delete_mode_changed.connect(_on_delete_mode_changed)
	_tool_settings.load_from_disk()
	_settings_panel.configure(_tool_settings)
	_settings_panel.settings_changed.connect(_on_tool_settings_changed)
	_camera.apply_tool_settings(_tool_settings)
	_camera.short_right_click.connect(_remove_at_mouse)
	var manifest: ZoneManifest = ContentDB.get_zone(ZONE_ID)
	if manifest != null:
		_grid.rebuild(manifest.validation_bounds, _layout.logical_grid_m)
	_refresh_status()


func _fit_window_to_screen() -> void:
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	var size := Vector2i(
		mini(1600, usable.size.x),
		mini(900, usable.size.y)
	)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if _palette.is_delete_mode():
				_remove_at_mouse()
			else:
				_apply_at_mouse()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.ctrl_pressed and key_event.keycode == KEY_S:
			save_world()
			get_viewport().set_input_as_handled()
		elif key_event.ctrl_pressed and key_event.keycode == KEY_Z:
			if key_event.shift_pressed:
				_redo_edit()
			else:
				_undo_edit()
			get_viewport().set_input_as_handled()
		elif key_event.ctrl_pressed and key_event.keycode == KEY_Y:
			_redo_edit()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_ESCAPE:
			_handle_escape()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_G:
			var grid_visible: bool = _grid.toggle()
			_toast.show_message("Grid on." if grid_visible else "Grid off.")
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F1:
			_palette.toggle_help()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_Q or key_event.keycode == KEY_E:
			_palette.cycle_family(-1 if key_event.keycode == KEY_Q else 1)
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_DELETE:
			_palette.set_delete_mode(not _palette.is_delete_mode())
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_R:
			_rotate_at_mouse()
			get_viewport().set_input_as_handled()
		elif key_event.keycode >= KEY_1 and key_event.keycode <= KEY_6:
			_select_shortcut(key_event.keycode - KEY_1)


func _process(_delta: float) -> void:
	_update_preview()


func save_world() -> void:
	if _layout == null:
		return
	var placement_error: Error = ResourceSaver.save(_layout, _layout.resource_path)
	var road_error: Error = OK
	if _road_network != null and _road_network.layout != null:
		road_error = ResourceSaver.save(_road_network.layout, ROAD_LAYOUT_PATH)
	if placement_error != OK or road_error != OK:
		_palette.set_status("Save failed.")
		_toast.show_message("Save failed.", MapMakerToast.BAD_COLOR)
		return
	_dirty = false
	_quit_armed = false
	_toast.show_message("Saved Brindlewick.", MapMakerToast.GOOD_COLOR)
	_refresh_status()


func _handle_escape() -> void:
	if _settings_panel.visible:
		_settings_panel.hide_panel()
		return
	if _dirty and not _quit_armed:
		_quit_armed = true
		_toast.show_message("Unsaved edits. Ctrl+S to save, Esc again to quit.", MapMakerToast.BAD_COLOR)
		_refresh_status()
		return
	get_tree().quit()


func _snapshot() -> Dictionary:
	var placements: Array[Dictionary] = []
	if _layout != null:
		for placement: ZonePlacement in _layout.placements:
			if placement == null:
				continue
			placements.append({
				"piece_id": placement.piece_id,
				"grid_x": placement.grid_x,
				"grid_z": placement.grid_z,
				"yaw": placement.yaw_quarter_turns,
			})
	var roads: Array[Vector4] = []
	if _road_network != null and _road_network.layout != null:
		roads = _road_network.layout.patches.duplicate()
	return {"placements": placements, "roads": roads}


func _restore(snapshot: Dictionary) -> void:
	if snapshot.is_empty() or _layout == null:
		return
	var rebuilt: Array[ZonePlacement] = []
	for entry: Dictionary in snapshot["placements"]:
		var placement: ZonePlacement = ZonePlacement.new()
		placement.piece_id = entry["piece_id"]
		placement.grid_x = int(entry["grid_x"])
		placement.grid_z = int(entry["grid_z"])
		placement.yaw_quarter_turns = int(entry["yaw"])
		rebuilt.append(placement)
	_layout.placements = rebuilt
	_placement_layer.rebuild()
	if _road_network != null and _road_network.layout != null:
		var roads: Array[Vector4] = snapshot["roads"]
		_road_network.layout.patches = roads.duplicate()
		_road_network.rebuild_surface()


func _record_edit() -> void:
	_history.record(_snapshot())


func _undo_edit() -> void:
	var snapshot: Dictionary = _history.undo(_snapshot())
	if snapshot.is_empty():
		_toast.show_message("Nothing to undo.")
		return
	_restore(snapshot)
	_dirty = true
	_toast.show_message("Undid one edit.")
	_refresh_status()


func _redo_edit() -> void:
	var snapshot: Dictionary = _history.redo(_snapshot())
	if snapshot.is_empty():
		_toast.show_message("Nothing to redo.")
		return
	_restore(snapshot)
	_dirty = true
	_toast.show_message("Redid one edit.")
	_refresh_status()


func _load_live_zone() -> bool:
	var manifest: ZoneManifest = ContentDB.get_zone(ZONE_ID)
	if manifest == null or manifest.scene == null:
		push_error("[MAP MAKER] Live zone '%s' is not registered." % ZONE_ID)
		return false
	var zone: Node = manifest.scene.instantiate()
	_world_host.add_child(zone)
	if zone.has_method(&"configure_zone"):
		zone.call(&"configure_zone", manifest, SPAWN_ID)
	_freeze_playable_actors(zone)
	_placement_layer = zone.get_node_or_null("Geometry/PlacementLayer") as PlacementLayer
	_road_network = zone.get_node_or_null("Geometry/DirtRoadSurface") as DirtRoadNetwork3D
	if _placement_layer == null:
		push_error("[MAP MAKER] Live zone is missing PlacementLayer.")
		return false
	_layout = _placement_layer.layout
	_catalog = _placement_layer.catalog
	_camera.current = true
	return _layout != null and _catalog != null


func _freeze_playable_actors(zone: Node) -> void:
	var player_node: Node = zone.get_node_or_null("Player")
	if player_node != null:
		player_node.process_mode = Node.PROCESS_MODE_DISABLED
	var camera_node: Node = zone.get_node_or_null("WorldCameraRig")
	if camera_node != null:
		camera_node.process_mode = Node.PROCESS_MODE_DISABLED


func _on_family_selected(_family: StringName) -> void:
	_refresh_status()


func _on_piece_selected(piece_id: StringName) -> void:
	_selected_piece_id = piece_id
	_refresh_status()


func _on_delete_mode_changed(enabled: bool) -> void:
	if enabled:
		_selected_piece_id = &""
	if _preview != null:
		_preview.set_delete_mode(enabled)
	_refresh_status()


func _on_tool_settings_changed(settings: MapMakerSettings) -> void:
	_camera.apply_tool_settings(settings)


func _toggle_settings() -> void:
	if _settings_panel.visible:
		_settings_panel.hide_panel()
	else:
		_settings_panel.show_panel()


func _on_road_selected(patch_index: int) -> void:
	_selected_road_index = patch_index
	_refresh_status()


func _select_shortcut(index: int) -> void:
	if _palette.get_active_family() == &"road":
		_palette.select_road(index)
		return
	var pieces: Array[WorldPieceDefinition] = _catalog.get_pieces_in_family(_palette.get_active_family())
	if index < 0 or index >= pieces.size():
		return
	if _selected_piece_id == pieces[index].id:
		_palette.clear_piece_selection()
		return
	_palette.select_piece(pieces[index].id)


func _apply_at_mouse() -> void:
	var cell: Variant = _cell_under_mouse()
	if cell == null:
		return
	var cell_coords: Vector2i = cell as Vector2i
	if _palette.get_active_family() == &"road":
		_move_selected_road(cell_coords)
		return
	if _selected_piece_id == &"":
		return
	var before: Dictionary = _snapshot()
	if _layout.toggle_same_piece(_selected_piece_id, cell_coords.x, cell_coords.y, _catalog):
		_commit_edit(before)
		return
	_layout.set_cell(_selected_piece_id, cell_coords.x, cell_coords.y, 0, _catalog)
	_commit_edit(before)


func _remove_at_mouse() -> void:
	if _palette.get_active_family() == &"road":
		return
	var cell: Variant = _cell_under_mouse()
	if cell == null:
		return
	var cell_coords: Vector2i = cell as Vector2i
	var before: Dictionary = _snapshot()
	if _layout.remove_cell(cell_coords.x, cell_coords.y, _catalog):
		_commit_edit(before)


func _rotate_at_mouse() -> void:
	if _palette.get_active_family() == &"road":
		return
	var cell: Variant = _cell_under_mouse()
	if cell == null:
		return
	var cell_coords: Vector2i = cell as Vector2i
	var before: Dictionary = _snapshot()
	if _layout.rotate_cell(cell_coords.x, cell_coords.y, _catalog):
		_commit_edit(before)


func _move_selected_road(cell_coords: Vector2i) -> void:
	if _road_network == null or _road_network.layout == null:
		return
	var world: Vector2 = Vector2(float(cell_coords.x) * _layout.logical_grid_m, float(cell_coords.y) * _layout.logical_grid_m)
	var before: Dictionary = _snapshot()
	if not _road_network.layout.set_patch_center(_selected_road_index, world):
		return
	_road_network.rebuild_surface()
	_history.record(before)
	_dirty = true
	_quit_armed = false
	_refresh_status()


func _cell_under_mouse() -> Variant:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = _camera.project_ray_origin(mouse_position)
	var direction: Vector3 = _camera.project_ray_normal(mouse_position)
	var hit_point: Variant = GROUND_PLANE.intersects_ray(origin, direction)
	if hit_point == null:
		return null
	var world_point: Vector3 = hit_point as Vector3
	var grid_m: float = _layout.logical_grid_m
	return Vector2i(ZonePlacement.snap_meters(world_point.x, grid_m), ZonePlacement.snap_meters(world_point.z, grid_m))


func _commit_edit(before: Dictionary) -> void:
	_history.record(before)
	_dirty = true
	_quit_armed = false
	_placement_layer.rebuild()
	_refresh_status()


func _refresh_status() -> void:
	if _palette == null:
		return
	var dirty_mark: String = " Unsaved." if _dirty else " Saved."
	var mode_text: String = "Delete mode."
	if not _palette.is_delete_mode():
		mode_text = "No piece picked." if _selected_piece_id == &"" and _palette.get_active_family() != &"road" else "Ready."
	var piece_count: int = _layout.placements.size() if _layout != null else 0
	_palette.set_status("%s %s %d pieces. Undo %d.%s" % [
		MapMakerWorldCoverage.beginner_status(),
		mode_text,
		piece_count,
		_history.undo_depth(),
		dirty_mark,
	])


func _update_preview() -> void:
	if _preview == null or _layout == null:
		return
	if get_viewport().gui_get_hovered_control() != null:
		_preview.clear_ghost()
		_preview.clear_highlight()
		return
	var cell: Variant = _cell_under_mouse()
	if cell == null:
		_preview.clear_ghost()
		_preview.clear_highlight()
		return
	var cell_coords: Vector2i = cell as Vector2i
	var world: Vector3 = Vector3(
		float(cell_coords.x) * _layout.logical_grid_m,
		0.02,
		float(cell_coords.y) * _layout.logical_grid_m
	)
	var hover_piece: Node3D = _placement_layer.get_instance_for_cell(cell_coords.x, cell_coords.y) if _placement_layer != null else null
	_preview.highlight_piece(hover_piece)
	if _palette.is_delete_mode() or _palette.get_active_family() == &"road" or _selected_piece_id == &"":
		_preview.clear_ghost()
		return
	_preview.show_ghost(_catalog, _selected_piece_id, world)
