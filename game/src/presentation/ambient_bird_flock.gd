class_name AmbientBirdFlock
extends Node3D

## Presentation-only flock of one bird species. Every bird rides a seeded circuit
## anchored on an authored tree, and the whole flock renders as a single MultiMesh
## so a lively sky costs one draw call. Reduced camera motion freezes the flock in
## place instead of hiding it, so the town keeps its silhouettes without movement.

const MULTIMESH_NODE_NAME: String = "Birds"
const CIRCUIT_HEIGHT_MARGIN_M: float = 2.0
## Part tags written into UV.x. The shader recolours by tag, so a variant species is a
## palette change rather than new geometry.
const PART_BODY: float = 0.0
const PART_HEAD: float = 1.0
const PART_BEAK: float = 2.0
const PART_WING: float = 3.0
const PART_TAIL: float = 4.0

@export var species: BirdSpeciesDefinition
## Circuit anchors are taken from this grove so birds always turn over real trees.
## Leave it empty for a standalone roost: the flock then circles its own node origin,
## which is how a map-maker-placed roost works.
@export var anchor_layout: TreeGroveLayout
@export var bird_material: ShaderMaterial
## Seeded so a rebuilt flock reproduces the same circuits.
@export var flock_seed: int = 20260827
@export var motion_enabled: bool = true

var _multimesh_instance: MultiMeshInstance3D
var _runtime_material: ShaderMaterial
var _anchors: PackedVector3Array = PackedVector3Array()
var _circuit_radii: PackedFloat32Array = PackedFloat32Array()
var _circuit_angles: PackedFloat32Array = PackedFloat32Array()
var _angular_speeds: PackedFloat32Array = PackedFloat32Array()
var _bob_phases: PackedFloat32Array = PackedFloat32Array()
var _elapsed_seconds: float = 0.0


func _ready() -> void:
	rebuild_flock()


func _process(delta: float) -> void:
	if not motion_enabled or _multimesh_instance == null:
		return
	_elapsed_seconds += delta
	for index: int in _anchors.size():
		_circuit_angles[index] += _angular_speeds[index] * delta
	_write_instance_transforms()


func rebuild_flock() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_multimesh_instance = null
	_runtime_material = null
	_anchors = PackedVector3Array()
	_circuit_radii = PackedFloat32Array()
	_circuit_angles = PackedFloat32Array()
	_angular_speeds = PackedFloat32Array()
	_bob_phases = PackedFloat32Array()

	var configuration_errors: Array[String] = validate_configuration()
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			push_error("[BIRD] %s" % message)
		return

	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = flock_seed
	var anchor_points: PackedVector2Array = _collect_anchor_points()
	for bird_index: int in species.flock_size:
		var anchor: Vector2 = anchor_points[bird_index % anchor_points.size()]
		var radius: float = species.circuit_radius_for(random)
		var height: float = species.cruise_height_for(random)
		_anchors.append(Vector3(anchor.x, height, anchor.y))
		_circuit_radii.append(radius)
		_circuit_angles.append(random.randf() * TAU)
		var direction: float = 1.0 if random.randf() < 0.5 else -1.0
		_angular_speeds.append(direction * species.cruise_speed_mps / maxf(radius, 0.5))
		_bob_phases.append(random.randf() * TAU)

	_build_multimesh()
	_write_instance_transforms()
	_apply_flap_strength(species.flap_amplitude if motion_enabled else 0.0)


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	motion_enabled = settings.camera_motion_mode == AccessibilitySettings.CameraMotionMode.FULL
	_apply_flap_strength(species.flap_amplitude if motion_enabled and species != null else 0.0)


func get_bird_count() -> int:
	return _anchors.size()


func get_multimesh_instance() -> MultiMeshInstance3D:
	return _multimesh_instance


func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if species == null:
		errors.append("Bird flock requires a BirdSpeciesDefinition resource.")
	else:
		errors.append_array(species.validate_definition())
	if bird_material == null or bird_material.shader == null:
		errors.append("Bird flock requires an external bird shader material.")
	if anchor_layout != null and anchor_layout.get_placement_count() == 0:
		errors.append("Bird flock was given a tree layout with no placements to anchor on.")
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())


## Hero specimens first, because the authored heroes mark the places worth circling.
## A flock with no grove is a standalone roost and circles its own origin.
func _collect_anchor_points() -> PackedVector2Array:
	if anchor_layout == null:
		return PackedVector2Array([Vector2.ZERO])
	var hero_points: PackedVector2Array = PackedVector2Array()
	var belt_points: PackedVector2Array = PackedVector2Array()
	for index: int in anchor_layout.get_placement_count():
		var origin: Vector3 = anchor_layout.get_placement_transform(index).origin
		var point: Vector2 = Vector2(origin.x, origin.z)
		if anchor_layout.is_hero(index):
			hero_points.append(point)
		else:
			belt_points.append(point)
	hero_points.append_array(belt_points)
	return hero_points


func _build_multimesh() -> void:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = build_bird_mesh(species)
	multimesh.instance_count = _anchors.size()

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = MULTIMESH_NODE_NAME
	_multimesh_instance.multimesh = multimesh
	_runtime_material = bird_material.duplicate() as ShaderMaterial
	_runtime_material.resource_local_to_scene = true
	_runtime_material.set_shader_parameter(&"flap_hz", species.flap_hz)
	_runtime_material.set_shader_parameter(&"half_span_m", species.half_span_m())
	_multimesh_instance.material_override = _runtime_material
	# Birds move every frame, so the instance keeps an authored culling volume.
	_multimesh_instance.custom_aabb = _build_flock_bounds()
	add_child(_multimesh_instance)

	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = flock_seed + 1
	for index: int in _anchors.size():
		multimesh.set_instance_custom_data(index, Color(random.randf(), 0.0, 0.0, 0.0))


func _write_instance_transforms() -> void:
	var multimesh: MultiMesh = _multimesh_instance.multimesh
	for index: int in _anchors.size():
		multimesh.set_instance_transform(index, get_bird_transform(index))


## Exposed so tests can assert circuit geometry without reading GPU state.
func get_bird_transform(index: int) -> Transform3D:
	var anchor: Vector3 = _anchors[index]
	var radius: float = _circuit_radii[index]
	var angle: float = _circuit_angles[index]
	var bob: float = sin(_elapsed_seconds * species.bob_speed + _bob_phases[index]) * species.bob_amplitude_m
	var position: Vector3 = anchor + Vector3(cos(angle) * radius, bob, sin(angle) * radius)
	var heading: Vector3 = Vector3(-sin(angle), 0.0, cos(angle)) * signf(_angular_speeds[index])
	var basis: Basis = Basis.looking_at(heading, Vector3.UP)
	var bank: float = deg_to_rad(species.bank_degrees) * signf(_angular_speeds[index])
	basis = basis.rotated(heading.normalized(), bank)
	return Transform3D(basis, position)


func _build_flock_bounds() -> AABB:
	var ground: Vector2 = anchor_layout.ground_size_m if anchor_layout != null else Vector2.ZERO
	var top: float = species.cruise_height_max_m + species.bob_amplitude_m + CIRCUIT_HEIGHT_MARGIN_M
	var span: float = species.circuit_radius_max_m
	return AABB(
		Vector3(-ground.x * 0.5 - span, 0.0, -ground.y * 0.5 - span),
		Vector3(ground.x + span * 2.0, top, ground.y + span * 2.0)
	)


func _apply_flap_strength(strength: float) -> void:
	if _runtime_material == null:
		return
	_runtime_material.set_shader_parameter(&"flap_strength", strength)


## The baseline bird body. Every species uses this builder: head, beak, tapered body,
## two-segment swept wings, and a forkable tail are all driven by the definition's
## ratios, and UV.x tags each part so one shader can recolour a variant without new
## geometry. A new species is a definition plus a material, never a new mesh function.
static func build_bird_mesh(definition: BirdSpeciesDefinition) -> ArrayMesh:
	var half_span: float = definition.half_span_m()
	var body_length: float = half_span * definition.body_length_ratio
	var body_front: float = -body_length * 0.55
	var body_back: float = body_length * 0.45
	var body_half_width: float = half_span * 0.15

	var builder: BirdMeshBuilder = BirdMeshBuilder.new(half_span)
	_append_body(builder, body_front, body_back, body_half_width)
	_append_head(builder, definition, half_span, body_front, body_half_width)
	_append_wings(builder, definition, half_span, body_front, body_back, body_half_width)
	_append_tail(builder, definition, half_span, body_back)
	return builder.build()


static func _append_body(
	builder: BirdMeshBuilder,
	body_front: float,
	body_back: float,
	body_half_width: float
) -> void:
	var nose: Vector3 = Vector3(0.0, 0.0, body_front)
	var breast_left: Vector3 = Vector3(-body_half_width * 0.85, 0.0, body_front * 0.35)
	var breast_right: Vector3 = Vector3(body_half_width * 0.85, 0.0, body_front * 0.35)
	var flank_left: Vector3 = Vector3(-body_half_width, 0.0, body_back * 0.3)
	var flank_right: Vector3 = Vector3(body_half_width, 0.0, body_back * 0.3)
	var rear: Vector3 = Vector3(0.0, 0.0, body_back)
	for triangle: Array in [
		[nose, breast_right, breast_left],
		[breast_left, breast_right, flank_right],
		[breast_left, flank_right, flank_left],
		[flank_left, flank_right, rear],
	]:
		builder.add_triangle(triangle[0], triangle[1], triangle[2], PART_BODY)


static func _append_head(
	builder: BirdMeshBuilder,
	definition: BirdSpeciesDefinition,
	half_span: float,
	body_front: float,
	body_half_width: float
) -> void:
	var head_length: float = half_span * definition.head_length_ratio
	var head_half_width: float = body_half_width * 0.8
	var crown: Vector3 = Vector3(0.0, 0.0, body_front - head_length)
	builder.add_triangle(
		Vector3(-head_half_width, 0.0, body_front),
		Vector3(head_half_width, 0.0, body_front),
		crown,
		PART_HEAD
	)
	var beak_length: float = half_span * definition.beak_length_ratio
	if beak_length <= 0.0:
		return
	builder.add_triangle(
		Vector3(-head_half_width * 0.35, 0.0, crown.z),
		Vector3(head_half_width * 0.35, 0.0, crown.z),
		Vector3(0.0, 0.0, crown.z - beak_length),
		PART_BEAK
	)


static func _append_wings(
	builder: BirdMeshBuilder,
	definition: BirdSpeciesDefinition,
	half_span: float,
	body_front: float,
	body_back: float,
	body_half_width: float
) -> void:
	var root_leading: float = body_front * 0.25
	var root_trailing: float = body_back * 0.45
	var root_chord: float = root_trailing - root_leading
	var sweep: float = half_span * definition.wing_sweep_ratio
	# The wrist sits mid-span, which is what lets the outer panel carry the sweep and taper.
	var wrist_x: float = half_span * 0.55
	var wrist_leading: float = root_leading + sweep * 0.45
	var wrist_chord: float = root_chord * lerpf(1.0, definition.wing_taper, 0.45)
	var tip_leading: float = root_leading + sweep
	var tip_chord: float = root_chord * definition.wing_taper

	for side: int in [-1, 1]:
		var root_front: Vector3 = Vector3(side * body_half_width, 0.0, root_leading)
		var root_back: Vector3 = Vector3(side * body_half_width, 0.0, root_trailing)
		var wrist_front: Vector3 = Vector3(side * wrist_x, 0.0, wrist_leading)
		var wrist_back: Vector3 = Vector3(side * wrist_x, 0.0, wrist_leading + wrist_chord)
		var tip_front: Vector3 = Vector3(side * half_span, 0.0, tip_leading)
		var tip_back: Vector3 = Vector3(side * half_span, 0.0, tip_leading + tip_chord)
		builder.add_quad(root_front, wrist_front, wrist_back, root_back, PART_WING)
		builder.add_quad(wrist_front, tip_front, tip_back, wrist_back, PART_WING)


static func _append_tail(
	builder: BirdMeshBuilder,
	definition: BirdSpeciesDefinition,
	half_span: float,
	body_back: float
) -> void:
	var tail_length: float = half_span * definition.tail_length_ratio
	var tail_half_width: float = half_span * 0.2
	var root: Vector3 = Vector3(0.0, 0.0, body_back)
	var left_corner: Vector3 = Vector3(-tail_half_width, 0.0, body_back + tail_length)
	var right_corner: Vector3 = Vector3(tail_half_width, 0.0, body_back + tail_length)
	var notch: Vector3 = Vector3(0.0, 0.0, body_back + tail_length * (1.0 - definition.tail_fork_ratio))
	builder.add_triangle(root, notch, left_corner, PART_TAIL)
	builder.add_triangle(root, right_corner, notch, PART_TAIL)


## Collects the flat bird surface. UV.x carries the part tag and UV.y the outboard
## fraction, so the shader can recolour parts and fade wingtips without extra streams.
class BirdMeshBuilder extends RefCounted:
	var _half_span: float
	var _vertices: PackedVector3Array = PackedVector3Array()
	var _normals: PackedVector3Array = PackedVector3Array()
	var _uvs: PackedVector2Array = PackedVector2Array()

	func _init(half_span: float) -> void:
		_half_span = maxf(half_span, 0.001)

	func add_triangle(first: Vector3, second: Vector3, third: Vector3, part: float) -> void:
		for vertex: Vector3 in [first, second, third]:
			_vertices.append(vertex)
			_normals.append(Vector3.UP)
			_uvs.append(Vector2(part, absf(vertex.x) / _half_span))

	func add_quad(first: Vector3, second: Vector3, third: Vector3, fourth: Vector3, part: float) -> void:
		add_triangle(first, second, third, part)
		add_triangle(first, third, fourth, part)

	func build() -> ArrayMesh:
		var surface_arrays: Array = []
		surface_arrays.resize(Mesh.ARRAY_MAX)
		surface_arrays[Mesh.ARRAY_VERTEX] = _vertices
		surface_arrays[Mesh.ARRAY_NORMAL] = _normals
		surface_arrays[Mesh.ARRAY_TEX_UV] = _uvs
		var bird_mesh: ArrayMesh = ArrayMesh.new()
		bird_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
		return bird_mesh
