class_name SpriteLayerCompositor
extends RefCounted

## Flattens per-layer actor art plus equipment into single textures.
##
## The world card stays one `Sprite3D`: composing a whole sheet on equipment
## change keeps transparent overdraw at one quad instead of one quad per layer.

const CACHE_LIMIT: int = 24
const HIGHLIGHT_COLOR: Color = Color(1.0, 0.87, 0.45, 1.0)

var _kit: ActorLayerKit
var _field_layers: Array[Image] = []
var _doll_layers: Array[Image] = []
var _hair_field: Array[Image] = []
var _hair_doll: Array[Image] = []
## Lazily filled per-frame opaque bounds so overlay accents have a stable anchor.
var _field_cell_bounds: Dictionary[int, Array] = {}
var _doll_bounds: Dictionary[int, Rect2i] = {}
var _tint_cache: Dictionary[String, Image] = {}
var _sheet_cache: Dictionary[String, ImageTexture] = {}
var _sheet_cache_order: Array[String] = []


func configure(kit: ActorLayerKit) -> bool:
	_field_layers.clear()
	_doll_layers.clear()
	_hair_field.clear()
	_hair_doll.clear()
	_field_cell_bounds.clear()
	_doll_bounds.clear()
	_tint_cache.clear()
	_sheet_cache.clear()
	_sheet_cache_order.clear()
	_kit = kit
	if _kit == null or _kit.field_atlas == null or _kit.doll_atlas == null:
		return false
	if _kit.hair_field_atlas == null or _kit.hair_doll_atlas == null:
		return false
	var field_atlas: Image = _readable_image(_kit.field_atlas)
	var doll_atlas: Image = _readable_image(_kit.doll_atlas)
	var hair_field_atlas: Image = _readable_image(_kit.hair_field_atlas)
	var hair_doll_atlas: Image = _readable_image(_kit.hair_doll_atlas)
	if field_atlas == null or doll_atlas == null or hair_field_atlas == null or hair_doll_atlas == null:
		return false
	for layer_index: int in ActorLayerIds.field_layer_count():
		_field_layers.append(field_atlas.get_region(_kit.field_layer_region(layer_index)))
	for layer_index: int in ActorLayerIds.doll_layer_count():
		_doll_layers.append(doll_atlas.get_region(_kit.doll_layer_region(layer_index)))
	for style_index: int in _kit.hair_style_count():
		_hair_field.append(hair_field_atlas.get_region(_kit.hair_field_region(style_index)))
		_hair_doll.append(hair_doll_atlas.get_region(_kit.hair_doll_region(style_index)))
	return true


func is_ready() -> bool:
	return (
		_kit != null
		and not _field_layers.is_empty()
		and not _doll_layers.is_empty()
		and _hair_field.size() == _kit.hair_style_count()
	)


func compose_field_sheet(
	equipped: Array[ItemDefinition],
	appearance: CharacterAppearance = null
) -> ImageTexture:
	if not is_ready():
		return null
	var cache_key: String = _cache_key(equipped, appearance)
	if _sheet_cache.has(cache_key):
		return _sheet_cache[cache_key]
	var sheet_size: Vector2i = _kit.field_sheet_size()
	var composed: Image = Image.create(sheet_size.x, sheet_size.y, false, Image.FORMAT_RGBA8)
	var replacements: Dictionary[StringName, ItemDefinition] = _field_replacements(equipped)
	for layer_index: int in _field_layers.size():
		var layer_id: StringName = ActorLayerIds.FIELD_LAYER_ORDER[layer_index]
		var source: Image = _resolved_layer(
			_field_layers[layer_index],
			"field_%d" % layer_index,
			layer_id,
			replacements,
			appearance
		)
		composed.blend_rect(source, Rect2i(Vector2i.ZERO, sheet_size), Vector2i.ZERO)
	_blend_hair_field(composed, equipped, appearance)
	_apply_field_overlays(composed, equipped)
	var texture: ImageTexture = ImageTexture.create_from_image(composed)
	_store_sheet(cache_key, texture)
	return texture


func compose_doll(
	equipped: Array[ItemDefinition],
	appearance: CharacterAppearance = null
) -> ImageTexture:
	if not is_ready():
		return null
	var frame_size: Vector2i = _kit.doll_frame_size()
	var composed: Image = Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
	var replacements: Dictionary[StringName, ItemDefinition] = _doll_replacements(equipped)
	for layer_index: int in _doll_layers.size():
		var layer_id: StringName = ActorLayerIds.DOLL_LAYER_ORDER[layer_index]
		var source: Image = _resolved_layer(
			_doll_layers[layer_index],
			"doll_%d" % layer_index,
			layer_id,
			replacements,
			appearance
		)
		composed.blend_rect(source, Rect2i(Vector2i.ZERO, frame_size), Vector2i.ZERO)
	_blend_hair_doll(composed, equipped, appearance)
	_apply_doll_overlays(composed, equipped)
	return ImageTexture.create_from_image(composed)


## Focus feedback for the paper doll. Shape, not colour, carries the meaning:
## only the focused region is drawn at all.
func compose_doll_highlight(layer_ids: Array[StringName]) -> ImageTexture:
	if not is_ready():
		return null
	var frame_size: Vector2i = _kit.doll_frame_size()
	var composed: Image = Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
	for layer_id: StringName in layer_ids:
		var layer_index: int = ActorLayerIds.doll_index(layer_id)
		if layer_index < 0:
			continue
		var source: Image = _tinted(_doll_layers[layer_index], "highlight_%d" % layer_index, HIGHLIGHT_COLOR)
		composed.blend_rect(source, Rect2i(Vector2i.ZERO, frame_size), Vector2i.ZERO)
	return ImageTexture.create_from_image(composed)


func _cache_key(equipped: Array[ItemDefinition], appearance: CharacterAppearance) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for definition: ItemDefinition in equipped:
		parts.append("%s:%s" % [definition.slot, definition.id])
	parts.sort()
	if appearance == null:
		parts.append("look:baked")
	else:
		parts.append("look:%s" % appearance.cache_key())
	return "|".join(parts)


func _resolved_layer(
	source: Image,
	cache_prefix: String,
	layer_id: StringName,
	replacements: Dictionary[StringName, ItemDefinition],
	appearance: CharacterAppearance
) -> Image:
	if replacements.has(layer_id):
		return _tinted(source, cache_prefix, replacements[layer_id].graybox_color)
	if appearance == null:
		return source
	var group_id: StringName = AppearanceCatalog.layer_tint_group(layer_id)
	if group_id == &"":
		return source
	return _tinted(source, cache_prefix, appearance.color_for_group(group_id))


func _blend_hair_field(
	composed: Image,
	equipped: Array[ItemDefinition],
	appearance: CharacterAppearance
) -> void:
	var hair: Image = _hair_image(_hair_field, appearance, equipped)
	if hair == null:
		return
	composed.blend_rect(hair, Rect2i(Vector2i.ZERO, _kit.field_sheet_size()), Vector2i.ZERO)


func _blend_hair_doll(
	composed: Image,
	equipped: Array[ItemDefinition],
	appearance: CharacterAppearance
) -> void:
	var hair: Image = _hair_image(_hair_doll, appearance, equipped)
	if hair == null:
		return
	composed.blend_rect(hair, Rect2i(Vector2i.ZERO, _kit.doll_frame_size()), Vector2i.ZERO)


func _hair_image(
	styles: Array[Image],
	appearance: CharacterAppearance,
	equipped: Array[ItemDefinition]
) -> Image:
	if _head_replaced(equipped) or styles.is_empty():
		return null
	var style_index: int = 0
	if appearance != null:
		style_index = appearance.hair_style_index()
	if style_index < 0 or style_index >= styles.size():
		style_index = 0
	var source: Image = styles[style_index]
	if appearance == null:
		return source
	return _tinted(source, "hair_%d" % style_index, appearance.hair_color())


func _head_replaced(equipped: Array[ItemDefinition]) -> bool:
	for definition: ItemDefinition in equipped:
		if definition.slot == EquipmentSlotCatalog.SLOT_HEAD and definition.draw_mode == ItemDefinition.DrawMode.REPLACE:
			return true
	return false


func _store_sheet(cache_key: String, texture: ImageTexture) -> void:
	_sheet_cache[cache_key] = texture
	_sheet_cache_order.append(cache_key)
	while _sheet_cache_order.size() > CACHE_LIMIT:
		var evicted: String = _sheet_cache_order.pop_front()
		_sheet_cache.erase(evicted)


func _field_replacements(equipped: Array[ItemDefinition]) -> Dictionary[StringName, ItemDefinition]:
	var replacements: Dictionary[StringName, ItemDefinition] = {}
	for definition: ItemDefinition in equipped:
		if definition.draw_mode != ItemDefinition.DrawMode.REPLACE:
			continue
		for layer_id: StringName in ActorLayerIds.collapse_to_field_layers(definition.covered_layers()):
			replacements[layer_id] = definition
	return replacements


func _doll_replacements(equipped: Array[ItemDefinition]) -> Dictionary[StringName, ItemDefinition]:
	var replacements: Dictionary[StringName, ItemDefinition] = {}
	for definition: ItemDefinition in equipped:
		if definition.draw_mode != ItemDefinition.DrawMode.REPLACE:
			continue
		for layer_id: StringName in definition.covered_layers():
			replacements[layer_id] = definition
	return replacements


func _apply_field_overlays(composed: Image, equipped: Array[ItemDefinition]) -> void:
	for definition: ItemDefinition in equipped:
		if definition.draw_mode != ItemDefinition.DrawMode.OVERLAY:
			continue
		var accent: Vector2i = _overlay_size(definition.slot, 1)
		var anchor: StringName = EquipmentSlotCatalog.overlay_anchor(definition.slot)
		for layer_id: StringName in ActorLayerIds.collapse_to_field_layers(definition.covered_layers()):
			var layer_index: int = ActorLayerIds.field_index(layer_id)
			if layer_index < 0:
				continue
			for cell_index: int in _kit.columns * _kit.rows:
				var bounds: Rect2i = _field_cell_bound(layer_index, cell_index)
				if bounds.size == Vector2i.ZERO:
					continue
				var cell: Rect2i = _cell_rect(cell_index)
				var placement: Rect2i = _anchored_rect(bounds, accent, anchor)
				placement.position += cell.position
				composed.fill_rect(placement.intersection(cell), definition.graybox_color)


func _apply_doll_overlays(composed: Image, equipped: Array[ItemDefinition]) -> void:
	var frame: Rect2i = Rect2i(Vector2i.ZERO, _kit.doll_frame_size())
	for definition: ItemDefinition in equipped:
		if definition.draw_mode != ItemDefinition.DrawMode.OVERLAY:
			continue
		var accent: Vector2i = _overlay_size(definition.slot, 2)
		var anchor: StringName = EquipmentSlotCatalog.overlay_anchor(definition.slot)
		for layer_id: StringName in definition.covered_layers():
			var layer_index: int = ActorLayerIds.doll_index(layer_id)
			if layer_index < 0:
				continue
			var bounds: Rect2i = _doll_bound(layer_index)
			if bounds.size == Vector2i.ZERO:
				continue
			composed.fill_rect(
				_anchored_rect(bounds, accent, anchor).intersection(frame),
				definition.graybox_color
			)


func _overlay_size(slot_id: StringName, scale: int) -> Vector2i:
	if EquipmentSlotCatalog.is_ring(slot_id):
		return Vector2i(2 * scale, 2 * scale)
	if slot_id == EquipmentSlotCatalog.SLOT_NECK:
		return Vector2i(6 * scale, 2 * scale)
	## Headwear must not repaint the face; it caps the top of the skull instead.
	if slot_id == EquipmentSlotCatalog.SLOT_HEAD:
		return Vector2i(14 * scale, 4 * scale)
	return Vector2i(4 * scale, 4 * scale)


func _anchored_rect(bounds: Rect2i, size: Vector2i, anchor: StringName) -> Rect2i:
	var position: Vector2i = bounds.position
	position.x += maxi((bounds.size.x - size.x) / 2, 0)
	if anchor != EquipmentSlotCatalog.ANCHOR_TOP:
		position.y += maxi((bounds.size.y - size.y) / 2, 0)
	return Rect2i(position, size)


func _cell_rect(cell_index: int) -> Rect2i:
	var column: int = cell_index % _kit.columns
	var row: int = cell_index / _kit.columns
	return _kit.frame_cell(column, row)


func _field_cell_bound(layer_index: int, cell_index: int) -> Rect2i:
	if not _field_cell_bounds.has(layer_index):
		var bounds: Array[Rect2i] = []
		var layer: Image = _field_layers[layer_index]
		for index: int in _kit.columns * _kit.rows:
			bounds.append(layer.get_region(_cell_rect(index)).get_used_rect())
		_field_cell_bounds[layer_index] = bounds
	var cached: Array = _field_cell_bounds[layer_index]
	return cached[cell_index] as Rect2i


func _doll_bound(layer_index: int) -> Rect2i:
	if not _doll_bounds.has(layer_index):
		_doll_bounds[layer_index] = _doll_layers[layer_index].get_used_rect()
	return _doll_bounds[layer_index]


## Recolours only the opaque bounding box so equipment changes stay cheap.
func _tinted(source: Image, cache_prefix: String, color: Color) -> Image:
	var cache_key: String = "%s_%s" % [cache_prefix, color.to_html(true)]
	if _tint_cache.has(cache_key):
		return _tint_cache[cache_key]
	var tinted: Image = source.duplicate() as Image
	var bounds: Rect2i = tinted.get_used_rect()
	for y: int in bounds.size.y:
		for x: int in bounds.size.x:
			var pixel_position: Vector2i = bounds.position + Vector2i(x, y)
			var pixel: Color = tinted.get_pixelv(pixel_position)
			if pixel.a <= 0.0:
				continue
			var luminance: float = clampf(pixel.get_luminance(), 0.0, 1.0)
			var shaded: Color = color * (0.55 + 0.45 * luminance)
			shaded.a = pixel.a
			tinted.set_pixelv(pixel_position, shaded)
	_tint_cache[cache_key] = tinted
	return tinted


func _readable_image(texture: Texture2D) -> Image:
	var image: Image = texture.get_image()
	if image == null:
		return null
	image = image.duplicate() as Image
	if image.is_compressed():
		if image.decompress() != OK:
			return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image
