class_name MapMakerToast
extends PanelContainer

## Transient bottom-center feedback so destructive or silent actions confirm themselves without
## the author reading the status line.

const HOLD_SECONDS: float = 1.6
const FADE_SECONDS: float = 0.45
const NEUTRAL_COLOR := Color(0.9, 0.93, 0.96)
const GOOD_COLOR := Color(0.55, 1.0, 0.68)
const BAD_COLOR := Color(1.0, 0.55, 0.5)

var _label: Label
var _fade: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	z_index = 60
	add_theme_stylebox_override(&"panel", MapMakerTheme.tooltip_style())
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 14)
	margin.add_theme_constant_override(&"margin_top", 8)
	margin.add_theme_constant_override(&"margin_right", 14)
	margin.add_theme_constant_override(&"margin_bottom", 8)
	add_child(margin)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(_label)


func show_message(text: String, color: Color = NEUTRAL_COLOR) -> void:
	if _label == null:
		return
	_label.text = text
	_label.add_theme_color_override(&"font_color", color)
	if _fade != null and _fade.is_valid():
		_fade.kill()
	modulate.a = 1.0
	_fade = create_tween()
	_fade.tween_interval(HOLD_SECONDS)
	_fade.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
