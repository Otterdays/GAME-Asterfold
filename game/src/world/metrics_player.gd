extends CharacterBody3D

const TRAVEL_SPEED: float = 4.0
const GRAVITY: float = 24.0

@export var movement_camera: Camera3D


func _physics_process(delta: float) -> void:
	if movement_camera == null:
		velocity = Vector3.ZERO
		return

	var input_vector: Vector2 = InputRouter.get_move_vector()
	var camera_yaw: float = movement_camera.global_rotation.y
	var direction: Vector3 = MovementMath.camera_relative_direction(input_vector, camera_yaw)

	velocity.x = direction.x * TRAVEL_SPEED
	velocity.z = direction.z * TRAVEL_SPEED
	velocity.y = -0.5 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()

	if direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 14.0))
