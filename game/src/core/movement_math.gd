class_name MovementMath
extends RefCounted


static func camera_relative_direction(input_vector: Vector2, committed_yaw_radians: float) -> Vector3:
	var direction: Vector3 = Basis(Vector3.UP, committed_yaw_radians) * Vector3(
		input_vector.x,
		0.0,
		input_vector.y
	)
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	return direction

