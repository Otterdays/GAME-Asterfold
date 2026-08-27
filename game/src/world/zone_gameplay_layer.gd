class_name ZoneGameplayLayer
extends Node3D

@onready var _spawn_points: Node3D = %SpawnPoints
@onready var _camera_volumes: Node3D = %CameraVolumes


func get_spawn_transform(spawn_id: StringName) -> Transform3D:
	for child: Node in _spawn_points.get_children():
		if child is Node3D and StringName(child.get_meta(&"spawn_id", &"")) == spawn_id:
			return (child as Node3D).global_transform
	push_error("[FLOW] Spawn '%s' is not present in the gameplay layer." % spawn_id)
	return Transform3D.IDENTITY


func has_spawn(spawn_id: StringName) -> bool:
	for child: Node in _spawn_points.get_children():
		if StringName(child.get_meta(&"spawn_id", &"")) == spawn_id:
			return true
	return false


func configure_camera_rig(camera_rig: WorldCameraRig) -> void:
	for child: Node in _camera_volumes.get_children():
		if child.has_method(&"set_camera_rig"):
			child.call(&"set_camera_rig", camera_rig)
