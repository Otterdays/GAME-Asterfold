class_name CharacterRosterStore
extends RefCounted

## Title-roster persistence. Not campaign SaveService: no zone, inventory, or quests.
## Writes stay versioned, validated, temporary-file-first, and recoverable from `.bak`.

const ROSTER_PATH: String = "user://character_roster.json"
const SCHEMA_VERSION: int = 1


static func load_data() -> CharacterRoster:
	return load_data_from_path(ROSTER_PATH)


static func load_data_from_path(path: String) -> CharacterRoster:
	var loaded: CharacterRoster = _load_valid_roster(path)
	if loaded != null:
		return loaded
	var backup: CharacterRoster = _load_valid_roster(_backup_path(path))
	if backup != null:
		push_warning("[SAVE] Character roster recovered from backup.")
		return backup
	return CharacterRoster.new()


static func save_data(roster: CharacterRoster, build_version: String = "") -> Error:
	return save_data_to_path(ROSTER_PATH, roster, build_version)


static func save_data_to_path(path: String, roster: CharacterRoster, build_version: String = "") -> Error:
	if roster == null:
		return ERR_INVALID_PARAMETER
	var errors: Array[String] = roster.validate()
	if not errors.is_empty():
		push_error("[SAVE] Character roster rejected: %s" % errors[0])
		return ERR_INVALID_DATA
	var payload: Dictionary = roster.to_dictionary()
	payload["schema_version"] = SCHEMA_VERSION
	payload["build_version"] = build_version
	var encoded: String = JSON.stringify(payload, "\t")
	var tmp_path: String = path + ".tmp"
	var write_error: Error = _write_text(tmp_path, encoded)
	if write_error != OK:
		return write_error
	var parsed: CharacterRoster = _load_valid_roster(tmp_path)
	if parsed == null:
		_remove_if_exists(tmp_path)
		push_error("[SAVE] Character roster temporary file failed validation.")
		return ERR_INVALID_DATA
	if FileAccess.file_exists(path):
		var backup_error: Error = _replace_file(_backup_path(path), path)
		if backup_error != OK:
			push_warning("[SAVE] Character roster backup could not be rotated.")
	var promote_error: Error = _replace_file(path, tmp_path)
	_remove_if_exists(tmp_path)
	if promote_error != OK:
		push_error("[SAVE] Character roster could not be written: error %d." % promote_error)
	return promote_error


static func _load_valid_roster(path: String) -> CharacterRoster:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	if parse_error != OK or not json.data is Dictionary:
		return null
	var data: Dictionary = json.data as Dictionary
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		return null
	var roster: CharacterRoster = CharacterRoster.from_dictionary(data)
	if not roster.validate().is_empty():
		return null
	return roster


static func _write_text(path: String, contents: String) -> Error:
	_ensure_parent(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	return OK


static func _replace_file(destination: String, source: String) -> Error:
	if not FileAccess.file_exists(source):
		return ERR_FILE_NOT_FOUND
	_ensure_parent(destination)
	var absolute_source: String = ProjectSettings.globalize_path(source)
	var absolute_destination: String = ProjectSettings.globalize_path(destination)
	if FileAccess.file_exists(destination):
		var remove_error: Error = DirAccess.remove_absolute(absolute_destination)
		if remove_error != OK:
			return remove_error
	return DirAccess.copy_absolute(absolute_source, absolute_destination)


static func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _ensure_parent(path: String) -> void:
	var absolute: String = ProjectSettings.globalize_path(path)
	var parent: String = absolute.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent):
		DirAccess.make_dir_recursive_absolute(parent)


static func _backup_path(path: String) -> String:
	return path + ".bak"
