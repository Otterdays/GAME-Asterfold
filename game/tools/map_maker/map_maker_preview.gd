class_name MapMakerPreview
extends Node3D

const GHOST_OVERLAY := Color(0.55, 0.92, 1.0, 0.38)
const HOVER_OVERLAY := Color(1.0, 0.82, 0.28, 0.32)
const DELETE_OVERLAY := Color(1.0, 0.28, 0.24, 0.42)

var _ghost: Node3D
var _ghost_piece_id: StringName = &""
var _hover_piece: Node3D
var _ghost_overlay: StandardMaterial3D
var _hover_overlay: StandardMaterial3D
var _delete_overlay: StandardMaterial3D
var _delete_mode: bool = false


func _ready() -> void:
	_ghost_overlay = _make_overlay(GHOST_OVERLAY)
	_hover_overlay = _make_overlay(HOVER_OVERLAY)
	_delete_overlay = _make_overlay(DELETE_OVERLAY)


## Hover highlight turns red while erasing so the click target reads as destructive.
func set_delete_mode(enabled: bool) -> void:
	if _delete_mode == enabled:
		return
	_delete_mode = enabled
	var piece: Node3D = _hover_piece
	clear_highlight()
	highlight_piece(piece)


func show_ghost(catalog: WorldPieceCatalog, piece_id: StringName, world_position: Vector3) -> void:
	if catalog == null or piece_id == &"":
		clear_ghost()
		return
	if _ghost == null or _ghost_piece_id != piece_id:
		_rebuild_ghost(catalog, piece_id)
	if _ghost == null:
		return
	_ghost.visible = true
	_ghost.global_position = world_position


func clear_ghost() -> void:
	if _ghost != null:
		_ghost.visible = false
	_ghost_piece_id = &""


func highlight_piece(piece: Node3D) -> void:
	if piece != null and not is_instance_valid(piece):
		piece = null
	if _hover_piece != null and not is_instance_valid(_hover_piece):
		_hover_piece = null
	if piece == _hover_piece:
		return
	clear_highlight()
	if piece == null:
		return
	_hover_piece = piece
	_apply_overlay(piece, _delete_overlay if _delete_mode else _hover_overlay)


func clear_highlight() -> void:
	if _hover_piece == null:
		return
	if is_instance_valid(_hover_piece):
		_apply_overlay(_hover_piece, null)
	_hover_piece = null


func _rebuild_ghost(catalog: WorldPieceCatalog, piece_id: StringName) -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	_ghost_piece_id = piece_id
	var packed_scene: PackedScene = catalog.get_scene(piece_id)
	if packed_scene == null:
		return
	var instance: Node = packed_scene.instantiate()
	if not instance is Node3D:
		instance.free()
		return
	_ghost = instance as Node3D
	_ghost.name = "Ghost"
	_ghost.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_ghost)
	var definition: WorldPieceDefinition = catalog.get_definition(piece_id)
	if definition != null and _ghost.has_method(&"apply_piece_definition"):
		_ghost.call(&"apply_piece_definition", definition)
	_disable_collision(_ghost)
	_apply_overlay(_ghost, _ghost_overlay)


func _disable_collision(root: Node) -> void:
	for node: Node in root.find_children("*", "CollisionObject3D", true, false):
		var body: CollisionObject3D = node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0


func _apply_overlay(root: Node, overlay: Material) -> void:
	for node: Node in root.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).material_overlay = overlay
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).material_overlay = overlay


func _make_overlay(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	return material
