extends Node3D

@export var player: PlayerActor
@export var camera_rig: WorldCameraRig
@export var gameplay_layer: ZoneGameplayLayer
@export var tree_grove: TreeGrove3D

var _manifest: ZoneManifest


func _ready() -> void:
	if player != null and camera_rig != null:
		player.camera_rig = camera_rig
		camera_rig.target = player
		if player.sprite_actor != null:
			player.sprite_actor.camera_rig = camera_rig
	if gameplay_layer != null and camera_rig != null:
		gameplay_layer.configure_camera_rig(camera_rig)


func configure_zone(manifest: ZoneManifest, spawn_id: StringName) -> bool:
	_manifest = manifest
	if player == null or camera_rig == null or gameplay_layer == null:
		push_error("[FLOW] Zone composition is missing a required dependency.")
		return false
	if not gameplay_layer.has_spawn(spawn_id):
		return false
	player.teleport_to(gameplay_layer.get_spawn_transform(spawn_id))
	camera_rig.snap_to_target()
	camera_rig.reset_peek_immediately()
	return true


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	if camera_rig != null:
		camera_rig.apply_accessibility_settings(settings)
	if tree_grove != null:
		tree_grove.apply_accessibility_settings(settings)


func get_camera_rig() -> WorldCameraRig:
	return camera_rig
