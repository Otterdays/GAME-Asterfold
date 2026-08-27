extends Control

const MARA_TEXTURE: Texture2D = preload("res://assets/generated/characters/mara/mara_prototype.png")
const CARD_POSITIONS: Array[Vector2] = [
	Vector2(80.0, 105.0),
	Vector2(240.0, 105.0),
	Vector2(400.0, 105.0),
	Vector2(560.0, 105.0),
	Vector2(80.0, 270.0),
	Vector2(240.0, 270.0),
	Vector2(400.0, 270.0),
	Vector2(560.0, 270.0),
]


func _ready() -> void:
	for direction: int in SpriteDirectionResolver.DIRECTION_COUNT:
		var row: int = direction
		var mirrored: bool = false
		if direction == SpriteDirectionResolver.Direction.SOUTH_WEST:
			row = SpriteDirectionResolver.Direction.SOUTH_EAST
			mirrored = true
		elif direction == SpriteDirectionResolver.Direction.WEST:
			row = SpriteDirectionResolver.Direction.EAST
			mirrored = true
		elif direction == SpriteDirectionResolver.Direction.NORTH_WEST:
			row = SpriteDirectionResolver.Direction.NORTH_EAST
			mirrored = true
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = MARA_TEXTURE
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0.0, float(row * 64), 48.0, 64.0)
		sprite.position = CARD_POSITIONS[direction]
		sprite.scale = Vector2(1.6, 1.6)
		sprite.flip_h = mirrored
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		var label: Label = Label.new()
		label.position = CARD_POSITIONS[direction] + Vector2(-70.0, 56.0)
		label.size = Vector2(140.0, 30.0)
		label.text = "%s%s" % [SpriteDirectionResolver.label(direction), "  • mirrored" if mirrored else ""]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override(&"font_size", 14)
		add_child(label)
