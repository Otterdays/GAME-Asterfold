class_name PlacementLayer
extends Node3D

@export var catalog: WorldPieceCatalog
@export var layout: ZonePlacementList


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.free()
	if catalog == null or layout == null:
		return
	for placement: ZonePlacement in layout.placements:
		if placement == null:
			continue
		var packed_scene: PackedScene = catalog.get_scene(placement.piece_id)
		if packed_scene == null:
			push_error("[WORLD] Unknown placed piece '%s'." % placement.piece_id)
			continue
		var instance: Node = packed_scene.instantiate()
		if not instance is Node3D:
			instance.free()
			push_error("[WORLD] Piece '%s' must inherit Node3D." % placement.piece_id)
			continue
		var piece: Node3D = instance as Node3D
		piece.name = "cell_%d_%d" % [placement.grid_x, placement.grid_z]
		piece.position = placement.to_world_position(layout.logical_grid_m)
		piece.rotation.y = placement.yaw_radians()
		add_child(piece)
		var definition: WorldPieceDefinition = catalog.get_definition(placement.piece_id)
		if definition != null and piece.has_method(&"apply_piece_definition"):
			piece.call(&"apply_piece_definition", definition)


func get_placed_count() -> int:
	return get_child_count()


func get_instance_for_cell(grid_x: int, grid_z: int) -> Node3D:
	if layout == null:
		return null
	var placement: ZonePlacement = layout.get_placement_at(grid_x, grid_z, catalog)
	if placement == null:
		return null
	return get_node_or_null("cell_%d_%d" % [placement.grid_x, placement.grid_z]) as Node3D
