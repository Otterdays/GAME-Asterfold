class_name BirdSpeciesDefinition
extends Resource

## Immutable description of one ambient bird species. Flight is presentation-only:
## birds never carry gameplay state, so a flock can be rebuilt or frozen at any time.
## Per-zone anchors and materials live on AmbientBirdFlock, not here.

const MIN_CRUISE_HEIGHT_M: float = 2.0

@export var id: StringName
@export var display_name_key: StringName = &""
@export_range(1, 24, 1) var flock_size: int = 7
@export_range(0.08, 1.2, 0.01) var wingspan_m: float = 0.34
## Meters per second along the circuit. Slow enough to read against the diorama.
@export_range(0.5, 12.0, 0.1) var cruise_speed_mps: float = 3.4
@export_range(1.0, 24.0, 0.5) var circuit_radius_min_m: float = 4.0
@export_range(1.0, 32.0, 0.5) var circuit_radius_max_m: float = 9.0
@export_range(2.0, 30.0, 0.5) var cruise_height_min_m: float = 6.0
@export_range(2.0, 40.0, 0.5) var cruise_height_max_m: float = 11.0
## Vertical bob amplitude and rate that keep a circuit from reading as a rail.
@export_range(0.0, 3.0, 0.05) var bob_amplitude_m: float = 0.55
@export_range(0.0, 3.0, 0.05) var bob_speed: float = 0.8
@export_group("Silhouette")
## Body length as a multiple of the half wingspan. Every shape value below is a ratio,
## so one baseline mesh builder covers every species and variants differ only by data.
@export_range(0.6, 3.0, 0.01) var body_length_ratio: float = 1.5
@export_range(0.05, 0.8, 0.01) var head_length_ratio: float = 0.26
@export_range(0.0, 0.6, 0.01) var beak_length_ratio: float = 0.12
@export_range(0.1, 1.5, 0.01) var tail_length_ratio: float = 0.55
## 0 gives a straight fan; 1 cuts the notch all the way back to the tail root.
@export_range(0.0, 1.0, 0.01) var tail_fork_ratio: float = 0.15
## How far the wingtip trails behind the shoulder, as a multiple of the half wingspan.
@export_range(-0.5, 1.2, 0.01) var wing_sweep_ratio: float = 0.32
## Wingtip chord relative to the wing root chord.
@export_range(0.15, 1.2, 0.01) var wing_taper: float = 0.55

@export_group("Motion")
@export_range(0.0, 12.0, 0.1) var flap_hz: float = 4.2
@export_range(0.0, 1.2, 0.01) var flap_amplitude: float = 0.55
## Roll into the turn, in degrees, so the silhouette stays lively from the town camera.
@export_range(0.0, 45.0, 1.0) var bank_degrees: float = 16.0


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	var id_pattern: RegEx = RegEx.new()
	id_pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	if id_pattern.search(String(id)) == null:
		errors.append("Bird ID '%s' is not a lowercase namespaced stable ID." % id)
	if circuit_radius_max_m < circuit_radius_min_m:
		errors.append("Bird '%s' circuit radius range must be ordered." % id)
	if cruise_height_max_m < cruise_height_min_m:
		errors.append("Bird '%s' cruise height range must be ordered." % id)
	if tail_fork_ratio >= 1.0:
		errors.append("Bird '%s' tail fork would split the tail into two loose points." % id)
	if wing_taper > 1.0 and wing_sweep_ratio < 0.0:
		errors.append("Bird '%s' cannot both widen and lead with its wingtip." % id)
	if cruise_height_min_m < MIN_CRUISE_HEIGHT_M:
		errors.append(
			"Bird '%s' cruises at %.2f m; %.2f m keeps it clear of walkable space." % [
				id,
				cruise_height_min_m,
				MIN_CRUISE_HEIGHT_M,
			]
		)
	return errors


func half_span_m() -> float:
	return wingspan_m * 0.5


## Seeded so a rebuilt flock reproduces the same circuit spread.
func circuit_radius_for(random: RandomNumberGenerator) -> float:
	return random.randf_range(circuit_radius_min_m, circuit_radius_max_m)


func cruise_height_for(random: RandomNumberGenerator) -> float:
	return random.randf_range(cruise_height_min_m, cruise_height_max_m)
