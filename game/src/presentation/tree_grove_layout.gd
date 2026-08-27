class_name TreeGroveLayout
extends Resource

## Authored placement data for one zone's trees. Parallel packed arrays keep the
## resource diffable and let the same rows drive hero instances and batched belts.

const GRID_SNAP_M: float = 0.5
const MIN_TRUNK_GAP_M: float = 0.25

@export var species: Array[TreeDefinition] = []
@export var species_ids: Array[StringName] = []
@export var positions_xz: PackedVector2Array = PackedVector2Array()
@export var yaw_degrees: PackedFloat32Array = PackedFloat32Array()
@export var uniform_scales: PackedFloat32Array = PackedFloat32Array()
@export var variant_seeds: PackedInt32Array = PackedInt32Array()
## 1 marks a hero specimen built as a full body; 0 marks a batched belt instance.
@export var hero_flags: PackedByteArray = PackedByteArray()
@export var ground_size_m: Vector2 = Vector2(68.0, 58.0)
## Route the grove must not intrude on, so streets keep their authored clear width.
@export var road_layout: DirtRoadLayout
@export_range(0.0, 4.0, 0.05) var road_shoulder_m: float = 1.0
@export_range(1, 32, 1) var max_hero_instances: int = 8
@export_range(1, 256, 1) var max_batched_instances: int = 64


func get_placement_count() -> int:
	return species_ids.size()


func is_hero(index: int) -> bool:
	return index < hero_flags.size() and hero_flags[index] != 0


func get_definition(species_id: StringName) -> TreeDefinition:
	for definition: TreeDefinition in species:
		if definition != null and definition.id == species_id:
			return definition
	return null


func get_definition_at(index: int) -> TreeDefinition:
	if index < 0 or index >= species_ids.size():
		return null
	return get_definition(species_ids[index])


func get_hero_count() -> int:
	var count: int = 0
	for index: int in get_placement_count():
		if is_hero(index):
			count += 1
	return count


func get_batched_count() -> int:
	return get_placement_count() - get_hero_count()


func get_placement_transform(index: int) -> Transform3D:
	var scale_value: float = uniform_scales[index] if index < uniform_scales.size() else 1.0
	var yaw_value: float = yaw_degrees[index] if index < yaw_degrees.size() else 0.0
	var position: Vector2 = positions_xz[index]
	var basis: Basis = Basis(Vector3.UP, deg_to_rad(yaw_value)).scaled(Vector3.ONE * scale_value)
	return Transform3D(basis, Vector3(position.x, 0.0, position.y))


## Signed distance from a point to the authored road surface. Negative values are on the road.
func distance_to_road_m(point: Vector2) -> float:
	if road_layout == null:
		return INF
	return road_layout.signed_distance_m(point)


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	if species.is_empty():
		errors.append("Tree grove requires at least one species definition.")
	var declared_ids: Dictionary[StringName, bool] = {}
	for definition: TreeDefinition in species:
		if definition == null:
			errors.append("Tree grove contains an empty species entry.")
			continue
		errors.append_array(definition.validate_definition())
		if declared_ids.has(definition.id):
			errors.append("Tree grove declares duplicate species '%s'." % definition.id)
		declared_ids[definition.id] = true

	var placement_count: int = species_ids.size()
	if placement_count == 0:
		errors.append("Tree grove requires at least one placement.")
	var rows_aligned: bool = true
	for array_name: String in ["positions_xz", "yaw_degrees", "uniform_scales", "variant_seeds", "hero_flags"]:
		var array_value: Variant = get(array_name)
		var array_size: int = int(array_value.size())
		if array_size != placement_count:
			rows_aligned = false
			errors.append(
				"Tree grove '%s' has %d rows but %d placements are declared." % [
					array_name,
					array_size,
					placement_count,
				]
			)
	# Per-placement checks index every parallel array, so misaligned rows stop here.
	if not rows_aligned:
		return errors

	if get_hero_count() > max_hero_instances:
		errors.append(
			"Tree grove uses %d hero specimens; the zone budget allows %d." % [
				get_hero_count(),
				max_hero_instances,
			]
		)
	if get_batched_count() > max_batched_instances:
		errors.append(
			"Tree grove uses %d batched instances; the zone budget allows %d." % [
				get_batched_count(),
				max_batched_instances,
			]
		)

	var ground_half_size: Vector2 = ground_size_m * 0.5
	for index: int in placement_count:
		var species_id: StringName = species_ids[index]
		var definition: TreeDefinition = get_definition(species_id)
		if definition == null:
			errors.append("Tree placement %d references unknown species '%s'." % [index, species_id])
			continue
		var position: Vector2 = positions_xz[index]
		var scale_value: float = uniform_scales[index]
		var trunk_radius: float = definition.trunk_base_radius_m * scale_value
		if not _is_snapped(position.x) or not _is_snapped(position.y):
			errors.append("Tree placement %d at %s is off the %.1f m logical grid." % [index, position, GRID_SNAP_M])
		if not definition.allows_scale(scale_value):
			errors.append(
				"Tree placement %d scale %.2f is outside the '%s' range %s." % [
					index,
					scale_value,
					species_id,
					definition.scale_range,
				]
			)
		if definition.yaw_snap_degrees > 0:
			var yaw_value: float = yaw_degrees[index]
			if not is_zero_approx(fposmod(yaw_value, float(definition.yaw_snap_degrees))):
				errors.append(
					"Tree placement %d yaw %.1f does not follow the %d degree species snap." % [
						index,
						yaw_value,
						definition.yaw_snap_degrees,
					]
				)
		if absf(position.x) + trunk_radius > ground_half_size.x or absf(position.y) + trunk_radius > ground_half_size.y:
			errors.append("Tree placement %d stands outside the authored ground surface." % index)
		var road_distance: float = distance_to_road_m(position)
		if not is_inf(road_distance) and road_distance - trunk_radius < road_shoulder_m:
			errors.append(
				"Tree placement %d leaves only %.2f m of road shoulder; %.2f m is required." % [
					index,
					road_distance - trunk_radius,
					road_shoulder_m,
				]
			)
		for other_index: int in range(index + 1, placement_count):
			var other_definition: TreeDefinition = get_definition(species_ids[other_index])
			if other_definition == null:
				continue
			var other_radius: float = other_definition.trunk_base_radius_m * uniform_scales[other_index]
			var required_gap: float = trunk_radius + other_radius + MIN_TRUNK_GAP_M
			if position.distance_to(positions_xz[other_index]) < required_gap:
				errors.append(
					"Tree placements %d and %d are closer than the %.2f m trunk gap." % [
						index,
						other_index,
						required_gap,
					]
				)
	return errors


func _is_snapped(value: float) -> bool:
	return is_zero_approx(fposmod(value, GRID_SNAP_M))
