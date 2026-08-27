class_name CharacterAppearance
extends RefCounted

## Mutable look for one roster character. Presentation tints layers from this;
## it never decides equipment occupancy.

var hair_style_id: StringName = AppearanceCatalog.HAIR_CROP
var hair_color_id: StringName = AppearanceCatalog.HAIR_BROWN
var skin_id: StringName = AppearanceCatalog.SKIN_WARM
var shirt_id: StringName = AppearanceCatalog.SHIRT_BROWN
var jeans_id: StringName = AppearanceCatalog.JEANS_BLUE
var boot_id: StringName = AppearanceCatalog.BOOT_TAN


static func starter() -> CharacterAppearance:
	return CharacterAppearance.new()


func duplicate_look() -> CharacterAppearance:
	var copy := CharacterAppearance.new()
	copy.hair_style_id = hair_style_id
	copy.hair_color_id = hair_color_id
	copy.skin_id = skin_id
	copy.shirt_id = shirt_id
	copy.jeans_id = jeans_id
	copy.boot_id = boot_id
	return copy


func option_for_channel(channel_id: StringName) -> StringName:
	match channel_id:
		AppearanceCatalog.CHANNEL_HAIR_STYLE:
			return hair_style_id
		AppearanceCatalog.CHANNEL_HAIR_COLOR:
			return hair_color_id
		AppearanceCatalog.CHANNEL_SKIN:
			return skin_id
		AppearanceCatalog.CHANNEL_SHIRT:
			return shirt_id
		AppearanceCatalog.CHANNEL_JEANS:
			return jeans_id
		AppearanceCatalog.CHANNEL_BOOTS:
			return boot_id
		_:
			return &""


func set_channel_option(channel_id: StringName, option_id: StringName) -> bool:
	if not AppearanceCatalog.channel_options(channel_id).has(option_id):
		return false
	match channel_id:
		AppearanceCatalog.CHANNEL_HAIR_STYLE:
			hair_style_id = option_id
		AppearanceCatalog.CHANNEL_HAIR_COLOR:
			hair_color_id = option_id
		AppearanceCatalog.CHANNEL_SKIN:
			skin_id = option_id
		AppearanceCatalog.CHANNEL_SHIRT:
			shirt_id = option_id
		AppearanceCatalog.CHANNEL_JEANS:
			jeans_id = option_id
		AppearanceCatalog.CHANNEL_BOOTS:
			boot_id = option_id
		_:
			return false
	return true


func cycle_channel(channel_id: StringName, step: int) -> void:
	var options: Array[StringName] = AppearanceCatalog.channel_options(channel_id)
	if options.is_empty():
		return
	var current: int = options.find(option_for_channel(channel_id))
	if current < 0:
		current = 0
	var next_index: int = posmod(current + step, options.size())
	set_channel_option(channel_id, options[next_index])


func color_for_group(group_id: StringName) -> Color:
	match group_id:
		AppearanceCatalog.TINT_SKIN:
			return AppearanceCatalog.option_color(skin_id)
		AppearanceCatalog.TINT_SHIRT:
			return AppearanceCatalog.option_color(shirt_id)
		AppearanceCatalog.TINT_JEANS:
			return AppearanceCatalog.option_color(jeans_id)
		AppearanceCatalog.TINT_BOOTS:
			return AppearanceCatalog.option_color(boot_id)
		_:
			return Color.WHITE


func hair_color() -> Color:
	return AppearanceCatalog.option_color(hair_color_id)


func hair_style_index() -> int:
	var index: int = AppearanceCatalog.hair_style_index(hair_style_id)
	return index if index >= 0 else 0


func cache_key() -> String:
	return "%s|%s|%s|%s|%s|%s" % [
		hair_style_id,
		hair_color_id,
		skin_id,
		shirt_id,
		jeans_id,
		boot_id,
	]


func to_dictionary() -> Dictionary:
	return {
		"hair_style_id": String(hair_style_id),
		"hair_color_id": String(hair_color_id),
		"skin_id": String(skin_id),
		"shirt_id": String(shirt_id),
		"jeans_id": String(jeans_id),
		"boot_id": String(boot_id),
	}


static func from_dictionary(data: Dictionary) -> CharacterAppearance:
	var appearance := CharacterAppearance.new()
	appearance.hair_style_id = _known_or_default(
		StringName(str(data.get("hair_style_id", ""))),
		AppearanceCatalog.CHANNEL_HAIR_STYLE,
		AppearanceCatalog.HAIR_CROP
	)
	appearance.hair_color_id = _known_or_default(
		StringName(str(data.get("hair_color_id", ""))),
		AppearanceCatalog.CHANNEL_HAIR_COLOR,
		AppearanceCatalog.HAIR_BROWN
	)
	appearance.skin_id = _known_or_default(
		StringName(str(data.get("skin_id", ""))),
		AppearanceCatalog.CHANNEL_SKIN,
		AppearanceCatalog.SKIN_WARM
	)
	appearance.shirt_id = _known_or_default(
		StringName(str(data.get("shirt_id", ""))),
		AppearanceCatalog.CHANNEL_SHIRT,
		AppearanceCatalog.SHIRT_BROWN
	)
	appearance.jeans_id = _known_or_default(
		StringName(str(data.get("jeans_id", ""))),
		AppearanceCatalog.CHANNEL_JEANS,
		AppearanceCatalog.JEANS_BLUE
	)
	appearance.boot_id = _known_or_default(
		StringName(str(data.get("boot_id", ""))),
		AppearanceCatalog.CHANNEL_BOOTS,
		AppearanceCatalog.BOOT_TAN
	)
	return appearance


func validate() -> Array[String]:
	var errors: Array[String] = []
	for channel_id: StringName in AppearanceCatalog.CHANNEL_ORDER:
		var option_id: StringName = option_for_channel(channel_id)
		if not AppearanceCatalog.channel_options(channel_id).has(option_id):
			errors.append("Appearance channel '%s' has unknown option '%s'." % [channel_id, option_id])
	return errors


static func _known_or_default(option_id: StringName, channel_id: StringName, fallback: StringName) -> StringName:
	if AppearanceCatalog.channel_options(channel_id).has(option_id):
		return option_id
	return fallback
