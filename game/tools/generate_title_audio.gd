extends SceneTree

## Writes the prototype title loop and UI transients. Original synthesis only.

const Foley := preload("res://src/audio/procedural_foley.gd")
const MUSIC_PATH: String = "res://assets/audio/music/title_fold_between.wav"
const HOVER_PATH: String = "res://assets/audio/ui/ui_hover_bling.wav"
const CLICK_PATH: String = "res://assets/audio/ui/ui_click.wav"


func _initialize() -> void:
	var music_error: Error = _write_wav(MUSIC_PATH, Foley.title_loop_samples())
	var hover_error: Error = _write_wav(HOVER_PATH, Foley.hover_bling_samples())
	var click_error: Error = _write_wav(CLICK_PATH, Foley.click_samples())
	if music_error != OK or hover_error != OK or click_error != OK:
		push_error("[AUDIO] Failed to write title audio.")
		quit(1)
		return
	print("[AUDIO] Wrote title loop and UI transients.")
	quit(0)


func _write_wav(path: String, samples: PackedFloat32Array) -> Error:
	var stream: AudioStreamWAV = Foley.make_wav_stream(samples)
	if path == MUSIC_PATH:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var directory: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		var make_error: Error = DirAccess.make_dir_recursive_absolute(directory)
		if make_error != OK:
			return make_error
	return stream.save_to_wav(absolute_path)
