class_name MapMakerPalette
extends PanelContainer

signal family_selected(family: StringName)
signal piece_selected(piece_id: StringName)
signal road_selected(patch_index: int)
signal save_requested
signal settings_requested

const FAMILIES: Array[StringName] = [&"prop", &"building", &"tree", &"road"]
const FAMILY_LABELS: Dictionary = {
	&"prop": "Things",
	&"building": "Buildings",
	&"tree": "Trees",
	&"road": "Roads",
}

@onready var _family_row: HBoxContainer = %FamilyRow
@onready var _button_row: HBoxContainer = %ButtonRow
@onready var _status_label: Label = %StatusLabel
@onready var _help_label: Label = %HelpLabel

var _tooltip: MapMakerTooltip
var _catalog: WorldPieceCatalog
var _family_buttons: Dictionary[StringName, Button] = {}
var _piece_buttons: Dictionary[StringName, Button] = {}
var _active_family: StringName = &"prop"


func configure(catalog: WorldPieceCatalog, tooltip: MapMakerTooltip, road_count: int) -> void:
	_catalog = catalog
	_tooltip = tooltip
	_help_label.text = "Click ground to place. Right-click erase. R turns. Hover any button for more."
	_build_family_row()
	rebuild_items(road_count)


func set_family(family: StringName, road_count: int) -> void:
	_active_family = family
	for id: StringName in _family_buttons.keys():
		_family_buttons[id].set_pressed_no_signal(id == family)
	rebuild_items(road_count)
	family_selected.emit(family)


func rebuild_items(road_count: int) -> void:
	for child: Node in _button_row.get_children():
		_button_row.remove_child(child)
		child.free()
	_piece_buttons.clear()
	if _active_family == &"road":
		for index: int in road_count:
			var button: Button = _make_toggle("%d" % (index + 1))
			var patch_index: int = index
			button.pressed.connect(func() -> void: road_selected.emit(patch_index))
			_bind_tooltip(button, &"tooltip.mode.road")
			_button_row.add_child(button)
		_append_save_button()
		return
	if _catalog == null:
		return
	var shortcut_index: int = 1
	for piece: WorldPieceDefinition in _catalog.get_pieces_in_family(_active_family):
		var button: Button = _make_toggle("%d  %s" % [shortcut_index, piece.display_name])
		var piece_id: StringName = piece.id
		button.pressed.connect(func() -> void: select_piece(piece_id))
		_bind_tooltip(button, piece.tooltip_id)
		_button_row.add_child(button)
		_piece_buttons[piece_id] = button
		shortcut_index += 1
	_append_save_button()


func select_piece(piece_id: StringName) -> void:
	for id: StringName in _piece_buttons.keys():
		_piece_buttons[id].set_pressed_no_signal(id == piece_id)
	if _piece_buttons.has(piece_id):
		_piece_buttons[piece_id].grab_focus()
	piece_selected.emit(piece_id)


func set_status(text: String) -> void:
	_status_label.text = text


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
		button.pressed.connect(func() -> void: set_family(selected_family, _road_count_hint()))
		_bind_tooltip(button, StringName("tooltip.mode.%s" % String(family)))
		_family_row.add_child(button)
		_family_buttons[family] = button
	if _family_buttons.has(&"prop"):
		_family_buttons[&"prop"].set_pressed_no_signal(true)


func _append_save_button() -> void:
	var save_button: Button = Button.new()
	save_button.text = "Save"
	save_button.focus_mode = Control.FOCUS_ALL
	save_button.pressed.connect(func() -> void: save_requested.emit())
	_bind_tooltip(save_button, &"tooltip.action.save")
	_button_row.add_child(save_button)
	var settings_button: Button = Button.new()
	settings_button.text = "Settings"
	settings_button.focus_mode = Control.FOCUS_ALL
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_button_row.add_child(settings_button)


func _make_toggle(label: String) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	return button


func _bind_tooltip(control: Control, tooltip_id: StringName) -> void:
	if _tooltip != null and tooltip_id != &"":
		_tooltip.bind_control(control, tooltip_id)


func _road_count_hint() -> int:
	return 6
