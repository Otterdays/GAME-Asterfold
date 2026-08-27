extends StaticBody3D

@export var mesh_instance: MeshInstance3D
@export_range(0.1, 0.8, 0.05) var faded_opacity: float = 0.25

var _material: ShaderMaterial
var _fade_tween: Tween


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	if mesh_instance == null or not mesh_instance.material_override is ShaderMaterial:
		push_error("[FLOW] Foreground occluder requires a ShaderMaterial override.")
		return
	_material = (mesh_instance.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	mesh_instance.material_override = _material


func set_faded(value: bool) -> void:
	if _material == null:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	var target_opacity: float = faded_opacity if value else 1.0
	var current_opacity: float = float(_material.get_shader_parameter(&"opacity"))
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_method(_set_opacity, current_opacity, target_opacity, 0.18)


func _set_opacity(value: float) -> void:
	_material.set_shader_parameter(&"opacity", value)

