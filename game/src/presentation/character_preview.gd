class_name CharacterPreview
extends TextureRect

## Title and slot portrait of the composed field sheet. One quad's texture, not extra 3D.

var _compositor: SpriteLayerCompositor
var _kit: ActorLayerKit
var _appearance: CharacterAppearance = CharacterAppearance.starter()
var _equipped: Array[ItemDefinition] = []
var _atlas: AtlasTexture = AtlasTexture.new()
var _animation_time: float = 0.0
var _moving: bool = false
var _animate: bool = true
var _direction: int = SpriteDirectionResolver.Direction.SOUTH


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture = _atlas
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(compositor: SpriteLayerCompositor, kit: ActorLayerKit) -> void:
	_compositor = compositor
	_kit = kit
	texture = _atlas
	_refresh_sheet()


func set_appearance(appearance: CharacterAppearance) -> void:
	if appearance == null:
		_appearance = CharacterAppearance.starter()
	else:
		_appearance = appearance
	_refresh_sheet()


func set_equipped(equipped: Array[ItemDefinition]) -> void:
	_equipped = equipped
	_refresh_sheet()


func set_moving(moving: bool) -> void:
	if _moving != moving:
		_animation_time = 0.0
	_moving = moving


func set_animate(animate: bool) -> void:
	_animate = animate
	if not _animate:
		_animation_time = 0.0
		_apply_frame()


func set_direction(direction: int) -> void:
	_direction = posmod(direction, SpriteDirectionResolver.DIRECTION_COUNT)
	_apply_frame()


func turn(step: int) -> void:
	set_direction(SpriteSheetPlayback.turn(_direction, step))


func get_direction() -> int:
	return _direction


func _process(delta: float) -> void:
	if not _animate:
		return
	_animation_time += delta
	_apply_frame()


func _refresh_sheet() -> void:
	if _compositor == null or not _compositor.is_ready():
		return
	_atlas.atlas = _compositor.compose_field_sheet(_equipped, _appearance)
	_apply_frame()


func _apply_frame() -> void:
	if _kit == null or _atlas.atlas == null:
		return
	var column: int = SpriteSheetPlayback.frame_column(_moving, _animation_time)
	var row: int = SpriteSheetPlayback.authored_row(_direction)
	_atlas.region = Rect2(_kit.frame_cell(column, row))
	flip_h = SpriteSheetPlayback.is_mirrored(_direction)
