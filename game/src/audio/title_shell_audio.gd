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
	if not FileAccess.file_exists(path):
		push_warning("[AUDIO] Missing cue '%s'." % path)
		return null
	var loaded: Resource = load(path)
	if not loaded is AudioStreamWAV:
		push_warning("[AUDIO] Cue '%s' is not a WAV stream." % path)
		return null
	var wav: AudioStreamWAV = (loaded as AudioStreamWAV).duplicate() as AudioStreamWAV
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
	return wav
