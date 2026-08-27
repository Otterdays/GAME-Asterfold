class_name MapMakerWorldCoverage
extends RefCounted

## Weights sum to 100. Rank is expected authoring leverage, not taste.
const SURFACES: Array[Dictionary] = [
	{"id": &"live_zone", "label": "Live zone scene", "weight": 20, "connected": true, "controlled": true},
	{"id": &"buildings", "label": "Buildings and bell", "weight": 25, "connected": true, "controlled": true},
	{"id": &"roads", "label": "Dirt-road patches", "weight": 18, "connected": true, "controlled": true},
	{"id": &"props", "label": "Dress props", "weight": 10, "connected": true, "controlled": true},
	{"id": &"trees", "label": "Trees", "weight": 8, "connected": true, "controlled": true},
	{"id": &"spawns", "label": "Spawn markers", "weight": 6, "connected": true, "controlled": false},
	{"id": &"grass", "label": "Grass ground", "weight": 5, "connected": true, "controlled": false},
	{"id": &"camera_volumes", "label": "Camera volumes", "weight": 3, "connected": true, "controlled": false},
	{"id": &"boundaries", "label": "Walk bounds", "weight": 3, "connected": true, "controlled": false},
	{"id": &"presentation", "label": "Lights and occluders", "weight": 2, "connected": true, "controlled": false},
]


static func connectivity_percent() -> int:
	return _weighted_percent("connected")


static func control_percent() -> int:
	return _weighted_percent("controlled")


static func ranked_next_routes() -> Array[Dictionary]:
	var remaining: Array[Dictionary] = []
	for surface: Dictionary in SURFACES:
		if bool(surface["controlled"]):
			continue
		remaining.append(surface)
	remaining.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left["weight"]) > int(right["weight"])
	)
	return remaining


static func beginner_status() -> String:
	return "World linked %d%%. You can edit %d%%. Next: %s." % [
		connectivity_percent(),
		control_percent(),
		String(ranked_next_routes()[0]["label"]) if not ranked_next_routes().is_empty() else "done",
	]


static func _weighted_percent(flag: String) -> int:
	var total: int = 0
	var earned: int = 0
	for surface: Dictionary in SURFACES:
		var weight: int = int(surface["weight"])
		total += weight
		if bool(surface[flag]):
			earned += weight
	if total <= 0:
		return 0
	return int(round(100.0 * float(earned) / float(total)))
