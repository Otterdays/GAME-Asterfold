extends Node

const REGISTRY_PATH: String = "res://content/content_registry.tres"

var _zones: Dictionary[StringName, ZoneManifest] = {}
var _validation_errors: Array[String] = []


func _ready() -> void:
	reload_content()


func reload_content() -> Array[String]:
	_zones.clear()
	_validation_errors.clear()

	if not ResourceLoader.exists(REGISTRY_PATH, "ContentRegistry"):
		_validation_errors.append("Required content registry is missing: %s" % REGISTRY_PATH)
		return get_validation_errors()

	var registry: ContentRegistry = load(REGISTRY_PATH) as ContentRegistry
	if registry == null:
		_validation_errors.append("Content registry could not be loaded: %s" % REGISTRY_PATH)
		return get_validation_errors()

	for zone: ZoneManifest in registry.zones:
		if zone == null:
			_validation_errors.append("Content registry contains an empty zone entry.")
			continue
		_validation_errors.append_array(zone.validate_definition())
		if _zones.has(zone.id):
			_validation_errors.append("Duplicate content ID '%s'." % zone.id)
			continue
		_zones[zone.id] = zone

	return get_validation_errors()


func is_valid() -> bool:
	return _validation_errors.is_empty()


func get_validation_errors() -> Array[String]:
	return _validation_errors.duplicate()


func get_validation_summary() -> String:
	if _validation_errors.is_empty():
		return ""
	return "Content validation failed: %s" % " ".join(_validation_errors)


func get_zone(zone_id: StringName) -> ZoneManifest:
	return _zones.get(zone_id) as ZoneManifest
