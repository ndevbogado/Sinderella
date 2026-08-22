extends Control

@export_category("Configuración central")
@export var combat_settings: CombatSettings

@export_category("Arte — Cenicienta")
@export var cinderella_portrait: Texture2D
@export var cinderella_battle_texture: Texture2D

@export_category("Arte — Caperucita")
@export var caperucita_portrait: Texture2D
@export var caperucita_battle_texture: Texture2D

@export_category("Escenas posteriores")
@export_file("*.tscn") var victory_cutscene := "res://scenes/victory_cutscene.tscn"
@export_file("*.tscn") var defeat_cutscene := "res://scenes/defeat_cutscene.tscn"

var cinderella_max_health: float = 120.0
var cinderella_attack: float = 25.0
var cinderella_defense: float = 50.0
var caperucita_max_health: float = 360.0
var caperucita_attack: float = 100.0
var caperucita_defense: float = 25.0
var reduction_per_letter: float = 0.125
var preparation_hold_duration: float = 1.2
var preparation_fade_duration: float = 0.15

var _cinderella_health := 0.0
var _caperucita_health := 0.0
var _battle_finished := false

@onready var _message: Label = %BattleMessage
@onready var _preparation_popup: PanelContainer = %PreparationPopup
@onready var _preparation_label: Label = %PreparationLabel
@onready var _cinderella_bar: ProgressBar = %CinderellaHealth
@onready var _caperucita_bar: ProgressBar = %CaperucitaHealth
@onready var _cinderella_stats: Label = %CinderellaStats
@onready var _caperucita_stats: Label = %CaperucitaStats
@onready var _cinderella_portrait_rect: TextureRect = %CinderellaPortrait
@onready var _caperucita_portrait_rect: TextureRect = %CaperucitaPortrait
@onready var _cinderella_portrait_placeholder: Label = %CinderellaPortraitPlaceholder
@onready var _caperucita_portrait_placeholder: Label = %CaperucitaPortraitPlaceholder
@onready var _cinderella_visual: EditableActorVisual = %CinderellaBattleVisual
@onready var _caperucita_visual: EditableActorVisual = %CaperucitaBattleVisual
@onready var _letter_qte: LetterQTE = %LetterQTE
@onready var _timing_bar: AttackTimingBar = %TimingBar


func _ready() -> void:
	_apply_combat_settings()
	_prepare_replaceable_art()
	_reset_stats()
	_preparation_popup.visible = false
	_letter_qte.visible = false
	_timing_bar.visible = false
	_start_battle.call_deferred()


func _apply_combat_settings() -> void:
	if combat_settings == null:
		push_warning("BattleArena no tiene CombatSettings. Se usarán los valores predeterminados.")
		combat_settings = CombatSettings.new()

	cinderella_max_health = combat_settings.vida_cenicienta
	cinderella_attack = combat_settings.ataque_cenicienta
	cinderella_defense = combat_settings.defensa_cenicienta
	caperucita_max_health = combat_settings.vida_caperucita
	caperucita_attack = combat_settings.ataque_caperucita
	caperucita_defense = combat_settings.defensa_caperucita
	reduction_per_letter = combat_settings.reduccion_por_acierto / 100.0
	preparation_hold_duration = combat_settings.duracion_aviso
	preparation_fade_duration = combat_settings.fundido_aviso

	_timing_bar.marker_speed = combat_settings.velocidad_marcador
	_timing_bar.good_zone_width = combat_settings.ancho_zona_buena / 100.0
	_timing_bar.perfect_zone_width = minf(
		combat_settings.ancho_zona_perfecta / 100.0,
		_timing_bar.good_zone_width,
	)

	_letter_qte.letter_count = combat_settings.cantidad_teclas
	_letter_qte.time_per_letter = combat_settings.tiempo_por_tecla
	_letter_qte.feedback_duration = combat_settings.tiempo_resultado_tecla
	_letter_qte.reduction_per_letter = reduction_per_letter
	_letter_qte.allowed_letters = combat_settings.letras_permitidas
	_letter_qte.include_arrow_keys = combat_settings.incluir_flechas


func _prepare_replaceable_art() -> void:
	_cinderella_portrait_rect.texture = cinderella_portrait
	_cinderella_portrait_rect.visible = cinderella_portrait != null
	_cinderella_portrait_placeholder.visible = cinderella_portrait == null
	_caperucita_portrait_rect.texture = caperucita_portrait
	_caperucita_portrait_rect.visible = caperucita_portrait != null
	_caperucita_portrait_placeholder.visible = caperucita_portrait == null
	_cinderella_visual.character_texture = cinderella_battle_texture
	_caperucita_visual.character_texture = caperucita_battle_texture
	_cinderella_visual._apply_visuals()
	_caperucita_visual._apply_visuals()


func _reset_stats() -> void:
	_cinderella_health = cinderella_max_health
	_caperucita_health = caperucita_max_health
	_cinderella_bar.max_value = cinderella_max_health
	_caperucita_bar.max_value = caperucita_max_health
	_update_status_cards()


func _start_battle() -> void:
	match BattleState.encounter_mode:
		BattleState.EncounterMode.FLEE:
			_message.text = "INTENTO DE HUIDA\nCaperucita es más rápida y obtiene un ataque directo."
			await get_tree().create_timer(0.8).timeout
			var flee_ended_battle: bool = await _enemy_attack(
				false, "ATAQUE DIRECTO · NO PUEDE ESQUIVARSE"
			)
			if flee_ended_battle:
				return
		BattleState.EncounterMode.CHARGE:
			_message.text = "CARGA FRONTAL\nCaperucita ataca primero, pero podés reducir el daño."
			await get_tree().create_timer(0.8).timeout
			var charge_ended_battle: bool = await _enemy_attack(true, "ATAQUE DURANTE LA CARGA")
			if charge_ended_battle:
				return
		_:
			_message.text = "GUARDIA\nCenicienta mantiene su posición y obtiene el primer turno."
			await get_tree().create_timer(0.8).timeout

	await _run_alternating_turns()


func _run_alternating_turns() -> void:
	while not _battle_finished:
		var player_ended_battle: bool = await _cinderella_attack_turn()
		if player_ended_battle:
			return
		var enemy_ended_battle: bool = await _enemy_attack(true, "ATAQUE DE CAPERUCITA")
		if enemy_ended_battle:
			return


func _cinderella_attack_turn() -> bool:
	await _show_preparation("PREPARATE PARA ATACAR")
	_message.text = "TURNO DE CENICIENTA\nDetené el marcador en la zona correcta."
	_timing_bar.start_timing()
	var timing_result: Array = await _timing_bar.resolved
	var multiplier: float = timing_result[0]
	var grade: String = timing_result[1]
	var damage := _calculate_damage(cinderella_attack, caperucita_defense, multiplier)
	_caperucita_health = maxf(_caperucita_health - damage, 0.0)
	_message.text = "%s\nAtaque efectivo: %d · Caperucita recibe %d de daño." % [
		grade,
		roundi(cinderella_attack * multiplier),
		damage,
	]
	await _animate_attack(_cinderella_visual, _caperucita_visual)
	_update_status_cards()
	if _caperucita_health <= 0.0:
		await _finish_battle(true)
		return true
	await get_tree().create_timer(0.65).timeout
	return false


func _enemy_attack(can_defend: bool, reason: String) -> bool:
	await _show_preparation("PREPARATE PARA DEFENDERTE")
	var correct_letters := 0
	var damage_multiplier := 1.0
	if can_defend:
		_message.text = "ATAQUE DE CAPERUCITA\nPresioná cada letra visible antes de que desaparezca."
		_letter_qte.start_sequence()
		correct_letters = await _letter_qte.completed
		damage_multiplier = clampf(1.0 - float(correct_letters) * reduction_per_letter, 0.0, 1.0)
	else:
		_message.text = "%s\nNo hay oportunidad de defenderse." % reason
		await get_tree().create_timer(0.55).timeout

	var damage := _calculate_damage(caperucita_attack, cinderella_defense, damage_multiplier)
	_cinderella_health = maxf(_cinderella_health - damage, 0.0)
	if can_defend:
		_message.text = "%d/%d LETRAS · DAÑO -%.1f%%\nCenicienta recibe %d de daño." % [
			correct_letters,
			_letter_qte.letter_count,
			(1.0 - damage_multiplier) * 100.0,
			damage,
		]
	else:
		_message.text = "%s\nCenicienta recibe %d de daño." % [reason, damage]
	await _animate_attack(_caperucita_visual, _cinderella_visual)
	_update_status_cards()
	if _cinderella_health <= 0.0:
		await _finish_battle(false)
		return true
	await get_tree().create_timer(0.7).timeout
	return false


func _show_preparation(text: String) -> void:
	_preparation_label.text = text
	_preparation_popup.visible = true
	_preparation_popup.modulate.a = 0.0
	_preparation_popup.scale = Vector2(0.92, 0.92)
	_preparation_popup.pivot_offset = _preparation_popup.size * 0.5
	var enter := create_tween().set_parallel(true)
	enter.tween_property(_preparation_popup, "modulate:a", 1.0, preparation_fade_duration)
	enter.tween_property(_preparation_popup, "scale", Vector2.ONE, preparation_fade_duration)
	await enter.finished
	await get_tree().create_timer(preparation_hold_duration).timeout
	var exit := create_tween().set_parallel(true)
	exit.tween_property(_preparation_popup, "modulate:a", 0.0, preparation_fade_duration)
	exit.tween_property(_preparation_popup, "scale", Vector2(1.04, 1.04), preparation_fade_duration)
	await exit.finished
	_preparation_popup.visible = false


func _calculate_damage(attack: float, defense: float, multiplier: float) -> int:
	return maxi(1, roundi((attack * multiplier * 100.0) / (100.0 + defense)))


func _animate_attack(attacker: Node2D, defender: Node2D) -> void:
	var attacker_origin := attacker.position
	var direction := attacker.global_position.direction_to(defender.global_position)
	var tween := create_tween()
	tween.tween_property(attacker, "position", attacker_origin + direction * 42.0, 0.12)
	tween.tween_property(attacker, "position", attacker_origin, 0.18)
	var flash := create_tween()
	flash.tween_property(defender, "modulate", Color(1.0, 0.25, 0.25, 1.0), 0.08)
	flash.tween_property(defender, "modulate", Color.WHITE, 0.18)
	await tween.finished


func _update_status_cards() -> void:
	_cinderella_bar.value = _cinderella_health
	_caperucita_bar.value = _caperucita_health
	_cinderella_stats.text = "VIDA  %d/%d\nATAQUE  %d\nDEFENSA  %d" % [
		ceili(_cinderella_health), ceili(cinderella_max_health),
		roundi(cinderella_attack), roundi(cinderella_defense),
	]
	_caperucita_stats.text = "VIDA  %d/%d\nATAQUE  %d\nDEFENSA  %d" % [
		ceili(_caperucita_health), ceili(caperucita_max_health),
		roundi(caperucita_attack), roundi(caperucita_defense),
	]


func _finish_battle(player_won: bool) -> void:
	_battle_finished = true
	BattleState.battle_result = "victory" if player_won else "defeat"
	_message.text = "VICTORIA IMPOSIBLE" if player_won else "CENICIENTA HA SIDO DERROTADA"
	await get_tree().create_timer(1.4).timeout
	var destination := victory_cutscene if player_won else defeat_cutscene
	var transition := get_node_or_null("/root/SceneTransition")
	if transition:
		await transition.change_scene(destination, 0.8)
	else:
		get_tree().change_scene_to_file(destination)
