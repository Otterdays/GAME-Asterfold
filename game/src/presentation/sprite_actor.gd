class_name SpriteActor
extends Node3D

@export var camera_rig: WorldCameraRig
@export var sprite: Sprite3D
## Optional. Without a kit the actor keeps its baked sheet and ignores equipment.
@export var layer_kit: ActorLayerKit

var _compositor: SpriteLayerCompositor = SpriteLayerCompositor.new()
var _world_facing: Vector3 = Vector3(0.0, 0.0, 1.0)
var _moving: bool = false
var _movement_speed: float = 0.0
var _animation_time: float = 0.0
var _direction: int = SpriteDirectionResolver.Direction.SOUTH
var _last_committed_yaw: float = INF
var _appearance: CharacterAppearance = CharacterAppearance.starter()
var _equipped: Array[ItemDefinition] = []


func _ready() -> void:
	if layer_kit != null:
		_compositor.configure(layer_kit)
		_apply_sheet_layout()
		apply_presentation(_equipped, _appearance)


## Presentation reacts to the loadout and look; it never decides either.
func apply_equipment(equipped: Array[ItemDefinition]) -> bool:
	return apply_presentation(equipped, _appearance)


func apply_appearance(appearance: CharacterAppearance) -> bool:
	return apply_presentation(_equipped, appearance)


func apply_presentation(equipped: Array[ItemDefinition], appearance: CharacterAppearance) -> bool:
	_equipped = equipped
	if appearance != null:
		_appearance = appearance
	if sprite == null or not _compositor.is_ready():
		return false
	var composed: ImageTexture = _compositor.compose_field_sheet(_equipped, _appearance)
	if composed == null:
		return false
	sprite.texture = composed
	_apply_sheet_layout()
	return true


func get_layer_compositor() -> SpriteLayerCompositor:
	return _compositor


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
	sprite.flip_h = SpriteSheetPlayback.is_mirrored(_direction)


func _update_frame() -> void:
	var moving: bool = _moving and _movement_speed > 0.1
	sprite.frame_coords = Vector2i(
		SpriteSheetPlayback.frame_column(moving, _animation_time),
		SpriteSheetPlayback.authored_row(_direction)
	)


func _apply_sheet_layout() -> void:
	if sprite == null:
		return
	if layer_kit != null:
		sprite.hframes = layer_kit.columns
		sprite.vframes = layer_kit.rows
	elif sprite.texture != null:
		sprite.hframes = SpriteSheetPlayback.IDLE_FRAME_COUNT + SpriteSheetPlayback.WALK_FRAME_COUNT
		sprite.vframes = 5

