extends TestCase

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_forward",
	&"move_back",
	&"confirm",
	&"cancel",
	&"menu",
	&"peek",
	&"peek_left",
	&"peek_right",
	&"peek_up",
	&"peek_down",
	&"fold_left",
	&"fold_right",
	&"scout",
	&"toggle_fullscreen",
	&"quit_prompt",
]


func suite_name() -> String:
	return "project_contract"


func run() -> void:
	_check(
		str(ProjectSettings.get_setting("application/config/version", "")) == "0.1.0-dev",
		"The development build version is configured."
	)
	_check(
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility")) != "gl_compatibility",
		"The project does not opt into the compatibility renderer."
	)
	for action: StringName in REQUIRED_ACTIONS:
		_check(InputMap.has_action(action), "Semantic input action '%s' exists." % action)
	_check(is_equal_approx(InputMap.action_get_deadzone(&"move_left"), 0.2), "Movement dead zone is explicit.")
	_check(_has_fullscreen_shortcut(KEY_F11, false), "F11 toggles fullscreen.")
	_check(_has_fullscreen_shortcut(KEY_ENTER, true), "Alt+Enter toggles fullscreen.")
	_check(_has_fullscreen_shortcut(KEY_F10, false) == false, "F10 is not a fullscreen shortcut.")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1920, "Default project canvas is 1920 wide.")
	_check(
		str(ProjectSettings.get_setting("audio/buses/default_bus_layout", ""))
		== "res://assets/audio/default_bus_layout.tres",
		"The project uses the authored audio bus layout."
	)
	_check(AudioServer.get_bus_index("Music") >= 0, "Music bus exists.")
	_check(AudioServer.get_bus_index("UI") >= 0, "UI bus exists.")


func _has_fullscreen_shortcut(keycode: Key, alt_pressed: bool) -> bool:
	for event: InputEvent in InputMap.action_get_events(&"toggle_fullscreen"):
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			if key_event.keycode == keycode and key_event.alt_pressed == alt_pressed:
				return true
	return false
