class_name DisplaySettings
extends RefCounted

signal changed

enum WindowModeOption {
	WINDOWED,
	BORDERLESS,
	EXCLUSIVE,
}

const REFERENCE_SIZE: Vector2 = Vector2(1920.0, 1080.0)
## Vertical room reserved for the OS title bar when a windowed size would
## otherwise fill the usable desktop height.
const WINDOW_DECORATION_MARGIN: int = 48
const UI_SCALES: Array[float] = [0.8, 1.0, 1.25, 1.5]
const STANDARD_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

## Vector2i.ZERO means use the current desktop/screen size.
var resolution: Vector2i = Vector2i(1920, 1080)
var window_mode: int = WindowModeOption.WINDOWED
var ui_scale: float = 1.0


func set_window_mode(value: int) -> void:
	var clamped_value: int = clampi(value, WindowModeOption.WINDOWED, WindowModeOption.EXCLUSIVE)
	if window_mode == clamped_value:
		return
	window_mode = clamped_value
	changed.emit()


func is_fullscreen() -> bool:
	return window_mode != WindowModeOption.WINDOWED


## Fullscreen toggles between windowed and borderless so the shortcut never
## strands the player in an exclusive mode they cannot alt-tab out of.
func toggle_fullscreen() -> void:
	if is_fullscreen():
		set_window_mode(WindowModeOption.WINDOWED)
	else:
		set_window_mode(WindowModeOption.BORDERLESS)


func set_resolution(value: Vector2i) -> void:
	var next_resolution: Vector2i = value
	if next_resolution != Vector2i.ZERO:
		next_resolution = Vector2i(maxi(next_resolution.x, 640), maxi(next_resolution.y, 360))
	if resolution == next_resolution:
		return
	resolution = next_resolution
	changed.emit()


func set_ui_scale(value: float) -> void:
	var closest: float = UI_SCALES[0]
	for supported_scale: float in UI_SCALES:
		if absf(supported_scale - value) < absf(closest - value):
			closest = supported_scale
	if is_equal_approx(ui_scale, closest):
		return
	ui_scale = closest
	changed.emit()


func resolved_window_size(screen_size: Vector2i) -> Vector2i:
	var usable_screen: Vector2i = Vector2i(maxi(screen_size.x, 640), maxi(screen_size.y, 360))
	if resolution == Vector2i.ZERO:
		return usable_screen
	return Vector2i(mini(resolution.x, usable_screen.x), mini(resolution.y, usable_screen.y))


func layout_size(canvas: Vector2 = REFERENCE_SIZE) -> Vector2:
	return canvas / ui_scale


func to_dictionary() -> Dictionary:
	return {
		"window_mode": window_mode,
		"resolution_x": resolution.x,
		"resolution_y": resolution.y,
		"ui_scale": ui_scale,
	}


func apply_dictionary(data: Dictionary) -> void:
	window_mode = clampi(
		int(data.get("window_mode", WindowModeOption.WINDOWED)),
		WindowModeOption.WINDOWED,
		WindowModeOption.EXCLUSIVE
	)
	set_resolution(Vector2i(int(data.get("resolution_x", 1920)), int(data.get("resolution_y", 1080))))
	set_ui_scale(float(data.get("ui_scale", 1.0)))
	changed.emit()


## A windowed window must fit inside the usable desktop area and leave room for
## the title bar, otherwise a screen-sized resolution looks like fullscreen and
## the player cannot reach the window controls.
func windowed_window_size(usable_size: Vector2i) -> Vector2i:
	var bounds: Vector2i = Vector2i(maxi(usable_size.x, 640), maxi(usable_size.y, 360))
	var target: Vector2i = resolved_window_size(bounds)
	if target.x >= bounds.x or target.y >= bounds.y:
		var fitted: Vector2 = Vector2(target)
		var shrink: float = minf(
			float(bounds.x) / maxf(fitted.x, 1.0),
			float(bounds.y - WINDOW_DECORATION_MARGIN) / maxf(fitted.y, 1.0)
		)
		if shrink < 1.0:
			fitted *= shrink
		target = Vector2i(maxi(roundi(fitted.x), 640), maxi(roundi(fitted.y), 360))
	return target


func apply_to_window(window: Window, screen_size: Vector2i) -> void:
	if window == null or DisplayServer.get_name() == "headless":
		return
	match window_mode:
		WindowModeOption.BORDERLESS:
			window.mode = Window.MODE_FULLSCREEN
		WindowModeOption.EXCLUSIVE:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		_:
			# Leave fullscreen before resizing; Godot ignores size changes made
			# while the window is still in a fullscreen mode.
			if window.mode != Window.MODE_WINDOWED:
				window.mode = Window.MODE_WINDOWED
			window.borderless = false
			window.size = windowed_window_size(_usable_screen_size(window, screen_size))
			window.move_to_center()


func _usable_screen_size(window: Window, fallback_size: Vector2i) -> Vector2i:
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return fallback_size
	return usable.size


static func list_resolutions(screen_size: Vector2i) -> Array[Vector2i]:
	var choices: Array[Vector2i] = [Vector2i.ZERO]
	for candidate: Vector2i in STANDARD_RESOLUTIONS:
		if candidate.x <= screen_size.x and candidate.y <= screen_size.y:
			choices.append(candidate)
	if choices.size() == 1:
		choices.append(Vector2i(mini(1280, maxi(screen_size.x, 640)), mini(720, maxi(screen_size.y, 360))))
	return choices


static func window_mode_label(mode: int) -> String:
	match mode:
		WindowModeOption.BORDERLESS:
			return "Borderless"
		WindowModeOption.EXCLUSIVE:
			return "Exclusive fullscreen"
		_:
			return "Windowed"


static func resolution_label(value: Vector2i) -> String:
	if value == Vector2i.ZERO:
		return "Desktop"
	return "%d × %d" % [value.x, value.y]
