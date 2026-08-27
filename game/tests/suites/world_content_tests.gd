extends TestCase


func suite_name() -> String:
	return "world_content"


func run() -> void:
	_test_zone_manifest()
	_test_dirt_road_network()
	_test_world_placements()
	_test_tree_definitions()
	_test_tree_grove_layout()


func _test_zone_manifest() -> void:
	_check(bool(content_db.call(&"is_valid")), "The explicit content registry validates.")
	var manifest: ZoneManifest = content_db.call(&"get_zone", &"zone.brindlewick_square") as ZoneManifest
	_check(manifest != null, "Brindlewick resolves by stable zone ID.")
	if manifest != null:
		_check(manifest.spawn_ids.has(&"spawn.brindlewick_square.south_gate"), "Brindlewick declares its south-gate spawn.")
		_check(manifest.validation_bounds.has_point(Vector3.ZERO), "Brindlewick validation bounds contain the authored center.")
	var invalid: ZoneManifest = ZoneManifest.new()
	invalid.id = &"Bad Display Name"
	invalid.default_facet = &"south"
	invalid.allowed_facets = [&"north"]
	_check(invalid.validate_definition().size() >= 4, "Manifest validation reports ID, scene, facet, and spawn failures.")


func _test_dirt_road_network() -> void:
	var road_scene: PackedScene = load("res://scenes/world/surfaces/brindlewick_dirt_road_surface.tscn") as PackedScene
	_check(road_scene != null, "Brindlewick dirt-road network scene loads.")
	if road_scene == null:
		return
	var road: DirtRoadNetwork3D = road_scene.instantiate() as DirtRoadNetwork3D
	_check(road != null, "Dirt-road surface uses the reusable network component.")
	if road == null:
		return
	_check(road.get_patch_count() == 6, "Brindlewick road network declares six authored patches.")
	_check(road.validate_configuration().is_empty(), "Brindlewick road network configuration validates.")
	_check(
		DirtRoadNetwork3D.rounded_box_distance(Vector2.ZERO, Vector4(0.0, 0.0, 1.6, 1.6), 1.35) < 0.0,
		"Rounded road patches contain their center."
	)
	_check(
		DirtRoadNetwork3D.rounded_box_distance(Vector2(1.55, 1.55), Vector4(0.0, 0.0, 1.6, 1.6), 1.35) > 0.0,
		"Rounded road patches trim their square corner."
	)
	_check(
		DirtRoadNetwork3D.smooth_union_distance(-0.1, -0.1, 0.55) < -0.1,
		"Road-patch unions soften connected joins."
	)
	road.rebuild_surface()
	var runtime_material: ShaderMaterial = road.material_override as ShaderMaterial
	var road_layout: Resource = road.get("layout") as Resource
	_check(road_layout != null and road.mesh is ArrayMesh and road.mesh.get_surface_count() == 1, "Road layout builds one batched patch surface.")
	_check(road.mesh.get_faces().size() == road.get_patch_count() * 6, "Each road patch contributes two triangles to the bounded surface.")
	_check(
		runtime_material != null and int(runtime_material.get_shader_parameter(&"patch_count")) == 6,
		"Road layout is transferred to an instance-local shader material."
	)
	road.free()


func _test_world_placements() -> void:
	_check(ZonePlacement.snap_meters(2.4, 0.5) == 5, "World positions snap to the 0.5 m grid.")
	_check(ZonePlacement.snap_meters(-0.24, 0.5) == 0, "Grid snap rounds toward the nearest cell.")
	var catalog: WorldPieceCatalog = load("res://content/pieces/piece_catalog.tres") as WorldPieceCatalog
	_check(catalog != null and catalog.validate_definition().is_empty(), "Shared piece catalog validates.")
	_check(catalog != null and catalog.get_piece_ids().size() == 14, "Catalog exposes the full beginner piece set.")
	if catalog != null:
		_check(catalog.has_piece(&"piece.crate_block"), "Crate component is catalogued.")
		_check(catalog.has_piece(&"piece.lamp_post"), "Lamp component is catalogued.")
		_check(catalog.has_piece(&"piece.planter_box"), "Planter component is catalogued.")
		_check(catalog.has_piece(&"piece.bell_tower"), "Bell tower is catalogued.")
		_check(catalog.has_piece(&"piece.shade_tree"), "Shade tree is catalogued.")
		_check(catalog.get_pieces_in_family(&"building").size() == 7, "Building family contains the town landmarks.")
		_check(catalog.get_pieces_in_family(&"nature").size() == 3, "Nature family offers both roosts and the leaf drift.")
		_check(
			MapMakerPalette.FAMILIES.has(&"nature"),
			"The map maker palette exposes the nature family."
		)
	var crate_scene: PackedScene = load("res://scenes/world/pieces/crate_block.tscn") as PackedScene
	var lamp_scene: PackedScene = load("res://scenes/world/pieces/lamp_post.tscn") as PackedScene
	var planter_scene: PackedScene = load("res://scenes/world/pieces/planter_box.tscn") as PackedScene
	var crate: Node = crate_scene.instantiate() if crate_scene != null else null
	var lamp: Node = lamp_scene.instantiate() if lamp_scene != null else null
	var planter: Node = planter_scene.instantiate() if planter_scene != null else null
	_check(crate is CrateBlock, "Crate piece is its own component type.")
	_check(lamp is LampPost, "Lamp piece is its own component type.")
	_check(planter is PlanterBox, "Planter piece is its own component type.")
	if crate != null:
		crate.free()
	if lamp != null:
		lamp.free()
	if planter != null:
		planter.free()
	var layout: ZonePlacementList = ZonePlacementList.new()
	layout.zone_id = &"zone.brindlewick_square"
	layout.set_cell(&"piece.crate_block", 2, 4, 1)
	layout.set_cell(&"piece.crate_block", 2, 4, 2)
	_check(layout.placements.size() == 1, "Placing on an occupied cell replaces the previous piece.")
	_check(layout.placements[0].yaw_quarter_turns == 2, "Replacement stores the new quarter-turn yaw.")
	_check(layout.get_placement_at(2, 4) != null, "Occupied cells report the authored placement.")
	_check(layout.toggle_same_piece(&"piece.crate_block", 2, 4, catalog), "Clicking the held piece on its cell unplaces it.")
	_check(layout.placements.is_empty(), "Unplace removes the matching piece.")
	layout.set_cell(&"piece.crate_block", 2, 4, 2)
	var bounds: AABB = AABB(Vector3(-34.0, -2.0, -29.0), Vector3(68.0, 24.0, 58.0))
	_check(layout.validate_definition(catalog, bounds).is_empty(), "Valid placements pass catalog and bounds checks.")
	layout.set_cell(&"piece.missing", 0, 0)
	_check(not layout.validate_definition(catalog, bounds).is_empty(), "Unknown piece IDs fail validation.")
	var authored: ZonePlacementList = load("res://content/zones/brindlewick_square/brindlewick_square_placements.tres") as ZonePlacementList
	_check(authored != null and authored.placements.size() == 15, "Brindlewick stores fifteen map-maker placements.")
	var layer_scene: PackedScene = load("res://scenes/world/placement_layer.tscn") as PackedScene
	_check(layer_scene != null, "PlacementLayer scene loads.")
	if layer_scene != null:
		var layer: PlacementLayer = layer_scene.instantiate() as PlacementLayer
		layer.rebuild()
		_check(layer.get_placed_count() == 15, "PlacementLayer instances every authored world piece.")
		_check(layer.find_child("cell_8_22", true, false) is CrateBlock, "Authored crate occupies its grid cell.")
		_check(layer.get_instance_for_cell(8, 22) is CrateBlock, "PlacementLayer resolves the instance covering a cell.")
		layer.free()
	_check(ResourceLoader.exists("res://tools/map_maker/map_maker.tscn", "PackedScene"), "Internal map maker scene exists.")
	var title_source: String = FileAccess.get_file_as_string("res://src/ui/title_screen.gd")
	_check(title_source.contains("map_maker_requested"), "Title screen offers a map maker action.")
	var title_scene_source: String = FileAccess.get_file_as_string("res://scenes/ui/title_screen.tscn")
	_check(title_scene_source.contains("Open Map Maker"), "Title menu includes an Open Map Maker button.")
	_check(MapMakerWorldCoverage.connectivity_percent() == 100, "Coverage model treats the live zone as fully connected.")
	_check(MapMakerWorldCoverage.control_percent() == 81, "Coverage model scores current writable world surfaces at 81 percent.")
	_check(String(MapMakerWorldCoverage.ranked_next_routes()[0]["id"]) == "spawns", "Highest remaining authoring weight is spawn data.")
	var tooltip_catalog: MapMakerTooltipCatalog = load("res://tools/map_maker/map_maker_tooltip_catalog.tres") as MapMakerTooltipCatalog
	_check(tooltip_catalog != null and tooltip_catalog.validate_definition().is_empty(), "Map maker tooltips validate as a separate catalog.")
	_check(tooltip_catalog != null and not tooltip_catalog.format_text(&"tooltip.action.save").is_empty(), "Save tooltip has beginner copy.")
	var road_layout: DirtRoadLayout = DirtRoadLayout.new()
	road_layout.network_size_m = Vector2(68.0, 58.0)
	road_layout.patches = [Vector4(0.0, 0.0, 1.6, 1.6)]
	road_layout.corner_radii_m = PackedFloat32Array([1.0])
	_check(road_layout.set_patch_center(0, Vector2(4.0, -3.0)), "Road centers can move on the authored network.")
	_check(is_equal_approx(road_layout.patches[0].x, 4.0), "Moved road patch stores the new center X.")
	var house: WorldPieceDefinition = catalog.get_definition(&"piece.civic_house") if catalog != null else null
	_check(house != null and house.covered_cells(0, 0).size() == 18 * 14, "Building footprints occupy every covered grid cell.")


func _test_tree_definitions() -> void:
	var species_paths: Array[String] = [
		"res://content/trees/civic_shade.tres",
		"res://content/trees/orchard_tidemark.tres",
		"res://content/trees/gate_sentinel.tres",
	]
	for species_path: String in species_paths:
		var definition: TreeDefinition = load(species_path) as TreeDefinition
		_check(definition != null, "Tree species '%s' loads." % species_path)
		if definition == null:
			continue
		_check(definition.validate_definition().is_empty(), "Tree species '%s' validates." % definition.id)
		_check(
			definition.canopy_clearance_m >= TreeDefinition.MIN_WALK_UNDER_CLEARANCE_M,
			"Tree species '%s' keeps door-metric clearance under its crown." % definition.id
		)
	var invalid: TreeDefinition = TreeDefinition.new()
	invalid.id = &"Bad Tree Name"
	invalid.walk_under = true
	invalid.canopy_clearance_m = 1.0
	invalid.trunk_base_radius_m = 3.0
	invalid.canopy_radius_m = 1.0
	invalid.crown_masses = []
	_check(
		invalid.validate_definition().size() >= 5,
		"Tree validation reports ID, material, trunk, crown, and clearance failures."
	)
	var civic: TreeDefinition = load("res://content/trees/civic_shade.tres") as TreeDefinition
	_check(civic.resolve_variant(7) < civic.variant_count, "Variant selection stays inside the authored variant set.")
	_check(civic.resolve_variant(-7) == civic.resolve_variant(7), "Variant selection ignores seed sign.")
	_check(not civic.allows_scale(1.5), "Species scale ranges reject oversized placements.")
	var first_masses: Array[Vector4] = TreeBody3D.build_variant_masses(civic, 3)
	var repeat_masses: Array[Vector4] = TreeBody3D.build_variant_masses(civic, 3)
	_check(first_masses == repeat_masses, "Crown variants are deterministic for one seed.")
	_check(
		first_masses != TreeBody3D.build_variant_masses(civic, 4),
		"Different seeds produce different crown silhouettes."
	)


func _test_tree_grove_layout() -> void:
	var layout: TreeGroveLayout = load(
		"res://content/zones/brindlewick_square/brindlewick_tree_grove_layout.tres"
	) as TreeGroveLayout
	_check(layout != null, "Brindlewick tree grove layout loads.")
	if layout == null:
		return
	var layout_errors: Array[String] = layout.validate_definition()
	_check(layout_errors.is_empty(), "Brindlewick grove layout validates. %s" % [layout_errors])
	_check(layout.get_placement_count() == 58, "Brindlewick authors all 58 grove placements.")
	_check(layout.get_hero_count() == 6, "Brindlewick uses six hero specimens.")
	_check(layout.get_batched_count() == 52, "Brindlewick batches its remaining belt trees.")
	_check(layout.distance_to_road_m(Vector2.ZERO) < 0.0, "Grove clearance math detects the plaza road surface.")
	_check(layout.distance_to_road_m(Vector2(-30.5, -13.0)) > 1.0, "Authored belt rows keep road shoulder.")

	var sentinel: TreeDefinition = load("res://content/trees/gate_sentinel.tres") as TreeDefinition
	var invalid: TreeGroveLayout = TreeGroveLayout.new()
	invalid.species = [sentinel]
	invalid.road_layout = load(
		"res://content/zones/brindlewick_square/brindlewick_dirt_road_layout.tres"
	) as DirtRoadLayout
	invalid.species_ids = [sentinel.id, sentinel.id, sentinel.id, &"tree.brindlewick.missing"]
	invalid.positions_xz = PackedVector2Array([
		Vector2(0.0, 20.0),
		Vector2(0.3, 20.0),
		Vector2(60.0, 0.0),
		Vector2(4.0, 20.0),
	])
	invalid.yaw_degrees = PackedFloat32Array([7.0, 0.0, 0.0, 0.0])
	invalid.uniform_scales = PackedFloat32Array([4.0, 1.0, 1.0, 1.0])
	invalid.variant_seeds = PackedInt32Array([0, 1, 2, 3])
	invalid.hero_flags = PackedByteArray([1, 1, 1, 1])
	var invalid_errors: Array[String] = invalid.validate_definition()
	_check(_errors_mention(invalid_errors, "road shoulder"), "Grove validation rejects trees standing on the road.")
	_check(_errors_mention(invalid_errors, "logical grid"), "Grove validation rejects off-grid placements.")
	_check(_errors_mention(invalid_errors, "species snap"), "Grove validation rejects unsnapped yaw.")
	_check(_errors_mention(invalid_errors, "outside the '"), "Grove validation rejects out-of-range scale.")
	_check(_errors_mention(invalid_errors, "unknown species"), "Grove validation rejects unknown species IDs.")
	_check(_errors_mention(invalid_errors, "trunk gap"), "Grove validation rejects crowded trunks.")
	_check(_errors_mention(invalid_errors, "outside the authored ground"), "Grove validation rejects trees off the ground surface.")

	var misaligned: TreeGroveLayout = TreeGroveLayout.new()
	misaligned.species = [sentinel]
	misaligned.species_ids = [sentinel.id]
	_check(
		_errors_mention(misaligned.validate_definition(), "rows but"),
		"Grove validation reports misaligned placement rows."
	)
