extends Node

const METRICS_SCENE_PATH: String = "res://scenes/debug/metrics_scene.tscn"

@onready var _world_root: Node3D = %WorldRoot
@onready var _build_label: Label = %BuildLabel
@onready var _help_panel: PanelContainer = %HelpPanel
@onready var _error_panel: PanelContainer = %ErrorPanel
@onready var _error_label: Label = %ErrorLabel


func _ready() -> void:
	var build_version: String = str(ProjectSettings.get_setting("application/config/version", "unknown"))
	_build_label.text = "ASTERFOLD  •  %s\nM0 METRICS ROOM" % build_version
	_load_metrics_scene()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"menu"):
		_help_panel.visible = not _help_panel.visible
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed(&"cancel"):
		get_tree().quit()


func _load_metrics_scene() -> void:
	if not ResourceLoader.exists(METRICS_SCENE_PATH, "PackedScene"):
		_show_error("Required metrics scene is missing:\n%s" % METRICS_SCENE_PATH)
		return

	var packed_scene: PackedScene = load(METRICS_SCENE_PATH) as PackedScene
	if packed_scene == null:
		_show_error("The metrics scene could not be loaded.\nRun the headless import check for details.")
		return

	var metrics_scene: Node = packed_scene.instantiate()
	if not metrics_scene is Node3D:
		metrics_scene.queue_free()
		_show_error("The metrics scene root must inherit Node3D.")
		return

	_world_root.add_child(metrics_scene)


func _show_error(message: String) -> void:
	push_error("[FLOW] %s" % message.replace("\n", " "))
	_error_label.text = "ASTERFOLD COULD NOT START\n\n%s\n\nPress Esc or controller B to close." % message
	_error_panel.visible = true
	_help_panel.visible = false

