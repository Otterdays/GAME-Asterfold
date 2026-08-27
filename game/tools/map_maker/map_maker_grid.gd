class_name MapMakerGrid
extends Node3D

## Authoring-only cell grid. Hidden by default so the diorama reads normally until the author
## asks for measurement help.

const MINOR_COLOR := Color(0.52, 0.68, 0.82, 0.05)
const MAJOR_COLOR := Color(0.7, 0.86, 1.0, 0.16)
const AXIS_COLOR := Color(1.0, 0.86, 0.42, 0.4)
const MAJOR_EVERY_M: float = 2.0
const GROUND_OFFSET_M: float = 0.012

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	visible = false


func rebuild(bounds: AABB, grid_m: float) -> void:
	if grid_m <= 0.0:
		return
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.material_override = _make_material()
		_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_mesh_instance)
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var min_x: float = snappedf(bounds.position.x, grid_m)
	var max_x: float = snappedf(bounds.position.x + bounds.size.x, grid_m)
	var min_z: float = snappedf(bounds.position.z, grid_m)
	var max_z: float = snappedf(bounds.position.z + bounds.size.z, grid_m)
	var x: float = min_x
	while x <= max_x:
		var color: Color = _line_color(x)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(x, GROUND_OFFSET_M, min_z))
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(x, GROUND_OFFSET_M, max_z))
		x += grid_m
	var z: float = min_z
	while z <= max_z:
		var color: Color = _line_color(z)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(min_x, GROUND_OFFSET_M, z))
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(max_x, GROUND_OFFSET_M, z))
		z += grid_m
	mesh.surface_end()
	_mesh_instance.mesh = mesh


func toggle() -> bool:
	visible = not visible
	return visible


func _line_color(coordinate: float) -> Color:
	if is_zero_approx(coordinate):
		return AXIS_COLOR
	if is_zero_approx(fposmod(coordinate, MAJOR_EVERY_M)):
		return MAJOR_COLOR
	return MINOR_COLOR


func _make_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.no_depth_test = false
	material.disable_receive_shadows = true
	return material
