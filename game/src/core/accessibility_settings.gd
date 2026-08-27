class_name AccessibilitySettings
extends RefCounted

signal changed

enum CameraMotionMode {
	FULL,
	REDUCED,
	MINIMAL,
}

enum PresentationQuality {
	LOW,
	MEDIUM,
	HIGH,
}

const TEXT_SCALES: Array[float] = [1.0, 1.25, 1.5]
const CANVAS_LOW: Vector2i = Vector2i(640, 360)
const CANVAS_MEDIUM: Vector2i = Vector2i(1280, 720)
const CANVAS_HIGH: Vector2i = Vector2i(1920, 1080)

var camera_motion_mode: int = CameraMotionMode.FULL
var presentation_quality: int = PresentationQuality.HIGH
var text_scale: float = 1.0
var confirm_cancel_swapped: bool = false


func set_camera_motion_mode(value: int) -> void:
	var clamped_value: int = clampi(value, CameraMotionMode.FULL, CameraMotionMode.MINIMAL)
	if camera_motion_mode == clamped_value:
		return
	camera_motion_mode = clamped_value
	changed.emit()


func set_presentation_quality(value: int) -> void:
	var clamped_value: int = clampi(value, PresentationQuality.LOW, PresentationQuality.HIGH)
	if presentation_quality == clamped_value:
		return
	presentation_quality = clamped_value
	changed.emit()


func canvas_size() -> Vector2i:
	return canvas_size_for(presentation_quality)


static func canvas_size_for(quality: int) -> Vector2i:
	match clampi(quality, PresentationQuality.LOW, PresentationQuality.HIGH):
		PresentationQuality.LOW:
			return CANVAS_LOW
		PresentationQuality.MEDIUM:
			return CANVAS_MEDIUM
		_:
			return CANVAS_HIGH


func set_text_scale(value: float) -> void:
	var closest: float = TEXT_SCALES[0]
	for supported_scale: float in TEXT_SCALES:
		if absf(supported_scale - value) < absf(closest - value):
			closest = supported_scale
	if is_equal_approx(text_scale, closest):
		return
	text_scale = closest
	changed.emit()


func set_confirm_cancel_swapped(value: bool) -> void:
	if confirm_cancel_swapped == value:
		return
	confirm_cancel_swapped = value
	changed.emit()


func to_dictionary() -> Dictionary:
	return {
		"camera_motion_mode": camera_motion_mode,
		"presentation_quality": presentation_quality,
		"text_scale": text_scale,
		"confirm_cancel_swapped": confirm_cancel_swapped,
	}


func apply_dictionary(data: Dictionary) -> void:
	camera_motion_mode = clampi(
		int(data.get("camera_motion_mode", CameraMotionMode.FULL)),
		CameraMotionMode.FULL,
		CameraMotionMode.MINIMAL
	)
	set_presentation_quality(int(data.get("presentation_quality", PresentationQuality.HIGH)))
	set_text_scale(float(data.get("text_scale", 1.0)))
	confirm_cancel_swapped = bool(data.get("confirm_cancel_swapped", false))
	changed.emit()


static func motion_mode_label(mode: int) -> String:
	match mode:
		CameraMotionMode.REDUCED:
			return "Reduced"
		CameraMotionMode.MINIMAL:
			return "Minimal"
		_:
			return "Full"


static func presentation_quality_label(quality: int) -> String:
	match quality:
		PresentationQuality.LOW:
			return "Low (640x360)"
		PresentationQuality.MEDIUM:
			return "Medium (1280x720)"
		_:
			return "High (1920x1080)"
