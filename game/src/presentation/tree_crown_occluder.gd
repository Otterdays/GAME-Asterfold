extends StaticBody3D

## Fades every crown mass of one tree when the camera ray hits it. The camera rig
## discovers occluders by collision layer 2 plus the `set_faded` method, so this
## component stays a sibling concept to the authored foreground occluders.

const FADE_SECONDS: float = 0.18

@export_range(0.1, 0.8, 0.05) var faded_opacity: float = 0.3

var _materials: Array[ShaderMaterial] = []
var _fade_tween: Tween


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0


func configure_crown_meshes(crown_meshes: Array[MeshInstance3D]) -> void:
	_materials.clear()
	for crown_mesh: MeshInstance3D in crown_meshes:
		if not crown_mesh.material_override is ShaderMaterial:
			push_error("[TREE] Crown occluder requires ShaderMaterial crowns.")
			continue
		var instance_material: ShaderMaterial = (crown_mesh.material_override as ShaderMaterial).duplicate() as ShaderMaterial
		instance_material.resource_local_to_scene = true
		crown_mesh.material_override = instance_material
		_materials.append(instance_material)


func set_faded(value: bool) -> void:
	if _materials.is_empty():
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	var target_opacity: float = faded_opacity if value else 1.0
	var current_opacity: float = float(_materials[0].get_shader_parameter(&"opacity"))
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_method(_set_opacity, current_opacity, target_opacity, FADE_SECONDS)


func _set_opacity(value: float) -> void:
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter(&"opacity", value)
