class_name SpriteActor
extends Node3D

const IDLE_FPS: float = 2.0
const WALK_FPS: float = 8.0

@export var camera_rig: WorldCameraRig
@export var sprite: Sprite3D

var _world_facing: Vector3 = Vector3(0.0, 0.0, 1.0)
var _moving: bool = false
var _movement_speed: float = 0.0
var _animation_time: float = 0.0
var _direction: int = SpriteDirectionResolver.Direction.SOUTH
var _last_committed_yaw: float = INF


func _process(delta: float) -> void:
	if sprite == null or camera_rig == null:
		return
	_animation_time += delta
	var committed_yaw: float = camera_rig.get_committed_yaw_radians()
	if not is_equal_approx(committed_yaw, _last_committed_yaw):
		_update_direction(committed_yaw)
		_last_committed_yaw = committed_yaw
	_update_frame()


func set_motion(world_facing: Vector3, moving: bool, movement_speed: float) -> void:
	var facing_changed: bool = not _world_facing.is_equal_approx(world_facing)
	if _moving != moving:
		_animation_time = 0.0
	_world_facing = world_facing
	_moving = moving
	_movement_speed = movement_speed
	if facing_changed and camera_rig != null:
		_update_direction(camera_rig.get_committed_yaw_radians())


func get_displayed_direction() -> int:
	return _direction


func _update_direction(committed_yaw: float) -> void:
	_direction = SpriteDirectionResolver.resolve(_world_facing, committed_yaw, _direction)
	var mirrored: bool = _direction in [
		SpriteDirectionResolver.Direction.SOUTH_WEST,
		SpriteDirectionResolver.Direction.WEST,
		SpriteDirectionResolver.Direction.NORTH_WEST,
	]
	sprite.flip_h = mirrored


func _update_frame() -> void:
	var row: int = _direction
	if _direction == SpriteDirectionResolver.Direction.SOUTH_WEST:
		row = SpriteDirectionResolver.Direction.SOUTH_EAST
	elif _direction == SpriteDirectionResolver.Direction.WEST:
		row = SpriteDirectionResolver.Direction.EAST
	elif _direction == SpriteDirectionResolver.Direction.NORTH_WEST:
		row = SpriteDirectionResolver.Direction.NORTH_EAST
	if row > SpriteDirectionResolver.Direction.SOUTH:
		row = SpriteDirectionResolver.Direction.SOUTH

	var column: int
	if _moving and _movement_speed > 0.1:
		column = 2 + int(floor(_animation_time * WALK_FPS)) % 4
	else:
		column = int(floor(_animation_time * IDLE_FPS)) % 2
	sprite.frame_coords = Vector2i(column, row)

