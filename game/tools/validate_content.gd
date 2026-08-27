extends SceneTree

const REQUIRED_DIRECTORIES: Array[String] = [
	"res://assets",
	"res://content",
	"res://content/actors",
	"res://content/callings",
	"res://content/dialogue",
	"res://content/encounters",
	"res://content/quests",
	"res://content/zones",
	"res://content/pieces",
	"res://content/items",
	"res://content/wildlife",
	"res://assets/audio",
]
const ASSET_MANIFEST_PATH: String = "res://assets/asset_manifest.json"
const CONTENT_REGISTRY_PATH: String = "res://content/content_registry.tres"
const PIECE_CATALOG_PATH: String = "res://content/pieces/piece_catalog.tres"
const TREE_SPECIES_PATHS: Array[String] = [
	"res://content/trees/civic_shade.tres",
	"res://content/trees/orchard_tidemark.tres",
	"res://content/trees/gate_sentinel.tres",
]
const TREE_GROVE_LAYOUT_PATH: String = "res://content/zones/brindlewick_square/brindlewick_tree_grove_layout.tres"
const TREE_GROVE_SCENE_PATH: String = "res://scenes/world/trees/brindlewick_tree_grove.tscn"
const TREE_BODY_SCENE_PATH: String = "res://scenes/world/trees/tree_body.tscn"
const BIRD_SPECIES_PATHS: Array[String] = [
	"res://content/wildlife/hearthfinch.tres",
	"res://content/wildlife/slate_swift.tres",
]
const NATURE_AMBIENCE_SCENE_PATH: String = "res://scenes/world/nature/brindlewick_nature_ambience.tscn"
const MAP_MAKER_SCENE_PATH: String = "res://tools/map_maker/map_maker.tscn"
const MARA_SOURCE_METADATA_PATH: String = "res://art_source/characters/mara/mara_prototype.source.json"
const MARA_LAYERS_METADATA_PATH: String = "res://art_source/characters/mara/mara_layers.source.json"
const MARA_LAYER_KIT_PATH: String = "res://content/actors/mara_layer_kit.tres"
const ITEM_CATALOG_PATH: String = "res://content/items/item_catalog.tres"
const GRASS_SURFACE_SCENE_PATH: String = "res://scenes/world/surfaces/brindlewick_grass_surface.tscn"
const DIRT_ROAD_SURFACE_SCENE_PATH: String = "res://scenes/world/surfaces/brindlewick_dirt_road_surface.tscn"
const DIRT_ROAD_LAYOUT_PATH: String = "res://content/zones/brindlewick_square/brindlewick_dirt_road_layout.tres"
const GRASS_MATERIAL_PATH: String = "res://assets/materials/environment/grass_surface_material.tres"
const DIRT_ROAD_MATERIAL_PATH: String = "res://assets/materials/environment/dirt_road_surface_material.tres"
const TITLE_AUDIO_PATHS: Array[String] = [
	"res://assets/audio/music/title_fold_between.wav",
	"res://assets/audio/ui/ui_hover_bling.wav",
	"res://assets/audio/ui/ui_click.wav",
]
const TITLE_AUDIO_TOOL_PATH: String = "res://tools/generate_title_audio.gd"
const AUDIO_BUS_LAYOUT_PATH: String = "res://assets/audio/default_bus_layout.tres"
const ROUTE_SPEED_MPS: float = 4.0
const MIN_ROUTE_SECONDS: float = 45.0
const MAX_ROUTE_SECONDS: float = 75.0

var _failures: Array[String] = []
var _validated_assets: int = 0
var _validated_zones: int = 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_install_input_router_for_scene_validation()
	for directory: String in REQUIRED_DIRECTORIES:
		if DirAccess.open(directory) == null:
			_failures.append("Required content directory is missing: %s" % directory)

	_validate_asset_manifest()
	_validate_source_metadata()
	_validate_content_registry()
	_validate_piece_catalog()
	_validate_tree_system()
	_validate_nature_ambience()
	_validate_equipment_content()
	_validate_actor_layer_kit()
	_validate_map_maker_isolation()
	_validate_title_audio()

	if _failures.is_empty():
		print("[CONTENT] PASS: %d assets and %d zones validated." % [_validated_assets, _validated_zones])
		quit(0)
		return

	for failure: String in _failures:
		push_error("[CONTENT] %s" % failure)
	print("[CONTENT] FAIL: %d validation errors." % _failures.size())
	quit(1)


func _validate_asset_manifest() -> void:
	var parsed: Variant = _read_json(ASSET_MANIFEST_PATH)
	if not parsed is Dictionary:
		return
	var manifest: Dictionary = parsed as Dictionary
	if int(manifest.get("schema_version", 0)) != 1:
		_failures.append("Asset provenance manifest schema_version must be 1.")
	var assets_value: Variant = manifest.get("assets", [])
	if not assets_value is Array:
		_failures.append("Asset provenance manifest must contain an assets array.")
		return
	var ids: Dictionary[String, bool] = {}
	for asset_value: Variant in assets_value as Array:
		if not asset_value is Dictionary:
			_failures.append("Asset provenance entries must be JSON objects.")
			continue
		var asset: Dictionary = asset_value as Dictionary
		var asset_id: String = str(asset.get("id", ""))
		if not _is_stable_id(asset_id):
			_failures.append("Asset ID '%s' is not a namespaced stable ID." % asset_id)
		if ids.has(asset_id):
			_failures.append("Duplicate asset ID '%s'." % asset_id)
		ids[asset_id] = true
		for field: String in ["source", "runtime", "creator", "license", "review_status"]:
			if str(asset.get(field, "")).strip_edges().is_empty():
				_failures.append("Asset '%s' is missing provenance field '%s'." % [asset_id, field])
		for path_field: String in ["source", "runtime", "generation_tool"]:
			var asset_path: String = str(asset.get(path_field, ""))
			if not asset_path.is_empty() and not FileAccess.file_exists(asset_path):
				_failures.append("Asset '%s' references missing %s '%s'." % [asset_id, path_field, asset_path])
		_validated_assets += 1


func _validate_source_metadata() -> void:
	var parsed: Variant = _read_json(MARA_SOURCE_METADATA_PATH)
	if not parsed is Dictionary:
		return
	var metadata: Dictionary = parsed as Dictionary
	for field: String in ["asset_id", "authorship", "license", "review_status", "export_settings", "palette"]:
		if not metadata.has(field):
			_failures.append("Mara source metadata is missing '%s'." % field)
	if str(metadata.get("authorship", "")).strip_edges().is_empty():
		_failures.append("Mara source metadata must identify authorship.")


func _validate_content_registry() -> void:
	if not ResourceLoader.exists(CONTENT_REGISTRY_PATH):
		_failures.append("Required content registry is missing: %s" % CONTENT_REGISTRY_PATH)
		return
	var registry: ContentRegistry = load(CONTENT_REGISTRY_PATH) as ContentRegistry
	if registry == null:
		_failures.append("Content registry could not be loaded.")
		return
	if registry.zones.is_empty():
		_failures.append("Content registry must declare at least one zone.")
		return
	var ids: Dictionary[StringName, bool] = {}
	for manifest: ZoneManifest in registry.zones:
		if manifest == null:
			_failures.append("Content registry contains an empty zone entry.")
			continue
		_failures.append_array(manifest.validate_definition())
		if ids.has(manifest.id):
			_failures.append("Duplicate content ID '%s'." % manifest.id)
		ids[manifest.id] = true
		_validate_zone_package(manifest)
		_validated_zones += 1


func _validate_zone_package(manifest: ZoneManifest) -> void:
	if manifest.scene == null:
		return
	var route_seconds: float = manifest.primary_route_length_m / ROUTE_SPEED_MPS
	if route_seconds < MIN_ROUTE_SECONDS or route_seconds > MAX_ROUTE_SECONDS:
		_failures.append(
			"Zone '%s' primary route is %.1f seconds; expected %.0f-%.0f seconds." % [
				manifest.id,
				route_seconds,
				MIN_ROUTE_SECONDS,
				MAX_ROUTE_SECONDS,
			]
		)
	var zone: Node = manifest.scene.instantiate()
	if not zone is Node3D:
		_failures.append("Zone '%s' entry scene must inherit Node3D." % manifest.id)
		zone.free()
		return
	for layer_name: String in ["Geometry", "Gameplay", "Presentation"]:
		if zone.get_node_or_null(NodePath(layer_name)) == null:
			_failures.append("Zone '%s' is missing its %s layer." % [manifest.id, layer_name.to_lower()])
	var gameplay: Node = zone.get_node_or_null("Gameplay")
	if gameplay != null:
		var spawn_points: Node = gameplay.get_node_or_null("SpawnPoints")
		var scene_spawn_ids: Array[StringName] = []
		if spawn_points != null:
			for child: Node in spawn_points.get_children():
				scene_spawn_ids.append(StringName(child.get_meta(&"spawn_id", &"")))
		for spawn_id: StringName in manifest.spawn_ids:
			if not scene_spawn_ids.has(spawn_id):
				_failures.append("Zone '%s' does not contain declared spawn '%s'." % [manifest.id, spawn_id])
		var camera_volumes: Node = gameplay.get_node_or_null("CameraVolumes")
		if camera_volumes == null or camera_volumes.get_child_count() < 1:
			_failures.append("Zone '%s' requires at least one constrained camera volume." % manifest.id)
	var placement_layer: PlacementLayer = zone.get_node_or_null("Geometry/PlacementLayer") as PlacementLayer
	if placement_layer != null:
		placement_layer.rebuild()
	if zone.find_child("BellTower", true, false) == null:
		_failures.append("Zone '%s' is missing its bell-tower landmark." % manifest.id)
	if manifest.id == &"zone.brindlewick_square":
		_validate_brindlewick_surfaces(zone)
		_validate_brindlewick_placements(zone, manifest)
		_validate_brindlewick_trees(zone)
		_validate_brindlewick_nature(zone)
	var foreground: Node = zone.get_node_or_null("Presentation/Foreground")
	if foreground == null or foreground.get_child_count() < manifest.foreground_occluder_ids.size():
		_failures.append("Zone '%s' is missing declared foreground occluders." % manifest.id)
	zone.free()


func _validate_brindlewick_surfaces(zone: Node) -> void:
	for resource_path: String in [GRASS_SURFACE_SCENE_PATH, DIRT_ROAD_SURFACE_SCENE_PATH, DIRT_ROAD_LAYOUT_PATH]:
		if not ResourceLoader.exists(resource_path):
			_failures.append("Brindlewick surface resource is missing: %s" % resource_path)
	var grass_surface: Node = zone.get_node_or_null("Geometry/GrassSurface")
	if grass_surface == null or grass_surface.get_node_or_null("Ground/Collision") == null:
		_failures.append("Brindlewick grass surface must own the canonical ground and collision.")
	var dirt_road_surface: Node = zone.get_node_or_null("Geometry/DirtRoadSurface")
	if not dirt_road_surface is DirtRoadNetwork3D:
		_failures.append("Brindlewick dirt-road surface must use the reusable road-network renderer.")
	else:
		var road_network: DirtRoadNetwork3D = dirt_road_surface as DirtRoadNetwork3D
		if road_network.get_patch_count() != 6:
			_failures.append("Brindlewick dirt-road network must contain all six authored route patches.")
		var road_layout: Resource = road_network.get("layout") as Resource
		if road_layout == null or road_layout.resource_path != DIRT_ROAD_LAYOUT_PATH:
			_failures.append("Brindlewick dirt-road network must reference its zone-owned layout resource.")
		for configuration_error: String in road_network.validate_configuration():
			_failures.append("Brindlewick dirt-road network: %s" % configuration_error)
	var grass_material: ShaderMaterial = load(GRASS_MATERIAL_PATH) as ShaderMaterial
	var dirt_road_material: ShaderMaterial = load(DIRT_ROAD_MATERIAL_PATH) as ShaderMaterial
	if grass_material == null or grass_material.shader == null:
		_failures.append("Brindlewick grass surface requires its external shader material.")
	if dirt_road_material == null or dirt_road_material.shader == null:
		_failures.append("Brindlewick dirt-road surface requires its external shader material.")
	if grass_material != null and dirt_road_material != null and grass_material.shader == dirt_road_material.shader:
		_failures.append("Grass and dirt road must remain independently owned shader families.")


func _validate_piece_catalog() -> void:
	if not ResourceLoader.exists(PIECE_CATALOG_PATH):
		_failures.append("World piece catalog is missing: %s" % PIECE_CATALOG_PATH)
		return
	var catalog: WorldPieceCatalog = load(PIECE_CATALOG_PATH) as WorldPieceCatalog
	if catalog == null:
		_failures.append("World piece catalog could not be loaded.")
		return
	_failures.append_array(catalog.validate_definition())
	var expected_ids: Array[StringName] = [
		&"piece.crate_block",
		&"piece.lamp_post",
		&"piece.planter_box",
		&"piece.bell_tower",
		&"piece.civic_house",
		&"piece.shade_tree",
		&"piece.bird_roost",
		&"piece.swift_roost",
		&"piece.leaf_drift",
	]
	for piece_id: StringName in expected_ids:
		if not catalog.has_piece(piece_id):
			_failures.append("World piece catalog is missing '%s'." % piece_id)
		else:
			var packed_scene: PackedScene = catalog.get_scene(piece_id)
			if packed_scene == null:
				continue
			var instance: Node = packed_scene.instantiate()
			if piece_id == &"piece.crate_block" or piece_id == &"piece.lamp_post" or piece_id == &"piece.planter_box":
				if not instance is StaticBody3D:
					_failures.append("Piece '%s' must be a StaticBody3D component." % piece_id)
			elif instance == null or not instance is Node3D:
				_failures.append("Piece '%s' must inherit Node3D." % piece_id)
			instance.free()
	# Every catalogued family needs a palette tab, or its pieces are unreachable in the tool.
	for piece: WorldPieceDefinition in catalog.pieces:
		if piece != null and not MapMakerPalette.FAMILIES.has(piece.family):
			_failures.append(
				"Piece '%s' is in family '%s', which the map maker palette does not show." % [
					piece.id,
					piece.family,
				]
			)


func _validate_tree_system() -> void:
	var species_ids: Dictionary[StringName, bool] = {}
	for species_path: String in TREE_SPECIES_PATHS:
		if not ResourceLoader.exists(species_path):
			_failures.append("Tree species definition is missing: %s" % species_path)
			continue
		var definition: TreeDefinition = load(species_path) as TreeDefinition
		if definition == null:
			_failures.append("Tree species definition could not be loaded: %s" % species_path)
			continue
		_failures.append_array(definition.validate_definition())
		if species_ids.has(definition.id):
			_failures.append("Duplicate tree species ID '%s'." % definition.id)
		species_ids[definition.id] = true
		if definition.trunk_material == definition.crown_material:
			_failures.append("Tree '%s' must keep trunk and crown as separate materials." % definition.id)

	for scene_path: String in [TREE_BODY_SCENE_PATH, TREE_GROVE_SCENE_PATH]:
		if not ResourceLoader.exists(scene_path, "PackedScene"):
			_failures.append("Tree scene is missing: %s" % scene_path)

	if not ResourceLoader.exists(TREE_GROVE_LAYOUT_PATH):
		_failures.append("Brindlewick tree grove layout is missing: %s" % TREE_GROVE_LAYOUT_PATH)
		return
	var layout: TreeGroveLayout = load(TREE_GROVE_LAYOUT_PATH) as TreeGroveLayout
	if layout == null:
		_failures.append("Brindlewick tree grove layout could not be loaded.")
		return
	for layout_error: String in layout.validate_definition():
		_failures.append("Brindlewick tree grove: %s" % layout_error)
	if layout.road_layout == null or layout.road_layout.resource_path != DIRT_ROAD_LAYOUT_PATH:
		_failures.append("Brindlewick tree grove must clear the zone-owned dirt-road layout.")


func _validate_brindlewick_trees(zone: Node) -> void:
	var grove: TreeGrove3D = zone.get_node_or_null("Geometry/TreeGrove") as TreeGrove3D
	if grove == null:
		_failures.append("Brindlewick geometry must instance the reusable tree grove.")
		return
	for configuration_error: String in grove.validate_configuration():
		_failures.append("Brindlewick tree grove: %s" % configuration_error)
	if grove.layout == null or grove.layout.resource_path != TREE_GROVE_LAYOUT_PATH:
		_failures.append("Brindlewick tree grove must reference its zone-owned layout resource.")
	if grove.tree_body_scene == null:
		_failures.append("Brindlewick tree grove must reference the reusable tree-body scene.")


func _validate_nature_ambience() -> void:
	var species_ids: Dictionary[StringName, bool] = {}
	for species_path: String in BIRD_SPECIES_PATHS:
		if not ResourceLoader.exists(species_path):
			_failures.append("Ambient bird species is missing: %s" % species_path)
			continue
		var species: BirdSpeciesDefinition = load(species_path) as BirdSpeciesDefinition
		if species == null:
			_failures.append("Ambient bird species could not be loaded: %s" % species_path)
			continue
		_failures.append_array(species.validate_definition())
		if species_ids.has(species.id):
			_failures.append("Duplicate ambient bird species ID '%s'." % species.id)
		species_ids[species.id] = true
		# One baseline body serves every species, so a variant must be buildable from data alone.
		var body: ArrayMesh = AmbientBirdFlock.build_bird_mesh(species)
		if body.get_surface_count() != 1:
			_failures.append("Bird '%s' must build a single-surface baseline body." % species.id)
	if not ResourceLoader.exists(NATURE_AMBIENCE_SCENE_PATH, "PackedScene"):
		_failures.append("Nature ambience scene is missing: %s" % NATURE_AMBIENCE_SCENE_PATH)
		return
	var ambience_scene: PackedScene = load(NATURE_AMBIENCE_SCENE_PATH) as PackedScene
	var ambience: NatureAmbience = ambience_scene.instantiate() as NatureAmbience
	if ambience == null:
		_failures.append("Nature ambience scene must use the NatureAmbience component.")
		return
	for configuration_error: String in ambience.validate_configuration():
		_failures.append("Brindlewick nature ambience: %s" % configuration_error)
	if ambience.leaf_fall != null and ambience.leaf_fall.layout != null:
		if ambience.leaf_fall.layout.resource_path != TREE_GROVE_LAYOUT_PATH:
			_failures.append("Leaf fall must read the zone-owned tree grove layout.")
	if ambience.footfall_motes != null and ambience.footfall_motes.road_layout != null:
		if ambience.footfall_motes.road_layout.resource_path != DIRT_ROAD_LAYOUT_PATH:
			_failures.append("Footfall motes must classify against the zone-owned dirt-road layout.")
	ambience.free()


func _validate_brindlewick_nature(zone: Node) -> void:
	var ambience: NatureAmbience = zone.get_node_or_null("Presentation/NatureAmbience") as NatureAmbience
	if ambience == null:
		_failures.append("Brindlewick presentation must instance the reusable nature ambience.")
		return
	for configuration_error: String in ambience.validate_configuration():
		_failures.append("Brindlewick nature ambience: %s" % configuration_error)
	var controller_source: String = FileAccess.get_file_as_string("res://src/world/zone_controller.gd")
	if not controller_source.contains("nature_ambience.configure_actor"):
		_failures.append("Zone controller must inject the player into the nature ambience.")


func _validate_equipment_content() -> void:
	if not ResourceLoader.exists(ITEM_CATALOG_PATH):
		_failures.append("Item catalog is missing: %s" % ITEM_CATALOG_PATH)
		return
	var catalog: ItemCatalog = load(ITEM_CATALOG_PATH) as ItemCatalog
	if catalog == null:
		_failures.append("Item catalog could not be loaded.")
		return
	_failures.append_array(catalog.validate_definition())
	for slot_id: StringName in EquipmentSlotCatalog.SLOT_ORDER:
		if catalog.items_for_slot(slot_id).is_empty():
			_failures.append("Slot '%s' has no graybox item to prove it works." % slot_id)
	for slot_id: StringName in EquipmentSlotCatalog.SLOT_ORDER:
		if EquipmentSlotCatalog.covered_layers(slot_id).is_empty():
			_failures.append("Slot '%s' declares no body layers." % slot_id)
		for layer_id: StringName in EquipmentSlotCatalog.covered_layers(slot_id):
			if ActorLayerIds.doll_index(layer_id) < 0:
				_failures.append("Slot '%s' references unknown layer '%s'." % [slot_id, layer_id])
	for layer_id: StringName in ActorLayerIds.DOLL_LAYER_ORDER:
		if not EquipmentSlotCatalog.has_slot(EquipmentSlotCatalog.focus_slot_for_layer(layer_id)):
			_failures.append("Layer '%s' has no focusable equipment slot." % layer_id)


func _validate_actor_layer_kit() -> void:
	var parsed: Variant = _read_json(MARA_LAYERS_METADATA_PATH)
	if parsed is Dictionary:
		var metadata: Dictionary = parsed as Dictionary
		for field: String in ["asset_id", "authorship", "license", "review_status", "export_settings"]:
			if not metadata.has(field):
				_failures.append("Mara layer metadata is missing '%s'." % field)
		var export_settings: Variant = metadata.get("export_settings", {})
		if export_settings is Dictionary:
			_compare_layer_order(
				(export_settings as Dictionary).get("field_layer_order", []),
				ActorLayerIds.FIELD_LAYER_ORDER,
				"field"
			)
			_compare_layer_order(
				(export_settings as Dictionary).get("hair_style_ids", []),
				AppearanceCatalog.HAIR_STYLE_ORDER,
				"hair style"
			)
			var frame: Variant = (export_settings as Dictionary).get("frame", {})
			if frame is Dictionary:
				if int((frame as Dictionary).get("columns", 0)) != SpriteSheetPlayback.IDLE_FRAME_COUNT + SpriteSheetPlayback.WALK_FRAME_COUNT:
					_failures.append("Mara layer metadata must pack 4 idle columns and 8 walk columns.")
				if int((export_settings as Dictionary).get("idle_frames", 0)) != SpriteSheetPlayback.IDLE_FRAME_COUNT:
					_failures.append("Mara layer metadata idle_frames must be 4.")
				if int((export_settings as Dictionary).get("walk_frames", 0)) != SpriteSheetPlayback.WALK_FRAME_COUNT:
					_failures.append("Mara layer metadata walk_frames must be 8.")
	if not ResourceLoader.exists(MARA_LAYER_KIT_PATH):
		_failures.append("Actor layer kit is missing: %s" % MARA_LAYER_KIT_PATH)
		return
	var kit: ActorLayerKit = load(MARA_LAYER_KIT_PATH) as ActorLayerKit
	if kit == null:
		_failures.append("Actor layer kit could not be loaded.")
		return
	_failures.append_array(kit.validate_definition())


func _compare_layer_order(generated: Variant, expected: Array[StringName], label: String) -> void:
	if not generated is Array:
		_failures.append("Mara layer metadata is missing the %s layer order." % label)
		return
	var generated_ids: Array = generated as Array
	if generated_ids.size() != expected.size():
		_failures.append(
			"Generated %s layer order has %d layers; runtime expects %d." % [
				label,
				generated_ids.size(),
				expected.size(),
			]
		)
		return
	for index: int in expected.size():
		if StringName(generated_ids[index]) != expected[index]:
			_failures.append(
				"Generated %s layer %d is '%s'; runtime expects '%s'." % [
					label,
					index,
					generated_ids[index],
					expected[index],
				]
			)


func _validate_map_maker_isolation() -> void:
	if not ResourceLoader.exists(MAP_MAKER_SCENE_PATH, "PackedScene"):
		_failures.append("Map maker scene is missing: %s" % MAP_MAKER_SCENE_PATH)
	if not ResourceLoader.exists("res://tools/map_maker/map_maker_tooltip_catalog.tres"):
		_failures.append("Map maker tooltip catalog is missing.")
	else:
		var tooltip_catalog: MapMakerTooltipCatalog = load("res://tools/map_maker/map_maker_tooltip_catalog.tres") as MapMakerTooltipCatalog
		if tooltip_catalog == null:
			_failures.append("Map maker tooltip catalog could not be loaded.")
		else:
			_failures.append_array(tooltip_catalog.validate_definition())
	var title_source: String = FileAccess.get_file_as_string("res://src/ui/title_screen.gd")
	if not title_source.contains("map_maker_requested"):
		_failures.append("Title screen must expose a map maker action.")
	var app_source: String = FileAccess.get_file_as_string("res://src/presentation/app_shell.gd")
	if not app_source.contains("MAP_MAKER_SCENE_PATH"):
		_failures.append("App shell must launch the map maker scene from title.")
	var flow_source: String = FileAccess.get_file_as_string("res://src/services/game_flow.gd")
	if flow_source.contains("map_maker"):
		_failures.append("GameFlow must not own the map maker.")


func _validate_title_audio() -> void:
	if not ResourceLoader.exists(AUDIO_BUS_LAYOUT_PATH):
		_failures.append("Default audio bus layout is missing: %s" % AUDIO_BUS_LAYOUT_PATH)
	if not FileAccess.file_exists(TITLE_AUDIO_TOOL_PATH):
		_failures.append("Title audio generator is missing: %s" % TITLE_AUDIO_TOOL_PATH)
	var foley_source: String = FileAccess.get_file_as_string("res://src/audio/procedural_foley.gd")
	if foley_source.is_empty() or not foley_source.contains("karplus"):
		_failures.append("Title audio must be generated from original Karplus-Strong synthesis.")
	for audio_path: String in TITLE_AUDIO_PATHS:
		if not FileAccess.file_exists(audio_path):
			_failures.append("Title audio cue is missing: %s" % audio_path)
	var app_source: String = FileAccess.get_file_as_string("res://src/presentation/app_shell.gd")
	if not app_source.contains("set_menu_music_active"):
		_failures.append("App shell must start and stop title music with GameFlow state.")
	var flow_source: String = FileAccess.get_file_as_string("res://src/services/game_flow.gd")
	if flow_source.contains("TitleShellAudio") or flow_source.contains("AudioDirector"):
		_failures.append("GameFlow must not own title audio.")
	if str(ProjectSettings.get_setting("audio/buses/default_bus_layout", "")) != AUDIO_BUS_LAYOUT_PATH:
		_failures.append("project.godot must use the default audio bus layout.")


func _validate_brindlewick_placements(zone: Node, manifest: ZoneManifest) -> void:
	var placement_layer: PlacementLayer = zone.get_node_or_null("Geometry/PlacementLayer") as PlacementLayer
	if placement_layer == null:
		_failures.append("Brindlewick geometry must instance PlacementLayer for map-maker dress pieces.")
		return
	var catalog: WorldPieceCatalog = placement_layer.catalog
	var layout: ZonePlacementList = placement_layer.layout
	if catalog == null or catalog.resource_path != PIECE_CATALOG_PATH:
		_failures.append("Brindlewick PlacementLayer must reference the shared piece catalog.")
	if layout == null:
		_failures.append("Brindlewick PlacementLayer must reference its zone placement list.")
		return
	if layout.zone_id != manifest.id:
		_failures.append("Brindlewick placement list zone ID must match the zone manifest.")
	_failures.append_array(layout.validate_definition(catalog, manifest.validation_bounds))
	placement_layer.rebuild()
	if placement_layer.get_placed_count() != layout.placements.size():
		_failures.append("Brindlewick PlacementLayer must instance every authored placement.")
	if layout.placements.size() != 15:
		_failures.append("Brindlewick must author all 15 map-maker world pieces.")
	if not layout.has_piece(&"piece.bell_tower"):
		_failures.append("Brindlewick placement list must include the bell tower.")
	var crate: Node = placement_layer.find_child("cell_8_22", true, false)
	var lamp: Node = placement_layer.find_child("cell_-10_8", true, false)
	var planter: Node = placement_layer.find_child("cell_6_-8", true, false)
	if not crate is CrateBlock or not lamp is LampPost or not planter is PlanterBox:
		_failures.append("Brindlewick starter placements must include crate, lamp, and planter components.")
	if zone.find_child("BellTower", true, false) == null:
		_failures.append("Brindlewick bell tower component must remain discoverable after PlacementLayer rebuild.")


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_failures.append("Required JSON file is missing: %s" % path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("Required JSON file could not be opened: %s" % path)
		return null
	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	if parse_error != OK:
		_failures.append("JSON parse failed for %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _is_stable_id(value: String) -> bool:
	var pattern: RegEx = RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	return pattern.search(value) != null


func _install_input_router_for_scene_validation() -> void:
	if root.get_node_or_null("InputRouter") != null:
		return
	var router_script: Script = load("res://src/services/input_router.gd") as Script
	var router: Node = router_script.new() as Node
	router.name = "InputRouter"
	root.add_child(router)
