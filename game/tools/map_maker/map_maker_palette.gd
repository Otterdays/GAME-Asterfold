class_name MapMakerPalette
extends PanelContainer

signal family_selected(family: StringName)
signal piece_selected(piece_id: StringName)
signal road_selected(patch_index: int)
signal delete_mode_changed(enabled: bool)
signal save_requested
signal settings_requested

const FAMILIES: Array[StringName] = [&"prop", &"building", &"tree", &"nature", &"road"]
const FAMILY_LABELS: Dictionary = {
	&"prop": "Things",
	&"building": "Buildings",
	&"tree": "Trees",
	&"nature": "Nature",
	&"road": "Roads",
}
const HELP_TEXT: String = "Pick a piece, then click the ground. Click the same piece again to lift it. Right-click deletes, right-drag pans, wheel zooms. Q/E change family, 1-6 pick a piece, R turns, G shows the grid, Ctrl+Z undoes, Ctrl+S saves, F1 hides this help."

@onready var _family_row: HBoxContainer = %FamilyRow
@onready var _button_row: HBoxContainer = %ButtonRow
@onready var _status_label: Label = %StatusLabel
@onready var _help_label: Label = %HelpLabel

var _tooltip: MapMakerTooltip
var _catalog: WorldPieceCatalog
var _family_buttons: Dictionary[StringName, Button] = {}
var _piece_buttons: Dictionary[StringName, Button] = {}
var _road_buttons: Array[Button] = []
var _delete_button: Button
var _active_family: StringName = &"prop"
var _selected_piece_id: StringName = &""
var _delete_mode: bool = false
var _road_count: int = 0


func configure(catalog: WorldPieceCatalog, tooltip: MapMakerTooltip, road_count: int) -> void:
	_catalog = catalog
	_tooltip = tooltip
	_road_count = road_count
	theme = MapMakerTheme.build()
	_help_label.text = HELP_TEXT
	_help_label.add_theme_color_override(&"font_color", MapMakerTheme.MUTED_TEXT_COLOR)
	_build_family_row()
	rebuild_items(road_count)


func set_family(family: StringName, road_count: int) -> void:
	_active_family = family
	_road_count = road_count
	for id: StringName in _family_buttons.keys():
		_family_buttons[id].set_pressed_no_signal(id == family)
	rebuild_items(road_count)
	family_selected.emit(family)


func cycle_family(step: int) -> void:
	var index: int = FAMILIES.find(_active_family)
	if index < 0:
		index = 0
	set_family(FAMILIES[posmod(index + step, FAMILIES.size())], _road_count)


func rebuild_items(road_count: int) -> void:
	_road_count = road_count
	for child: Node in _button_row.get_children():
		_button_row.remove_child(child)
		child.free()
	_piece_buttons.clear()
	_road_buttons.clear()
	if _active_family == &"road":
		for index: int in road_count:
			var road_button: Button = _make_toggle("%d" % (index + 1))
			var patch_index: int = index
			road_button.toggled.connect(
				func(pressed: bool) -> void:
					if pressed:
						select_road(patch_index)
			)
			_bind_tooltip(road_button, &"tooltip.mode.road")
			_button_row.add_child(road_button)
			_road_buttons.append(road_button)
		_append_action_buttons()
		return
	if _catalog == null:
		return
	var shortcut_index: int = 1
	for piece: WorldPieceDefinition in _catalog.get_pieces_in_family(_active_family):
		var button: Button = _make_toggle("%d  %s" % [shortcut_index, piece.display_name])
		var piece_id: StringName = piece.id
		button.toggled.connect(
			func(pressed: bool) -> void:
				if pressed:
					select_piece(piece_id)
				elif _selected_piece_id == piece_id:
					clear_piece_selection()
		)
		_bind_tooltip(button, piece.tooltip_id)
		_button_row.add_child(button)
		_piece_buttons[piece_id] = button
		shortcut_index += 1
	_append_action_buttons()


func select_piece(piece_id: StringName) -> void:
	set_delete_mode(false)
	_selected_piece_id = piece_id
	for id: StringName in _piece_buttons.keys():
		_piece_buttons[id].set_pressed_no_signal(id == piece_id)
	if _piece_buttons.has(piece_id):
		_piece_buttons[piece_id].grab_focus()
	piece_selected.emit(piece_id)


func clear_piece_selection() -> void:
	_selected_piece_id = &""
	for id: StringName in _piece_buttons.keys():
		_piece_buttons[id].set_pressed_no_signal(false)
	piece_selected.emit(&"")


func select_road(patch_index: int) -> void:
	set_delete_mode(false)
	for index: int in _road_buttons.size():
		_road_buttons[index].set_pressed_no_signal(index == patch_index)
	road_selected.emit(patch_index)


func clear_selection() -> void:
	_selected_piece_id = &""
	for id: StringName in _piece_buttons.keys():
		_piece_buttons[id].set_pressed_no_signal(false)
	for button: Button in _road_buttons:
		button.set_pressed_no_signal(false)


func set_delete_mode(enabled: bool) -> void:
	if _delete_mode == enabled:
		if _delete_button != null:
			_delete_button.set_pressed_no_signal(enabled)
		return
	_delete_mode = enabled
	if _delete_button != null:
		_delete_button.set_pressed_no_signal(enabled)
	if enabled:
		clear_selection()
	delete_mode_changed.emit(enabled)


func is_delete_mode() -> bool:
	return _delete_mode


func set_status(text: String) -> void:
	_status_label.text = text


func toggle_help() -> bool:
	_help_label.visible = not _help_label.visible
	return _help_label.visible


func get_selected_piece_id() -> StringName:
	return _selected_piece_id


func get_active_family() -> StringName:
	return _active_family


func _build_family_row() -> void:
	for child: Node in _family_row.get_children():
		_family_row.remove_child(child)
		child.free()
	_family_buttons.clear()
	for family: StringName in FAMILIES:
		var button: Button = _make_toggle(String(FAMILY_LABELS[family]))
		var selected_family: StringName = family
		button.pressed.connect(func() -> void: set_family(selected_family, _road_count))
		_bind_tooltip(button, StringName("tooltip.mode.%s" % String(family)))
		_family_row.add_child(button)
		_family_buttons[family] = button
	if _family_buttons.has(&"prop"):
		_family_buttons[&"prop"].set_pressed_no_signal(true)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_family_row.add_child(spacer)
	_delete_button = _make_toggle("Delete")
	_delete_button.add_theme_stylebox_override(&"pressed", MapMakerTheme.filled_style(MapMakerTheme.DANGER_COLOR))
	_delete_button.add_theme_stylebox_override(
		&"hover_pressed",
		MapMakerTheme.filled_style(MapMakerTheme.DANGER_HOVER_COLOR)
	)
	_delete_button.toggled.connect(set_delete_mode)
	_bind_tooltip(_delete_button, &"tooltip.action.delete")
	_family_row.add_child(_delete_button)


func _append_action_buttons() -> void:
	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(16.0, 0.0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button_row.add_child(gap)
	var save_button: Button = _make_action("Save", 76.0)
	save_button.pressed.connect(func() -> void: save_requested.emit())
	_bind_tooltip(save_button, &"tooltip.action.save")
	_button_row.add_child(save_button)
	var settings_button: Button = _make_action("Settings", 100.0)
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_button_row.add_child(settings_button)


func _make_action(label: String, minimum_width: float) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.custom_minimum_size = Vector2(minimum_width, 36.0)
	return button


func _make_toggle(label: String) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.custom_minimum_size = Vector2(_label_width(label) + 24.0, 36.0)
	return button


func _bind_tooltip(control: Control, tooltip_id: StringName) -> void:
	if _tooltip != null and tooltip_id != &"":
		_tooltip.bind_control(control, tooltip_id)


func _label_width(label: String) -> float:
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	if font == null:
		return float(label.length() * 10)
	return font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
