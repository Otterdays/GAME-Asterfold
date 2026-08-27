class_name UiButtonFeedback
extends Node

## Hover lift plus UI bling/click. Visual highlight stays if audio is muted.
## Does not steal focus from keyboard/gamepad navigation.

const HOVER_MODULATE: Color = Color(1.22, 1.14, 0.78, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.035, 1.035)
const HOVER_COOLDOWN_MSEC: int = 70

@export var audio: Node
@export var scan_root: NodePath

var _wired: Dictionary[int, bool] = {}
var _last_hover_msec: int = 0


func _ready() -> void:
	call_deferred(&"rescan")


func rescan() -> void:
	var root: Node = get_node_or_null(scan_root)
	if root == null:
		root = get_parent()
	_wire_tree(root)


func _wire_tree(node: Node) -> void:
	if node is BaseButton:
		_wire_button(node as BaseButton)
	for child: Node in node.get_children():
		_wire_tree(child)


func _wire_button(button: BaseButton) -> void:
	var object_id: int = button.get_instance_id()
	if _wired.has(object_id):
		return
	_wired[object_id] = true
	if not button.has_meta(&"asterfold_base_modulate"):
		button.set_meta(&"asterfold_base_modulate", button.modulate)
		button.set_meta(&"asterfold_base_scale", button.scale)
		button.set_meta(&"asterfold_hovered", false)
	button.mouse_entered.connect(_on_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_mouse_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.tree_exiting.connect(_on_button_exiting.bind(button))


func _on_mouse_entered(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	_apply_highlight(button, true)
	var now_msec: int = Time.get_ticks_msec()
	if now_msec - _last_hover_msec < HOVER_COOLDOWN_MSEC:
		return
	_last_hover_msec = now_msec
	if audio != null and audio.has_method(&"play_hover"):
		audio.call(&"play_hover")


func _on_mouse_exited(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return
	_apply_highlight(button, false)


func _on_button_down(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	if audio != null and audio.has_method(&"play_click"):
		audio.call(&"play_click")


func _on_button_exiting(button: BaseButton) -> void:
	_wired.erase(button.get_instance_id())


func _apply_highlight(button: BaseButton, hovered: bool) -> void:
	button.set_meta(&"asterfold_hovered", hovered)
	var base_modulate: Color = button.get_meta(&"asterfold_base_modulate") as Color
	var base_scale: Vector2 = button.get_meta(&"asterfold_base_scale") as Vector2
	button.modulate = HOVER_MODULATE if hovered else base_modulate
	button.scale = HOVER_SCALE if hovered else base_scale
	button.pivot_offset = button.size * 0.5
