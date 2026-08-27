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
]
const ASSET_MANIFEST_PATH: String = "res://assets/asset_manifest.json"
const CONTENT_REGISTRY_PATH: String = "res://content/content_registry.tres"
const MARA_SOURCE_METADATA_PATH: String = "res://art_source/characters/mara/mara_prototype.source.json"
const GRASS_SURFACE_SCENE_PATH: String = "res://scenes/world/surfaces/brindlewick_grass_surface.tscn"
const DIRT_ROAD_SURFACE_SCENE_PATH: String = "res://scenes/world/surfaces/brindlewick_dirt_road_surface.tscn"
const GRASS_MATERIAL_PATH: String = "res://assets/materials/environment/grass_surface_material.tres"
const DIRT_ROAD_MATERIAL_PATH: String = "res://assets/materials/environment/dirt_road_surface_material.tres"
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
	if zone.find_child("BellTower", true, false) == null:
		_failures.append("Zone '%s' is missing its bell-tower landmark." % manifest.id)
	if manifest.id == &"zone.brindlewick_square":
		_validate_brindlewick_surfaces(zone)
	var foreground: Node = zone.get_node_or_null("Presentation/Foreground")
	if foreground == null or foreground.get_child_count() < manifest.foreground_occluder_ids.size():
		_failures.append("Zone '%s' is missing declared foreground occluders." % manifest.id)
	zone.free()


func _validate_brindlewick_surfaces(zone: Node) -> void:
	for scene_path: String in [GRASS_SURFACE_SCENE_PATH, DIRT_ROAD_SURFACE_SCENE_PATH]:
		if not ResourceLoader.exists(scene_path):
			_failures.append("Brindlewick surface scene is missing: %s" % scene_path)
	var grass_surface: Node = zone.get_node_or_null("Geometry/GrassSurface")
	if grass_surface == null or grass_surface.get_node_or_null("Ground/Collision") == null:
		_failures.append("Brindlewick grass surface must own the canonical ground and collision.")
	var dirt_road_surface: Node = zone.get_node_or_null("Geometry/DirtRoadSurface")
	if dirt_road_surface == null or dirt_road_surface.get_child_count() < 6:
		_failures.append("Brindlewick dirt-road surface must contain all six authored route pieces.")
	var grass_material: ShaderMaterial = load(GRASS_MATERIAL_PATH) as ShaderMaterial
	var dirt_road_material: ShaderMaterial = load(DIRT_ROAD_MATERIAL_PATH) as ShaderMaterial
	if grass_material == null or grass_material.shader == null:
		_failures.append("Brindlewick grass surface requires its external shader material.")
	if dirt_road_material == null or dirt_road_material.shader == null:
		_failures.append("Brindlewick dirt-road surface requires its external shader material.")
	if grass_material != null and dirt_road_material != null and grass_material.shader == dirt_road_material.shader:
		_failures.append("Grass and dirt road must remain independently owned shader families.")


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
