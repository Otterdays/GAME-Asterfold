class_name FootfallMotes
extends Node3D

## Ground response under a walking actor. The node rides the actor's feet and turns
## exactly one emitter on: dust over the authored dirt road, flicked blades over the
## grass. The surface is read from the road layout rather than from collision, because
## the dirt road is a painted signed-distance surface with no collider of its own.

const SURFACE_DIRT_ROAD: StringName = &"surface.dirt_road"
const SURFACE_GRASS: StringName = &"surface.grass"
const DUST_NODE_NAME: String = "DirtDust"
const GRASS_NODE_NAME: String = "GrassBlades"
const FOOT_HEIGHT_M: float = 0.04

@export var road_layout: DirtRoadLayout
@export var dust_material: ShaderMaterial
@export var grass_material: ShaderMaterial
## Strides slower than this leave no mark, so idle shuffling does not spray the ground.
@export_range(0.0, 4.0, 0.05) var walk_speed_threshold_mps: float = 0.9
@export var motion_enabled: bool = true

var _actor: CharacterBody3D
var _dust: GPUParticles3D
var _grass: GPUParticles3D
var _active_surface: StringName = SURFACE_GRASS


func _ready() -> void:
	rebuild_emitters()


func _physics_process(_delta: float) -> void:
	if _dust == null or _grass == null:
		return
	if _actor == null or not motion_enabled:
		_set_emitting(false, false)
		return
	global_position = Vector3(_actor.global_position.x, FOOT_HEIGHT_M, _actor.global_position.z)
	_active_surface = get_surface_id(Vector2(global_position.x, global_position.z))
	var speed: float = Vector2(_actor.velocity.x, _actor.velocity.z).length()
	var striding: bool = _actor.is_on_floor() and speed >= walk_speed_threshold_mps
	_set_emitting(
		striding and _active_surface == SURFACE_DIRT_ROAD,
		striding and _active_surface == SURFACE_GRASS
	)


## Called by the zone once the actor exists; the emitters never search the tree.
func configure_actor(actor: CharacterBody3D) -> void:
	_actor = actor


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	motion_enabled = settings.camera_motion_mode == AccessibilitySettings.CameraMotionMode.FULL
	if not motion_enabled:
		_set_emitting(false, false)


## Classifies a world XZ point against the authored road surface.
func get_surface_id(point: Vector2) -> StringName:
	if road_layout == null:
		return SURFACE_GRASS
	var distance: float = road_layout.signed_distance_m(point)
	if is_inf(distance):
		return SURFACE_GRASS
	return SURFACE_DIRT_ROAD if distance <= 0.0 else SURFACE_GRASS


func get_active_surface_id() -> StringName:
	return _active_surface


func is_emitting_dust() -> bool:
	return _dust != null and _dust.emitting


func is_emitting_grass() -> bool:
	return _grass != null and _grass.emitting


func rebuild_emitters() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_dust = null
	_grass = null

	var configuration_errors: Array[String] = validate_configuration()
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			push_error("[FOOTFALL] %s" % message)
		return

	_dust = _build_emitter(DUST_NODE_NAME, dust_material, 0.16, 1.0, 0.55, Vector3(0.0, -0.35, 0.0), 55.0)
	_grass = _build_emitter(GRASS_NODE_NAME, grass_material, 0.11, 0.55, 1.5, Vector3(0.0, -3.2, 0.0), 32.0)
	add_child(_dust)
	add_child(_grass)


func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if road_layout == null:
		errors.append("Footfall motes require the zone dirt-road layout to classify the ground.")
	if dust_material == null or dust_material.shader == null:
		errors.append("Footfall motes require an external dirt-dust shader material.")
	if grass_material == null or grass_material.shader == null:
		errors.append("Footfall motes require an external grass-mote shader material.")
	if dust_material != null and dust_material == grass_material:
		errors.append("Dirt and grass footfalls must stay separately authored materials.")
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())


func _build_emitter(
	node_name: String,
	material: ShaderMaterial,
	card_size_m: float,
	lifetime_seconds: float,
	launch_speed_mps: float,
	gravity: Vector3,
	spread_degrees: float
) -> GPUParticles3D:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = node_name
	particles.amount = 24
	particles.lifetime = lifetime_seconds
	particles.fixed_fps = 30
	# World coordinates so a stride leaves its motes behind instead of dragging them.
	particles.local_coords = false
	particles.emitting = false
	var card: QuadMesh = QuadMesh.new()
	card.size = Vector2(card_size_m, card_size_m)
	particles.draw_pass_1 = card
	particles.material_override = material

	var process_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = 0.22
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = spread_degrees
	process_material.initial_velocity_min = launch_speed_mps * 0.45
	process_material.initial_velocity_max = launch_speed_mps
	process_material.gravity = gravity
	process_material.damping_min = 0.6
	process_material.damping_max = 1.4
	process_material.scale_min = 0.6
	process_material.scale_max = 1.2
	particles.process_material = process_material
	return particles


func _set_emitting(dust_active: bool, grass_active: bool) -> void:
	if _dust != null:
		_dust.emitting = dust_active
	if _grass != null:
		_grass.emitting = grass_active
