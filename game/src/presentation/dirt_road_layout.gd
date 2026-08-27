class_name DirtRoadLayout
extends Resource

const MAX_PATCHES: int = 16
const MIN_PATCH_SIZE_M: float = 0.25
const MIN_CORNER_RADIUS_M: float = 0.05

## Each patch stores center X/Z and half-width/half-depth in meters.
@export var patches: Array[Vector4] = []
@export var corner_radii_m: PackedFloat32Array = PackedFloat32Array()
@export var network_size_m: Vector2 = Vector2(1.0, 1.0)
@export_range(0.05, 2.0, 0.05) var join_softness_m: float = 0.55


func set_patch_center(index: int, center_xz: Vector2) -> bool:
	if index < 0 or index >= patches.size():
		return false
	var patch: Vector4 = patches[index]
	var half_size: Vector2 = Vector2(patch.z, patch.w)
	var network_half_size: Vector2 = network_size_m * 0.5
	var clamped: Vector2 = Vector2(
		clampf(center_xz.x, -network_half_size.x + half_size.x, network_half_size.x - half_size.x),
		clampf(center_xz.y, -network_half_size.y + half_size.y, network_half_size.y - half_size.y)
	)
	patches[index] = Vector4(clamped.x, clamped.y, patch.z, patch.w)
	return true


## Signed distance from a world XZ point to the authored road surface.
## Negative values stand on the road; INF means no road is authored.
func signed_distance_m(point: Vector2) -> float:
	if patches.is_empty():
		return INF
	var distance: float = INF
	for index: int in patches.size():
		var radius: float = corner_radii_m[index] if index < corner_radii_m.size() else 0.0
		var patch_distance: float = DirtRoadNetwork3D.rounded_box_distance(point, patches[index], radius)
		if is_inf(distance):
			distance = patch_distance
		else:
			distance = DirtRoadNetwork3D.smooth_union_distance(distance, patch_distance, join_softness_m)
	return distance


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	if network_size_m.x <= 0.0 or network_size_m.y <= 0.0:
		errors.append("Road network size must be positive.")
	if patches.is_empty():
		errors.append("Road network requires at least one rounded patch.")
	if patches.size() > MAX_PATCHES:
		errors.append("Road network has %d patches; the shader supports at most %d." % [patches.size(), MAX_PATCHES])
	if corner_radii_m.size() != patches.size():
		errors.append("Road patch and corner-radius counts must match.")

	var network_half_size: Vector2 = network_size_m * 0.5
	for index: int in patches.size():
		var patch: Vector4 = patches[index]
		var center: Vector2 = Vector2(patch.x, patch.y)
		var half_size: Vector2 = Vector2(patch.z, patch.w)
		if half_size.x < MIN_PATCH_SIZE_M or half_size.y < MIN_PATCH_SIZE_M:
			errors.append("Road patch %d has a non-viable half-size %s." % [index, half_size])
		if absf(center.x) + half_size.x > network_half_size.x or absf(center.y) + half_size.y > network_half_size.y:
			errors.append("Road patch %d extends beyond the authored network bounds." % index)
		if index < corner_radii_m.size():
			var radius: float = corner_radii_m[index]
			if radius < MIN_CORNER_RADIUS_M or radius > minf(half_size.x, half_size.y):
				errors.append("Road patch %d corner radius %.2f is outside its half-size." % [index, radius])
	return errors
