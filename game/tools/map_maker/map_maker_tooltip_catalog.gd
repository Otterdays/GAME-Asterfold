class_name MapMakerTooltipCatalog
extends Resource

@export var entries: Array[MapMakerTooltipEntry] = []


func get_entry(tooltip_id: StringName) -> MapMakerTooltipEntry:
	for entry: MapMakerTooltipEntry in entries:
		if entry != null and entry.id == tooltip_id:
			return entry
	return null


func format_text(tooltip_id: StringName) -> String:
	var entry: MapMakerTooltipEntry = get_entry(tooltip_id)
	if entry == null:
		return ""
	if entry.title.strip_edges().is_empty():
		return entry.body
	return "%s\n%s" % [entry.title, entry.body]


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	var ids: Dictionary[StringName, bool] = {}
	if entries.is_empty():
		errors.append("Map maker tooltip catalog must declare at least one entry.")
	for entry: MapMakerTooltipEntry in entries:
		if entry == null:
			errors.append("Map maker tooltip catalog contains an empty entry.")
			continue
		if String(entry.id).strip_edges().is_empty():
			errors.append("A map maker tooltip is missing its id.")
		if entry.body.strip_edges().is_empty():
			errors.append("Tooltip '%s' has no body text." % entry.id)
		if ids.has(entry.id):
			errors.append("Duplicate tooltip id '%s'." % entry.id)
		ids[entry.id] = true
	return errors
