class_name MapMakerCamera
extends Camera3D

const MIN_DISTANCE: float = 12.0
const MAX_DISTANCE: float = 90.0
const PAN_SPEED_MPS: float = 18.0
const FOLLOW_SPEED: float = 10.0
const GROUND_PLANE := Plane(Vector3.UP, 0.0)
const DEFAULT_PIVOT: Vector3 = Vector3(0.0, 0.0, 8.0)
const DEFAULT_DISTANCE: float = 42.0
const DEFAULT_YAW: float = deg_to_rad(38.0)
const DEFAULT_PITCH: float = deg_to_rad(-40.0)

var pivot_position: Vector3 = DEFAULT_PIVOT
var distance: float = DEFAULT_DISTANCE
var yaw: float = DEFAULT_YAW
var pitch: float = DEFAULT_PITCH
var _orbiting: bool = false
var _session: MapMakerCameraSession = MapMakerCameraSession.new()
var _follow_snapped: bool = false


func _ready() -> void:
	current = true
	fov = 28.0
	near = 0.1
	far = 180.0
	restore_default_vision()


func apply_tool_settings(settings: MapMakerSettings) -> void:
	_session.configure(settings.follow_cursor, settings.idle_reset, settings.idle_reset_seconds)
	if settings.follow_cursor:
		_session.note_cursor_moved()
		_follow_cursor_immediately()
	else:
		_session.park()
		restore_default_vision()


func restore_default_vision() -> void:
	pivot_position = DEFAULT_PIVOT
	distance = DEFAULT_DISTANCE
	yaw = DEFAULT_YAW
	pitch = DEFAULT_PITCH
	_follow_snapped = false
	_apply_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_MIDDLE:
			_orbiting = mouse_button.pressed
			if _orbiting:
				_session.note_manual_camera()
			get_viewport().set_input_as_handled()
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_session.note_manual_camera()
			distance = clampf(distance - 4.0, MIN_DISTANCE, MAX_DISTANCE)
			_apply_transform()
			get_viewport().set_input_as_handled()
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_session.note_manual_camera()
			distance = clampf(distance + 4.0, MIN_DISTANCE, MAX_DISTANCE)
			_apply_transform()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if _orbiting:
			_session.note_manual_camera()
			yaw -= motion.relative.x * 0.006
			pitch = clampf(pitch - motion.relative.y * 0.006, deg_to_rad(-80.0), deg_to_rad(-12.0))
			_apply_transform()
			get_viewport().set_input_as_handled()
		elif motion.relative.length_squared() > 0.25:
			_session.note_cursor_moved()


func _process(delta: float) -> void:
	if _session.advance(delta):
		restore_default_vision()
	_apply_wasd_pan(delta)
	if _session.is_following():
		_follow_cursor(delta)


func _apply_wasd_pan(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_CTRL):
		return
	var pan: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		pan.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		pan.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		pan.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		pan.y += 1.0
	if pan == Vector2.ZERO:
		return
	_session.note_manual_camera()
	pan = pan.normalized()
	var speed: float = PAN_SPEED_MPS * (2.2 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
	var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
	pivot_position += (right * pan.x + forward * pan.y) * speed * delta
	_apply_transform()


func _follow_cursor_immediately() -> void:
	var hit: Variant = _ground_under_mouse()
	if hit == null:
		return
	pivot_position = hit as Vector3
	_follow_snapped = true
	_apply_transform()


func _follow_cursor(delta: float) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		return
	var hit: Variant = _ground_under_mouse()
	if hit == null:
		return
	var target_pivot: Vector3 = hit as Vector3
	if not _follow_snapped:
		pivot_position = target_pivot
		_follow_snapped = true
	else:
		var weight: float = 1.0 - exp(-FOLLOW_SPEED * delta)
		pivot_position = pivot_position.lerp(target_pivot, weight)
	_apply_transform()


func _ground_under_mouse() -> Variant:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = project_ray_origin(mouse_position)
	var direction: Vector3 = project_ray_normal(mouse_position)
	return GROUND_PLANE.intersects_ray(origin, direction)


func _apply_transform() -> void:
	var offset: Vector3 = Vector3(
		sin(yaw) * cos(pitch),
		-sin(pitch),
		cos(yaw) * cos(pitch)
	) * distance
	global_position = pivot_position + Vector3(0.0, 1.2, 0.0) + offset
	look_at(pivot_position + Vector3(0.0, 1.2, 0.0), Vector3.UP)
