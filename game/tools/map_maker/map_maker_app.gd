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

var _layout: ZonePlacementList
var _catalog: WorldPieceCatalog
var _placement_layer: PlacementLayer
var _road_network: DirtRoadNetwork3D
var _selected_piece_id: StringName = &""
var _selected_road_index: int = 0
var _dirty: bool = false
var _tool_settings: MapMakerSettings = MapMakerSettings.new()


func _ready() -> void:
	DisplayServer.window_set_title("Asterfold Map Maker")
	DisplayServer.window_set_size(Vector2i(1600, 900))
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
	_tool_settings.load_from_disk()
	_settings_panel.configure(_tool_settings)
	_settings_panel.settings_changed.connect(_on_tool_settings_changed)
	_camera.apply_tool_settings(_tool_settings)
	var props: Array[WorldPieceDefinition] = _catalog.get_pieces_in_family(&"prop")
	if not props.is_empty():
		_palette.select_piece(props[0].id)
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_apply_at_mouse()
			get_viewport().set_input_as_handled()
		elif mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			_remove_at_mouse()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.ctrl_pressed and key_event.keycode == KEY_S:
			save_world()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_ESCAPE:
			if _settings_panel.visible:
				_settings_panel.hide_panel()
			else:
				get_tree().quit()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_R:
			_rotate_at_mouse()
			get_viewport().set_input_as_handled()
		elif key_event.keycode >= KEY_1 and key_event.keycode <= KEY_6:
			_select_shortcut(key_event.keycode - KEY_1)


func save_world() -> void:
	if _layout == null:
		return
	var placement_error: Error = ResourceSaver.save(_layout, _layout.resource_path)
	var road_error: Error = OK
	if _road_network != null and _road_network.layout != null:
		road_error = ResourceSaver.save(_road_network.layout, ROAD_LAYOUT_PATH)
	if placement_error != OK or road_error != OK:
		_palette.set_status("Save failed.")
		return
	_dirty = false
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
		_on_road_selected(index)
		return
	var pieces: Array[WorldPieceDefinition] = _catalog.get_pieces_in_family(_palette.get_active_family())
	if index < 0 or index >= pieces.size():
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
	_layout.set_cell(_selected_piece_id, cell_coords.x, cell_coords.y, 0, _catalog)
	_dirty = true
	_placement_layer.rebuild()
	_refresh_status()


func _remove_at_mouse() -> void:
	if _palette.get_active_family() == &"road":
		return
	var cell: Variant = _cell_under_mouse()
	if cell == null:
		return
	var cell_coords: Vector2i = cell as Vector2i
	if _layout.remove_cell(cell_coords.x, cell_coords.y, _catalog):
		_dirty = true
		_placement_layer.rebuild()
		_refresh_status()


func _rotate_at_mouse() -> void:
	if _palette.get_active_family() == &"road":
		return
	var cell: Variant = _cell_under_mouse()
	if cell == null:
		return
	var cell_coords: Vector2i = cell as Vector2i
	if _layout.rotate_cell(cell_coords.x, cell_coords.y, _catalog):
		_dirty = true
		_placement_layer.rebuild()
		_refresh_status()


func _move_selected_road(cell_coords: Vector2i) -> void:
	if _road_network == null or _road_network.layout == null:
		return
	var world: Vector2 = Vector2(float(cell_coords.x) * _layout.logical_grid_m, float(cell_coords.y) * _layout.logical_grid_m)
	if not _road_network.layout.set_patch_center(_selected_road_index, world):
		return
	_road_network.rebuild_surface()
	_dirty = true
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


func _refresh_status() -> void:
	if _palette == null:
		return
	var dirty_mark: String = " Unsaved." if _dirty else ""
	_palette.set_status("%s%s" % [MapMakerWorldCoverage.beginner_status(), dirty_mark])
