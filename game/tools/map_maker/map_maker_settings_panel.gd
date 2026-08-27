class_name MapMakerSettingsPanel
extends PanelContainer

signal settings_changed(settings: MapMakerSettings)
signal closed

var _settings: MapMakerSettings
var _follow_check: CheckBox
var _idle_check: CheckBox
var _idle_spin: SpinBox
var _close_button: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = MapMakerTheme.build()
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 14)
	margin.add_theme_constant_override(&"margin_top", 12)
	margin.add_theme_constant_override(&"margin_right", 14)
	margin.add_theme_constant_override(&"margin_bottom", 12)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	margin.add_child(column)
	var heading: Label = Label.new()
	heading.text = "Map maker settings"
	heading.add_theme_font_size_override(&"font_size", 18)
	column.add_child(heading)
	var divider: HSeparator = HSeparator.new()
	column.add_child(divider)
	_follow_check = CheckBox.new()
	_follow_check.text = "Follow cursor on start"
	_follow_check.focus_mode = Control.FOCUS_ALL
	_follow_check.toggled.connect(_on_follow_toggled)
	column.add_child(_follow_check)
	_idle_check = CheckBox.new()
	_idle_check.text = "Restore default view when idle"
	_idle_check.focus_mode = Control.FOCUS_ALL
	_idle_check.toggled.connect(_on_idle_toggled)
	column.add_child(_idle_check)
	var idle_row: HBoxContainer = HBoxContainer.new()
	idle_row.add_theme_constant_override(&"separation", 8)
	column.add_child(idle_row)
	var idle_label: Label = Label.new()
	idle_label.text = "Idle seconds"
	idle_row.add_child(idle_label)
	_idle_spin = SpinBox.new()
	_idle_spin.min_value = MapMakerSettings.IDLE_RESET_MIN_SECONDS
	_idle_spin.max_value = MapMakerSettings.IDLE_RESET_MAX_SECONDS
	_idle_spin.step = 1.0
	_idle_spin.value_changed.connect(_on_idle_seconds_changed)
	idle_row.add_child(_idle_spin)
	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.pressed.connect(hide_panel)
	column.add_child(_close_button)


func configure(settings: MapMakerSettings) -> void:
	_settings = settings
	_sync_controls()


func show_panel() -> void:
	visible = true
	_sync_controls()
	_follow_check.grab_focus()


func hide_panel() -> void:
	visible = false
	closed.emit()


func _sync_controls() -> void:
	if _settings == null:
		return
	_follow_check.set_pressed_no_signal(_settings.follow_cursor)
	_idle_check.set_pressed_no_signal(_settings.idle_reset)
	_idle_spin.set_value_no_signal(_settings.idle_reset_seconds)
	_idle_spin.editable = _settings.idle_reset


func _on_follow_toggled(pressed: bool) -> void:
	if _settings == null:
		return
	_settings.follow_cursor = pressed
	_emit_changed()


func _on_idle_toggled(pressed: bool) -> void:
	if _settings == null:
		return
	_settings.idle_reset = pressed
	_idle_spin.editable = pressed
	_emit_changed()


func _on_idle_seconds_changed(value: float) -> void:
	if _settings == null:
		return
	_settings.idle_reset_seconds = value
	_emit_changed()


func _emit_changed() -> void:
	_settings.save_to_disk()
	settings_changed.emit(_settings)
