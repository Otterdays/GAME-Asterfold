extends Area3D

@export var camera_rig: WorldCameraRig
@export_range(0.0, 24.0, 0.5) var horizontal_limit_degrees: float = 12.0
@export_range(0.0, 8.0, 0.5) var vertical_limit_degrees: float = 4.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func set_camera_rig(value: WorldCameraRig) -> void:
	camera_rig = value


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player") and camera_rig != null:
		camera_rig.set_peek_limits(horizontal_limit_degrees, vertical_limit_degrees)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(&"player") and camera_rig != null:
		camera_rig.reset_peek_limits()
