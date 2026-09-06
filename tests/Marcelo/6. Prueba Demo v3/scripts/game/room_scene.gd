extends Node2D

## La casa, sus sectores, colisiones, objetos y UI viven en el .tscn.

@export_category("Preparativos")
@export var preparacion_de_viaje: TravelQuest
@export_range(0.0, 5.0, 0.1) var demora_dialogo_inicial := 0.55

@export_category("Audio de la casa")
@export_file("*.wav","*.ogg","*.mp3") var music_path := "res://assets/audio/music/room_theme.wav"
@export_file("*.wav","*.ogg","*.mp3") var ambience_path := "res://assets/audio/music/room_ambience.wav"
@export_range(0.5, 15.0, 0.1) var message_duration := 3.8

@onready var _player: EliasController = %Elias
@onready var _interactions_root: Node2D = %Interactions
@onready var _sectors_root: Node2D = %Sectors
@onready var _interaction_prompt: Control = %InteractionPrompt
@onready var _interaction_prompt_label: Label = %InteractionPromptLabel
@onready var _message_panel: Control = %MessagePanel
@onready var _message_label: Label = %MessageLabel
@onready var _location_label: Label = %LocationLabel
@onready var _sector_label: Label = %SectorLabel
@onready var _pause_hint: Label = %PauseHint
@onready var _inventory_ui: InventoryPanel = %InventoryInterface
@onready var _speech_bubble: WorldSpeechBubble = _player.get_node("SpeechBubble")

var _interactions: Array[InteractionPoint] = []
var _active_interaction: InteractionPoint
var _message_generation := 0
var _interface_locked := false


func _ready() -> void:
	get_tree().paused = false
	PauseManager.set_pause_enabled(true)
	Audio.play_music(music_path)
	Audio.play_ambience(ambience_path)
	_inventory_ui.configure(preparacion_de_viaje)
	_inventory_ui.open_changed.connect(_on_inventory_open_changed)
	_speech_bubble.finished.connect(_on_arrival_dialogue_finished)
	_prepare_interactions()
	_prepare_sectors()
	_fade_editorial_label(_location_label, 4.0, 1.2)
	_fade_editorial_label(_pause_hint, 5.5, 1.0)
	call_deferred("_begin_arrival_dialogue")


func _process(_delta: float) -> void:
	_update_nearest_interaction()
	if (
		not get_tree().paused
		and not _interface_locked
		and not _message_panel.visible
		and _active_interaction != null
		and Input.is_action_just_pressed("interact")
	):
		_handle_interaction(_active_interaction)


func _prepare_interactions() -> void:
	for child in _interactions_root.get_children():
		if child is InteractionPoint:
			var interaction := child as InteractionPoint
			_interactions.append(interaction)
			if (
				interaction.recoger_al_interactuar
				and interaction.objeto != null
				and Inventory.has_item(interaction.objeto)
			):
				interaction.mark_collected()


func _prepare_sectors() -> void:
	for child in _sectors_root.get_children():
		if child is RoomSector:
			var sector := child as RoomSector
			sector.body_entered.connect(_on_sector_entered.bind(sector))


func _begin_arrival_dialogue() -> void:
	if preparacion_de_viaje == null or preparacion_de_viaje.dialogo_al_llegar.is_empty():
		return
	_interface_locked = true
	_player.set_controls_enabled(false)
	_inventory_ui.input_enabled = false
	await get_tree().create_timer(demora_dialogo_inicial, false).timeout
	_speech_bubble.present(preparacion_de_viaje.dialogo_al_llegar)


func _on_arrival_dialogue_finished() -> void:
	_interface_locked = false
	_player.set_controls_enabled(true)
	_inventory_ui.input_enabled = true


func _on_inventory_open_changed(is_open: bool) -> void:
	_interface_locked = is_open
	if is_open:
		_interaction_prompt.hide()


func _update_nearest_interaction() -> void:
	if _interface_locked:
		_interaction_prompt.hide()
		_active_interaction = null
		return
	var nearest: InteractionPoint
	var nearest_distance := INF
	for interaction in _interactions:
		if interaction == null or not interaction.habilitado:
			continue
		var distance := _player.global_position.distance_to(interaction.global_position)
		if distance <= interaction.radio and distance < nearest_distance:
			nearest = interaction
			nearest_distance = distance
	_active_interaction = nearest
	if nearest == null or _message_panel.visible:
		_interaction_prompt.hide()
	else:
		_interaction_prompt_label.text = "E   ·   " + nearest.etiqueta
		_interaction_prompt.show()


func _handle_interaction(interaction: InteractionPoint) -> void:
	if interaction.recoger_al_interactuar and interaction.objeto != null:
		_collect_item(interaction)
		return
	if interaction.es_salida:
		_check_exit()
		return
	_show_message(interaction.mensaje)


func _collect_item(interaction: InteractionPoint) -> void:
	if not Inventory.add_item(interaction.objeto):
		_show_message("No queda espacio o ese objeto ya está en la mochila.")
		return
	interaction.mark_collected()
	_active_interaction = null
	_interaction_prompt.hide()
	Audio.play_sfx("res://assets/audio/sfx/ui_confirm.wav", -4.0, 1.08)
	var pickup_message := interaction.mensaje_al_recoger
	if pickup_message.is_empty():
		pickup_message = interaction.objeto.nombre + " se añadió al inventario."
	_show_message(pickup_message)


func _check_exit() -> void:
	if preparacion_de_viaje == null:
		_show_message("La salida continuará en la próxima escena.")
		return
	if Inventory.contains_all(preparacion_de_viaje.objetos_requeridos):
		_show_message(preparacion_de_viaje.mensaje_completado)
	else:
		_show_message(preparacion_de_viaje.mensaje_incompleto)


func _on_sector_entered(body: Node2D, sector: RoomSector) -> void:
	if body != _player:
		return
	_sector_label.text = sector.nombre.to_upper() + "  ·  " + sector.subtitulo.to_upper()
	_sector_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_sector_label, "modulate:a", 0.82, 0.2)
	tween.tween_interval(1.8)
	tween.tween_property(_sector_label, "modulate:a", 0.0, 0.7)


func _show_message(message: String) -> void:
	_message_generation += 1
	var local_generation := _message_generation
	Audio.play_sfx("res://assets/audio/sfx/ui_open.wav", -9.0)
	_message_label.text = message
	_message_panel.modulate.a = 0.0
	_message_panel.show()
	_interaction_prompt.hide()
	var tween := create_tween()
	tween.tween_property(_message_panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(message_duration)
	tween.tween_property(_message_panel, "modulate:a", 0.0, 0.28)
	await tween.finished
	if local_generation == _message_generation:
		_message_panel.hide()


func _fade_editorial_label(label: Label, delay: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(label, "modulate:a", 0.0, duration)
