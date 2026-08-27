class_name GrayboxBuilding
extends Node3D


func apply_piece_definition(definition: WorldPieceDefinition) -> void:
	var body: StaticBody3D = get_node("Body") as StaticBody3D
	var body_mesh: MeshInstance3D = get_node("Body/BodyMesh") as MeshInstance3D
	var roof: MeshInstance3D = get_node("Roof") as MeshInstance3D
	var door: MeshInstance3D = get_node("Door") as MeshInstance3D
	var size: Vector3 = definition.body_size
	body.scale = size
	body.position = Vector3(0.0, size.y * 0.5, 0.0)
	var body_material: StandardMaterial3D = StandardMaterial3D.new()
	body_material.albedo_color = definition.body_color
	body_material.roughness = 0.9
	body_mesh.material_override = body_material
	roof.visible = definition.has_roof
	if definition.has_roof:
		roof.scale = Vector3(size.x + 0.8, 0.7, size.z + 0.8)
		roof.position = Vector3(0.0, size.y + 0.25, 0.0)
		var roof_material: StandardMaterial3D = StandardMaterial3D.new()
		roof_material.albedo_color = definition.accent_color
		roof_material.roughness = 0.9
		roof.material_override = roof_material
	door.visible = definition.has_door
	if definition.has_door:
		door.scale = Vector3(1.4, 3.4, 0.12)
		door.position = Vector3(0.0, 1.7, size.z * 0.5 + 0.06)
		var door_material: StandardMaterial3D = StandardMaterial3D.new()
		door_material.albedo_color = Color(0.30, 0.20, 0.14, 1.0)
		door_material.roughness = 1.0
		door.material_override = door_material
