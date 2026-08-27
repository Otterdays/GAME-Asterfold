class_name PlayerActor
extends CharacterBody3D

const TRAVEL_SPEED: float = 4.0
const ACCELERATION: float = 28.0
const DECELERATION: float = 36.0
const GRAVITY: float = 24.0

@export var camera_rig: WorldCameraRig
@export var sprite_actor: SpriteActor

var _input_enabled: bool = true
var _world_facing: Vector3 = Vector3(0.0, 0.0, 1.0)
var _last_safe_position: Vector3


func _ready() -> void:
	add_to_group(&"player")
	_last_safe_position = global_position


func _physics_process(delta: float) -> void:
	if camera_rig == null:
		velocity = Vector3.ZERO
		return

	var input_vector: Vector2 = InputRouter.get_move_vector() if _input_enabled else Vector2.ZERO
	var direction: Vector3 = MovementMath.camera_relative_direction(
		input_vector,
		camera_rig.get_committed_yaw_radians()
	)
	var target_velocity: Vector3 = direction * TRAVEL_SPEED
	var horizontal_acceleration: float = ACCELERATION if direction.length_squared() > 0.001 else DECELERATION
	velocity.x = move_toward(velocity.x, target_velocity.x, horizontal_acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, horizontal_acceleration * delta)
	velocity.y = -0.5 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()

	var moving: bool = direction.length_squared() > 0.001
	if moving:
		_world_facing = direction.normalized()
	if sprite_actor != null:
		sprite_actor.set_motion(_world_facing, moving, Vector2(velocity.x, velocity.z).length())
	if is_on_floor():
		_last_safe_position = global_position
	if global_position.y < -4.0:
		global_position = _last_safe_position
		velocity = Vector3.ZERO


func teleport_to(world_transform: Transform3D) -> void:
	global_transform = world_transform
	velocity = Vector3.ZERO
	_last_safe_position = global_position


func set_input_enabled(value: bool) -> void:
	_input_enabled = value


func get_world_facing() -> Vector3:
	return _world_facing

