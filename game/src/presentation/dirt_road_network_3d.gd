@tool
class_name DirtRoadNetwork3D
extends MeshInstance3D

@export var layout: DirtRoadLayout
@export var surface_material: ShaderMaterial


func _ready() -> void:
	rebuild_surface()


func rebuild_surface() -> void:
	var configuration_errors: Array[String] = validate_configuration()
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			push_error("[ROAD] %s" % message)
		return
	mesh = _build_batched_patch_mesh()
	var runtime_material: ShaderMaterial = surface_material.duplicate() as ShaderMaterial
	runtime_material.resource_local_to_scene = true
	runtime_material.set_shader_parameter(&"patch_count", layout.patches.size())
	runtime_material.set_shader_parameter(&"road_patches", PackedVector4Array(layout.patches))
	runtime_material.set_shader_parameter(&"corner_radii_m", layout.corner_radii_m)
	runtime_material.set_shader_parameter(&"join_softness_m", layout.join_softness_m)
	material_override = runtime_material


func _build_batched_patch_mesh() -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var padding_m: float = layout.join_softness_m + 0.2
	for patch: Vector4 in layout.patches:
		var center: Vector2 = Vector2(patch.x, patch.y)
		var half_size: Vector2 = Vector2(patch.z, patch.w) + Vector2.ONE * padding_m
		var vertex_start: int = vertices.size()
		vertices.append(Vector3(center.x - half_size.x, 0.0, center.y - half_size.y))
		vertices.append(Vector3(center.x + half_size.x, 0.0, center.y - half_size.y))
		vertices.append(Vector3(center.x + half_size.x, 0.0, center.y + half_size.y))
		vertices.append(Vector3(center.x - half_size.x, 0.0, center.y + half_size.y))
		for _vertex: int in 4:
			normals.append(Vector3.UP)
		indices.append_array(PackedInt32Array([
			vertex_start,
			vertex_start + 1,
			vertex_start + 2,
			vertex_start,
			vertex_start + 2,
			vertex_start + 3,
		]))
	var surface_arrays: Array = []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = vertices
	surface_arrays[Mesh.ARRAY_NORMAL] = normals
	surface_arrays[Mesh.ARRAY_INDEX] = indices
	var network_mesh: ArrayMesh = ArrayMesh.new()
	network_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	return network_mesh


func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if layout == null:
		errors.append("Road network requires a DirtRoadLayout resource.")
	else:
		errors.append_array(layout.validate_definition())
	if surface_material == null:
		errors.append("Road network requires an authored surface material.")
	elif surface_material.shader == null:
		errors.append("Road network material requires a shader.")
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())


func get_patch_count() -> int:
	return layout.patches.size() if layout != null else 0


static func rounded_box_distance(point: Vector2, patch: Vector4, radius: float) -> float:
	var center: Vector2 = Vector2(patch.x, patch.y)
	var half_size: Vector2 = Vector2(patch.z, patch.w)
	var offset: Vector2 = (point - center).abs() - half_size + Vector2.ONE * radius
	return minf(maxf(offset.x, offset.y), 0.0) + Vector2(maxf(offset.x, 0.0), maxf(offset.y, 0.0)).length() - radius


static func smooth_union_distance(first: float, second: float, softness: float) -> float:
	if softness <= 0.0:
		return minf(first, second)
	var blend: float = clampf(0.5 + 0.5 * (second - first) / softness, 0.0, 1.0)
	return lerpf(second, first, blend) - softness * blend * (1.0 - blend)
