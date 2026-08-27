class_name MapMakerTheme
extends RefCounted

## Shared look for every map-maker HUD root. Built in code so the tool needs no imported theme
## asset and stays readable against the live zone behind it.

const SURFACE_COLOR := Color(0.055, 0.07, 0.094, 0.92)
const SURFACE_BORDER := Color(0.42, 0.63, 0.78, 0.34)
const TOOLTIP_COLOR := Color(0.04, 0.05, 0.07, 0.96)
const BUTTON_COLOR := Color(0.13, 0.16, 0.2, 0.96)
const BUTTON_HOVER_COLOR := Color(0.19, 0.24, 0.3, 0.98)
const BUTTON_BORDER := Color(0.36, 0.47, 0.58, 0.5)
const ACCENT_COLOR := Color(0.14, 0.9, 0.28)
const ACCENT_HOVER_COLOR := Color(0.24, 1.0, 0.38)
const DANGER_COLOR := Color(0.92, 0.31, 0.28)
const DANGER_HOVER_COLOR := Color(1.0, 0.42, 0.38)
const FOCUS_COLOR := Color(0.62, 0.85, 1.0, 0.9)
const TEXT_COLOR := Color(0.9, 0.93, 0.96)
const MUTED_TEXT_COLOR := Color(0.66, 0.72, 0.79)


static func build() -> Theme:
	var theme: Theme = Theme.new()
	theme.set_stylebox(&"panel", &"PanelContainer", surface_style())
	theme.set_color(&"font_color", &"Label", TEXT_COLOR)
	theme.set_color(&"font_color", &"Button", TEXT_COLOR)
	theme.set_color(&"font_hover_color", &"Button", Color.WHITE)
	theme.set_color(&"font_color", &"CheckBox", TEXT_COLOR)
	theme.set_stylebox(&"normal", &"Button", button_style(BUTTON_COLOR))
	theme.set_stylebox(&"hover", &"Button", button_style(BUTTON_HOVER_COLOR))
	theme.set_stylebox(&"pressed", &"Button", filled_style(ACCENT_COLOR))
	theme.set_stylebox(&"hover_pressed", &"Button", filled_style(ACCENT_HOVER_COLOR))
	theme.set_stylebox(&"focus", &"Button", focus_style())
	theme.set_color(&"font_pressed_color", &"Button", Color.BLACK)
	theme.set_color(&"font_hover_pressed_color", &"Button", Color.BLACK)
	return theme


static func surface_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SURFACE_COLOR
	style.border_color = SURFACE_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 8
	return style


static func tooltip_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = surface_style()
	style.bg_color = TOOLTIP_COLOR
	style.set_corner_radius_all(6)
	return style


static func button_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BUTTON_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	return style


static func filled_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	return style


static func focus_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = FOCUS_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	return style
