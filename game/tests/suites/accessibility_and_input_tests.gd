extends TestCase


func suite_name() -> String:
	return "accessibility_and_input"


func run() -> void:
	_test_accessibility_settings()
	_test_display_settings()
	_test_input_router()


func _test_accessibility_settings() -> void:
	var settings: AccessibilitySettings = AccessibilitySettings.new()
	_check(
		settings.presentation_quality == AccessibilitySettings.PresentationQuality.HIGH,
		"Default presentation quality is High."
	)
	_check(settings.canvas_size() == AccessibilitySettings.CANVAS_HIGH, "High quality uses a 1920x1080 canvas.")
	_check(
		AccessibilitySettings.canvas_size_for(AccessibilitySettings.PresentationQuality.LOW) == AccessibilitySettings.CANVAS_LOW,
		"Low quality keeps the 640x360 minimum canvas."
	)
	_check(
		AccessibilitySettings.canvas_size_for(AccessibilitySettings.PresentationQuality.MEDIUM) == AccessibilitySettings.CANVAS_MEDIUM,
		"Medium quality uses a 1280x720 canvas."
	)
	settings.set_presentation_quality(-2)
	_check(settings.presentation_quality == AccessibilitySettings.PresentationQuality.LOW, "Presentation quality clamps to Low.")
	settings.set_presentation_quality(99)
	_check(settings.presentation_quality == AccessibilitySettings.PresentationQuality.HIGH, "Presentation quality clamps to High.")
	var display: DisplaySettings = DisplaySettings.new()
	_check(display.resolution == Vector2i(1920, 1080), "Default window resolution is 1920x1080.")
	_check(display.layout_size() == Vector2(1920, 1080), "Default UI layout is the 1080p reference.")
	var listed: Array[Vector2i] = DisplaySettings.list_resolutions(Vector2i(3840, 2160))
	_check(listed.has(Vector2i(1920, 1080)) and listed.has(Vector2i(2560, 1440)) and listed.has(Vector2i(3840, 2160)), "Resolution list allows 1080p, 1440p, and 4K.")
	settings.set_text_scale(1.44)
	_check(is_equal_approx(settings.text_scale, 1.5), "Text scale snaps to 150 percent.")
	settings.set_camera_motion_mode(99)
	_check(settings.camera_motion_mode == AccessibilitySettings.CameraMotionMode.MINIMAL, "Camera mode clamps to supported values.")
	settings.set_confirm_cancel_swapped(true)
	var restored: AccessibilitySettings = AccessibilitySettings.new()
	restored.apply_dictionary(settings.to_dictionary())
	_check(restored.camera_motion_mode == settings.camera_motion_mode, "Camera setting round-trips.")
	_check(is_equal_approx(restored.text_scale, settings.text_scale), "Text scale round-trips.")
	_check(restored.confirm_cancel_swapped, "Confirm/cancel preference round-trips.")
	_check(restored.presentation_quality == settings.presentation_quality, "Presentation quality round-trips.")


func _test_display_settings() -> void:
	var display: DisplaySettings = DisplaySettings.new()
	display.set_ui_scale(1.4)
	_check(is_equal_approx(display.ui_scale, 1.5), "UI scale snaps to 150 percent.")
	display.set_window_mode(99)
	_check(display.window_mode == DisplaySettings.WindowModeOption.EXCLUSIVE, "Window mode clamps to supported values.")
	display.set_window_mode(DisplaySettings.WindowModeOption.WINDOWED)
	display.toggle_fullscreen()
	_check(display.window_mode == DisplaySettings.WindowModeOption.BORDERLESS and display.is_fullscreen(), "Fullscreen shortcut enters borderless fullscreen.")
	display.toggle_fullscreen()
	_check(display.window_mode == DisplaySettings.WindowModeOption.WINDOWED and not display.is_fullscreen(), "Fullscreen shortcut returns to windowed.")
	display.set_window_mode(DisplaySettings.WindowModeOption.EXCLUSIVE)
	display.toggle_fullscreen()
	_check(display.window_mode == DisplaySettings.WindowModeOption.WINDOWED, "Fullscreen shortcut leaves exclusive fullscreen.")
	display.set_resolution(Vector2i(1920, 1080))
	var fitted: Vector2i = display.windowed_window_size(Vector2i(1920, 1080))
	_check(fitted.y < 1080 and fitted.x <= 1920, "Windowed size leaves room for the title bar on a matching screen.")
	_check(absf(float(fitted.x) / float(fitted.y) - 16.0 / 9.0) < 0.01, "Windowed shrink keeps the requested aspect ratio.")
	_check(display.windowed_window_size(Vector2i(2560, 1440)) == Vector2i(1920, 1080), "Windowed size stays exact when it fits the desktop.")
	display.set_resolution(Vector2i.ZERO)
	_check(display.resolved_window_size(Vector2i(2560, 1440)) == Vector2i(2560, 1440), "Desktop resolution uses the current screen size.")
	display.set_resolution(Vector2i(1920, 1080))
	_check(display.resolved_window_size(Vector2i(1280, 720)) == Vector2i(1280, 720), "Window resolution clamps to the screen.")
	var listed: Array[Vector2i] = DisplaySettings.list_resolutions(Vector2i(1920, 1080))
	_check(listed.has(Vector2i.ZERO) and listed.has(Vector2i(1920, 1080)) and not listed.has(Vector2i(2560, 1440)), "Resolution list includes desktop and fitting standard sizes.")
	display.set_ui_scale(1.25)
	_check(display.layout_size(Vector2(1920, 1080)).is_equal_approx(Vector2(1536, 864)), "UI scale shrinks layout size so widgets grow inside the canvas.")
	var restored_display: DisplaySettings = DisplaySettings.new()
	restored_display.apply_dictionary(display.to_dictionary())
	_check(restored_display.window_mode == display.window_mode, "Window mode round-trips.")
	_check(restored_display.resolution == display.resolution, "Resolution round-trips.")
	_check(is_equal_approx(restored_display.ui_scale, display.ui_scale), "UI scale round-trips.")


func _test_input_router() -> void:
	var w_key: InputEventKey = InputEventKey.new()
	w_key.physical_keycode = KEY_W
	_check((input_router.call(&"find_conflicts", w_key) as Array).has(&"move_forward"), "Binding conflicts detect an occupied key.")
	_check(not (input_router.call(&"find_conflicts", w_key, &"move_forward") as Array).has(&"move_forward"), "Conflict checks can exclude the edited action.")
	var original_bindings: Dictionary = input_router.call(&"serialize_bindings") as Dictionary
	var test_key: InputEventKey = InputEventKey.new()
	test_key.physical_keycode = KEY_T
	_check(bool(input_router.call(&"rebind_action", &"move_forward", test_key, false)), "A free keyboard binding can be captured.")
	_check(String(input_router.call(&"get_prompt", &"move_forward")).contains("T"), "Prompt labels update after rebinding.")
	input_router.call(&"apply_serialized_bindings", original_bindings)
	input_router.call(&"swap_confirm_cancel")
	_check(String(input_router.call(&"get_prompt", &"confirm")) == "Escape", "Confirm/cancel preference swaps semantic keyboard prompts.")
	_check(_actions_share_events(&"confirm", &"ui_accept"), "Swapped confirm bindings drive UI activation.")
	_check(_actions_share_events(&"cancel", &"ui_cancel"), "Swapped cancel bindings drive UI cancellation.")
	input_router.call(&"swap_confirm_cancel")
	var router_script: Script = load("res://src/services/input_router.gd") as Script
	var tracker: Node = router_script.new() as Node
	var joy_event: InputEventJoypadButton = InputEventJoypadButton.new()
	joy_event.pressed = true
	tracker.call(&"consider_input_device", joy_event, 1000)
	_check(tracker.call(&"get_active_device") == &"gamepad", "Gamepad activity changes the active device.")
	var key_event: InputEventKey = InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_A
	tracker.call(&"consider_input_device", key_event, 1100)
	_check(tracker.call(&"get_active_device") == &"gamepad", "Device hysteresis rejects rapid prompt flicker.")
	tracker.call(&"consider_input_device", key_event, 1300)
	_check(tracker.call(&"get_active_device") == &"keyboard_mouse", "Device hysteresis accepts settled device changes.")
	tracker.call(&"consider_input_device", joy_event, 1600)
	tracker.call(&"_on_joy_connection_changed", 0, false)
	_check(tracker.call(&"get_active_device") == &"keyboard_mouse", "Disconnecting the active gamepad restores keyboard prompts.")
	tracker.free()
