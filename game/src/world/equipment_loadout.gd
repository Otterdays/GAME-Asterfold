class_name EquipmentLoadout
extends RefCounted

## Mutable runtime occupancy for the closed slot catalog.
##
## Stores item instance IDs only. Definitions stay immutable in `ItemCatalog`.

var _slots: Dictionary[StringName, StringName] = {}
var _two_handed_main: bool = false


func occupant(slot_id: StringName) -> StringName:
	return StringName(_slots.get(slot_id, &""))


func is_occupied(slot_id: StringName) -> bool:
	return not String(occupant(slot_id)).is_empty()


## A two-handed main hand keeps the off hand unavailable rather than silently full.
func is_blocked(slot_id: StringName) -> bool:
	return slot_id == EquipmentSlotCatalog.SLOT_OFF_HAND and _two_handed_main


func can_equip(slot_id: StringName) -> bool:
	if not EquipmentSlotCatalog.has_slot(slot_id):
		return false
	return not is_blocked(slot_id)


## Returns the instance IDs displaced by the new occupant, in removal order.
func set_occupant(slot_id: StringName, instance_id: StringName, two_handed: bool = false) -> Array[StringName]:
	var displaced: Array[StringName] = []
	if not can_equip(slot_id) or String(instance_id).is_empty():
		return displaced
	if is_occupied(slot_id):
		displaced.append(occupant(slot_id))
	_slots[slot_id] = instance_id
	if slot_id == EquipmentSlotCatalog.SLOT_MAIN_HAND:
		_two_handed_main = two_handed
		if two_handed and is_occupied(EquipmentSlotCatalog.SLOT_OFF_HAND):
			displaced.append(occupant(EquipmentSlotCatalog.SLOT_OFF_HAND))
			_slots.erase(EquipmentSlotCatalog.SLOT_OFF_HAND)
	return displaced


func clear_slot(slot_id: StringName) -> StringName:
	if not is_occupied(slot_id):
		return &""
	var removed: StringName = occupant(slot_id)
	_slots.erase(slot_id)
	if slot_id == EquipmentSlotCatalog.SLOT_MAIN_HAND:
		_two_handed_main = false
	return removed


func occupied_slots() -> Array[StringName]:
	var occupied: Array[StringName] = []
	for slot_id: StringName in EquipmentSlotCatalog.SLOT_ORDER:
		if is_occupied(slot_id):
			occupied.append(slot_id)
	return occupied


func clear() -> void:
	_slots.clear()
	_two_handed_main = false


func to_dictionary() -> Dictionary:
	var serialized: Dictionary = {}
	for slot_id: StringName in occupied_slots():
		serialized[String(slot_id)] = String(occupant(slot_id))
	return serialized


## Stable across sessions so the sprite compositor can cache composed sheets.
func content_hash() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for slot_id: StringName in occupied_slots():
		parts.append("%s=%s" % [slot_id, occupant(slot_id)])
	return "|".join(parts)
