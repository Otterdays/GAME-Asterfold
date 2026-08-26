extends Node3D

const TARGET_HEIGHT: Vector3 = Vector3(0.0, 0.9, 0.0)

@export var target: Node3D
@export_range(1.0, 30.0, 0.1) var follow_speed: float = 8.0

@onready var _camera: Camera3D = %MetricsCamera


func _ready() -> void:
	if target == null:
		push_error("[FLOW] MetricsCameraRig requires a target.")
		set_process(false)
		return
	global_position = target.global_position
	_aim_at_target()


func _process(delta: float) -> void:
	if target == null:
		return
	var desired_position: Vector3 = target.global_position
	global_position = global_position.lerp(desired_position, 1.0 - exp(-follow_speed * delta))
	_aim_at_target()


func _aim_at_target() -> void:
	_camera.look_at(target.global_position + TARGET_HEIGHT, Vector3.UP)

