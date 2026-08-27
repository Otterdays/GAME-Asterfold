class_name WorldPieceDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var family: StringName = &"prop"
@export var tooltip_id: StringName = &""
@export var scene: PackedScene
@export var footprint_x: int = 1
@export var footprint_z: int = 1
@export var body_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var body_color: Color = Color(0.55, 0.36, 0.22, 1.0)
@export var accent_color: Color = Color(0.47, 0.22, 0.31, 1.0)
@export var has_roof: bool = false
@export var has_door: bool = false


func covered_cells(origin_x: int, origin_z: int) -> Array[Vector2i]:
	var width: int = maxi(footprint_x, 1)
	var depth: int = maxi(footprint_z, 1)
	var start_x: int = origin_x - (width - 1) / 2
	var start_z: int = origin_z - (depth - 1) / 2
	var cells: Array[Vector2i] = []
	for x_offset: int in width:
		for z_offset: int in depth:
			cells.append(Vector2i(start_x + x_offset, start_z + z_offset))
	return cells
