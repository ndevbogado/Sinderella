class_name LetterQTE
extends Control

signal completed(correct_letters: int)

@export_range(1, 12, 1) var letter_count: int = 6
@export_range(0.2, 2.0, 0.05) var time_per_letter: float = 0.7
@export_range(0.05, 0.6, 0.05) var feedback_duration: float = 0.18
@export_range(0.01, 0.25, 0.005) var reduction_per_letter: float = 0.125

@export_category("Allowed inputs")
@export var allowed_letters: String = "WASD"
@export var include_arrow_keys: bool = true

var _running := false
var _waiting_for_key := false
var _expected_keycode := 0
var _expected_label := ""
var _letter_resolved := false
var _correct := 0
var _allowed_inputs: Array[Dictionary] = []

@onready var _letter_label: Label = %LetterLabel
@onready var _feedback_label: Label = %LetterFeedback
@onready var _timer_bar: ProgressBar = %LetterTimer
@onready var _progress_label: Label = %LetterProgress
@onready var _flash: ColorRect = %LetterFlash


func start_sequence() -> void:
	if _running:
		return
	_build_allowed_inputs()
	_running = true
	_correct = 0
	visible = true
	_run_sequence()


func _run_sequence() -> void:
	for index in range(letter_count):
		var option: Dictionary = _allowed_inputs[randi_range(0, _allowed_inputs.size() - 1)]
		_expected_keycode = int(option["keycode"])
		_expected_label = str(option["label"])
		_letter_label.text = _expected_label
		_progress_label.text = "LETRA %d/%d  ·  REDUCCIÓN %s" % [
			index + 1,
			letter_count,
			_format_percent(float(_correct) * reduction_per_letter),
		]
		_feedback_label.text = ""
		_letter_resolved = false
		_waiting_for_key = true
		_timer_bar.max_value = time_per_letter
		_timer_bar.value = time_per_letter
		_letter_label.scale = Vector2(0.72, 0.72)
		_letter_label.pivot_offset = _letter_label.size * 0.5
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(
			_letter_label, "scale", Vector2.ONE, 0.12
		)

		var remaining := time_per_letter
		while remaining > 0.0 and not _letter_resolved:
			await get_tree().process_frame
			remaining -= get_process_delta_time()
			_timer_bar.value = maxf(remaining, 0.0)

		if not _letter_resolved:
			_resolve_letter(false)
		await get_tree().create_timer(feedback_duration).timeout

	_waiting_for_key = false
	_progress_label.text = "%d/%d CORRECTAS  ·  DAÑO -%s" % [
		_correct,
		letter_count,
		_format_percent(float(_correct) * reduction_per_letter),
	]
	await get_tree().create_timer(0.5).timeout
	visible = false
	_running = false
	completed.emit(_correct)


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_for_key or _letter_resolved:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var success: bool = false
		if event.keycode == _expected_keycode:
			success = true
		elif event.physical_keycode == _expected_keycode:
			success = true
		if not success and event.unicode > 0:
			success = String.chr(event.unicode).to_upper() == _expected_label
		_resolve_letter(success)
		get_viewport().set_input_as_handled()


func _build_allowed_inputs() -> void:
	_allowed_inputs.clear()
	var normalized_letters := allowed_letters.to_upper()
	var used_labels: Array[String] = []
	for index in range(normalized_letters.length()):
		var label := normalized_letters.substr(index, 1)
		if label.strip_edges().is_empty() or label in used_labels:
			continue
		used_labels.append(label)
		_allowed_inputs.append({
			"keycode": label.unicode_at(0),
			"label": label,
		})

	if include_arrow_keys:
		_allowed_inputs.append_array([
			{"keycode": KEY_UP, "label": "↑"},
			{"keycode": KEY_DOWN, "label": "↓"},
			{"keycode": KEY_LEFT, "label": "←"},
			{"keycode": KEY_RIGHT, "label": "→"},
		])

	if _allowed_inputs.is_empty():
		push_warning("LetterQTE no tiene entradas configuradas. Se usará WASD.")
		for label in ["W", "A", "S", "D"]:
			_allowed_inputs.append({
				"keycode": label.unicode_at(0),
				"label": label,
			})


func _resolve_letter(success: bool) -> void:
	if _letter_resolved:
		return
	_letter_resolved = true
	_waiting_for_key = false
	if success:
		_correct += 1
		_feedback_label.text = "✓  A TIEMPO"
		_feedback_label.modulate = Color("82ef9d")
		_flash.color = Color(0.2, 0.9, 0.35, 0.28)
	else:
		_feedback_label.text = "✕  FALLASTE"
		_feedback_label.modulate = Color("ff6a67")
		_flash.color = Color(0.95, 0.12, 0.12, 0.28)
		var original_x := position.x
		var shake := create_tween()
		shake.tween_property(self, "position:x", original_x - 8.0, 0.035)
		shake.tween_property(self, "position:x", original_x + 8.0, 0.07)
		shake.tween_property(self, "position:x", original_x, 0.035)
	_flash.modulate.a = 1.0
	create_tween().tween_property(_flash, "modulate:a", 0.0, feedback_duration)


func _format_percent(value: float) -> String:
	return "%.1f%%" % (value * 100.0)
