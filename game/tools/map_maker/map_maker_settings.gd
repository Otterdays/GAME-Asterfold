class_name MapMakerSettings
extends RefCounted

const STORE_PATH: String = "user://asterfold_map_maker.cfg"
const IDLE_RESET_MIN_SECONDS: float = 1.0
const IDLE_RESET_MAX_SECONDS: float = 60.0
const DEFAULT_IDLE_RESET_SECONDS: float = 10.0

var follow_cursor: bool = true
var idle_reset: bool = true
var idle_reset_seconds: float = DEFAULT_IDLE_RESET_SECONDS


func load_from_disk() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(STORE_PATH) != OK:
		return
	follow_cursor = bool(config.get_value("camera", "follow_cursor", true))
	idle_reset = bool(config.get_value("camera", "idle_reset", true))
	idle_reset_seconds = clampf(
		float(config.get_value("camera", "idle_reset_seconds", DEFAULT_IDLE_RESET_SECONDS)),
		IDLE_RESET_MIN_SECONDS,
		IDLE_RESET_MAX_SECONDS
	)


func save_to_disk() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("camera", "follow_cursor", follow_cursor)
	config.set_value("camera", "idle_reset", idle_reset)
	config.set_value("camera", "idle_reset_seconds", idle_reset_seconds)
	config.save(STORE_PATH)
