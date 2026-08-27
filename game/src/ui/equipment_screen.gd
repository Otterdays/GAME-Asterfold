extends Control

## Field equipment overlay. Sends equip intent; it never mutates presentation truth.

signal closed

const EMPTY_LABEL: String = "Empty"
const BLOCKED_LABEL: String = "Blocked by two-handed main hand"

@onready var _doll_texture: TextureRect = %DollTexture
@onready var _doll_highlight: TextureRect = %DollHighlight
@onready var _doll_notice: Label = %DollNotice
@onready var _slot_list: VBoxContainer = %SlotList
@onready var _bag_panel: PanelContainer = %BagPanel
@onready var _bag_heading: Label = %BagHeading
@onready var _bag_list: VBoxContainer = %BagList

var _inventory: PartyInventory
var _compositor: SpriteLayerCompositor
var _appearance: CharacterAppearance = CharacterAppearance.starter()
var _slot_buttons: Dictionary[StringName, Button] = {}
var _picker_slot: StringName = &""
var _focus_restore: Button


func _ready() -> void:
	_build_slot_rows()
	_bag_panel.visible = false


func configure(
	inventory: PartyInventory,
	compositor: SpriteLayerCompositor,
	appearance: CharacterAppearance = null
) -> void:
	if _inventory != null and _inventory.loadout_changed.is_connected(_refresh):
		_inventory.loadout_changed.disconnect(_refresh)
	_inventory = inventory
	_compositor = compositor
	if appearance != null:
		_appearance = appearance
	if _inventory != null:
		_inventory.loadout_changed.connect(_refresh)
	_refresh()


func show_screen() -> void:
	visible = true
	_close_picker()
	_refresh()
	var first_slot: StringName = EquipmentSlotCatalog.SLOT_ORDER[0]
	if _slot_buttons.has(first_slot):
		_slot_buttons[first_slot].call_deferred(&"grab_focus")


func hide_screen() -> void:
	_close_picker()
	visible = false


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"cancel"):
		if _bag_panel.visible:
			_close_picker()
		else:
			_request_close()
		get_viewport().set_input_as_handled()


func _request_close() -> void:
	hide_screen()
	closed.emit()


func _build_slot_rows() -> void:
	for slot_id: StringName in EquipmentSlotCatalog.SLOT_ORDER:
		var row: Button = Button.new()
		row.custom_minimum_size = Vector2(320.0, 30.0)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.text = EquipmentSlotCatalog.label(slot_id)
		row.pressed.connect(_on_slot_pressed.bind(slot_id))
		row.focus_entered.connect(_on_slot_focused.bind(slot_id))
		_slot_list.add_child(row)
		_slot_buttons[slot_id] = row


func _refresh() -> void:
	for slot_id: StringName in _slot_buttons:
		_slot_buttons[slot_id].text = _slot_row_text(slot_id)
	_refresh_doll()
	if _bag_panel.visible:
		_populate_picker(_picker_slot)


func _slot_row_text(slot_id: StringName) -> String:
	var label: String = EquipmentSlotCatalog.label(slot_id)
	if _inventory == null:
		return "%s  —  %s" % [label, EMPTY_LABEL]
	var loadout: EquipmentLoadout = _inventory.get_loadout()
	if loadout.is_blocked(slot_id):
		return "%s  —  %s" % [label, BLOCKED_LABEL]
	var definition: ItemDefinition = _inventory.definition_for_instance(loadout.occupant(slot_id))
	if definition == null:
		return "%s  —  %s" % [label, EMPTY_LABEL]
	return "%s  —  %s" % [label, definition.display_name()]


func _refresh_doll() -> void:
	var available: bool = _compositor != null and _compositor.is_ready() and _inventory != null
	_doll_texture.visible = available
	_doll_highlight.visible = available
	_doll_notice.visible = not available
	if not available:
		return
	_doll_texture.texture = _compositor.compose_doll(_inventory.equipped_definitions(), _appearance)


func _on_slot_focused(slot_id: StringName) -> void:
	if _compositor == null or not _compositor.is_ready():
		return
	_doll_highlight.texture = _compositor.compose_doll_highlight(
		EquipmentSlotCatalog.covered_layers(slot_id)
	)


func _on_slot_pressed(slot_id: StringName) -> void:
	if _inventory == null:
		return
	if _inventory.get_loadout().is_blocked(slot_id):
		return
	_focus_restore = _slot_buttons.get(slot_id) as Button
	_populate_picker(slot_id)


func _populate_picker(slot_id: StringName) -> void:
	_picker_slot = slot_id
	for child: Node in _bag_list.get_children():
		child.queue_free()
	_bag_heading.text = "%s  —  choose equipment" % EquipmentSlotCatalog.label(slot_id)
	_bag_panel.visible = true
	var loadout: EquipmentLoadout = _inventory.get_loadout()
	var first_choice: Button
	if loadout.is_occupied(slot_id):
		var unequip: Button = _make_choice_button("Remove current equipment")
		unequip.pressed.connect(_on_unequip_pressed.bind(slot_id))
		first_choice = unequip
	for instance_id: StringName in _inventory.bag_instances_for_slot(slot_id):
		var definition: ItemDefinition = _inventory.definition_for_instance(instance_id)
		if definition == null:
			continue
		var suffix: String = "  (two-handed)" if definition.two_handed else ""
		var choice: Button = _make_choice_button("%s%s" % [definition.display_name(), suffix])
		choice.pressed.connect(_on_equip_pressed.bind(instance_id))
		if first_choice == null:
			first_choice = choice
	if first_choice == null:
		var notice: Button = _make_choice_button("No equipment available for this slot")
		notice.disabled = true
		notice.tooltip_text = "The party bag holds nothing for this slot."
		first_choice = notice
	first_choice.call_deferred(&"grab_focus")


func _make_choice_button(text: String) -> Button:
	var choice: Button = Button.new()
	choice.custom_minimum_size = Vector2(300.0, 30.0)
	choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
	choice.text = text
	_bag_list.add_child(choice)
	return choice


func _on_equip_pressed(instance_id: StringName) -> void:
	if _inventory != null:
		_inventory.equip(instance_id)
	_close_picker()


func _on_unequip_pressed(slot_id: StringName) -> void:
	if _inventory != null:
		_inventory.unequip(slot_id)
	_close_picker()


func _close_picker() -> void:
	_bag_panel.visible = false
	_picker_slot = &""
	for child: Node in _bag_list.get_children():
		child.queue_free()
	if _focus_restore != null and _focus_restore.is_inside_tree():
		_focus_restore.call_deferred(&"grab_focus")
	_focus_restore = null
