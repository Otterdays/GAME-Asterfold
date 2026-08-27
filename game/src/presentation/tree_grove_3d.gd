@tool
class_name TreeGrove3D
extends Node3D

## Builds one zone's trees from a TreeGroveLayout. Hero specimens become full
## TreeBody3D instances with trunk collision and optional crown fading; belt and
## copse rows collapse into one MultiMesh per species part plus a single batched
## trunk-collision body, which keeps a dense town inside the draw-call budget.
## Every generated node is runtime-only and is never saved into a scene.

const BATCHED_TRUNK_BODY_NAME: String = "BatchedTrunks"

@export var layout: TreeGroveLayout:
	set(value):
		layout = value
		if is_inside_tree():
			rebuild_grove()
@export var tree_body_scene: PackedScene
## Authored sway is disabled outright in Reduced and Minimal camera-motion modes.
@export var sway_enabled: bool = true

var _crown_materials: Array[ShaderMaterial] = []
var _base_sway_strengths: PackedFloat32Array = PackedFloat32Array()
var _hero_count: int = 0
var _batched_count: int = 0
var _multimesh_count: int = 0


func _ready() -> void:
	rebuild_grove()


func rebuild_grove() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_crown_materials.clear()
	_base_sway_strengths = PackedFloat32Array()
	_hero_count = 0
	_batched_count = 0
	_multimesh_count = 0

	var configuration_errors: Array[String] = validate_configuration()
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			push_error("[TREE] %s" % message)
		return

	var batched_indices_by_species: Dictionary[StringName, PackedInt32Array] = {}
	for index: int in layout.get_placement_count():
		if layout.is_hero(index):
			_build_hero_tree(index)
			continue
		var species_id: StringName = layout.species_ids[index]
		var indices: PackedInt32Array = batched_indices_by_species.get(species_id, PackedInt32Array())
		indices.append(index)
		batched_indices_by_species[species_id] = indices

	if not batched_indices_by_species.is_empty():
		_build_batched_species(batched_indices_by_species)
	_apply_sway_strength(1.0 if sway_enabled else 0.0)


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	sway_enabled = settings.camera_motion_mode == AccessibilitySettings.CameraMotionMode.FULL
	_apply_sway_strength(1.0 if sway_enabled else 0.0)


func get_hero_count() -> int:
	return _hero_count


func get_batched_count() -> int:
	return _batched_count


func get_multimesh_count() -> int:
	return _multimesh_count


func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if layout == null:
		errors.append("Tree grove requires a TreeGroveLayout resource.")
	else:
		errors.append_array(layout.validate_definition())
	if tree_body_scene == null:
		errors.append("Tree grove requires the reusable tree-body scene.")
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())


func _build_hero_tree(index: int) -> void:
	var definition: TreeDefinition = layout.get_definition_at(index)
	var body: TreeBody3D = tree_body_scene.instantiate() as TreeBody3D
	if body == null:
		push_error("[TREE] Tree body scene must use the TreeBody3D component.")
		return
	body.name = "Hero%d_%s" % [index, String(layout.species_ids[index]).get_slice(".", 2)]
	body.definition = definition
	body.variant_seed = layout.variant_seeds[index]
	body.allow_crown_occluder = true
	body.transform = layout.get_placement_transform(index)
	add_child(body)
	_hero_count += 1
	for crown_mesh: MeshInstance3D in body.get_crown_meshes():
		_register_crown_material(crown_mesh)


func _build_batched_species(batched_indices_by_species: Dictionary[StringName, PackedInt32Array]) -> void:
	var collision_body: StaticBody3D = StaticBody3D.new()
	collision_body.name = BATCHED_TRUNK_BODY_NAME
	collision_body.collision_layer = 1
	collision_body.collision_mask = 0
	add_child(collision_body)

	for species_id: StringName in batched_indices_by_species:
		var indices: PackedInt32Array = batched_indices_by_species[species_id]
		var definition: TreeDefinition = layout.get_definition(species_id)
		var species_slug: String = String(species_id).get_slice(".", 2)
		_batched_count += indices.size()

		var trunk_transforms: Array[Transform3D] = []
		var crown_transforms: Array[Array] = []
		for _mass_index: int in definition.crown_masses.size():
			crown_transforms.append([])

		for index: int in indices:
			var placement: Transform3D = layout.get_placement_transform(index)
			var placement_scale: float = layout.uniform_scales[index]
			trunk_transforms.append(placement.translated_local(
				Vector3(0.0, definition.trunk_height_m * 0.5, 0.0)
			))
			var masses: Array[Vector4] = TreeBody3D.build_variant_masses(
				definition,
				layout.variant_seeds[index]
			)
			for mass_index: int in masses.size():
				var mass: Vector4 = masses[mass_index]
				var radius_ratio: float = mass.w / maxf(definition.crown_masses[mass_index].w, 0.01)
				var crown_basis: Basis = Basis().scaled(definition.crown_flatten * radius_ratio)
				var crown_local: Transform3D = Transform3D(crown_basis, Vector3(mass.x, mass.y, mass.z))
				(crown_transforms[mass_index] as Array).append(placement * crown_local)
			_add_batched_trunk_collision(collision_body, placement, definition, placement_scale)

		_add_multimesh(
			"%sTrunks" % species_slug.to_pascal_case(),
			TreeBody3D.build_trunk_mesh(definition),
			definition.trunk_material,
			trunk_transforms,
			false
		)
		for mass_index: int in crown_transforms.size():
			var mass_transforms: Array[Transform3D] = []
			for placed: Variant in crown_transforms[mass_index] as Array:
				mass_transforms.append(placed as Transform3D)
			_add_multimesh(
				"%sCrowns%d" % [species_slug.to_pascal_case(), mass_index],
				TreeBody3D.build_crown_mesh(definition.crown_masses[mass_index].w),
				definition.crown_material,
				mass_transforms,
				true
			)


func _add_multimesh(
	node_name: String,
	mesh: Mesh,
	material: ShaderMaterial,
	transforms: Array[Transform3D],
	is_crown: bool
) -> void:
	if transforms.is_empty():
		return
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index: int in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	instance.multimesh = multimesh
	var instance_material: ShaderMaterial = material.duplicate() as ShaderMaterial
	instance_material.resource_local_to_scene = true
	instance.material_override = instance_material
	add_child(instance)
	_multimesh_count += 1
	if is_crown:
		_crown_materials.append(instance_material)
		_base_sway_strengths.append(float(instance_material.get_shader_parameter(&"sway_strength_m")))


func _add_batched_trunk_collision(
	collision_body: StaticBody3D,
	placement: Transform3D,
	definition: TreeDefinition,
	placement_scale: float
) -> void:
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = definition.trunk_base_radius_m * placement_scale
	shape.height = definition.trunk_height_m * placement_scale
	shape_node.shape = shape
	shape_node.position = placement.origin + Vector3(0.0, shape.height * 0.5, 0.0)
	collision_body.add_child(shape_node)


func _register_crown_material(crown_mesh: MeshInstance3D) -> void:
	if not crown_mesh.material_override is ShaderMaterial:
		return
	var instance_material: ShaderMaterial = crown_mesh.material_override as ShaderMaterial
	if not instance_material.resource_local_to_scene:
		instance_material = instance_material.duplicate() as ShaderMaterial
		instance_material.resource_local_to_scene = true
		crown_mesh.material_override = instance_material
	_crown_materials.append(instance_material)
	_base_sway_strengths.append(float(instance_material.get_shader_parameter(&"sway_strength_m")))


func _apply_sway_strength(multiplier: float) -> void:
	for index: int in _crown_materials.size():
		var base_strength: float = _base_sway_strengths[index] if index < _base_sway_strengths.size() else 0.0
		_crown_materials[index].set_shader_parameter(&"sway_strength_m", base_strength * multiplier)
