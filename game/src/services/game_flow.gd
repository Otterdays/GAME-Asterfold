extends Node

signal state_changed(previous_state: int, current_state: int)
signal active_world_changed(active_world: Node)
signal flow_failed(message: String)

enum FlowState {
	BOOT,
	TITLE,
	FIELD,
	DEBUG,
}

var state: int = FlowState.BOOT
var _world_host: Node3D
var _active_world: Node


func bind_world_host(world_host: Node3D) -> void:
	_world_host = world_host


func show_title() -> void:
	_clear_active_world()
	_set_state(FlowState.TITLE)


func load_zone(zone_id: StringName, spawn_id: StringName) -> bool:
	if _world_host == null:
		return _fail("World host is not configured.")
	var manifest: ZoneManifest = ContentDB.get_zone(zone_id)
	if manifest == null:
		return _fail("Required zone '%s' is not registered." % zone_id)
	if not manifest.spawn_ids.has(spawn_id):
		return _fail("Zone '%s' does not declare spawn '%s'." % [zone_id, spawn_id])
	if manifest.scene == null:
		return _fail("Zone '%s' has no loadable scene." % zone_id)

	_clear_active_world()
	var instance: Node = manifest.scene.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return _fail("Zone '%s' entry scene must inherit Node3D." % zone_id)

	_world_host.add_child(instance)
	if instance.has_method(&"configure_zone"):
		var configured: Variant = instance.call(&"configure_zone", manifest, spawn_id)
		if configured is bool and not bool(configured):
			_world_host.remove_child(instance)
			instance.queue_free()
			return _fail("Zone '%s' rejected its configuration." % zone_id)

	_active_world = instance
	active_world_changed.emit(_active_world)
	_set_state(FlowState.FIELD)
	return true


func load_debug_scene(scene_path: String) -> bool:
	if _world_host == null:
		return _fail("World host is not configured.")
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		return _fail("Debug scene is missing: %s" % scene_path)
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		return _fail("Debug scene could not be loaded: %s" % scene_path)
	var instance: Node = packed_scene.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return _fail("Debug scene root must inherit Node3D: %s" % scene_path)
	_clear_active_world()
	_world_host.add_child(instance)
	_active_world = instance
	active_world_changed.emit(_active_world)
	_set_state(FlowState.DEBUG)
	return true


func get_active_world() -> Node:
	return _active_world


func _clear_active_world() -> void:
	if _active_world == null:
		return
	if is_instance_valid(_active_world):
		if _active_world.get_parent() == _world_host:
			_world_host.remove_child(_active_world)
		_active_world.queue_free()
	_active_world = null
	active_world_changed.emit(null)


func _set_state(next_state: int) -> void:
	if state == next_state:
		return
	var previous_state: int = state
	state = next_state
	state_changed.emit(previous_state, state)


func _fail(message: String) -> bool:
	push_warning("[FLOW] %s" % message)
	flow_failed.emit(message)
	return false
