class_name MapMakerCameraSession
extends RefCounted

enum Mode { FOLLOW, MANUAL, PARKED }

var follow_enabled: bool = true
var idle_reset_enabled: bool = true
var idle_reset_seconds: float = 10.0
var mode: int = Mode.FOLLOW
var idle_seconds: float = 0.0


func configure(follow_cursor: bool, idle_reset: bool, idle_seconds_limit: float) -> void:
	follow_enabled = follow_cursor
	idle_reset_enabled = idle_reset
	idle_reset_seconds = maxf(idle_seconds_limit, 0.01)
	if not follow_enabled and mode == Mode.FOLLOW:
		mode = Mode.PARKED
	elif follow_enabled and mode == Mode.PARKED:
		mode = Mode.FOLLOW
		idle_seconds = 0.0


func note_cursor_moved() -> void:
	if not follow_enabled:
		return
	mode = Mode.FOLLOW
	idle_seconds = 0.0


func note_manual_camera() -> void:
	mode = Mode.MANUAL
	idle_seconds = 0.0


func park() -> void:
	mode = Mode.PARKED
	idle_seconds = 0.0


func is_following() -> bool:
	return follow_enabled and mode == Mode.FOLLOW


func advance(delta: float) -> bool:
	if not idle_reset_enabled:
		return false
	if mode == Mode.PARKED:
		return false
	idle_seconds += delta
	if idle_seconds < idle_reset_seconds:
		return false
	idle_seconds = 0.0
	mode = Mode.PARKED
	return true
