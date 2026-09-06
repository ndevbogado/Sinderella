class_name WorldSpeechBubble
extends Control

signal finished

@export_range(1.0, 20.0, 0.1) var visible_time := 8.0

@onready var _label: Label = %SpeechText

var _generation := 0
var _closing := false


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _closing:
		return
	if event.is_action_pressed("advance_story") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		dismiss()


func present(message: String, duration := -1.0) -> void:
	_generation += 1
	var local_generation := _generation
	_closing = false
	_label.text = message
	modulate.a = 0.0
	scale = Vector2(0.96, 0.96)
	show()
	var entrance := create_tween().set_parallel(true)
	entrance.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entrance.tween_property(self, "modulate:a", 1.0, 0.22)
	entrance.tween_property(self, "scale", Vector2.ONE, 0.22)
	var wait_time := visible_time if duration < 0.0 else duration
	await get_tree().create_timer(wait_time, false).timeout
	if local_generation == _generation and visible:
		dismiss()


func dismiss() -> void:
	if not visible or _closing:
		return
	_generation += 1
	_closing = true
	var exit_tween := create_tween().set_parallel(true)
	exit_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.16)
	exit_tween.tween_property(self, "scale", Vector2(0.98, 0.98), 0.16)
	exit_tween.finished.connect(_on_exit_finished)


func _on_exit_finished() -> void:
	hide()
	_closing = false
	finished.emit()

