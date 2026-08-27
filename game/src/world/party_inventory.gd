class_name PartyInventory
extends RefCounted

## Session-scoped bag plus equipped loadout for one actor.
##
## Nothing here is persisted yet. Campaign persistence waits for `SaveService`
## and the save envelope described in docs/TECHNICAL_ARCHITECTURE.md.

signal loadout_changed

var _catalog: ItemCatalog
var _definitions: Dictionary[StringName, StringName] = {}
var _bag: Array[StringName] = []
var _loadout: EquipmentLoadout = EquipmentLoadout.new()
var _next_instance_index: int = 1


static func create_from_catalog(catalog: ItemCatalog) -> PartyInventory:
	var inventory: PartyInventory = PartyInventory.new()
	inventory.configure(catalog)
	return inventory


func configure(catalog: ItemCatalog) -> void:
	_catalog = catalog
	_definitions.clear()
	_bag.clear()
	_loadout.clear()
	if _catalog == null:
		return
	for item_id: StringName in _catalog.starter_item_ids:
		add_item(item_id)


func get_catalog() -> ItemCatalog:
	return _catalog


func get_loadout() -> EquipmentLoadout:
	return _loadout


func add_item(item_id: StringName) -> StringName:
	if _catalog == null or not _catalog.has_item(item_id):
		return &""
	var instance_id: StringName = StringName("%s@%d" % [item_id, _next_instance_index])
	_next_instance_index += 1
	_definitions[instance_id] = item_id
	_bag.append(instance_id)
	return instance_id


func definition_for_instance(instance_id: StringName) -> ItemDefinition:
	if _catalog == null or not _definitions.has(instance_id):
		return null
	return _catalog.get_item(_definitions[instance_id])


func equip(instance_id: StringName) -> bool:
	var definition: ItemDefinition = definition_for_instance(instance_id)
	if definition == null or not _bag.has(instance_id):
		return false
	if not _loadout.can_equip(definition.slot):
		return false
	var displaced: Array[StringName] = _loadout.set_occupant(definition.slot, instance_id, definition.two_handed)
	if displaced.is_empty() and _loadout.occupant(definition.slot) != instance_id:
		return false
	_bag.erase(instance_id)
	for displaced_id: StringName in displaced:
		if not _bag.has(displaced_id):
			_bag.append(displaced_id)
	loadout_changed.emit()
	return true


func unequip(slot_id: StringName) -> bool:
	var removed: StringName = _loadout.clear_slot(slot_id)
	if String(removed).is_empty():
		return false
	if not _bag.has(removed):
		_bag.append(removed)
	loadout_changed.emit()
	return true


func bag_instances_for_slot(slot_id: StringName) -> Array[StringName]:
	var matches: Array[StringName] = []
	for instance_id: StringName in _bag:
		var definition: ItemDefinition = definition_for_instance(instance_id)
		if definition != null and definition.slot == slot_id:
			matches.append(instance_id)
	return matches


func bag_instances() -> Array[StringName]:
	return _bag.duplicate()


## Equipped definitions in slot presentation order, ready for the compositor.
func equipped_definitions() -> Array[ItemDefinition]:
	var definitions: Array[ItemDefinition] = []
	for slot_id: StringName in _loadout.occupied_slots():
		var definition: ItemDefinition = definition_for_instance(_loadout.occupant(slot_id))
		if definition != null:
			definitions.append(definition)
	return definitions
