class_name ZonePlacement
extends Resource

@export var piece_id: StringName = &""
@export var grid_x: int = 0
@export var grid_z: int = 0
@export_range(0, 3, 1) var yaw_quarter_turns: int = 0


func to_world_position(logical_grid_m: float) -> Vector3:
	return Vector3(float(grid_x) * logical_grid_m, 0.0, float(grid_z) * logical_grid_m)


func yaw_radians() -> float:
	return float(posmod(yaw_quarter_turns, 4)) * TAU * 0.25


static func snap_meters(meters: float, logical_grid_m: float) -> int:
	return roundi(meters / logical_grid_m)
