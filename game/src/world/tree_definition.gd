class_name TreeDefinition
extends Resource

## Immutable species description for a repeatable 3D tree body.
## Placement, scale, and variant selection live in TreeGroveLayout.

const MIN_WALK_UNDER_CLEARANCE_M: float = 2.25
const MAX_CROWN_MASSES: int = 4

@export var id: StringName
@export var display_name_key: StringName = &""
@export var trunk_material: ShaderMaterial
@export var crown_material: ShaderMaterial
@export_range(0.1, 1.5, 0.01) var trunk_base_radius_m: float = 0.36
@export_range(0.05, 1.5, 0.01) var trunk_top_radius_m: float = 0.26
@export_range(1.0, 9.0, 0.1) var trunk_height_m: float = 3.2
@export_range(0.5, 6.0, 0.1) var canopy_radius_m: float = 2.2
## Vertical clearance under the lowest crown mass. Walk-under species must exceed the door metric.
@export_range(0.0, 8.0, 0.05) var canopy_clearance_m: float = 2.4
@export var walk_under: bool = true
## Each mass stores a local offset (x, y, z) and its radius in meters.
@export var crown_masses: Array[Vector4] = [Vector4(0.0, 3.9, 0.0, 2.0)]
@export var crown_flatten: Vector3 = Vector3(1.0, 0.78, 1.0)
## Minimum and maximum authored uniform scale for placements of this species.
@export var scale_range: Vector2 = Vector2(0.9, 1.1)
@export_range(0, 90, 15) var yaw_snap_degrees: int = 15
@export_range(1, 8, 1) var variant_count: int = 3
## Crown fades when it blocks the camera. Only hero instances receive an occluder body.
@export var fade_crown: bool = false
@export_range(0.0, 2.0, 0.05) var root_flare_radius_m: float = 0.0
## Relative cost hint used to keep hero specimens away from the batched belt budget.
@export_range(1, 16, 1) var draw_budget_weight: int = 1


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	var id_pattern: RegEx = RegEx.new()
	id_pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	if id_pattern.search(String(id)) == null:
		errors.append("Tree ID '%s' is not a lowercase namespaced stable ID." % id)
	if trunk_material == null or trunk_material.shader == null:
		errors.append("Tree '%s' requires an external trunk shader material." % id)
	if crown_material == null or crown_material.shader == null:
		errors.append("Tree '%s' requires an external crown shader material." % id)
	if trunk_top_radius_m > trunk_base_radius_m:
		errors.append("Tree '%s' trunk must not widen toward its crown." % id)
	if trunk_base_radius_m >= canopy_radius_m:
		errors.append("Tree '%s' trunk radius must stay inside its canopy radius." % id)
	if crown_masses.is_empty() or crown_masses.size() > MAX_CROWN_MASSES:
		errors.append("Tree '%s' must define 1 to %d crown masses." % [id, MAX_CROWN_MASSES])
	for index: int in crown_masses.size():
		var mass: Vector4 = crown_masses[index]
		if mass.w <= 0.0:
			errors.append("Tree '%s' crown mass %d has a non-viable radius." % [id, index])
		if mass.y <= 0.0:
			errors.append("Tree '%s' crown mass %d must sit above the ground plane." % [id, index])
		if Vector2(mass.x, mass.z).length() + mass.w > canopy_radius_m + 0.5:
			errors.append("Tree '%s' crown mass %d exceeds its declared canopy radius." % [id, index])
	if walk_under and canopy_clearance_m < MIN_WALK_UNDER_CLEARANCE_M:
		errors.append(
			"Tree '%s' claims walk-under clearance but only offers %.2f m; %.2f m is required." % [
				id,
				canopy_clearance_m,
				MIN_WALK_UNDER_CLEARANCE_M,
			]
		)
	if walk_under and canopy_clearance_m > get_lowest_crown_underside_m():
		errors.append("Tree '%s' declares more clearance than its lowest crown mass allows." % id)
	if crown_flatten.x <= 0.0 or crown_flatten.y <= 0.0 or crown_flatten.z <= 0.0:
		errors.append("Tree '%s' crown flatten factors must be positive." % id)
	if scale_range.x <= 0.0 or scale_range.y < scale_range.x:
		errors.append("Tree '%s' scale range must be positive and ordered." % id)
	return errors


func get_lowest_crown_underside_m() -> float:
	var lowest: float = INF
	for mass: Vector4 in crown_masses:
		lowest = minf(lowest, mass.y - mass.w * crown_flatten.y)
	return 0.0 if is_inf(lowest) else lowest


func allows_scale(value: float) -> bool:
	return value >= scale_range.x - 0.001 and value <= scale_range.y + 0.001


func resolve_variant(seed_value: int) -> int:
	return absi(seed_value) % maxi(variant_count, 1)
