class_name FirstPersonLookModel
extends RefCounted

const EYE_HEIGHT_M: float = 1.65
const MIN_PITCH_DEGREES: float = -75.0
const MAX_PITCH_DEGREES: float = 75.0
const MOUSE_SENSITIVITY: float = 0.12
const STICK_SPEED_DEGREES: float = 90.0

var yaw_degrees: float = 0.0
var pitch_degrees: float = 0.0


func reset(yaw_degrees_value: float = 0.0) -> void:
	yaw_degrees = yaw_degrees_value
	pitch_degrees = 0.0


func apply_mouse_delta(pixel_delta: Vector2) -> void:
	yaw_degrees -= pixel_delta.x * MOUSE_SENSITIVITY
	pitch_degrees = clampf(
		pitch_degrees - pixel_delta.y * MOUSE_SENSITIVITY,
		MIN_PITCH_DEGREES,
		MAX_PITCH_DEGREES
	)


func apply_stick(stick: Vector2, delta: float) -> void:
	if stick.length_squared() < 0.0001:
		return
	yaw_degrees -= stick.x * STICK_SPEED_DEGREES * delta
	pitch_degrees = clampf(
		pitch_degrees + stick.y * STICK_SPEED_DEGREES * delta,
		MIN_PITCH_DEGREES,
		MAX_PITCH_DEGREES
	)


func apply_to_camera(camera: Camera3D) -> void:
	camera.rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)


static func clamp_xz(point: Vector3, bounds: AABB) -> Vector3:
	var minimum: Vector3 = bounds.position
	var maximum: Vector3 = bounds.position + bounds.size
	return Vector3(
		clampf(point.x, minimum.x, maximum.x),
		point.y,
		clampf(point.z, minimum.z, maximum.z)
	)


static func map_uv_to_world(uv: Vector2, bounds: AABB) -> Vector3:
	var world: Vector3 = Vector3(
		bounds.position.x + uv.x * bounds.size.x,
		0.0,
		bounds.position.z + (1.0 - uv.y) * bounds.size.z
	)
	return clamp_xz(world, bounds)
