class_name ZoneManifest
extends Resource

@export var id: StringName
@export var scene: PackedScene
@export var default_facet: StringName = &"north"
@export var allowed_facets: Array[StringName] = [&"north"]
@export var spawn_ids: Array[StringName] = []
@export var validation_bounds: AABB = AABB(Vector3(-32.0, -2.0, -28.0), Vector3(64.0, 24.0, 56.0))
@export_range(0.1, 2.0, 0.1) var logical_grid_m: float = 0.5
@export_range(0.0, 1000.0, 0.5) var primary_route_length_m: float = 0.0
@export_range(1, 8, 1) var depth_layer_count: int = 1
@export var landmark_ids: Array[StringName] = []
@export var foreground_occluder_ids: Array[StringName] = []


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	var id_pattern: RegEx = RegEx.new()
	id_pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	if id_pattern.search(String(id)) == null:
		errors.append("Zone ID '%s' is not a lowercase namespaced stable ID." % id)
	if scene == null:
		errors.append("Zone '%s' has no entry scene." % id)
	if allowed_facets.is_empty() or not allowed_facets.has(default_facet):
		errors.append("Zone '%s' default facet '%s' is not allowed." % [id, default_facet])
	if spawn_ids.is_empty():
		errors.append("Zone '%s' has no declared spawn IDs." % id)
	for spawn_id: StringName in spawn_ids:
		if id_pattern.search(String(spawn_id)) == null:
			errors.append("Zone '%s' has invalid spawn ID '%s'." % [id, spawn_id])
	if not is_equal_approx(logical_grid_m, 0.5):
		errors.append("Zone '%s' must use the 0.5 m logical grid." % id)
	if primary_route_length_m <= 0.0:
		errors.append("Zone '%s' has no primary route length metadata." % id)
	if depth_layer_count < 3:
		errors.append("Zone '%s' must declare at least three depth layers." % id)
	if landmark_ids.is_empty():
		errors.append("Zone '%s' has no declared landmark IDs." % id)
	return errors
