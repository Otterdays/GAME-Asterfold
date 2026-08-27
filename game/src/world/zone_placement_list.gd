class_name ZonePlacementList
extends Resource

@export var zone_id: StringName = &""
@export_range(0.1, 2.0, 0.1) var logical_grid_m: float = 0.5
@export var placements: Array[ZonePlacement] = []


func find_index(grid_x: int, grid_z: int, catalog: WorldPieceCatalog = null) -> int:
	for index: int in placements.size():
		var placement: ZonePlacement = placements[index]
		if placement == null:
			continue
		if catalog == null:
			if placement.grid_x == grid_x and placement.grid_z == grid_z:
				return index
			continue
		var definition: WorldPieceDefinition = catalog.get_definition(placement.piece_id)
		if definition == null:
			if placement.grid_x == grid_x and placement.grid_z == grid_z:
				return index
			continue
		for cell: Vector2i in definition.covered_cells(placement.grid_x, placement.grid_z):
			if cell.x == grid_x and cell.y == grid_z:
				return index
	return -1


func set_cell(
	piece_id: StringName,
	grid_x: int,
	grid_z: int,
	yaw_quarter_turns: int = 0,
	catalog: WorldPieceCatalog = null
) -> void:
	_remove_overlapping(piece_id, grid_x, grid_z, catalog)
	var placement: ZonePlacement = ZonePlacement.new()
	placement.piece_id = piece_id
	placement.grid_x = grid_x
	placement.grid_z = grid_z
	placement.yaw_quarter_turns = posmod(yaw_quarter_turns, 4)
	placements.append(placement)


func remove_cell(grid_x: int, grid_z: int, catalog: WorldPieceCatalog = null) -> bool:
	var index: int = find_index(grid_x, grid_z, catalog)
	if index < 0:
		return false
	placements.remove_at(index)
	return true


func rotate_cell(grid_x: int, grid_z: int, catalog: WorldPieceCatalog = null) -> bool:
	var index: int = find_index(grid_x, grid_z, catalog)
	if index < 0:
		return false
	var placement: ZonePlacement = placements[index]
	placement.yaw_quarter_turns = posmod(placement.yaw_quarter_turns + 1, 4)
	return true


func has_piece(piece_id: StringName) -> bool:
	for placement: ZonePlacement in placements:
		if placement != null and placement.piece_id == piece_id:
			return true
	return false


func _remove_overlapping(
	piece_id: StringName,
	grid_x: int,
	grid_z: int,
	catalog: WorldPieceCatalog
) -> void:
	var incoming: Array[Vector2i] = [Vector2i(grid_x, grid_z)]
	if catalog != null:
		var definition: WorldPieceDefinition = catalog.get_definition(piece_id)
		if definition != null:
			incoming = definition.covered_cells(grid_x, grid_z)
	var remaining: Array[ZonePlacement] = []
	for placement: ZonePlacement in placements:
		if placement == null:
			continue
		if _footprints_overlap(placement, incoming, catalog):
			continue
		remaining.append(placement)
	placements = remaining


func _footprints_overlap(
	placement: ZonePlacement,
	incoming: Array[Vector2i],
	catalog: WorldPieceCatalog
) -> bool:
	var existing: Array[Vector2i] = [Vector2i(placement.grid_x, placement.grid_z)]
	if catalog != null:
		var definition: WorldPieceDefinition = catalog.get_definition(placement.piece_id)
		if definition != null:
			existing = definition.covered_cells(placement.grid_x, placement.grid_z)
	for cell: Vector2i in incoming:
		if existing.has(cell):
			return true
	return false


func validate_definition(catalog: WorldPieceCatalog, bounds: AABB) -> Array[String]:
	var errors: Array[String] = []
	var id_pattern: RegEx = RegEx.new()
	id_pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	if id_pattern.search(String(zone_id)) == null:
		errors.append("Placement list zone ID '%s' is not a lowercase namespaced stable ID." % zone_id)
	if not is_equal_approx(logical_grid_m, 0.5):
		errors.append("Placement list '%s' must use the 0.5 m logical grid." % zone_id)
	if catalog == null:
		errors.append("Placement list '%s' has no piece catalog." % zone_id)
		return errors
	var occupied: Dictionary[String, bool] = {}
	for index: int in placements.size():
		var placement: ZonePlacement = placements[index]
		if placement == null:
			errors.append("Placement list '%s' entry %d is empty." % [zone_id, index])
			continue
		if not catalog.has_piece(placement.piece_id):
			errors.append(
				"Placement list '%s' entry %d uses unknown piece '%s'." % [zone_id, index, placement.piece_id]
			)
		var definition: WorldPieceDefinition = catalog.get_definition(placement.piece_id)
		var cells: Array[Vector2i] = [Vector2i(placement.grid_x, placement.grid_z)]
		if definition != null:
			cells = definition.covered_cells(placement.grid_x, placement.grid_z)
		for cell: Vector2i in cells:
			var cell_key: String = "%d,%d" % [cell.x, cell.y]
			if occupied.has(cell_key):
				errors.append("Placement list '%s' has two pieces on cell %s." % [zone_id, cell_key])
			occupied[cell_key] = true
		var world_position: Vector3 = placement.to_world_position(logical_grid_m)
		if not bounds.has_point(world_position):
			errors.append(
				"Placement list '%s' entry %d sits outside zone bounds at %s." % [zone_id, index, world_position]
			)
		if placement.yaw_quarter_turns < 0 or placement.yaw_quarter_turns > 3:
			errors.append("Placement list '%s' entry %d has an invalid yaw." % [zone_id, index])
	return errors
