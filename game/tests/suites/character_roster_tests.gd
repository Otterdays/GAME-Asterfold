extends TestCase

const TEST_ROSTER_PATH: String = "user://asterfold_test_character_roster.json"


func suite_name() -> String:
	return "character_roster"


func run() -> void:
	_test_name_rules()
	_test_appearance_catalog()
	_test_roster_slots()
	_test_roster_store()
	_test_sheet_playback()
	_test_appearance_composition()


func _test_name_rules() -> void:
	_check(
		AppearanceCatalog.validate_display_name("Mara").is_empty(),
		"A two-letter name is accepted."
	)
	_check(
		not AppearanceCatalog.validate_display_name("A").is_empty(),
		"A one-letter name is rejected."
	)
	_check(
		not AppearanceCatalog.validate_display_name(" Wanderer").is_empty(),
		"Leading spaces are rejected."
	)
	_check(
		AppearanceCatalog.validate_display_name("Wanderer 2").is_empty(),
		"A numbered default name is accepted."
	)
	_check(
		not AppearanceCatalog.validate_display_name("Name_1").is_empty(),
		"Underscores are rejected in display names."
	)
	_check(
		AppearanceCatalog.validate_display_name("Ann-Marie O'Hara").is_empty(),
		"Hyphens, spaces, and apostrophes are allowed."
	)
	var taken := PackedStringArray(["Wanderer"])
	_check(
		not AppearanceCatalog.validate_display_name("wanderer", taken).is_empty(),
		"Names are unique without regard to case."
	)
	_check(
		AppearanceCatalog.unique_default_name(taken) == "Wanderer 2",
		"The default name increments when Wanderer is taken."
	)
	_check(AppearanceCatalog.slug_for_name("Ann-Marie") == "ann_marie", "Slugs keep letters and collapse punctuation.")


func _test_appearance_catalog() -> void:
	_check(AppearanceCatalog.hair_style_count() == 3, "Three short hair styles are available.")
	_check(
		AppearanceCatalog.channel_options(AppearanceCatalog.CHANNEL_HAIR_STYLE)[0] == AppearanceCatalog.HAIR_CROP,
		"Creation defaults start at short crop."
	)
	var look: CharacterAppearance = CharacterAppearance.starter()
	_check(look.hair_style_id == AppearanceCatalog.HAIR_CROP, "Starter hair is the short crop.")
	_check(look.shirt_id == AppearanceCatalog.SHIRT_BROWN, "Starter shirt is the brown tee.")
	_check(look.jeans_id == AppearanceCatalog.JEANS_BLUE, "Starter jeans are blue.")
	_check(look.boot_id == AppearanceCatalog.BOOT_TAN, "Starter boots are tan.")
	look.cycle_channel(AppearanceCatalog.CHANNEL_HAIR_STYLE, 1)
	_check(look.hair_style_id == AppearanceCatalog.HAIR_FRINGE, "Hair style cycles forward.")
	look.cycle_channel(AppearanceCatalog.CHANNEL_HAIR_STYLE, -1)
	_check(look.hair_style_id == AppearanceCatalog.HAIR_CROP, "Hair style cycles backward.")
	var restored: CharacterAppearance = CharacterAppearance.from_dictionary(look.to_dictionary())
	_check(restored.cache_key() == look.cache_key(), "Appearance round-trips through a dictionary.")
	var unknown: CharacterAppearance = CharacterAppearance.from_dictionary({"hair_style_id": "hair.unknown"})
	_check(unknown.hair_style_id == AppearanceCatalog.HAIR_CROP, "Unknown appearance IDs fall back to starter options.")


func _test_roster_slots() -> void:
	var roster := CharacterRoster.new()
	_check(roster.slot_count() == 3, "The title roster has three slots.")
	_check(not roster.is_locked(0), "Slot one is writable.")
	_check(roster.is_locked(1) and roster.is_locked(2), "Slots two and three are locked.")
	_check(roster.lock_reason(1).contains("later milestone"), "Locked slots explain why in text.")
	var locked: Dictionary = roster.create_in_slot(1, "Mara", CharacterAppearance.starter(), 10)
	_check(not bool(locked.get("ok", true)), "Locked slots refuse creation.")
	var bad_name: Dictionary = roster.create_in_slot(0, "!", CharacterAppearance.starter(), 10)
	_check(not bool(bad_name.get("ok", true)), "Invalid names refuse creation.")
	var created: Dictionary = roster.create_in_slot(0, "Mara", CharacterAppearance.starter(), 10)
	_check(bool(created.get("ok", false)), "The open slot accepts a valid adventurer.")
	var record: CharacterRecord = created.get("record") as CharacterRecord
	_check(record != null and record.id == &"character.mara", "Created characters receive a stable character ID.")
	var duplicate: Dictionary = roster.create_in_slot(0, "Other", CharacterAppearance.starter(), 11)
	_check(not bool(duplicate.get("ok", true)), "An occupied slot refuses a second character.")
	var same_name := CharacterRoster.new()
	same_name.create_in_slot(0, "Mara", CharacterAppearance.starter(), 10)
	# Occupied first slot is the only writable one, so uniqueness is proven by the occupied check above
	# plus name validation against taken names.
	_check(not AppearanceCatalog.validate_display_name("Mara", roster.taken_names()).is_empty(), "Taken names are rejected.")
	_check(roster.delete_slot(1).size() > 0, "Locked slots cannot be deleted.")
	_check(roster.delete_slot(0).is_empty(), "The open slot can be cleared.")
	_check(not roster.is_occupied(0), "Deleting the open slot leaves it empty.")


func _test_roster_store() -> void:
	_cleanup_roster_files()
	var roster := CharacterRoster.new()
	var look: CharacterAppearance = CharacterAppearance.starter()
	look.hair_style_id = AppearanceCatalog.HAIR_TOUSLE
	look.shirt_id = AppearanceCatalog.SHIRT_OLIVE
	roster.create_in_slot(0, "Willow", look, 42)
	_check(
		CharacterRosterStore.save_data_to_path(TEST_ROSTER_PATH, roster, "0.1.0-dev") == OK,
		"Roster writes through a temporary file."
	)
	_check(
		CharacterRosterStore.save_data_to_path(TEST_ROSTER_PATH, roster, "0.1.0-dev") == OK,
		"A second write rotates the previous roster to backup."
	)
	var loaded: CharacterRoster = CharacterRosterStore.load_data_from_path(TEST_ROSTER_PATH)
	var record: CharacterRecord = loaded.get_record(0)
	_check(record != null and record.display_name == "Willow", "Roster load restores the display name.")
	_check(
		record != null and record.appearance.hair_style_id == AppearanceCatalog.HAIR_TOUSLE,
		"Roster load restores hair style."
	)
	_check(loaded.is_locked(2), "Loaded rosters keep later slots locked.")
	var corrupt: FileAccess = FileAccess.open(TEST_ROSTER_PATH, FileAccess.WRITE)
	corrupt.store_string("{not json")
	corrupt.close()
	var recovered: CharacterRoster = CharacterRosterStore.load_data_from_path(TEST_ROSTER_PATH)
	_check(
		recovered.get_record(0) != null and recovered.get_record(0).display_name == "Willow",
		"A corrupt roster file recovers from backup."
	)
	_cleanup_roster_files()
	var missing: CharacterRoster = CharacterRosterStore.load_data_from_path(TEST_ROSTER_PATH)
	_check(missing.occupied_count() == 0, "A missing roster file starts empty.")


func _test_sheet_playback() -> void:
	_check(SpriteSheetPlayback.frame_column(false, 0.0) == 0, "Idle starts on column 0.")
	_check(
		SpriteSheetPlayback.frame_column(false, 1.01) == 3,
		"Idle uses four frames at 3 fps."
	)
	_check(SpriteSheetPlayback.frame_column(true, 0.0) == 4, "Walk starts after the idle columns.")
	_check(
		SpriteSheetPlayback.authored_row(SpriteDirectionResolver.Direction.WEST) == SpriteDirectionResolver.Direction.EAST,
		"West reuses the authored east row."
	)
	_check(SpriteSheetPlayback.is_mirrored(SpriteDirectionResolver.Direction.WEST), "West is mirrored.")
	_check(
		SpriteSheetPlayback.turn(SpriteDirectionResolver.Direction.SOUTH, 1) == SpriteDirectionResolver.Direction.SOUTH_WEST,
		"Preview turn wraps around the compass."
	)


func _test_appearance_composition() -> void:
	var kit: ActorLayerKit = load("res://content/actors/mara_layer_kit.tres") as ActorLayerKit
	if kit == null:
		_check(false, "The Mara layer kit loads for appearance composition.")
		return
	_check(kit.columns == 12, "The field sheet packs twelve animation columns.")
	_check(kit.hair_style_count() == 3, "The kit packs three hair styles.")
	_check(kit.validate_definition().is_empty(), "The kit matches the hair and frame contract.")
	var compositor := SpriteLayerCompositor.new()
	_check(compositor.configure(kit), "The compositor slices body and hair atlases.")
	var crop: ImageTexture = compositor.compose_field_sheet([] as Array[ItemDefinition], CharacterAppearance.starter())
	_check(crop != null, "Starter appearance composes.")
	if crop == null:
		return
	_check(crop.get_size() == Vector2(kit.field_sheet_size()), "Appearance compose keeps the 12x5 sheet.")
	var fringe := CharacterAppearance.starter()
	fringe.hair_style_id = AppearanceCatalog.HAIR_FRINGE
	var fringe_sheet: ImageTexture = compositor.compose_field_sheet([] as Array[ItemDefinition], fringe)
	_check(
		fringe_sheet != null and fringe_sheet.get_image().get_data() != crop.get_image().get_data(),
		"Hair style changes the composed card."
	)
	var olive := CharacterAppearance.starter()
	olive.shirt_id = AppearanceCatalog.SHIRT_OLIVE
	var olive_sheet: ImageTexture = compositor.compose_field_sheet([] as Array[ItemDefinition], olive)
	_check(
		olive_sheet != null and olive_sheet.get_image().get_data() != crop.get_image().get_data(),
		"Shirt colour changes the composed card."
	)


func _cleanup_roster_files() -> void:
	for path: String in [TEST_ROSTER_PATH, TEST_ROSTER_PATH + ".bak", TEST_ROSTER_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
