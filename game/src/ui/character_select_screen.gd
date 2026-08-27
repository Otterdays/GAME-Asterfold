extends Control

## MapleStory-style roster: three portraits, one writable slot, two locked.

signal back_requested
signal create_requested
signal play_requested(slot_index: int)
signal delete_requested(slot_index: int)

const CARD_SIZE := Vector2(280, 420)
const PREVIEW_SIZE := Vector2(192, 256)

@onready var _built: bool = false

var _roster: CharacterRoster
var _compositor: SpriteLayerCompositor
var _kit: ActorLayerKit
var _reduced_motion: bool = false
var _busy: bool = false
var _status: Label
var _back_button: Button
var _slot_buttons: Array[Button] = []
var _previews: Array[CharacterPreview] = []
var _name_labels: Array[Label] = []
var _delete_buttons: Array[Button] = []
var _pending_delete: int = -1
var _confirm_panel: PanelContainer
var _confirm_label: Label
var _confirm_yes: Button
var _confirm_no: Button


func configure(roster: CharacterRoster, compositor: SpriteLayerCompositor, kit: ActorLayerKit) -> void:
	_roster = roster
	_compositor = compositor
	_kit = kit
	_ensure_built()
	refresh()


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	for preview: CharacterPreview in _previews:
		preview.set_animate(not reduced)
		preview.set_moving(false)


func set_busy(busy: bool, reason: String = "") -> void:
	_busy = busy
	_apply_interactive_state(reason)


func show_screen() -> void:
	_ensure_built()
	refresh()
	visible = true
	_focus_default()


func hide_screen() -> void:
	_close_confirm()
	visible = false


func refresh() -> void:
	_ensure_built()
	if _roster == null:
		return
	for index: int in CharacterRoster.SLOT_COUNT:
		_refresh_slot(index)
	_apply_interactive_state("")


func _ready() -> void:
	_ensure_built()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy:
		return
	if event.is_action_pressed(&"cancel"):
		if _confirm_panel.visible:
			_close_confirm()
		else:
			back_requested.emit()
		get_viewport().set_input_as_handled()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override(&"panel", _plate_style())
	center.add_child(plate)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 16)
	rows.custom_minimum_size = Vector2(980, 0)
	plate.add_child(_padded(rows, 24))
	var heading := Label.new()
	heading.text = "Choose an adventurer"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override(&"font_size", 32)
	heading.add_theme_color_override(&"font_color", Color(0.96, 0.97, 0.90))
	rows.add_child(heading)
	var hint := Label.new()
	hint.text = "One writable slot in this build. The other two wait for party companions."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override(&"font_size", 16)
	rows.add_child(hint)
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override(&"separation", 18)
	rows.add_child(cards)
	for index: int in CharacterRoster.SLOT_COUNT:
		cards.add_child(_make_slot_card(index))
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override(&"font_size", 16)
	_status.add_theme_color_override(&"font_color", Color(0.86, 0.90, 0.76))
	rows.add_child(_status)
	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.custom_minimum_size = Vector2(220, 40)
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	rows.add_child(_back_button)
	_confirm_panel = _make_confirm_panel()
	add_child(_confirm_panel)


func _make_slot_card(index: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override(&"panel", _card_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(_padded(column, 14))
	var caption := Label.new()
	caption.text = "Slot %d" % (index + 1)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	var preview := CharacterPreview.new()
	preview.custom_minimum_size = PREVIEW_SIZE
	preview.set_anchors_preset(Control.PRESET_CENTER)
	column.add_child(preview)
	_previews.append(preview)
	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override(&"font_size", 20)
	column.add_child(name_label)
	_name_labels.append(name_label)
	var action := Button.new()
	action.custom_minimum_size = Vector2(0, 40)
	action.pressed.connect(_on_slot_pressed.bind(index))
	action.focus_entered.connect(_on_slot_focused.bind(index))
	column.add_child(action)
	_slot_buttons.append(action)
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_on_delete_pressed.bind(index))
	column.add_child(delete_button)
	_delete_buttons.append(delete_button)
	return card


func _make_confirm_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_top = -110
	panel.offset_right = 280
	panel.offset_bottom = 110
	panel.add_theme_stylebox_override(&"panel", _plate_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	panel.add_child(_padded(column, 20))
	_confirm_label = Label.new()
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_confirm_label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 16)
	column.add_child(buttons)
	_confirm_no = Button.new()
	_confirm_no.text = "Keep adventurer"
	_confirm_no.pressed.connect(_close_confirm)
	buttons.add_child(_confirm_no)
	_confirm_yes = Button.new()
	_confirm_yes.text = "Delete"
	_confirm_yes.pressed.connect(_confirm_delete)
	buttons.add_child(_confirm_yes)
	return panel


func _refresh_slot(index: int) -> void:
	var locked: bool = _roster.is_locked(index)
	var record: CharacterRecord = _roster.get_record(index)
	var preview: CharacterPreview = _previews[index]
	preview.configure(_compositor, _kit)
	preview.set_animate(not _reduced_motion)
	preview.set_moving(false)
	preview.set_direction(SpriteDirectionResolver.Direction.SOUTH)
	if record != null:
		preview.set_appearance(record.appearance)
		_name_labels[index].text = record.display_name
		_slot_buttons[index].text = "Enter Brindlewick"
		_slot_buttons[index].tooltip_text = "Play as %s." % record.display_name
		_delete_buttons[index].visible = true
		_delete_buttons[index].tooltip_text = "Remove %s from this roster." % record.display_name
		preview.modulate = Color.WHITE
	elif locked:
		preview.set_appearance(CharacterAppearance.starter())
		_name_labels[index].text = "Locked"
		_slot_buttons[index].text = "Locked"
		_slot_buttons[index].tooltip_text = _roster.lock_reason(index)
		_delete_buttons[index].visible = false
		preview.modulate = Color(0.55, 0.55, 0.58, 1.0)
	else:
		preview.set_appearance(CharacterAppearance.starter())
		_name_labels[index].text = "Empty"
		_slot_buttons[index].text = "Create adventurer"
		_slot_buttons[index].tooltip_text = "Open character creation for this slot."
		_delete_buttons[index].visible = false
		preview.modulate = Color.WHITE


func _apply_interactive_state(reason: String) -> void:
	if _back_button == null:
		return
	_back_button.disabled = _busy
	_back_button.tooltip_text = reason if _busy else "Return to the title menu."
	for index: int in _slot_buttons.size():
		var locked: bool = _roster != null and _roster.is_locked(index)
		_slot_buttons[index].disabled = _busy or locked
		if _busy:
			_slot_buttons[index].tooltip_text = reason
		_delete_buttons[index].disabled = _busy
		if _busy:
			_delete_buttons[index].tooltip_text = reason
	if _busy:
		_status.text = reason
	elif _status.text.begins_with("Loading"):
		_status.text = ""


func _on_slot_pressed(index: int) -> void:
	if _busy or _roster == null:
		return
	if _roster.is_locked(index):
		_status.text = _roster.lock_reason(index)
		return
	if _roster.is_occupied(index):
		play_requested.emit(index)
		return
	create_requested.emit()


func _on_slot_focused(index: int) -> void:
	if _roster == null:
		return
	if _roster.is_locked(index):
		_status.text = _roster.lock_reason(index)
	elif _roster.is_occupied(index):
		_status.text = "Play as %s, or delete this adventurer." % _roster.get_record(index).display_name
	else:
		_status.text = "Create an adventurer in this slot."


func _on_delete_pressed(index: int) -> void:
	if _busy or _roster == null or not _roster.is_occupied(index):
		return
	_pending_delete = index
	_confirm_label.text = "Delete %s? This roster is local and cannot be undone." % _roster.get_record(index).display_name
	_confirm_panel.visible = true
	_confirm_no.call_deferred(&"grab_focus")


func _confirm_delete() -> void:
	var index: int = _pending_delete
	_close_confirm()
	if index >= 0:
		delete_requested.emit(index)


func _close_confirm() -> void:
	_pending_delete = -1
	if _confirm_panel != null:
		_confirm_panel.visible = false
	_focus_default()


func _focus_default() -> void:
	if _slot_buttons.is_empty():
		return
	var target: Button = _slot_buttons[0]
	for index: int in _slot_buttons.size():
		if not _slot_buttons[index].disabled:
			target = _slot_buttons[index]
			break
	target.call_deferred(&"grab_focus")


func _padded(child: Control, margin: int) -> MarginContainer:
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override(&"margin_left", margin)
	wrap.add_theme_constant_override(&"margin_top", margin)
	wrap.add_theme_constant_override(&"margin_right", margin)
	wrap.add_theme_constant_override(&"margin_bottom", margin)
	wrap.add_child(child)
	return wrap


func _plate_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.07, 0.86)
	style.border_color = Color(0.78, 0.86, 0.72, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.11, 0.10, 0.92)
	style.border_color = Color(0.42, 0.58, 0.54, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
