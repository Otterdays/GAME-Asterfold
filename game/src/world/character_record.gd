class_name CharacterRecord
extends RefCounted

## One title-roster adventurer. Campaign position and inventory are not stored here.

var id: StringName = &""
var display_name: String = ""
var appearance: CharacterAppearance = CharacterAppearance.starter()
var created_unix: int = 0


func to_dictionary() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"appearance": appearance.to_dictionary() if appearance != null else {},
		"created_unix": created_unix,
	}


static func from_dictionary(data: Dictionary) -> CharacterRecord:
	var record := CharacterRecord.new()
	record.id = StringName(str(data.get("id", "")))
	record.display_name = str(data.get("display_name", ""))
	var appearance_data: Variant = data.get("appearance", {})
	if appearance_data is Dictionary:
		record.appearance = CharacterAppearance.from_dictionary(appearance_data as Dictionary)
	record.created_unix = int(data.get("created_unix", 0))
	return record


func validate() -> Array[String]:
	var errors: Array[String] = []
	if not _is_character_id(String(id)):
		errors.append("Character ID '%s' is not a namespaced character ID." % id)
	errors.append_array(AppearanceCatalog.validate_display_name(display_name))
	if appearance == null:
		errors.append("Character '%s' is missing an appearance." % id)
	else:
		errors.append_array(appearance.validate())
	if created_unix < 0:
		errors.append("Character '%s' has a negative created time." % id)
	return errors


static func _is_character_id(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^character\\.[a-z][a-z0-9_]*$")
	return pattern.search(value) != null
