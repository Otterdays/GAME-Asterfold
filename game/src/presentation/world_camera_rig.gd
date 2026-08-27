class_name WorldCameraRig
extends Node3D

const DEFAULT_HORIZONTAL_PEEK_DEGREES: float = CameraPeekModel.DEFAULT_HORIZONTAL_LIMIT_DEGREES
const DEFAULT_VERTICAL_PEEK_DEGREES: float = CameraPeekModel.DEFAULT_VERTICAL_LIMIT_DEGREES
const TARGET_OFFSET: Vector3 = Vector3(0.0, 3.0, -8.0)
const OCCLUSION_TARGET_HEIGHT: Vector3 = Vector3(0.0, 0.95, 0.0)
const OCCLUDER_COLLISION_MASK: int = 2
const MOUSE_LOOK_SENSITIVITY: float = 0.004

@export var target: Node3D
@export_range(0.0, 359.0, 0.5) var committed_yaw_degrees: float = 0.0
@export_range(1.0, 30.0, 0.1) var follow_speed: float = 9.0

@onready var _peek_yaw: Node3D = %PeekYaw
@onready var _peek_pitch: Node3D = %PeekPitch
@onready var _camera: Camera3D = %WorldCamera

var _peek_model: CameraPeekModel = CameraPeekModel.new()
var _active_occluder: Node
var _occlusion_elapsed: float = 0.0
var _mouse_look: Vector2 = Vector2.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO


func _ready() -> void:
	rotation.y = deg_to_rad(committed_yaw_degrees)
	if target == null:
		push_error("[FLOW] WorldCameraRig requires a target.")
		set_process(false)
		return
	snap_to_target()


func _process(delta: float) -> void:
	if target == null:
		return
	var desired_position: Vector3 = target.global_position + Basis(Vector3.UP, get_committed_yaw_radians()) * TARGET_OFFSET
	global_position = global_position.lerp(desired_position, 1.0 - exp(-follow_speed * delta))
	_update_peek(delta)
	_occlusion_elapsed += delta
	if _occlusion_elapsed >= 0.1:
		_occlusion_elapsed = 0.0
		_update_foreground_occlusion()


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	_peek_model.set_motion_mode(settings.camera_motion_mode)
	_apply_peek_transform(_peek_model.current_degrees)


func snap_to_target() -> void:
	if target == null:
		return
	global_position = target.global_position + Basis(Vector3.UP, get_committed_yaw_radians()) * TARGET_OFFSET


func get_committed_yaw_radians() -> float:
	return rotation.y


func get_camera() -> Camera3D:
	return _camera


func set_peek_limits(horizontal_degrees: float, vertical_degrees: float) -> void:
	_peek_model.set_limits(horizontal_degrees, vertical_degrees)


func reset_peek_limits() -> void:
	set_peek_limits(DEFAULT_HORIZONTAL_PEEK_DEGREES, DEFAULT_VERTICAL_PEEK_DEGREES)


func reset_peek_immediately() -> void:
	_peek_model.reset()
	_mouse_look = Vector2.ZERO
	_mouse_delta = Vector2.ZERO
	_apply_peek_transform(Vector2.ZERO)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_mouse_delta += motion.relative


func _update_peek(delta: float) -> void:
	var stick_peek: Vector2 = InputRouter.get_peek_vector()
	var mouse_moved: bool = _mouse_delta.length_squared() > 0.25
	if mouse_moved:
		_mouse_look.x = clampf(_mouse_look.x + _mouse_delta.x * MOUSE_LOOK_SENSITIVITY, -1.0, 1.0)
		_mouse_look.y = clampf(_mouse_look.y + _mouse_delta.y * MOUSE_LOOK_SENSITIVITY, -1.0, 1.0)
	_mouse_delta = Vector2.ZERO
	var peek_input: Vector2 = stick_peek if stick_peek.length() >= CameraPeekModel.INPUT_EPSILON else _mouse_look
	var input_active: bool = stick_peek.length() >= CameraPeekModel.INPUT_EPSILON or mouse_moved
	_apply_peek_transform(_peek_model.advance_activity(peek_input, delta, input_active))
	if not input_active and _peek_model.target_degrees == Vector2.ZERO:
		_mouse_look = Vector2.ZERO


func _apply_peek_transform(peek_degrees: Vector2) -> void:
	_peek_yaw.rotation.y = deg_to_rad(peek_degrees.x)
	_peek_pitch.rotation.x = deg_to_rad(-35.0 + peek_degrees.y)


func _update_foreground_occlusion() -> void:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		_camera.global_position,
		target.global_position + OCCLUSION_TARGET_HEIGHT,
		OCCLUDER_COLLISION_MASK
	)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var next_occluder: Node = hit.get("collider") as Node
	if next_occluder != null and not next_occluder.has_method(&"set_faded"):
		next_occluder = null
	if next_occluder == _active_occluder:
		return
	if _active_occluder != null and is_instance_valid(_active_occluder):
		_active_occluder.call(&"set_faded", false)
	_active_occluder = next_occluder
	if _active_occluder != null:
		_active_occluder.call(&"set_faded", true)
