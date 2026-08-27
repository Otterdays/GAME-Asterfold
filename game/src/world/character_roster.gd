class_name CharacterRoster
extends RefCounted

## Title-side adventurer slots. This is not a campaign save.
##
## Three slots exist so the shell can teach party size. Only the first is
## writable in preproduction; the others stay locked until companions ship.

const SLOT_COUNT: int = 3
const UNLOCKED_SLOT_COUNT: int = 1
const LOCKED_REASON: String = "Locked. Party companions unlock in a later milestone."

var _slots: Array[CharacterRecord] = []


func _init() -> void:
	_slots.resize(SLOT_COUNT)
	for index: int in SLOT_COUNT:
		_slots[index] = null


func slot_count() -> int:
	return SLOT_COUNT


func is_locked(slot_index: int) -> bool:
	return not _index_ok(slot_index) or slot_index >= UNLOCKED_SLOT_COUNT


func lock_reason(slot_index: int) -> String:
	if not is_locked(slot_index):
		return ""
	if not _index_ok(slot_index):
		return "That character slot does not exist."
	return LOCKED_REASON


func get_record(slot_index: int) -> CharacterRecord:
	if not _index_ok(slot_index):
		return null
	return _slots[slot_index]


func is_occupied(slot_index: int) -> bool:
	return get_record(slot_index) != null


func occupied_count() -> int:
	var count: int = 0
	for record: CharacterRecord in _slots:
		if record != null:
			count += 1
	return count


func taken_names() -> PackedStringArray:
	var names := PackedStringArray()
	for record: CharacterRecord in _slots:
		if record != null:
			names.append(record.display_name)
	return names


func taken_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for record: CharacterRecord in _slots:
		if record != null:
			ids.append(record.id)
	return ids


func first_empty_unlocked_slot() -> int:
	for index: int in UNLOCKED_SLOT_COUNT:
		if _slots[index] == null:
			return index
	return -1


func create_in_slot(
	slot_index: int,
	display_name: String,
	appearance: CharacterAppearance,
	created_unix: int
) -> Dictionary:
	var errors: Array[String] = []
	if not _index_ok(slot_index):
		errors.append("That character slot does not exist.")
		return _result(false, errors, null)
	if is_locked(slot_index):
		errors.append(lock_reason(slot_index))
		return _result(false, errors, null)
	if _slots[slot_index] != null:
		errors.append("That character slot is already occupied.")
		return _result(false, errors, null)
	errors.append_array(AppearanceCatalog.validate_display_name(display_name, taken_names()))
	if appearance == null:
		errors.append("A created character needs an appearance.")
	else:
		errors.append_array(appearance.validate())
	if not errors.is_empty():
		return _result(false, errors, null)
	var record := CharacterRecord.new()
	record.id = _allocate_id(display_name)
	record.display_name = display_name.strip_edges()
	record.appearance = appearance.duplicate_look()
	record.created_unix = created_unix
	errors.append_array(record.validate())
	if not errors.is_empty():
		return _result(false, errors, null)
	_slots[slot_index] = record
	return _result(true, errors, record)


func delete_slot(slot_index: int) -> Array[String]:
	var errors: Array[String] = []
	if not _index_ok(slot_index):
		errors.append("That character slot does not exist.")
		return errors
	if is_locked(slot_index):
		errors.append(lock_reason(slot_index))
		return errors
	if _slots[slot_index] == null:
		errors.append("That character slot is already empty.")
		return errors
	_slots[slot_index] = null
	return errors


func to_dictionary() -> Dictionary:
	var slot_payload: Array = []
	for index: int in SLOT_COUNT:
		var record: CharacterRecord = _slots[index]
		if record == null:
			slot_payload.append(null)
		else:
			var payload: Dictionary = record.to_dictionary()
			payload["index"] = index
			slot_payload.append(payload)
	return {
		"slots": slot_payload,
	}


static func from_dictionary(data: Dictionary) -> CharacterRoster:
	var roster := CharacterRoster.new()
	var slots_value: Variant = data.get("slots", [])
	if not slots_value is Array:
		return roster
	var slots: Array = slots_value as Array
	for index: int in mini(slots.size(), SLOT_COUNT):
		var entry: Variant = slots[index]
		if entry == null:
			continue
		if not entry is Dictionary:
			continue
		var record: CharacterRecord = CharacterRecord.from_dictionary(entry as Dictionary)
		if roster.is_locked(index):
			continue
		if not record.validate().is_empty():
			continue
		roster._slots[index] = record
	return roster


func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen_ids: Dictionary[StringName, bool] = {}
	var seen_names: Dictionary[String, bool] = {}
	for index: int in SLOT_COUNT:
		var record: CharacterRecord = _slots[index]
		if record == null:
			continue
		if is_locked(index):
			errors.append("Locked slot %d cannot hold a character." % index)
			continue
		errors.append_array(record.validate())
		if seen_ids.has(record.id):
			errors.append("Duplicate character ID '%s'." % record.id)
		seen_ids[record.id] = true
		var lowered: String = record.display_name.to_lower()
		if seen_names.has(lowered):
			errors.append("Duplicate character name '%s'." % record.display_name)
		seen_names[lowered] = true
	return errors


func _allocate_id(display_name: String) -> StringName:
	var slug: String = AppearanceCatalog.slug_for_name(display_name)
	var candidate: StringName = StringName("character.%s" % slug)
	var occupied: Array[StringName] = taken_ids()
	if not occupied.has(candidate):
		return candidate
	for suffix: int in range(2, 99):
		var numbered: StringName = StringName("character.%s_%d" % [slug, suffix])
		if not occupied.has(numbered):
			return numbered
	return StringName("character.%s_x" % slug)


func _index_ok(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < SLOT_COUNT


func _result(ok: bool, errors: Array[String], record: CharacterRecord) -> Dictionary:
	return {
		"ok": ok,
		"errors": errors,
		"record": record,
	}
