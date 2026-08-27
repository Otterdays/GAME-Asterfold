extends Node

const OUTPUT_PATH: String = "res://builds/performance/m1_soak.json"
const DEFAULT_DURATION_SECONDS: float = 600.0
const WARMUP_SECONDS: float = 3.0
const ROUTE_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_forward",
	&"move_right",
	&"move_back",
	&"move_left",
]
const ROUTE_SEGMENT_SECONDS: Array[float] = [6.25, 10.0, 12.5, 10.0, 6.25]

@onready var _app: Node = %App


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var duration_seconds: float = _get_duration_seconds()
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_app.call(&"_start_diorama")
	for frame: int in 30:
		await get_tree().process_frame
	var gameplay_hud: Control = _app.find_child("GameplayHUD", true, false) as Control
	if gameplay_hud != null:
		gameplay_hud.visible = false
	var world_viewport: SubViewport = _app.find_child("WorldViewport", true, false) as SubViewport
	var root_rid: RID = get_viewport().get_viewport_rid()
	var world_rid: RID = world_viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(root_rid, true)
	RenderingServer.viewport_set_measure_render_time(world_rid, true)
	await _wait_seconds(WARMUP_SECONDS)

	var frame_samples: Array[float] = []
	var cpu_samples: Array[float] = []
	var gpu_samples: Array[float] = []
	var draw_call_samples: Array[float] = []
	var start_usec: int = Time.get_ticks_usec()
	var previous_usec: int = start_usec
	var next_progress_seconds: float = 60.0
	var active_route_action: StringName = &""
	var active_peek_action: StringName = &""

	while float(Time.get_ticks_usec() - start_usec) / 1000000.0 < duration_seconds:
		var elapsed_seconds: float = float(Time.get_ticks_usec() - start_usec) / 1000000.0
		var route_action: StringName = _route_action_at(elapsed_seconds)
		if route_action != active_route_action:
			if not active_route_action.is_empty():
				Input.action_release(active_route_action)
			active_route_action = route_action
			Input.action_press(active_route_action, 1.0)
		var peek_action: StringName = &"peek_right" if int(elapsed_seconds / 4.0) % 2 == 0 else &"peek_left"
		if peek_action != active_peek_action:
			if not active_peek_action.is_empty():
				Input.action_release(active_peek_action)
			active_peek_action = peek_action
			Input.action_press(active_peek_action, 0.7)

		await get_tree().process_frame
		var now_usec: int = Time.get_ticks_usec()
		frame_samples.append(float(now_usec - previous_usec) / 1000.0)
		previous_usec = now_usec
		cpu_samples.append(
			RenderingServer.get_frame_setup_time_cpu()
			+ RenderingServer.viewport_get_measured_render_time_cpu(root_rid)
			+ RenderingServer.viewport_get_measured_render_time_cpu(world_rid)
		)
		gpu_samples.append(
			RenderingServer.viewport_get_measured_render_time_gpu(root_rid)
			+ RenderingServer.viewport_get_measured_render_time_gpu(world_rid)
		)
		draw_call_samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if elapsed_seconds >= next_progress_seconds:
			print("[SOAK] %.0f / %.0f seconds" % [elapsed_seconds, duration_seconds])
			next_progress_seconds += 60.0

	if not active_route_action.is_empty():
		Input.action_release(active_route_action)
	if not active_peek_action.is_empty():
		Input.action_release(active_peek_action)
	RenderingServer.viewport_set_measure_render_time(root_rid, false)
	RenderingServer.viewport_set_measure_render_time(world_rid, false)
	_write_report(duration_seconds, frame_samples, cpu_samples, gpu_samples, draw_call_samples)
	get_tree().quit(0)


func _route_action_at(elapsed_seconds: float) -> StringName:
	var route_duration: float = 0.0
	for duration: float in ROUTE_SEGMENT_SECONDS:
		route_duration += duration
	var route_time: float = fmod(elapsed_seconds, route_duration)
	var accumulated: float = 0.0
	for index: int in ROUTE_SEGMENT_SECONDS.size():
		accumulated += ROUTE_SEGMENT_SECONDS[index]
		if route_time < accumulated:
			return ROUTE_ACTIONS[index]
	return ROUTE_ACTIONS[0]


func _wait_seconds(seconds: float) -> void:
	var start_usec: int = Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - start_usec) / 1000000.0 < seconds:
		await get_tree().process_frame


func _get_duration_seconds() -> float:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--soak-seconds="):
			return maxf(float(argument.get_slice("=", 1)), 1.0)
	return DEFAULT_DURATION_SECONDS


func _write_report(
	duration_seconds: float,
	frame_samples: Array[float],
	cpu_samples: Array[float],
	gpu_samples: Array[float],
	draw_call_samples: Array[float]
) -> void:
	var cpu: Dictionary = _percentiles(cpu_samples)
	var gpu: Dictionary = _percentiles(gpu_samples)
	var frame: Dictionary = _percentiles(frame_samples)
	var draw_calls: Dictionary = _percentiles(draw_call_samples)
	var passed: bool = (
		float(cpu.get("p50", INF)) <= 12.0
		and float(cpu.get("p99", INF)) <= 16.6
		and float(gpu.get("p50", INF)) <= 12.0
		and float(draw_calls.get("max", INF)) <= 500.0
	)
	var report: Dictionary = {
		"build": ProjectSettings.get_setting("application/config/version", "unknown"),
		"engine": Engine.get_version_info().get("string", "unknown"),
		"renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"cpu": OS.get_processor_name(),
		"internal_resolution": [1920, 1080],
		"output_resolution": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"duration_seconds": duration_seconds,
		"sample_count": frame_samples.size(),
		"route": "zone.brindlewick_square south outer loop",
		"settings": {"camera_motion": "full", "text_scale": 1.0},
		"frame_ms": frame,
		"cpu_ms": cpu,
		"gpu_ms": gpu,
		"draw_calls": draw_calls,
		"targets": {"cpu_typical_ms": 12.0, "cpu_p99_ms": 16.6, "gpu_typical_ms": 12.0, "draw_calls": 500},
		"passed": passed,
	}
	var output_path: String = ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("[SOAK] Could not write performance report.")
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("[SOAK] PASS=%s CPU p99=%.3f ms GPU p99=%.3f ms draw calls max=%d" % [
		passed,
		float(cpu.get("p99", 0.0)),
		float(gpu.get("p99", 0.0)),
		roundi(float(draw_calls.get("max", 0.0))),
	])


func _percentiles(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {"p50": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0}
	var sorted: Array[float] = samples.duplicate()
	sorted.sort()
	return {
		"p50": sorted[mini(floori(float(sorted.size() - 1) * 0.50), sorted.size() - 1)],
		"p95": sorted[mini(floori(float(sorted.size() - 1) * 0.95), sorted.size() - 1)],
		"p99": sorted[mini(floori(float(sorted.size() - 1) * 0.99), sorted.size() - 1)],
		"max": sorted[-1],
	}
