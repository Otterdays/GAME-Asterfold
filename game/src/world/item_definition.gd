class_name ItemDefinition
extends Resource

## Immutable equipment definition. Runtime ownership lives in `PartyInventory`.

enum DrawMode {
	## Repaints the covered body layers, as a coat or boot replaces skin.
	REPLACE,
	## Adds an accent on top of whatever already paints the covered layers.
	OVERLAY,
}

@export var id: StringName = &""
## Localization key. Display text is never authored directly into gameplay UI.
@export var display_name_key: String = ""
## Development-only fallback shown until a localization table exists.
@export var fallback_name: String = ""
@export var slot: StringName = &""
@export var draw_mode: DrawMode = DrawMode.REPLACE
## Graybox presentation colour. Production art replaces this with authored layers.
@export var graybox_color: Color = Color(0.8, 0.8, 0.8, 1.0)
@export var two_handed: bool = false
## Empty means every Calling may equip it. Callings are not implemented yet.
@export var calling_ids: Array[StringName] = []


func covered_layers() -> Array[StringName]:
	return EquipmentSlotCatalog.covered_layers(slot)


func display_name() -> String:
	return fallback_name if not fallback_name.is_empty() else String(id)


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	var pattern: RegEx = RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	if pattern.search(String(id)) == null:
		errors.append("Item ID '%s' is not a namespaced stable ID." % id)
	if not String(id).begins_with("item."):
		errors.append("Item ID '%s' must live in the 'item' namespace." % id)
	if display_name_key.strip_edges().is_empty():
		errors.append("Item '%s' is missing a localization key." % id)
	if fallback_name.strip_edges().is_empty():
		errors.append("Item '%s' is missing development display text." % id)
	if not EquipmentSlotCatalog.has_slot(slot):
		errors.append("Item '%s' references unknown slot '%s'." % [id, slot])
	if two_handed and slot != EquipmentSlotCatalog.SLOT_MAIN_HAND:
		errors.append("Item '%s' can only be two-handed in the main hand." % id)
	if graybox_color.a <= 0.0:
		errors.append("Item '%s' needs a visible graybox colour." % id)
	return errors
