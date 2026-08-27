class_name CameraPeekModel
extends RefCounted

const DEFAULT_HORIZONTAL_LIMIT_DEGREES: float = 24.0
const DEFAULT_VERTICAL_LIMIT_DEGREES: float = 8.0
const RECENTER_DELAY_SECONDS: float = 1.25
const FULL_RESPONSE_SPEED: float = 7.0
const REDUCED_RESPONSE_SPEED: float = 24.0
const INPUT_EPSILON: float = 0.08

var motion_mode: int = AccessibilitySettings.CameraMotionMode.FULL
var horizontal_limit_degrees: float = DEFAULT_HORIZONTAL_LIMIT_DEGREES
var vertical_limit_degrees: float = DEFAULT_VERTICAL_LIMIT_DEGREES
var target_degrees: Vector2 = Vector2.ZERO
var current_degrees: Vector2 = Vector2.ZERO
var idle_seconds: float = RECENTER_DELAY_SECONDS


func set_motion_mode(value: int) -> void:
	motion_mode = clampi(
		value,
		AccessibilitySettings.CameraMotionMode.FULL,
		AccessibilitySettings.CameraMotionMode.MINIMAL
	)
	if motion_mode == AccessibilitySettings.CameraMotionMode.MINIMAL:
		current_degrees = target_degrees


func set_limits(horizontal_degrees: float, vertical_degrees: float) -> void:
	horizontal_limit_degrees = clampf(horizontal_degrees, 0.0, DEFAULT_HORIZONTAL_LIMIT_DEGREES)
	vertical_limit_degrees = clampf(vertical_degrees, 0.0, DEFAULT_VERTICAL_LIMIT_DEGREES)
	target_degrees.x = clampf(target_degrees.x, -horizontal_limit_degrees, horizontal_limit_degrees)
	target_degrees.y = clampf(target_degrees.y, -vertical_limit_degrees, vertical_limit_degrees)


func reset() -> void:
	target_degrees = Vector2.ZERO
	current_degrees = Vector2.ZERO
	idle_seconds = RECENTER_DELAY_SECONDS


func advance(peek_input: Vector2, delta: float) -> Vector2:
	if peek_input.length() >= INPUT_EPSILON:
		idle_seconds = 0.0
		if motion_mode == AccessibilitySettings.CameraMotionMode.FULL:
			target_degrees = Vector2(
				clampf(peek_input.x, -1.0, 1.0) * horizontal_limit_degrees,
				-clampf(peek_input.y, -1.0, 1.0) * vertical_limit_degrees
			)
		else:
			target_degrees = Vector2(
				signf(peek_input.x) * horizontal_limit_degrees if absf(peek_input.x) >= 0.5 else 0.0,
				-signf(peek_input.y) * vertical_limit_degrees if absf(peek_input.y) >= 0.5 else 0.0
			)
	else:
		idle_seconds += delta
		if idle_seconds >= RECENTER_DELAY_SECONDS:
			target_degrees = Vector2.ZERO

	if motion_mode == AccessibilitySettings.CameraMotionMode.MINIMAL:
		current_degrees = target_degrees
	else:
		var response_speed: float = (
			REDUCED_RESPONSE_SPEED
			if motion_mode == AccessibilitySettings.CameraMotionMode.REDUCED
			else FULL_RESPONSE_SPEED
		)
		var weight: float = 1.0 - exp(-response_speed * delta)
		current_degrees = current_degrees.lerp(target_degrees, weight)
	return current_degrees
