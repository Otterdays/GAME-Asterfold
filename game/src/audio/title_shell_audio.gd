extends Node

## Title music and UI cue players. Scene-owned; not an AudioDirector autoload.

const MUSIC_PATH: String = "res://assets/audio/music/title_fold_between.wav"
const HOVER_PATH: String = "res://assets/audio/ui/ui_hover_bling.wav"
const CLICK_PATH: String = "res://assets/audio/ui/ui_click.wav"
const MUSIC_FADE_S: float = 0.45
const MUSIC_VOLUME_DB: float = -9.0

@onready var _music: AudioStreamPlayer = %MusicPlayer
@onready var _hover: AudioStreamPlayer = %HoverPlayer
@onready var _click: AudioStreamPlayer = %ClickPlayer

var _menu_active: bool = false
var _fade: Tween


func _ready() -> void:
	_music.bus = "Music"
	_hover.bus = "UI"
	_click.bus = "UI"
	_music.stream = _load_wav(MUSIC_PATH, true)
	_hover.stream = _load_wav(HOVER_PATH, false)
	_click.stream = _load_wav(CLICK_PATH, false)
	set_menu_music_active(true)


func set_menu_music_active(active: bool) -> void:
	_menu_active = active
	if _fade != null:
		_fade.kill()
	if _music.stream == null:
		return
	if active:
		if not _music.playing:
			_music.volume_db = -48.0
			_music.play()
		_fade = create_tween()
		_fade.tween_property(_music, "volume_db", MUSIC_VOLUME_DB, MUSIC_FADE_S)
	elif _music.playing:
		_fade = create_tween()
		_fade.tween_property(_music, "volume_db", -48.0, MUSIC_FADE_S)
		_fade.tween_callback(_music.stop)


func play_hover() -> void:
	if _hover.stream == null:
		return
	if _hover.playing:
		_hover.stop()
	_hover.play()


func play_click() -> void:
	if _click.stream == null:
		return
	if _click.playing:
		_click.stop()
	_click.play()


func is_menu_music_active() -> bool:
	return _menu_active


func _load_wav(path: String, loop: bool) -> AudioStreamWAV:
	var wav: AudioStreamWAV = null
	if FileAccess.file_exists(path):
		var loaded: Resource = load(path)
		if loaded is AudioStreamWAV:
			wav = (loaded as AudioStreamWAV).duplicate() as AudioStreamWAV
	if wav == null:
		wav = _synthesize_fallback(path)
	if wav == null:
		push_warning("[AUDIO] Missing cue '%s'." % path)
		return null
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
	return wav


func _synthesize_fallback(path: String) -> AudioStreamWAV:
	var samples: PackedFloat32Array
	match path:
		MUSIC_PATH:
			samples = ProceduralFoley.title_loop_samples()
		HOVER_PATH:
			samples = ProceduralFoley.hover_bling_samples()
		CLICK_PATH:
			samples = ProceduralFoley.click_samples()
		_:
			return null
	return ProceduralFoley.make_wav_stream(samples)
