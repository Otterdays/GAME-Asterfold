extends Control

## Title creation: name plus the looks the layered kit can actually honour.

signal cancel_requested
signal created(display_name: String, appearance: CharacterAppearance)

@onready var _built: bool = false

var _roster: CharacterRoster
var _compositor: SpriteLayerCompositor
var _kit: ActorLayerKit
var _appearance: CharacterAppearance = CharacterAppearance.starter()
var _reduced_motion: bool = false
var _busy: bool = false
var _preview: CharacterPreview
var _name_edit: LineEdit
var _status: Label
var _create_button: Button
var _cancel_button: Button
var _walk_button: Button
var _turn_left: Button
var _turn_right: Button
var _option_value_labels: Dictionary[StringName, Label] = {}
var _option_prev: Dictionary[StringName, Button] = {}
var _option_next: Dictionary[StringName, Button] = {}


func configure(roster: CharacterRoster, compositor: SpriteLayerCompositor, kit: ActorLayerKit) -> void:
	_roster = roster
	_compositor = compositor
	_kit = kit
	_ensure_built()
	reset_draft()


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	if _preview != null:
		_preview.set_animate(not reduced)
		if reduced:
			_preview.set_moving(false)
			if _walk_button != null:
				_walk_button.button_pressed = false


func set_busy(busy: bool, reason: String = "") -> void:
	_busy = busy
	_apply_interactive_state(reason)


func show_screen() -> void:
	_ensure_built()
	reset_draft()
	visible = true
	_name_edit.call_deferred(&"grab_focus")


func hide_screen() -> void:
	visible = false


func reset_draft() -> void:
	_ensure_built()
	_appearance = CharacterAppearance.starter()
	var taken: PackedStringArray = _roster.taken_names() if _roster != null else PackedStringArray()
	_name_edit.text = AppearanceCatalog.unique_default_name(taken)
	_preview.configure(_compositor, _kit)
	_preview.set_appearance(_appearance)
	_preview.set_direction(SpriteDirectionResolver.Direction.SOUTH)
	_preview.set_moving(false)
	_preview.set_animate(not _reduced_motion)
	if _walk_button != null:
		_walk_button.button_pressed = false
	_refresh_options()
	_validate()


func _ready() -> void:
	_ensure_built()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy:
		return
	if event.is_action_pressed(&"cancel"):
		cancel_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"fold_left"):
		_preview.turn(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"fold_right"):
		_preview.turn(1)
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
	var root := VBoxContainer.new()
	root.add_theme_constant_override(&"separation", 14)
	root.custom_minimum_size = Vector2(1080, 0)
	plate.add_child(_padded(root, 22))
	var heading := Label.new()
	heading.text = "Create adventurer"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override(&"font_size", 32)
	heading.add_theme_color_override(&"font_color", Color(0.96, 0.97, 0.90))
	root.add_child(heading)
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 28)
	root.add_child(body)
	body.add_child(_make_preview_column())
	body.add_child(_make_form_column())
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override(&"font_size", 16)
	root.add_child(_status)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override(&"separation", 18)
	root.add_child(footer)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.custom_minimum_size = Vector2(200, 42)
	_cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	footer.add_child(_cancel_button)
	_create_button = Button.new()
	_create_button.text = "Create adventurer"
	_create_button.custom_minimum_size = Vector2(260, 42)
	_create_button.pressed.connect(_on_create_pressed)
	footer.add_child(_create_button)


func _make_preview_column() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	column.custom_minimum_size = Vector2(320, 0)
	var caption := Label.new()
	caption.text = "Preview"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	_preview = CharacterPreview.new()
	_preview.custom_minimum_size = Vector2(288, 384)
	column.add_child(_preview)
	var turn_row := HBoxContainer.new()
	turn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	turn_row.add_theme_constant_override(&"separation", 12)
	column.add_child(turn_row)
	_turn_left = Button.new()
	_turn_left.text = "Turn left"
	_turn_left.pressed.connect(func() -> void: _preview.turn(-1))
	turn_row.add_child(_turn_left)
	_turn_right = Button.new()
	_turn_right.text = "Turn right"
	_turn_right.pressed.connect(func() -> void: _preview.turn(1))
	turn_row.add_child(_turn_right)
	_walk_button = Button.new()
	_walk_button.text = "Preview walk"
	_walk_button.toggle_mode = true
	_walk_button.toggled.connect(_on_walk_toggled)
	column.add_child(_walk_button)
	var hint := Label.new()
	hint.text = "Q / E also turns the preview."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override(&"font_size", 14)
	column.add_child(hint)
	return column


func _make_form_column() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 12)
	var name_label := Label.new()
	name_label.text = "Name"
	column.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.max_length = AppearanceCatalog.NAME_MAX
	_name_edit.placeholder_text = AppearanceCatalog.DEFAULT_DISPLAY_NAME
	_name_edit.caret_blink = true
	_name_edit.text_changed.connect(func(_value: String) -> void: _validate())
	column.add_child(_name_edit)
	var looks := Label.new()
	looks.text = "Looks"
	looks.add_theme_font_size_override(&"font_size", 22)
	column.add_child(looks)
	for channel_id: StringName in AppearanceCatalog.CHANNEL_ORDER:
		column.add_child(_make_option_row(channel_id))
	var note := Label.new()
	note.text = "Starter clothes are a brown t-shirt, blue jeans, and tan boots. Callings and extra costumes are not in this build."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override(&"font_size", 14)
	column.add_child(note)
	return column


func _make_option_row(channel_id: StringName) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	var label := Label.new()
	label.text = AppearanceCatalog.channel_label(channel_id)
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	var prev := Button.new()
	prev.text = "<"
	prev.custom_minimum_size = Vector2(44, 36)
	prev.pressed.connect(_on_cycle_pressed.bind(channel_id, -1))
	row.add_child(prev)
	_option_prev[channel_id] = prev
	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.custom_minimum_size = Vector2(180, 0)
	row.add_child(value)
	_option_value_labels[channel_id] = value
	var next := Button.new()
	next.text = ">"
	next.custom_minimum_size = Vector2(44, 36)
	next.pressed.connect(_on_cycle_pressed.bind(channel_id, 1))
	row.add_child(next)
	_option_next[channel_id] = next
	return row


func _on_cycle_pressed(channel_id: StringName, step: int) -> void:
	_appearance.cycle_channel(channel_id, step)
	_preview.set_appearance(_appearance)
	_refresh_options()


func _on_walk_toggled(pressed: bool) -> void:
	if _reduced_motion:
		_preview.set_moving(false)
		_walk_button.button_pressed = false
		_status.text = "Walk preview is still while camera motion is reduced."
		return
	_preview.set_moving(pressed)
	_walk_button.text = "Preview idle" if pressed else "Preview walk"


func _refresh_options() -> void:
	for channel_id: StringName in AppearanceCatalog.CHANNEL_ORDER:
		var option_id: StringName = _appearance.option_for_channel(channel_id)
		_option_value_labels[channel_id].text = AppearanceCatalog.option_label(option_id)


func _validate() -> Array[String]:
	var taken: PackedStringArray = _roster.taken_names() if _roster != null else PackedStringArray()
	var errors: Array[String] = AppearanceCatalog.validate_display_name(_name_edit.text, taken)
	errors.append_array(_appearance.validate())
	if _roster != null and _roster.first_empty_unlocked_slot() < 0:
		errors.append("No writable character slot is free.")
	_create_button.disabled = _busy or not errors.is_empty()
	if errors.is_empty():
		_status.text = "Ready. Confirm creates this adventurer in the open slot."
		_create_button.tooltip_text = "Save this adventurer to the open roster slot."
	else:
		_status.text = errors[0]
		_create_button.tooltip_text = errors[0]
	_apply_interactive_state("")
	return errors


func _on_create_pressed() -> void:
	if _busy:
		return
	var errors: Array[String] = _validate()
	if not errors.is_empty():
		return
	created.emit(_name_edit.text.strip_edges(), _appearance.duplicate_look())


func _apply_interactive_state(reason: String) -> void:
	if _cancel_button == null:
		return
	_cancel_button.disabled = _busy
	_name_edit.editable = not _busy
	_walk_button.disabled = _busy
	_turn_left.disabled = _busy
	_turn_right.disabled = _busy
	for channel_id: StringName in AppearanceCatalog.CHANNEL_ORDER:
		_option_prev[channel_id].disabled = _busy
		_option_next[channel_id].disabled = _busy
	if _busy:
		_create_button.disabled = true
		_status.text = reason
		_create_button.tooltip_text = reason
		_cancel_button.tooltip_text = reason
	else:
		_cancel_button.tooltip_text = "Return to character select without saving."


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
	style.bg_color = Color(0.05, 0.08, 0.07, 0.88)
	style.border_color = Color(0.78, 0.86, 0.72, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
