class_name SpriteDirectionResolver
extends RefCounted

enum Direction {
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST,
}

const DIRECTION_COUNT: int = 8
const SECTOR_RADIANS: float = TAU / float(DIRECTION_COUNT)


static func resolve(
	world_facing: Vector3,
	committed_yaw_radians: float,
	previous_direction: int = -1,
	hysteresis_degrees: float = 6.0
) -> int:
	var flat_facing: Vector3 = Vector3(world_facing.x, 0.0, world_facing.z)
	if flat_facing.length_squared() < 0.0001:
		return previous_direction if previous_direction >= 0 else Direction.SOUTH

	flat_facing = flat_facing.normalized()
	var camera_relative: Vector3 = Basis(Vector3.UP, -committed_yaw_radians) * flat_facing
	var angle: float = wrapf(atan2(camera_relative.x, -camera_relative.z), 0.0, TAU)

	if previous_direction >= 0:
		var previous_center: float = float(previous_direction) * SECTOR_RADIANS
		var distance_from_center: float = absf(wrapf(angle - previous_center, -PI, PI))
		var retention_limit: float = (SECTOR_RADIANS * 0.5) + deg_to_rad(hysteresis_degrees)
		if distance_from_center <= retention_limit:
			return previous_direction

	return int(floor((angle + SECTOR_RADIANS * 0.5) / SECTOR_RADIANS)) % DIRECTION_COUNT


static func label(direction: int) -> String:
	const LABELS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	return LABELS[posmod(direction, DIRECTION_COUNT)]

