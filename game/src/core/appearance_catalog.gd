class_name AppearanceCatalog
extends RefCounted

## Closed v1 title-creation looks. IDs persist; colours and labels may be retuned.
##
## Only options the layered kit can actually honour: hair style, hair colour, skin,
## shirt, jeans, and boots. Callings, faces, and extra costumes stay out until
## those systems exist.

const HAIR_CROP: StringName = &"hair.crop"
const HAIR_FRINGE: StringName = &"hair.fringe"
const HAIR_TOUSLE: StringName = &"hair.tousle"

const HAIR_STYLE_ORDER: Array[StringName] = [
	HAIR_CROP,
	HAIR_FRINGE,
	HAIR_TOUSLE,
]

const HAIR_BROWN: StringName = &"color.hair.brown"
const HAIR_DARK: StringName = &"color.hair.dark"
const HAIR_AUBURN: StringName = &"color.hair.auburn"
const HAIR_BLACK: StringName = &"color.hair.black"

const SKIN_FAIR: StringName = &"color.skin.fair"
const SKIN_WARM: StringName = &"color.skin.warm"
const SKIN_TAN: StringName = &"color.skin.tan"
const SKIN_DEEP: StringName = &"color.skin.deep"

const SHIRT_BROWN: StringName = &"color.shirt.brown"
const SHIRT_RUST: StringName = &"color.shirt.rust"
const SHIRT_OLIVE: StringName = &"color.shirt.olive"
const SHIRT_SLATE: StringName = &"color.shirt.slate"

const JEANS_BLUE: StringName = &"color.jeans.blue"
const JEANS_DARK: StringName = &"color.jeans.dark"
const JEANS_FADED: StringName = &"color.jeans.faded"

const BOOT_TAN: StringName = &"color.boots.tan"
const BOOT_BROWN: StringName = &"color.boots.brown"
const BOOT_DARK: StringName = &"color.boots.dark"

const CHANNEL_HAIR_STYLE: StringName = &"channel.hair_style"
const CHANNEL_HAIR_COLOR: StringName = &"channel.hair_color"
const CHANNEL_SKIN: StringName = &"channel.skin"
const CHANNEL_SHIRT: StringName = &"channel.shirt"
const CHANNEL_JEANS: StringName = &"channel.jeans"
const CHANNEL_BOOTS: StringName = &"channel.boots"

const CHANNEL_ORDER: Array[StringName] = [
	CHANNEL_HAIR_STYLE,
	CHANNEL_HAIR_COLOR,
	CHANNEL_SKIN,
	CHANNEL_SHIRT,
	CHANNEL_JEANS,
	CHANNEL_BOOTS,
]

const TINT_SKIN: StringName = &"tint.skin"
const TINT_SHIRT: StringName = &"tint.shirt"
const TINT_JEANS: StringName = &"tint.jeans"
const TINT_BOOTS: StringName = &"tint.boots"

const DEFAULT_DISPLAY_NAME: String = "Wanderer"
const NAME_MIN: int = 2
const NAME_MAX: int = 16


static func hair_style_count() -> int:
	return HAIR_STYLE_ORDER.size()


static func hair_style_index(style_id: StringName) -> int:
	return HAIR_STYLE_ORDER.find(style_id)


static func is_hair_style(style_id: StringName) -> bool:
	return HAIR_STYLE_ORDER.has(style_id)


static func channel_options(channel_id: StringName) -> Array[StringName]:
	var options: Array[StringName] = []
	match channel_id:
		CHANNEL_HAIR_STYLE:
			options.assign(HAIR_STYLE_ORDER)
		CHANNEL_HAIR_COLOR:
			options.assign([HAIR_BROWN, HAIR_DARK, HAIR_AUBURN, HAIR_BLACK] as Array[StringName])
		CHANNEL_SKIN:
			options.assign([SKIN_WARM, SKIN_FAIR, SKIN_TAN, SKIN_DEEP] as Array[StringName])
		CHANNEL_SHIRT:
			options.assign([SHIRT_BROWN, SHIRT_RUST, SHIRT_OLIVE, SHIRT_SLATE] as Array[StringName])
		CHANNEL_JEANS:
			options.assign([JEANS_BLUE, JEANS_DARK, JEANS_FADED] as Array[StringName])
		CHANNEL_BOOTS:
			options.assign([BOOT_TAN, BOOT_BROWN, BOOT_DARK] as Array[StringName])
	return options


static func channel_label(channel_id: StringName) -> String:
	match channel_id:
		CHANNEL_HAIR_STYLE:
			return "Hair style"
		CHANNEL_HAIR_COLOR:
			return "Hair colour"
		CHANNEL_SKIN:
			return "Skin"
		CHANNEL_SHIRT:
			return "Shirt"
		CHANNEL_JEANS:
			return "Jeans"
		CHANNEL_BOOTS:
			return "Boots"
		_:
			return String(channel_id)


static func option_label(option_id: StringName) -> String:
	match option_id:
		HAIR_CROP:
			return "Short crop"
		HAIR_FRINGE:
			return "Short fringe"
		HAIR_TOUSLE:
			return "Short tousle"
		HAIR_BROWN:
			return "Brown"
		HAIR_DARK:
			return "Dark brown"
		HAIR_AUBURN:
			return "Auburn"
		HAIR_BLACK:
			return "Black"
		SKIN_FAIR:
			return "Fair"
		SKIN_WARM:
			return "Warm"
		SKIN_TAN:
			return "Tan"
		SKIN_DEEP:
			return "Deep"
		SHIRT_BROWN:
			return "Brown tee"
		SHIRT_RUST:
			return "Rust tee"
		SHIRT_OLIVE:
			return "Olive tee"
		SHIRT_SLATE:
			return "Slate tee"
		JEANS_BLUE:
			return "Blue jeans"
		JEANS_DARK:
			return "Dark jeans"
		JEANS_FADED:
			return "Faded jeans"
		BOOT_TAN:
			return "Tan boots"
		BOOT_BROWN:
			return "Brown boots"
		BOOT_DARK:
			return "Dark boots"
		_:
			return String(option_id)


static func option_color(option_id: StringName) -> Color:
	match option_id:
		HAIR_BROWN:
			return Color("6B4423")
		HAIR_DARK:
			return Color("3D2814")
		HAIR_AUBURN:
			return Color("8B4513")
		HAIR_BLACK:
			return Color("1A1410")
		SKIN_FAIR:
			return Color("E8C4A8")
		SKIN_WARM:
			return Color("D7A07B")
		SKIN_TAN:
			return Color("C4865A")
		SKIN_DEEP:
			return Color("8D5A3C")
		SHIRT_BROWN:
			return Color("8B5A2B")
		SHIRT_RUST:
			return Color("A04A32")
		SHIRT_OLIVE:
			return Color("6B6B3A")
		SHIRT_SLATE:
			return Color("4A5568")
		JEANS_BLUE:
			return Color("3B5A8A")
		JEANS_DARK:
			return Color("243A5C")
		JEANS_FADED:
			return Color("6A8AAA")
		BOOT_TAN:
			return Color("C4A574")
		BOOT_BROWN:
			return Color("8B7355")
		BOOT_DARK:
			return Color("5C4A32")
		_:
			return Color.WHITE


static func layer_tint_group(layer_id: StringName) -> StringName:
	match layer_id:
		&"layer.head", &"layer.l_hand", &"layer.r_hand", &"layer.l_forearm", &"layer.r_forearm":
			return TINT_SKIN
		&"layer.l_thumb", &"layer.l_index", &"layer.l_middle", &"layer.l_ring", &"layer.l_little":
			return TINT_SKIN
		&"layer.r_thumb", &"layer.r_index", &"layer.r_middle", &"layer.r_ring", &"layer.r_little":
			return TINT_SKIN
		&"layer.torso", &"layer.abdomen", &"layer.l_shoulder", &"layer.r_shoulder":
			return TINT_SHIRT
		&"layer.l_upper_arm", &"layer.r_upper_arm":
			return TINT_SHIRT
		&"layer.pelvis", &"layer.waist", &"layer.l_thigh", &"layer.r_thigh":
			return TINT_JEANS
		&"layer.l_knee", &"layer.r_knee", &"layer.l_calf", &"layer.r_calf":
			return TINT_JEANS
		&"layer.l_foot", &"layer.r_foot":
			return TINT_BOOTS
		_:
			return &""


static func validate_display_name(display_name: String, taken_names: PackedStringArray = PackedStringArray()) -> Array[String]:
	var errors: Array[String] = []
	var trimmed: String = display_name.strip_edges()
	if trimmed != display_name:
		errors.append("Name cannot start or end with a space.")
	if trimmed.length() < NAME_MIN:
		errors.append("Name must be at least %d letters." % NAME_MIN)
	if trimmed.length() > NAME_MAX:
		errors.append("Name must be at most %d characters." % NAME_MAX)
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z][A-Za-z '\\-]*[A-Za-z]$")
	if trimmed.length() >= NAME_MIN and pattern.search(trimmed) == null:
		errors.append("Name may use letters, spaces, hyphens, and apostrophes.")
	if trimmed.contains("  "):
		errors.append("Name cannot contain consecutive spaces.")
	var lowered: String = trimmed.to_lower()
	for taken: String in taken_names:
		if taken.to_lower() == lowered:
			errors.append("That name is already on this roster.")
			break
	return errors


static func slug_for_name(display_name: String) -> String:
	var lowered: String = display_name.strip_edges().to_lower()
	var slug := ""
	for index: int in lowered.length():
		var code: int = lowered.unicode_at(index)
		var is_letter: bool = (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
		if is_letter:
			slug += char(code)
		elif not slug.ends_with("_") and not slug.is_empty():
			slug += "_"
	slug = slug.trim_prefix("_").trim_suffix("_")
	if slug.is_empty():
		return "wanderer"
	return slug


static func unique_default_name(taken_names: PackedStringArray) -> String:
	if validate_display_name(DEFAULT_DISPLAY_NAME, taken_names).is_empty():
		return DEFAULT_DISPLAY_NAME
	for suffix: int in range(2, 99):
		var candidate: String = "%s %d" % [DEFAULT_DISPLAY_NAME, suffix]
		if validate_display_name(candidate, taken_names).is_empty():
			return candidate
	return DEFAULT_DISPLAY_NAME
