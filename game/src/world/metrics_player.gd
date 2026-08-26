extends CharacterBody3D

const TRAVEL_SPEED: float = 4.0
const GRAVITY: float = 24.0

@export var movement_camera: Camera3D


func _physics_process(delta: float) -> void:
	if movement_camera == null:
		velocity = Vector3.ZERO
		return

	var input_vector: Vector2 = Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_forward",
		&"move_back"
	)
	var camera_yaw: float = movement_camera.global_rotation.y
	var direction: Vector3 = Basis(Vector3.UP, camera_yaw) * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	velocity.x = direction.x * TRAVEL_SPEED
	velocity.z = direction.z * TRAVEL_SPEED
	velocity.y = -0.5 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()

	if direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 14.0))

