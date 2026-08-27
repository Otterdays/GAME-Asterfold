class_name SettingsStore
extends RefCounted

const SETTINGS_PATH: String = "user://settings.cfg"


static func load_data() -> Dictionary:
	return load_data_from_path(SETTINGS_PATH)


static func load_data_from_path(path: String) -> Dictionary:
	var config: ConfigFile = ConfigFile.new()
	var load_error: Error = config.load(path)
	if load_error == ERR_FILE_NOT_FOUND:
		return {}
	if load_error != OK:
		push_warning("[INPUT] Settings could not be read; defaults will be used.")
		return {}
	return {
		"accessibility": config.get_value("settings", "accessibility", {}),
		"bindings": config.get_value("settings", "bindings", {}),
	}


static func save_data(accessibility: Dictionary, bindings: Dictionary) -> Error:
	return save_data_to_path(SETTINGS_PATH, accessibility, bindings)


static func save_data_to_path(path: String, accessibility: Dictionary, bindings: Dictionary) -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "accessibility", accessibility)
	config.set_value("settings", "bindings", bindings)
	var save_error: Error = config.save(path)
	if save_error != OK:
		push_error("[INPUT] Settings could not be saved: error %d." % save_error)
	return save_error
