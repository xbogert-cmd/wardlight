extends Node
## Sound effect and music playback. Sounds live in res://assets/audio/sfx/<name>.wav.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"  # music .import files set loop_mode=2 (forward)
const POOL := 16

var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)


func _stream(dir: String, sound: String) -> AudioStream:
	var key := dir + sound
	if not _cache.has(key):
		var path := dir + sound + ".wav"
		_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _cache[key]


func play(sound: String, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	var s := _stream(SFX_DIR, sound)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func music(track: String) -> void:
	if track == _music_name:
		return
	_music_name = track
	var s := _stream(MUSIC_DIR, track)
	if s == null:
		_music.stop()
		return
	_music.stream = s
	_music.play()
