@tool
class_name TreeBody3D
extends Node3D

## Repeatable 3D tree body built from a TreeDefinition. Placement, yaw, and scale
## belong to the owner transform so the same body serves hero specimens and
## map-builder previews. Only the trunk collides; crowns stay walk-under.
## Generated children are runtime-only and are never saved into a scene.

const TRUNK_RADIAL_SEGMENTS: int = 10
const CROWN_RADIAL_SEGMENTS: int = 12
const CROWN_RINGS: int = 5
const ROOT_FLARE_HEIGHT_M: float = 0.12
const CROWN_OCCLUDER_SCRIPT_PATH: String = "res://src/presentation/tree_crown_occluder.gd"

@export var definition: TreeDefinition:
	set(value):
		definition = value
		if is_inside_tree():
			rebuild_body()
@export var variant_seed: int = 0:
	set(value):
		variant_seed = value
		if is_inside_tree():
			rebuild_body()
## Hero specimens may own a crown occluder; batched belt instances never do.
@export var allow_crown_occluder: bool = true

var _crown_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	rebuild_body()


func rebuild_body() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_crown_meshes.clear()
	var configuration_errors: Array[String] = validate_configuration()
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			push_error("[TREE] %s" % message)
		return

	if definition.root_flare_radius_m > 0.0:
		_add_root_flare()
	_add_trunk()
	_add_crown_masses()
	_add_trunk_collision()
	if allow_crown_occluder and definition.fade_crown:
		_add_crown_occluder()


func get_crown_meshes() -> Array[MeshInstance3D]:
	return _crown_meshes


func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if definition == null:
		errors.append("Tree body requires a TreeDefinition resource.")
		return errors
	errors.append_array(definition.validate_definition())
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())


func _add_root_flare() -> void:
	var flare: MeshInstance3D = MeshInstance3D.new()
	flare.name = "RootFlare"
	var flare_mesh: CylinderMesh = CylinderMesh.new()
	flare_mesh.top_radius = definition.trunk_base_radius_m
	flare_mesh.bottom_radius = definition.root_flare_radius_m
	flare_mesh.height = ROOT_FLARE_HEIGHT_M
	flare_mesh.radial_segments = TRUNK_RADIAL_SEGMENTS
	flare.mesh = flare_mesh
	flare.material_override = definition.trunk_material
	flare.position = Vector3(0.0, ROOT_FLARE_HEIGHT_M * 0.5, 0.0)
	add_child(flare)


func _add_trunk() -> void:
	var trunk: MeshInstance3D = MeshInstance3D.new()
	trunk.name = "Trunk"
	trunk.mesh = build_trunk_mesh(definition)
	trunk.material_override = definition.trunk_material
	trunk.position = Vector3(0.0, definition.trunk_height_m * 0.5, 0.0)
	add_child(trunk)


func _add_crown_masses() -> void:
	var masses: Array[Vector4] = build_variant_masses(definition, variant_seed)
	for index: int in masses.size():
		var mass: Vector4 = masses[index]
		var crown: MeshInstance3D = MeshInstance3D.new()
		crown.name = "Crown%d" % index
		crown.mesh = build_crown_mesh(mass.w)
		crown.material_override = definition.crown_material
		crown.position = Vector3(mass.x, mass.y, mass.z)
		crown.scale = definition.crown_flatten
		add_child(crown)
		_crown_meshes.append(crown)


func _add_trunk_collision() -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "TrunkCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = "Collision"
	shape_node.shape = build_trunk_shape(definition)
	shape_node.position = Vector3(0.0, definition.trunk_height_m * 0.5, 0.0)
	body.add_child(shape_node)
	add_child(body)


func _add_crown_occluder() -> void:
	var occluder_script: Script = load(CROWN_OCCLUDER_SCRIPT_PATH) as Script
	if occluder_script == null:
		push_error("[TREE] Crown occluder script is missing.")
		return
	var occluder: StaticBody3D = StaticBody3D.new()
	occluder.name = "CrownOccluder"
	occluder.set_script(occluder_script)
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = "Collision"
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = definition.canopy_radius_m
	shape_node.shape = shape
	occluder.add_child(shape_node)
	occluder.position = get_crown_center(definition)
	add_child(occluder)
	occluder.call(&"configure_crown_meshes", _crown_meshes)


static func build_trunk_mesh(tree_definition: TreeDefinition) -> CylinderMesh:
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = tree_definition.trunk_top_radius_m
	trunk_mesh.bottom_radius = tree_definition.trunk_base_radius_m
	trunk_mesh.height = tree_definition.trunk_height_m
	trunk_mesh.radial_segments = TRUNK_RADIAL_SEGMENTS
	trunk_mesh.rings = 1
	return trunk_mesh


static func build_crown_mesh(radius_m: float) -> SphereMesh:
	var crown_mesh: SphereMesh = SphereMesh.new()
	crown_mesh.radius = radius_m
	crown_mesh.height = radius_m * 2.0
	crown_mesh.radial_segments = CROWN_RADIAL_SEGMENTS
	crown_mesh.rings = CROWN_RINGS
	return crown_mesh


static func build_trunk_shape(tree_definition: TreeDefinition) -> CylinderShape3D:
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = tree_definition.trunk_base_radius_m
	shape.height = tree_definition.trunk_height_m
	return shape


## Deterministic per-variant crown jitter. Seeded locally so no global randomness
## leaks into placement or gameplay state.
static func build_variant_masses(tree_definition: TreeDefinition, seed_value: int) -> Array[Vector4]:
	var masses: Array[Vector4] = []
	var variant: int = tree_definition.resolve_variant(seed_value)
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.seed = hash(String(tree_definition.id)) + variant * 7919
	for mass: Vector4 in tree_definition.crown_masses:
		var offset_jitter: Vector2 = Vector2(
			generator.randf_range(-0.18, 0.18),
			generator.randf_range(-0.18, 0.18)
		)
		var radius_jitter: float = generator.randf_range(-0.08, 0.08)
		masses.append(Vector4(
			mass.x + offset_jitter.x,
			mass.y + generator.randf_range(-0.08, 0.08),
			mass.z + offset_jitter.y,
			maxf(mass.w * (1.0 + radius_jitter), 0.2)
		))
	return masses


static func get_crown_center(tree_definition: TreeDefinition) -> Vector3:
	var center: Vector3 = Vector3.ZERO
	for mass: Vector4 in tree_definition.crown_masses:
		center += Vector3(mass.x, mass.y, mass.z)
	return center / maxf(float(tree_definition.crown_masses.size()), 1.0)
