class_name ItemCatalog
extends Resource

## Validated set of equipment definitions resolved through `ContentDB`.

@export var items: Array[ItemDefinition] = []
## Instances handed to the party when a field session starts.
@export var starter_item_ids: Array[StringName] = []


func has_item(item_id: StringName) -> bool:
	return get_item(item_id) != null


func get_item(item_id: StringName) -> ItemDefinition:
	for definition: ItemDefinition in items:
		if definition != null and definition.id == item_id:
			return definition
	return null


func items_for_slot(slot_id: StringName) -> Array[ItemDefinition]:
	var matches: Array[ItemDefinition] = []
	for definition: ItemDefinition in items:
		if definition != null and definition.slot == slot_id:
			matches.append(definition)
	return matches


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	if items.is_empty():
		errors.append("Item catalog must declare at least one item.")
	var seen_ids: Dictionary[StringName, bool] = {}
	for definition: ItemDefinition in items:
		if definition == null:
			errors.append("Item catalog contains an empty entry.")
			continue
		errors.append_array(definition.validate_definition())
		if seen_ids.has(definition.id):
			errors.append("Duplicate item ID '%s'." % definition.id)
		seen_ids[definition.id] = true
	for starter_id: StringName in starter_item_ids:
		if not seen_ids.has(starter_id):
			errors.append("Starter item '%s' is not present in the catalog." % starter_id)
	return errors
