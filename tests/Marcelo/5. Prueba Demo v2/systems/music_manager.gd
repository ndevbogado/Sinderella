extends Node

## Música persistente entre escenas con fundido cruzado.
## Las pistas y los volúmenes se cambian desde systems/music_manager.tscn.

@export_category("Pistas por escena")
@export var cinematica_inicial: AudioStream
@export var bosque_persecucion: AudioStream
@export var combate: AudioStream
@export var cinematica_derrota: AudioStream
@export var cinematica_victoria: AudioStream

@export_category("Mezcla")
@export_range(-40.0, 6.0, 0.5) var volumen_general_db: float = -5.0
@export_range(0.0, 4.0, 0.05) var duracion_fundido: float = 0.85
@export_range(0.05, 1.0, 0.05) var intervalo_deteccion: float = 0.20

var _active_index: int = 0
var _last_scene_path: String = ""
var _poll_time: float = 0.0
var _fade_tween: Tween

@onready var _players: Array[AudioStreamPlayer] = [$PlayerA, $PlayerB]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_players[0].finished.connect(_on_player_finished.bind(0))
	_players[1].finished.connect(_on_player_finished.bind(1))
	call_deferred("_refresh_scene_music")


func _process(delta: float) -> void:
	_poll_time += delta
	if _poll_time < intervalo_deteccion:
		return
	_poll_time = 0.0
	_refresh_scene_music()


func _refresh_scene_music() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var scene_path: String = current_scene.scene_file_path
	if scene_path == _last_scene_path:
		return
	_last_scene_path = scene_path
	var desired_stream: AudioStream = _stream_for_scene(scene_path)
	if desired_stream == null:
		return
	if _players[_active_index].stream == desired_stream and _players[_active_index].playing:
		return
	_crossfade_to(desired_stream)


func _stream_for_scene(scene_path: String) -> AudioStream:
	match scene_path:
		"res://main.tscn":
			return cinematica_inicial
		"res://scenes/forest_gameplay.tscn":
			return bosque_persecucion
		"res://scenes/battle_arena.tscn":
			return combate
		"res://scenes/defeat_cutscene.tscn":
			return cinematica_derrota
		"res://scenes/victory_cutscene.tscn":
			return cinematica_victoria
		"res://scenes/end_screen.tscn":
			if BattleState.battle_result == "victory":
				return cinematica_victoria
			return cinematica_derrota
	return null


func _crossfade_to(new_stream: AudioStream) -> void:
	if new_stream == null:
		return
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	var old_index: int = _active_index
	var next_index: int = 1 - _active_index
	var old_player: AudioStreamPlayer = _players[old_index]
	var next_player: AudioStreamPlayer = _players[next_index]
	next_player.stop()
	next_player.stream = new_stream
	next_player.volume_db = -45.0
	next_player.play()
	_active_index = next_index

	if duracion_fundido <= 0.0:
		old_player.stop()
		next_player.volume_db = volumen_general_db
		return

	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(next_player, "volume_db", volumen_general_db, duracion_fundido)
	if old_player.playing:
		_fade_tween.tween_property(old_player, "volume_db", -45.0, duracion_fundido)
	_fade_tween.finished.connect(Callable(old_player, "stop"))


func _on_player_finished(player_index: int) -> void:
	# Reinicio manual: no depende de que la opción Loop del importador esté activa.
	if player_index == _active_index and _players[player_index].stream != null:
		_players[player_index].play()


func set_music_volume_db(value: float) -> void:
	volumen_general_db = clampf(value, -40.0, 6.0)
	_players[_active_index].volume_db = volumen_general_db


func stop_music(fade_seconds: float = 0.5) -> void:
	var player: AudioStreamPlayer = _players[_active_index]
	if not player.playing:
		return
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", -45.0, maxf(0.0, fade_seconds))
	_fade_tween.finished.connect(Callable(player, "stop"))
