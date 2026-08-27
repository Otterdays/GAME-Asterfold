class_name SpriteSheetPlayback
extends RefCounted

## Shared idle/walk column math for the field sheet and title preview.
##
## Columns 0-3 are idle. Columns 4-11 are one walk cycle. Mirrored compass
## directions reuse the authored NE/E/SE rows.

const IDLE_FPS: float = 3.0
const WALK_FPS: float = 10.0
const IDLE_FRAME_COUNT: int = 4
const WALK_FRAME_COUNT: int = 8
const IDLE_START_COLUMN: int = 0
const WALK_START_COLUMN: int = 4


static func frame_column(moving: bool, animation_time: float) -> int:
	if moving:
		return WALK_START_COLUMN + int(floor(animation_time * WALK_FPS)) % WALK_FRAME_COUNT
	return IDLE_START_COLUMN + int(floor(animation_time * IDLE_FPS)) % IDLE_FRAME_COUNT


static func authored_row(direction: int) -> int:
	match direction:
		SpriteDirectionResolver.Direction.SOUTH_WEST:
			return SpriteDirectionResolver.Direction.SOUTH_EAST
		SpriteDirectionResolver.Direction.WEST:
			return SpriteDirectionResolver.Direction.EAST
		SpriteDirectionResolver.Direction.NORTH_WEST:
			return SpriteDirectionResolver.Direction.NORTH_EAST
		_:
			if direction > SpriteDirectionResolver.Direction.SOUTH:
				return SpriteDirectionResolver.Direction.SOUTH
			return direction


static func is_mirrored(direction: int) -> bool:
	return direction in [
		SpriteDirectionResolver.Direction.SOUTH_WEST,
		SpriteDirectionResolver.Direction.WEST,
		SpriteDirectionResolver.Direction.NORTH_WEST,
	]


static func turn(direction: int, step: int) -> int:
	return posmod(direction + step, SpriteDirectionResolver.DIRECTION_COUNT)
