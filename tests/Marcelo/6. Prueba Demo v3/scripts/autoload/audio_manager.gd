extends Node

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _current_music := ""
var _current_ambience := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = _make_player("MusicPlayer", "Music")
	_ambience_player = _make_player("AmbiencePlayer", "Ambience")
	_music_player.finished.connect(_on_music_finished)
	_ambience_player.finished.connect(_on_ambience_finished)


func _make_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player


func play_music(path: String, restart := false) -> void:
	if path.is_empty():
		stop_music()
		return
	if _current_music == path and _music_player.playing and not restart:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("No se pudo cargar la música: " + path)
		return
	_current_music = path
	_music_player.stream = stream
	_music_player.play()


func play_ambience(path: String, restart := false) -> void:
	if path.is_empty():
		stop_ambience()
		return
	if _current_ambience == path and _ambience_player.playing and not restart:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("No se pudo cargar el ambiente: " + path)
		return
	_current_ambience = path
	_ambience_player.stream = stream
	_ambience_player.play()


func play_sfx(path: String, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.finished.connect(_free_sfx_player.bind(player))
	player.play()


func stop_music() -> void:
	_current_music = ""
	_music_player.stop()


func stop_ambience() -> void:
	_current_ambience = ""
	_ambience_player.stop()


func _on_music_finished() -> void:
	if not _current_music.is_empty():
		_music_player.play()


func _on_ambience_finished() -> void:
	if not _current_ambience.is_empty():
		_ambience_player.play()


func _free_sfx_player(player: AudioStreamPlayer) -> void:
	player.queue_free()
