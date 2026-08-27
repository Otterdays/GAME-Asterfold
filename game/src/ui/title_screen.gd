extends Control

signal start_diorama_requested
signal metrics_requested
signal map_maker_requested
signal settings_requested
signal quit_requested
signal character_play_requested(slot_index: int)
signal roster_changed

@onready var _start_button: Button = %StartButton
@onready var _metrics_button: Button = %MetricsButton
@onready var _map_maker_button: Button = %MapMakerButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _version_label: Label = %VersionLabel
@onready var _start_status: Label = %StartStatus
@onready var _input_catcher: Control = %InputCatcher
@onready var _menu: Control = %Menu
@onready var _menu_plate: Control = %Plate
@onready var _character_select: Control = %CharacterSelectScreen
@onready var _character_create: Control = %CharacterCreateScreen

var _busy: bool = false
var _start_available: bool = true
var _start_unavailable_reason: String = ""
var _busy_reason: String = "Loading."
var _roster: CharacterRoster
var _compositor: SpriteLayerCompositor = SpriteLayerCompositor.new()
var _kit: ActorLayerKit
var _reduced_motion: bool = false


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_metrics_button.pressed.connect(_on_metrics_pressed)
	_map_maker_button.pressed.connect(_on_map_maker_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_input_catcher.gui_input.connect(_on_input_catcher_gui_input)
	_character_select.back_requested.connect(_show_menu)
	_character_select.create_requested.connect(_show_create)
	_character_select.play_requested.connect(_on_character_play_requested)
	_character_select.delete_requested.connect(_on_character_delete_requested)
	_character_create.cancel_requested.connect(_show_select)
	_character_create.created.connect(_on_character_created)


func configure_play(roster: CharacterRoster, kit: ActorLayerKit, reduced_motion: bool) -> void:
	_roster = roster
	_kit = kit
	_reduced_motion = reduced_motion
	if _kit != null:
		_compositor.configure(_kit)
	_character_select.configure(_roster, _compositor, _kit)
	_character_create.configure(_roster, _compositor, _kit)
	set_reduced_motion(reduced_motion)


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	_character_select.set_reduced_motion(reduced)
	_character_create.set_reduced_motion(reduced)


func configure_version(build_version: String) -> void:
	_version_label.text = "Development build %s  •  Godot 4.7.2" % build_version


func set_start_available(available: bool, reason: String = "") -> void:
	_start_available = available
	_start_unavailable_reason = reason
	_start_status.visible = not available
	_start_status.text = reason
	_apply_button_state()


func is_busy() -> bool:
	return _busy


## Covers the menu so a second click cannot land on Quit or fall through
## into the field once the hitch ends.
func set_busy(busy: bool, reason: String = "Loading.") -> void:
	_busy = busy
	if busy:
		_busy_reason = reason
		var viewport: Viewport = get_viewport()
		if viewport != null:
			var focus_owner: Control = viewport.gui_get_focus_owner()
			if focus_owner != null and is_ancestor_of(focus_owner):
				focus_owner.release_focus()
	_input_catcher.visible = busy
	_input_catcher.mouse_filter = Control.MOUSE_FILTER_STOP if busy else Control.MOUSE_FILTER_IGNORE
	_apply_button_state()


func show_screen() -> void:
	visible = true
	set_busy(false)
	_show_menu()


func hide_screen() -> void:
	visible = false
	_character_select.hide_screen()
	_character_create.hide_screen()


func apply_canvas_size(_canvas: Vector2i) -> void:
	pass


func _on_input_catcher_gui_input(_event: InputEvent) -> void:
	_input_catcher.accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy:
		return
	if event.is_action_pressed(&"cancel"):
		if _character_create.visible or _character_select.visible:
			return
		quit_requested.emit()
		get_viewport().set_input_as_handled()


func _apply_button_state() -> void:
	var interactive: bool = not _busy
	_start_button.disabled = (not interactive) or (not _start_available)
	_metrics_button.disabled = not interactive
	_map_maker_button.disabled = not interactive
	_settings_button.disabled = not interactive
	_quit_button.disabled = not interactive
	var tooltip: String = _busy_reason if _busy else _start_unavailable_reason
	_start_button.tooltip_text = tooltip
	_metrics_button.tooltip_text = _busy_reason if _busy else ""
	_map_maker_button.tooltip_text = _busy_reason if _busy else ""
	_settings_button.tooltip_text = _busy_reason if _busy else ""
	_quit_button.tooltip_text = _busy_reason if _busy else ""
	_character_select.set_busy(_busy, _busy_reason)
	_character_create.set_busy(_busy, _busy_reason)


func _show_menu() -> void:
	_menu_plate.visible = true
	_menu.visible = true
	_character_select.hide_screen()
	_character_create.hide_screen()
	var initial_focus: Button = _start_button if not _start_button.disabled else _metrics_button
	initial_focus.call_deferred(&"grab_focus")


func _show_select() -> void:
	if not _start_available:
		return
	_menu_plate.visible = false
	_character_create.hide_screen()
	_character_select.show_screen()


func _show_create() -> void:
	if _roster == null or _roster.first_empty_unlocked_slot() < 0:
		return
	_menu_plate.visible = false
	_character_select.hide_screen()
	_character_create.show_screen()


func _on_start_pressed() -> void:
	if _busy:
		return
	_show_select()


func _on_character_play_requested(slot_index: int) -> void:
	if _busy:
		return
	character_play_requested.emit(slot_index)


func _on_character_created(display_name: String, appearance: CharacterAppearance) -> void:
	if _roster == null:
		return
	var slot_index: int = _roster.first_empty_unlocked_slot()
	var result: Dictionary = _roster.create_in_slot(
		slot_index,
		display_name,
		appearance,
		int(Time.get_unix_time_from_system())
	)
	if not bool(result.get("ok", false)):
		return
	roster_changed.emit()
	_show_select()


func _on_character_delete_requested(slot_index: int) -> void:
	if _roster == null:
		return
	var errors: Array[String] = _roster.delete_slot(slot_index)
	if not errors.is_empty():
		return
	roster_changed.emit()
	_character_select.refresh()


func _on_metrics_pressed() -> void:
	if _busy:
		return
	metrics_requested.emit()


func _on_map_maker_pressed() -> void:
	if _busy:
		return
	map_maker_requested.emit()


func _on_settings_pressed() -> void:
	if _busy:
		return
	settings_requested.emit()


func _on_quit_pressed() -> void:
	if _busy:
		return
	quit_requested.emit()
