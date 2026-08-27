class_name FirstPersonScout
extends Control

signal mouse_capture_changed(captured: bool)

enum Mode { IDLE, PICKING, LOOKING }

const MAP_CAMERA_HEIGHT_M: float = 90.0

@onready var _open_button: Button = %OpenButton
@onready var _picker: Control = %Picker
@onready var _instruction: Label = %Instruction
@onready var _map_host: SubViewportContainer = %MapHost
@onready var _map_viewport: SubViewport = %MapViewport
@onready var _map_camera: Camera3D = %MapCamera
@onready var _map_cursor: Control = %MapCursor
@onready var _crosshair: Control = %Crosshair
@onready var _leave_button: Button = %LeaveButton
@onready var _eye: Camera3D = %ScoutEye

var _mode: int = Mode.IDLE
var _world_viewport: SubViewport
var _bounds: AABB = AABB(Vector3(-34.0, -2.0, -29.0), Vector3(68.0, 24.0, 58.0))
var _look: FirstPersonLookModel = FirstPersonLookModel.new()
var _cursor_uv: Vector2 = Vector2(0.5, 0.5)
var _player: PlayerActor
var _camera_rig: WorldCameraRig


func _ready() -> void:
	visible = false
	_open_button.pressed.connect(open_picker)
	_leave_button.pressed.connect(exit_to_field)
	_map_host.gui_input.connect(_on_map_gui_input)
	_show_mode(Mode.IDLE)


func bind_world(world_viewport: SubViewport, zone: Node, manifest: ZoneManifest) -> void:
	_world_viewport = world_viewport
	if manifest != null:
		_bounds = manifest.validation_bounds
	_player = zone.get("player") as PlayerActor if zone != null else null
	_camera_rig = zone.get("camera_rig") as WorldCameraRig if zone != null else null
	_map_viewport.world_3d = world_viewport.world_3d
	_fit_map_camera()
	if not _eye.is_inside_tree() or _eye.get_parent() != world_viewport:
		if _eye.get_parent() != null:
			_eye.get_parent().remove_child(_eye)
		world_viewport.add_child(_eye)
	_eye.current = false


func set_hud_visible(field_active: bool) -> void:
	visible = field_active
	if not field_active:
		exit_to_field()


func is_picking() -> bool:
	return _mode == Mode.PICKING


func is_looking() -> bool:
	return _mode == Mode.LOOKING


func consumes_cancel() -> bool:
	return _mode != Mode.IDLE


func open_picker() -> void:
	if not visible:
		return
	_show_mode(Mode.PICKING)
	_cursor_uv = Vector2(0.5, 0.5)
	_update_map_cursor()
	if _player != null:
		_player.set_input_enabled(false)
	_open_button.release_focus()
	_map_host.grab_focus()
	mouse_capture_changed.emit(false)


func enter_at_world_xz(world_xz: Vector3) -> void:
	var point: Vector3 = FirstPersonLookModel.clamp_xz(world_xz, _bounds)
	var eye_position: Vector3 = _eye_position_at(point)
	_eye.global_position = eye_position
	_look.reset(0.0)
	_look.apply_to_camera(_eye)
	_eye.current = true
	if _camera_rig != null:
		_camera_rig.set_process(false)
		_camera_rig.set_process_input(false)
		var diorama_camera: Camera3D = _camera_rig.get_camera()
		if diorama_camera != null:
			diorama_camera.current = false
	if _player != null:
		_player.set_input_enabled(false)
		_player.visible = false
	_show_mode(Mode.LOOKING)
	mouse_capture_changed.emit(true)


func exit_to_field() -> void:
	_eye.current = false
	if _camera_rig != null:
		_camera_rig.set_process(true)
		_camera_rig.set_process_input(true)
		var diorama_camera: Camera3D = _camera_rig.get_camera()
		if diorama_camera != null:
			diorama_camera.current = true
	if _player != null:
		_player.visible = true
		_player.set_input_enabled(true)
	_show_mode(Mode.IDLE)
	if visible:
		_open_button.grab_focus()
		mouse_capture_changed.emit(true)
	else:
		mouse_capture_changed.emit(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"scout") and _mode == Mode.IDLE:
		open_picker()
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.PICKING and event.is_action_pressed(&"confirm"):
		enter_at_world_xz(FirstPersonLookModel.map_uv_to_world(_cursor_uv, _bounds))
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.LOOKING and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look.apply_mouse_delta((event as InputEventMouseMotion).relative)
		_look.apply_to_camera(_eye)


func _process(delta: float) -> void:
	if _mode == Mode.PICKING:
		var move: Vector2 = InputRouter.get_move_vector()
		if move.length_squared() > 0.0001:
			_cursor_uv.x = clampf(_cursor_uv.x + move.x * delta * 0.55, 0.0, 1.0)
			_cursor_uv.y = clampf(_cursor_uv.y + move.y * delta * 0.55, 0.0, 1.0)
			_update_map_cursor()
	elif _mode == Mode.LOOKING:
		_look.apply_stick(InputRouter.get_peek_vector(), delta)
		_look.apply_to_camera(_eye)


func _on_map_gui_input(event: InputEvent) -> void:
	if _mode != Mode.PICKING:
		return
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_cursor_uv = _uv_from_map_position(mouse_button.position)
			enter_at_world_xz(FirstPersonLookModel.map_uv_to_world(_cursor_uv, _bounds))
			accept_event()
	elif event is InputEventMouseMotion:
		_cursor_uv = _uv_from_map_position((event as InputEventMouseMotion).position)
		_update_map_cursor()


func _uv_from_map_position(local_position: Vector2) -> Vector2:
	var size: Vector2 = _map_host.size
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(0.5, 0.5)
	return Vector2(clampf(local_position.x / size.x, 0.0, 1.0), clampf(local_position.y / size.y, 0.0, 1.0))


func _update_map_cursor() -> void:
	var size: Vector2 = _map_host.size
	_map_cursor.position = Vector2(_cursor_uv.x * size.x - 6.0, _cursor_uv.y * size.y - 6.0)


func _fit_map_camera() -> void:
	var center: Vector3 = _bounds.position + _bounds.size * 0.5
	_map_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_map_camera.size = maxf(_bounds.size.x, _bounds.size.z) * 0.55
	_map_camera.position = Vector3(center.x, MAP_CAMERA_HEIGHT_M, center.z)
	_map_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_map_camera.current = true


func _eye_position_at(point: Vector3) -> Vector3:
	var fallback: Vector3 = Vector3(point.x, FirstPersonLookModel.EYE_HEIGHT_M, point.z)
	var world: World3D = null
	if _world_viewport != null:
		world = _world_viewport.world_3d
	if world == null and _player != null:
		world = _player.get_world_3d()
	if world == null:
		return fallback
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	if space == null:
		return fallback
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(point.x, 40.0, point.z),
		Vector3(point.x, -2.0, point.z),
		1
	)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.has("position"):
		var ground: Vector3 = hit["position"] as Vector3
		return Vector3(ground.x, ground.y + FirstPersonLookModel.EYE_HEIGHT_M, ground.z)
	return Vector3(point.x, FirstPersonLookModel.EYE_HEIGHT_M, point.z)


func _show_mode(mode: int) -> void:
	_mode = mode
	_open_button.visible = mode == Mode.IDLE
	_picker.visible = mode == Mode.PICKING
	_crosshair.visible = mode == Mode.LOOKING
	_leave_button.visible = mode == Mode.LOOKING
	_instruction.text = "Click a place on the map to look from there.\nMove the mark with the stick or WASD, then Confirm."
	if mode == Mode.LOOKING:
		_leave_button.grab_focus()
