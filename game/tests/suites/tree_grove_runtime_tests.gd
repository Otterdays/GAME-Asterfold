extends TestCase


func suite_name() -> String:
	return "tree_grove_runtime"


func run() -> void:
	var grove_scene: PackedScene = load("res://scenes/world/trees/brindlewick_tree_grove.tscn") as PackedScene
	_check(grove_scene != null, "Brindlewick tree grove scene loads.")
	if grove_scene == null:
		return
	var grove: TreeGrove3D = grove_scene.instantiate() as TreeGrove3D
	_check(grove != null, "Tree grove uses the reusable grove component.")
	if grove == null:
		return
	_check(grove.validate_configuration().is_empty(), "Tree grove configuration validates.")
	tree.root.add_child(grove)
	await tree.process_frame
	_check(grove.get_hero_count() == 6, "Grove builds every hero specimen as a full body.")
	_check(grove.get_batched_count() == 52, "Grove batches every belt placement.")
	_check(grove.get_multimesh_count() == 7, "Grove collapses batched species into seven MultiMesh draws.")
	var batched_trunks: StaticBody3D = grove.get_node_or_null("BatchedTrunks") as StaticBody3D
	_check(batched_trunks != null and batched_trunks.get_child_count() == 52, "Batched belt trees keep trunk collision.")

	var hero: TreeBody3D = null
	for child: Node in grove.get_children():
		if child is TreeBody3D:
			hero = child as TreeBody3D
			break
	_check(hero != null, "Hero specimens are TreeBody3D instances.")
	if hero != null:
		_check(hero.get_node_or_null("Trunk") is MeshInstance3D, "Hero tree owns a painted trunk mesh.")
		_check(hero.get_node_or_null("TrunkCollision/Collision") != null, "Hero tree collides on its trunk only.")
		_check(hero.get_crown_meshes().size() == 3, "Civic shade builds its three crown masses.")
		var occluder: Node = hero.get_node_or_null("CrownOccluder")
		_check(occluder != null and occluder.has_method(&"set_faded"), "Fade-crown species expose the camera occluder contract.")
		if occluder != null:
			_check(int(occluder.get("collision_layer")) == 2, "Crown occluders answer only the camera occlusion mask.")
			occluder.call(&"set_faded", true)

	var crown_material: ShaderMaterial = null
	if hero != null and not hero.get_crown_meshes().is_empty():
		crown_material = hero.get_crown_meshes()[0].material_override as ShaderMaterial
	_check(crown_material != null and crown_material.resource_local_to_scene, "Crown materials stay instance-local.")
	var reduced: AccessibilitySettings = AccessibilitySettings.new()
	reduced.set_camera_motion_mode(AccessibilitySettings.CameraMotionMode.REDUCED)
	grove.apply_accessibility_settings(reduced)
	_check(
		crown_material != null and is_zero_approx(float(crown_material.get_shader_parameter(&"sway_strength_m"))),
		"Reduced camera motion disables crown sway."
	)
	var full: AccessibilitySettings = AccessibilitySettings.new()
	grove.apply_accessibility_settings(full)
	_check(
		crown_material != null and float(crown_material.get_shader_parameter(&"sway_strength_m")) > 0.0,
		"Full camera motion restores authored crown sway."
	)
	grove.queue_free()
	await tree.process_frame
