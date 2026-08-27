class_name MapMakerTooltip
extends PanelContainer

const SHOW_DELAY_SECONDS: float = 0.35

var _catalog: MapMakerTooltipCatalog
var _label: Label
var _pending_id: StringName = &""
var _delay: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_index = 80
	add_theme_stylebox_override(&"panel", MapMakerTheme.tooltip_style())
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(280, 0)
	_label.add_theme_color_override(&"font_color", MapMakerTheme.TEXT_COLOR)
	margin.add_child(_label)


func configure(catalog: MapMakerTooltipCatalog) -> void:
	_catalog = catalog


func bind_control(control: Control, tooltip_id: StringName) -> void:
	control.mouse_entered.connect(func() -> void: _arm(tooltip_id))
	control.mouse_exited.connect(_disarm)
	control.focus_entered.connect(func() -> void: _arm(tooltip_id))
	control.focus_exited.connect(_disarm)


func _arm(tooltip_id: StringName) -> void:
	_pending_id = tooltip_id
	_delay = 0.0


func _disarm() -> void:
	_pending_id = &""
	_delay = 0.0
	visible = false


func _process(delta: float) -> void:
	if _pending_id == &"" or _catalog == null:
		return
	_delay += delta
	if _delay < SHOW_DELAY_SECONDS:
		return
	var text: String = _catalog.format_text(_pending_id)
	if text.is_empty():
		visible = false
		return
	_label.text = text
	visible = true
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	position = mouse_position + Vector2(18.0, 18.0)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if position.x + size.x > viewport_size.x - 8.0:
		position.x = viewport_size.x - size.x - 8.0
	if position.y + size.y > viewport_size.y - 8.0:
		position.y = viewport_size.y - size.y - 8.0
