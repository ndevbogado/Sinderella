extends Node2D

@export_category("Encounter")
@export_range(20.0, 120.0, 1.0) var encounter_distance: float = 48.0
@export_range(0.05, 0.8, 0.05) var direction_threshold: float = 0.3
@export_file("*.tscn") var battle_scene_path := "res://scenes/battle_arena.tscn"
@export_range(0.1, 2.0, 0.05) var transition_duration := 0.65

var _encounter_started := false
var _last_action_text := ""
var _feedback_tween: Tween

@onready var _player: CinderellaController = %Cinderella
@onready var _hunter: RedHoodController = %Caperucita
@onready var _intro_popup: PanelContainer = %IntroPopup
@onready var _ok_button: Button = %OkButton
@onready var _action_feedback: PanelContainer = %ActionFeedback
@onready var _action_feedback_label: Label = %ActionFeedbackLabel


func _ready() -> void:
	BattleState.reset()
	_player.controls_enabled = false
	_hunter.chase_enabled = false
	_action_feedback.visible = false
	_ok_button.pressed.connect(_dismiss_intro)
	_ok_button.grab_focus.call_deferred()


func _process(_delta: float) -> void:
	if _encounter_started or not _player.controls_enabled:
		return
	var action_text: String = _detect_current_action()
	_update_live_action(action_text)
	if _player.global_position.distance_to(_hunter.global_position) <= encounter_distance:
		_start_encounter()


func _dismiss_intro() -> void:
	_ok_button.disabled = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_intro_popup, "modulate:a", 0.0, 0.22)
	tween.tween_property(_intro_popup, "position:y", _intro_popup.position.y - 18.0, 0.22)
	await tween.finished
	_intro_popup.visible = false
	_player.controls_enabled = true
	_hunter.chase_enabled = true
	_action_feedback.visible = true
	_update_live_action(_detect_current_action(), true)


func _start_encounter() -> void:
	_encounter_started = true
	var action_text: String = _detect_current_action()
	_update_live_action(action_text, true)
	_player.controls_enabled = false
	_hunter.chase_enabled = false

	var transition := get_node_or_null("/root/SceneTransition")
	if transition:
		transition.change_scene(battle_scene_path, transition_duration)
	else:
		get_tree().change_scene_to_file(battle_scene_path)


func _detect_current_action() -> String:
	var movement := _player.movement_input
	var direction_to_caperucita := _player.global_position.direction_to(_hunter.global_position)
	var movement_intention := 0.0
	if movement.length_squared() > 0.01:
		movement_intention = movement.normalized().dot(direction_to_caperucita)

	if movement.length_squared() <= 0.01 or absf(movement_intention) < direction_threshold:
		BattleState.encounter_mode = BattleState.EncounterMode.GUARD
		return "Manteniendo la guardia"
	elif movement_intention > 0.0:
		BattleState.encounter_mode = BattleState.EncounterMode.CHARGE
		return "Cargando contra el enemigo"
	else:
		BattleState.encounter_mode = BattleState.EncounterMode.FLEE
		return "Huyendo del enemigo"


func _update_live_action(action_text: String, force_pulse: bool = false) -> void:
	if action_text == _last_action_text and not force_pulse:
		return
	_last_action_text = action_text
	_action_feedback_label.text = action_text
	_action_feedback.visible = true
	match BattleState.encounter_mode:
		BattleState.EncounterMode.CHARGE:
			_action_feedback_label.modulate = Color("ffb347")
		BattleState.EncounterMode.FLEE:
			_action_feedback_label.modulate = Color("ff6868")
		_:
			_action_feedback_label.modulate = Color("79d5ff")

	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_action_feedback.scale = Vector2(1.06, 1.06)
	_action_feedback.pivot_offset = _action_feedback.size * 0.5
	_feedback_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_action_feedback, "scale", Vector2.ONE, 0.16)
