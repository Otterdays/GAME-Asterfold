class_name LeafFallEmitter
extends Node3D

## Drifting leaves for a whole grove. Every authored crown mass contributes one
## emission point to a single GPUParticles3D, so a town-wide leaf fall stays at one
## draw call instead of one emitter per tree. Reduced camera motion stops emission.

const PARTICLES_NODE_NAME: String = "LeafFall"
const FALL_HEIGHT_MARGIN_M: float = 3.0

## Leave empty for a standalone drift: leaves then fall from a ring above this node,
## which is how a map-maker-placed leaf drift works.
@export var layout: TreeGroveLayout
## Ring geometry used only when no grove layout is assigned.
@export_range(1.0, 12.0, 0.1) var local_crown_height_m: float = 4.4
@export_range(0.5, 12.0, 0.1) var local_crown_radius_m: float = 2.6
@export_range(1, 32, 1) var local_emission_points: int = 8
@export var leaf_material: ShaderMaterial
@export_range(8, 512, 1) var leaf_count: int = 80
@export_range(0.02, 0.6, 0.01) var leaf_size_m: float = 0.16
## A leaf must survive long enough to drift from the crown to the ground.
@export_range(1.0, 30.0, 0.5) var leaf_lifetime_seconds: float = 9.0
@export_range(0.0, 3.0, 0.05) var fall_speed_mps: float = 0.55
@export var motion_enabled: bool = true

var _particles: GPUParticles3D
var _emission_points: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	rebuild_leaf_fall()


func rebuild_leaf_fall() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_particles = null
	_emission_points = PackedVector3Array()

	var configuration_errors: Array[String] = validate_configuration()
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			push_error("[LEAF] %s" % message)
		return

	_emission_points = collect_crown_points(layout) if layout != null else _build_local_crown_ring()
	if _emission_points.is_empty():
		push_error("[LEAF] Grove layout produced no crown emission points.")
		return

	_particles = GPUParticles3D.new()
	_particles.name = PARTICLES_NODE_NAME
	_particles.amount = leaf_count
	_particles.lifetime = leaf_lifetime_seconds
	_particles.preprocess = leaf_lifetime_seconds
	_particles.fixed_fps = 30
	_particles.local_coords = false
	_particles.draw_pass_1 = _build_leaf_card()
	_particles.material_override = leaf_material
	_particles.process_material = _build_process_material()
	_particles.visibility_aabb = _build_fall_bounds()
	_particles.emitting = motion_enabled
	add_child(_particles)


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	motion_enabled = settings.camera_motion_mode == AccessibilitySettings.CameraMotionMode.FULL
	if _particles != null:
		_particles.emitting = motion_enabled


func get_emission_point_count() -> int:
	return _emission_points.size()


func get_particles() -> GPUParticles3D:
	return _particles


func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if layout != null and layout.get_placement_count() == 0:
		errors.append("Leaf fall was given a tree grove layout with no placements.")
	if leaf_material == null or leaf_material.shader == null:
		errors.append("Leaf fall requires an external leaf shader material.")
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())


## World-space center of every crown mass in the grove, hero and batched alike.
static func collect_crown_points(grove_layout: TreeGroveLayout) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	if grove_layout == null:
		return points
	for index: int in grove_layout.get_placement_count():
		var definition: TreeDefinition = grove_layout.get_definition_at(index)
		if definition == null:
			continue
		var placement: Transform3D = grove_layout.get_placement_transform(index)
		for mass: Vector4 in definition.crown_masses:
			points.append(placement * Vector3(mass.x, mass.y, mass.z))
	return points


func _build_local_crown_ring() -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for index: int in local_emission_points:
		var angle: float = TAU * float(index) / float(local_emission_points)
		points.append(Vector3(
			cos(angle) * local_crown_radius_m,
			local_crown_height_m,
			sin(angle) * local_crown_radius_m
		))
	return points


func _build_leaf_card() -> QuadMesh:
	var card: QuadMesh = QuadMesh.new()
	card.size = Vector2(leaf_size_m, leaf_size_m)
	return card


func _build_process_material() -> ParticleProcessMaterial:
	var process_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	process_material.emission_point_count = _emission_points.size()
	process_material.emission_point_texture = _build_emission_texture()
	process_material.direction = Vector3(0.0, -1.0, 0.0)
	process_material.spread = 25.0
	process_material.initial_velocity_min = fall_speed_mps * 0.5
	process_material.initial_velocity_max = fall_speed_mps
	process_material.gravity = Vector3(0.0, -fall_speed_mps * 0.6, 0.0)
	process_material.damping_min = 0.1
	process_material.damping_max = 0.4
	process_material.scale_min = 0.7
	process_material.scale_max = 1.25
	# Turbulence is what makes a leaf wander instead of dropping like a pebble.
	process_material.turbulence_enabled = true
	process_material.turbulence_noise_strength = 0.9
	process_material.turbulence_noise_scale = 2.2
	process_material.turbulence_influence_min = 0.05
	process_material.turbulence_influence_max = 0.2
	return process_material


func _build_emission_texture() -> ImageTexture:
	var point_image: Image = Image.create_empty(_emission_points.size(), 1, false, Image.FORMAT_RGBF)
	for index: int in _emission_points.size():
		var point: Vector3 = _emission_points[index]
		point_image.set_pixel(index, 0, Color(point.x, point.y, point.z))
	return ImageTexture.create_from_image(point_image)


func _build_fall_bounds() -> AABB:
	var ground: Vector2 = layout.ground_size_m if layout != null else Vector2.ONE * local_crown_radius_m * 4.0
	var highest: float = 0.0
	for point: Vector3 in _emission_points:
		highest = maxf(highest, point.y)
	return AABB(
		Vector3(-ground.x * 0.5, 0.0, -ground.y * 0.5),
		Vector3(ground.x, highest + FALL_HEIGHT_MARGIN_M, ground.y)
	)
