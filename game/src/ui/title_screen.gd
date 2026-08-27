extends Control

signal start_diorama_requested
signal metrics_requested
signal settings_requested
signal quit_requested

@onready var _start_button: Button = %StartButton
@onready var _metrics_button: Button = %MetricsButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _version_label: Label = %VersionLabel
@onready var _start_status: Label = %StartStatus


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_metrics_button.pressed.connect(_on_metrics_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func configure_version(build_version: String) -> void:
	_version_label.text = "Development build %s  •  Godot 4.7.2" % build_version


func set_start_available(available: bool, reason: String = "") -> void:
	_start_button.disabled = not available
	_start_status.visible = not available
	_start_status.text = reason
	_start_button.tooltip_text = reason


func show_screen() -> void:
	visible = true
	var initial_focus: Button = _start_button if not _start_button.disabled else _metrics_button
	initial_focus.call_deferred(&"grab_focus")


func hide_screen() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"cancel"):
		quit_requested.emit()
		get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	start_diorama_requested.emit()


func _on_metrics_pressed() -> void:
	metrics_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()

