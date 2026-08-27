extends TestCase

## Brindlewick nature ambience: one bird species on seeded circuits, grove leaf fall,
## and surface-aware footfall motes. Every check is presentation-only.

const NATURE_AMBIENCE_SCENE_PATH: String = "res://scenes/world/nature/brindlewick_nature_ambience.tscn"
const GROVE_LAYOUT_PATH: String = "res://content/zones/brindlewick_square/brindlewick_tree_grove_layout.tres"
const HEARTHFINCH_PATH: String = "res://content/wildlife/hearthfinch.tres"
const SLATE_SWIFT_PATH: String = "res://content/wildlife/slate_swift.tres"
const BIRD_ROOST_SCENE_PATH: String = "res://scenes/world/pieces/bird_roost.tscn"
const SWIFT_ROOST_SCENE_PATH: String = "res://scenes/world/pieces/swift_roost.tscn"
const LEAF_DRIFT_SCENE_PATH: String = "res://scenes/world/pieces/leaf_drift.tscn"


func suite_name() -> String:
	return "nature_ambience"


func run() -> void:
	_run_species_checks()
	_run_baseline_mesh_checks()
	await _run_runtime_checks()
	await _run_placeable_piece_checks()


func _run_species_checks() -> void:
	var species: BirdSpeciesDefinition = load(HEARTHFINCH_PATH) as BirdSpeciesDefinition
	_check(species != null, "Hearthfinch species definition loads.")
	if species == null:
		return
	_check(species.validate_definition().is_empty(), "Hearthfinch species definition validates.")
	_check(species.id == &"bird.brindlewick.hearthfinch", "Hearthfinch uses a namespaced stable ID.")
	_check(
		species.cruise_height_min_m >= BirdSpeciesDefinition.MIN_CRUISE_HEIGHT_M,
		"Hearthfinch cruises clear of walkable space."
	)

	var grounded: BirdSpeciesDefinition = BirdSpeciesDefinition.new()
	grounded.id = &"bird.test.grounded"
	grounded.cruise_height_min_m = 0.5
	grounded.cruise_height_max_m = 1.0
	_check(
		_errors_mention(grounded.validate_definition(), "keeps it clear of walkable space"),
		"A bird flying through head height is rejected."
	)

	var swift: BirdSpeciesDefinition = load(SLATE_SWIFT_PATH) as BirdSpeciesDefinition
	_check(swift != null, "Slate swift variant species loads.")
	if swift == null:
		return
	_check(swift.validate_definition().is_empty(), "Slate swift variant validates on the same contract.")
	_check(
		swift.tail_fork_ratio > species.tail_fork_ratio and swift.wing_sweep_ratio > species.wing_sweep_ratio,
		"The variant differs from the baseline by silhouette ratios, not by a new mesh."
	)


## The baseline body must be one builder driven by definition ratios, so a new species
## costs a resource and a palette rather than new geometry code.
func _run_baseline_mesh_checks() -> void:
	var species: BirdSpeciesDefinition = load(HEARTHFINCH_PATH) as BirdSpeciesDefinition
	var swift: BirdSpeciesDefinition = load(SLATE_SWIFT_PATH) as BirdSpeciesDefinition
	if species == null or swift == null:
		return
	var finch_mesh: ArrayMesh = AmbientBirdFlock.build_bird_mesh(species)
	var swift_mesh: ArrayMesh = AmbientBirdFlock.build_bird_mesh(swift)
	_check(finch_mesh.get_surface_count() == 1, "The bird body stays one surface for one draw.")
	var finch_arrays: Array = finch_mesh.surface_get_arrays(0)
	var swift_arrays: Array = swift_mesh.surface_get_arrays(0)
	var finch_vertices: PackedVector3Array = finch_arrays[Mesh.ARRAY_VERTEX]
	var swift_vertices: PackedVector3Array = swift_arrays[Mesh.ARRAY_VERTEX]
	var finch_uvs: PackedVector2Array = finch_arrays[Mesh.ARRAY_TEX_UV]
	_check(
		finch_vertices.size() == swift_vertices.size(),
		"Both species share the baseline vertex layout."
	)
	_check(finch_vertices.size() >= 36, "The baseline body carries head, beak, body, wings, and tail.")
	_check(finch_uvs.size() == finch_vertices.size(), "Every vertex carries its part tag.")

	var parts_present: Dictionary[float, bool] = {}
	var widest: float = 0.0
	for index: int in finch_uvs.size():
		parts_present[finch_uvs[index].x] = true
		widest = maxf(widest, absf(finch_vertices[index].x))
	for part: float in [
		AmbientBirdFlock.PART_BODY,
		AmbientBirdFlock.PART_HEAD,
		AmbientBirdFlock.PART_BEAK,
		AmbientBirdFlock.PART_WING,
		AmbientBirdFlock.PART_TAIL,
	]:
		_check(parts_present.has(part), "Baseline mesh tags part %d for recolouring." % int(part))
	_check(
		is_equal_approx(widest, species.half_span_m()),
		"Wingtips land exactly on the authored half span."
	)

	var finch_length: float = _mesh_length(finch_vertices)
	var swift_length: float = _mesh_length(swift_vertices)
	_check(not is_equal_approx(finch_length, swift_length), "Species ratios change the silhouette.")


func _mesh_length(vertices: PackedVector3Array) -> float:
	var nearest: float = INF
	var farthest: float = -INF
	for vertex: Vector3 in vertices:
		nearest = minf(nearest, vertex.z)
		farthest = maxf(farthest, vertex.z)
	return farthest - nearest


func _run_runtime_checks() -> void:
	var ambience_scene: PackedScene = load(NATURE_AMBIENCE_SCENE_PATH) as PackedScene
	_check(ambience_scene != null, "Brindlewick nature ambience scene loads.")
	if ambience_scene == null:
		return
	var ambience: NatureAmbience = ambience_scene.instantiate() as NatureAmbience
	_check(ambience != null, "Nature ambience uses the reusable coordinator component.")
	if ambience == null:
		return
	_check(ambience.validate_configuration().is_empty(), "Nature ambience configuration validates.")
	tree.root.add_child(ambience)
	await tree.process_frame

	_check_bird_flock(ambience.bird_flock)
	_check_leaf_fall(ambience.leaf_fall)
	_check_footfall(ambience.footfall_motes)
	_check_accessibility(ambience)

	ambience.queue_free()
	await tree.process_frame


## Nature must be authorable: the map maker places roosts and leaf drifts as ordinary
## world pieces, and those standalone components anchor on themselves.
func _run_placeable_piece_checks() -> void:
	var catalog: WorldPieceCatalog = load("res://content/pieces/piece_catalog.tres") as WorldPieceCatalog
	_check(catalog != null, "Shared piece catalog loads.")
	if catalog != null:
		for piece_id: StringName in [&"piece.bird_roost", &"piece.swift_roost", &"piece.leaf_drift"]:
			_check(catalog.has_piece(piece_id), "Map maker can place '%s'." % piece_id)
		var tooltips: MapMakerTooltipCatalog = load("res://tools/map_maker/map_maker_tooltip_catalog.tres") as MapMakerTooltipCatalog
		if tooltips != null:
			for tooltip_id: StringName in [
				&"tooltip.mode.nature",
				&"tooltip.piece.bird_roost",
				&"tooltip.piece.swift_roost",
				&"tooltip.piece.leaf_drift",
			]:
				_check(not tooltips.format_text(tooltip_id).is_empty(), "'%s' has beginner copy." % tooltip_id)

	for scene_path: String in [BIRD_ROOST_SCENE_PATH, SWIFT_ROOST_SCENE_PATH]:
		var roost_scene: PackedScene = load(scene_path) as PackedScene
		var roost: BirdRoost = roost_scene.instantiate() as BirdRoost if roost_scene != null else null
		_check(roost != null, "Roost piece '%s' uses the shared component." % scene_path.get_file())
		if roost == null:
			continue
		tree.root.add_child(roost)
		await tree.process_frame
		_check(
			roost.flock != null and roost.flock.get_bird_count() == roost.flock.species.flock_size,
			"A placed roost builds its own flock without a grove."
		)
		_check(
			roost.is_in_group(NatureAmbience.AMBIENT_MOTION_GROUP),
			"A placed roost can be reached by the zone motion fan-out."
		)
		var reduced: AccessibilitySettings = AccessibilitySettings.new()
		reduced.set_camera_motion_mode(AccessibilitySettings.CameraMotionMode.REDUCED)
		roost.apply_accessibility_settings(reduced)
		_check(not roost.flock.motion_enabled, "Reduced camera motion freezes a placed roost.")
		roost.queue_free()
		await tree.process_frame

	var drift_scene: PackedScene = load(LEAF_DRIFT_SCENE_PATH) as PackedScene
	var drift: LeafDrift = drift_scene.instantiate() as LeafDrift if drift_scene != null else null
	_check(drift != null, "Leaf drift piece uses the shared component.")
	if drift == null:
		return
	tree.root.add_child(drift)
	await tree.process_frame
	_check(
		drift.leaf_fall != null and drift.leaf_fall.get_emission_point_count() == drift.leaf_fall.local_emission_points,
		"A placed leaf drift sheds from its own ring."
	)
	_check(
		drift.is_in_group(NatureAmbience.AMBIENT_MOTION_GROUP),
		"A placed leaf drift can be reached by the zone motion fan-out."
	)
	var minimal: AccessibilitySettings = AccessibilitySettings.new()
	minimal.set_camera_motion_mode(AccessibilitySettings.CameraMotionMode.MINIMAL)
	drift.apply_accessibility_settings(minimal)
	_check(not drift.leaf_fall.get_particles().emitting, "Minimal camera motion stops a placed leaf drift.")
	drift.queue_free()
	await tree.process_frame


func _check_bird_flock(flock: AmbientBirdFlock) -> void:
	_check(flock != null, "Nature ambience owns a bird flock.")
	if flock == null:
		return
	_check(flock.get_bird_count() == flock.species.flock_size, "Flock builds every authored bird.")
	var instance: MultiMeshInstance3D = flock.get_multimesh_instance()
	_check(instance != null, "Flock renders through a single MultiMesh draw.")
	if instance == null:
		return
	_check(
		instance.multimesh.instance_count == flock.get_bird_count(),
		"Every bird has a MultiMesh instance."
	)
	_check(instance.multimesh.use_custom_data, "Flock carries per-bird flap phase in custom data.")
	var first: Transform3D = flock.get_bird_transform(0)
	var second: Transform3D = flock.get_bird_transform(1)
	_check(not first.origin.is_equal_approx(second.origin), "Birds spread across their own circuits.")
	_check(
		first.origin.y >= flock.species.cruise_height_min_m - flock.species.bob_amplitude_m,
		"Birds hold their authored cruise height."
	)
	var runtime_material: ShaderMaterial = instance.material_override as ShaderMaterial
	_check(
		runtime_material != null and runtime_material.resource_local_to_scene,
		"Bird materials stay instance-local."
	)


func _check_leaf_fall(leaf_fall: LeafFallEmitter) -> void:
	_check(leaf_fall != null, "Nature ambience owns a leaf-fall emitter.")
	if leaf_fall == null:
		return
	var layout: TreeGroveLayout = load(GROVE_LAYOUT_PATH) as TreeGroveLayout
	var expected_points: int = LeafFallEmitter.collect_crown_points(layout).size()
	_check(expected_points > 0, "Grove layout exposes crown emission points.")
	_check(
		leaf_fall.get_emission_point_count() == expected_points,
		"Leaf fall emits from every authored crown mass."
	)
	var particles: GPUParticles3D = leaf_fall.get_particles()
	_check(particles != null, "Leaf fall collapses the whole grove into one particle draw.")
	if particles == null:
		return
	_check(particles.emitting, "Leaf fall runs by default.")
	_check(not particles.local_coords, "Leaves drift in world space, not with the emitter node.")
	_check(particles.amount == leaf_fall.leaf_count, "Leaf budget matches the authored count.")


func _check_footfall(motes: FootfallMotes) -> void:
	_check(motes != null, "Nature ambience owns the footfall motes.")
	if motes == null:
		return
	_check(
		motes.get_surface_id(Vector2.ZERO) == FootfallMotes.SURFACE_DIRT_ROAD,
		"The plaza reads as dirt road."
	)
	_check(
		motes.get_surface_id(Vector2(12.0, 12.0)) == FootfallMotes.SURFACE_GRASS,
		"Open ground away from the road reads as grass."
	)
	_check(
		motes.get_node_or_null(FootfallMotes.DUST_NODE_NAME) is GPUParticles3D,
		"Dirt dust has its own emitter."
	)
	_check(
		motes.get_node_or_null(FootfallMotes.GRASS_NODE_NAME) is GPUParticles3D,
		"Grass motes have their own emitter."
	)
	_check(not motes.is_emitting_dust(), "Footfall stays silent until an actor is walking.")
	_check(not motes.is_emitting_grass(), "Grass motes stay silent until an actor is walking.")


func _check_accessibility(ambience: NatureAmbience) -> void:
	var reduced: AccessibilitySettings = AccessibilitySettings.new()
	reduced.set_camera_motion_mode(AccessibilitySettings.CameraMotionMode.REDUCED)
	ambience.apply_accessibility_settings(reduced)
	var runtime_material: ShaderMaterial = ambience.bird_flock.get_multimesh_instance().material_override as ShaderMaterial
	_check(not ambience.bird_flock.motion_enabled, "Reduced camera motion freezes the flock.")
	_check(
		is_zero_approx(float(runtime_material.get_shader_parameter(&"flap_strength"))),
		"Reduced camera motion stops the wing beat."
	)
	_check(not ambience.leaf_fall.get_particles().emitting, "Reduced camera motion stops leaf fall.")
	_check(not ambience.footfall_motes.motion_enabled, "Reduced camera motion stops footfall motes.")

	var full: AccessibilitySettings = AccessibilitySettings.new()
	ambience.apply_accessibility_settings(full)
	_check(ambience.bird_flock.motion_enabled, "Full camera motion restores the flock.")
	_check(
		float(runtime_material.get_shader_parameter(&"flap_strength")) > 0.0,
		"Full camera motion restores the wing beat."
	)
	_check(ambience.leaf_fall.get_particles().emitting, "Full camera motion restores leaf fall.")
	_check(ambience.footfall_motes.motion_enabled, "Full camera motion restores footfall motes.")
