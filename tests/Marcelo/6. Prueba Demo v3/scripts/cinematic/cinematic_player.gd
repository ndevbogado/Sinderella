extends Control

@export var secuencia: ComicSequence

var _page_index := -1
var _generation := 0
var _busy := false
var _finishing := false
var _current_page: VisualComicPage
var _outgoing_page: VisualComicPage
var _current_panels: Array = []
var _active_tween: Tween
var _active_finals: Array[Dictionary] = []

@onready var _panel_layer: Control = %PanelLayer
@onready var _atmosphere: AtmosphereOverlay = %Atmosphere
@onready var _advance_hint: Control = %AdvanceHint
@onready var _progress_label: Label = %ProgressLabel
@onready var _error_label: Label = %ErrorLabel


func _ready() -> void:
	add_to_group("cinematic")
	PauseManager.set_pause_enabled(true)
	resized.connect(_layout_pages)
	if secuencia == null or secuencia.paginas.is_empty():
		_show_error("La secuencia visual no contiene páginas.")
		return
	_play_audio_stream(secuencia.musica, true)
	_play_audio_stream(secuencia.ambiente, false)
	await get_tree().create_timer(secuencia.demora_inicial, false).timeout
	_show_page(0)


func _exit_tree() -> void:
	if PauseManager != null:
		PauseManager.set_pause_enabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if _finishing or get_tree().paused:
		return
	if event.is_action_pressed("advance_story"):
		get_viewport().set_input_as_handled()
		Audio.play_sfx("res://assets/audio/sfx/page_step.wav", -8.0, randf_range(0.97, 1.03))
		if _busy:
			_complete_motion()
		else:
			advance()


func advance() -> void:
	if _finishing:
		return
	if _page_index + 1 < secuencia.paginas.size():
		_show_page(_page_index + 1)
	else:
		_finish_sequence(true)


func skip() -> void:
	if not _finishing:
		_finish_sequence(false)


func _show_page(index: int) -> void:
	if index < 0 or index >= secuencia.paginas.size():
		return
	var packed_page := secuencia.paginas[index]
	if packed_page == null:
		_show_error("La página %d no tiene una escena asignada." % [index + 1])
		return
	var page := packed_page.instantiate() as VisualComicPage
	if page == null:
		_show_error("La escena %d no es una VisualComicPage." % [index + 1])
		return

	_generation += 1
	var local_generation := _generation
	_busy = true
	_advance_hint.hide()
	_active_finals.clear()
	_page_index = index
	_progress_label.text = "%02d  /  %02d" % [index + 1, secuencia.paginas.size()]

	_outgoing_page = _current_page
	_current_page = page
	_panel_layer.add_child(_current_page)
	_fit_page(_current_page)
	_current_panels = _current_page.get_panels()

	_atmosphere.set_atmosphere(
		_current_page.get_atmosphere_mode(), _current_page.intensidad_atmosfera
	)
	if _current_page.efecto_de_sonido != null:
		Audio.play_sfx(
			_current_page.efecto_de_sonido.resource_path,
			_current_page.volumen_efecto_db
		)

	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var longest_motion := 0.15
	if is_instance_valid(_outgoing_page):
		_active_tween.tween_property(_outgoing_page, "modulate:a", 0.0, 0.24)
		if not Settings.reduce_motion:
			_active_tween.tween_property(_outgoing_page, "position:y", -12.0, 0.24)

	var speed := maxf(Settings.cinematic_speed, 0.05)
	for panel_value in _current_panels:
		var panel := panel_value as VisualComicPanel
		if panel == null:
			continue
		var final_state := _prepare_panel_entrance(panel)
		_active_finals.append(final_state)
		var panel_delay := panel.demora / speed
		var duration := panel.duracion / speed
		if Settings.reduce_motion:
			duration = minf(duration, 0.12)
			panel_delay = minf(panel_delay, 0.08)
		longest_motion = maxf(longest_motion, panel_delay + duration)
		_active_tween.tween_property(
			panel, "position", final_state["position"], duration
		).set_delay(panel_delay)
		_active_tween.tween_property(
			panel, "scale", final_state["scale"], duration
		).set_delay(panel_delay)
		_active_tween.tween_property(
			panel, "modulate:a", final_state["alpha"], duration * 0.75
		).set_delay(panel_delay)
		_active_tween.tween_property(
			panel, "rotation", final_state["rotation"], duration
		).set_delay(panel_delay)
		panel.start_internal_motion(_current_page.espera / speed)

	Audio.play_sfx("res://assets/audio/sfx/panel_in.wav", -8.0, randf_range(0.96, 1.04))
	await get_tree().create_timer(longest_motion, false).timeout
	if local_generation == _generation:
		_complete_motion(false)


func _prepare_panel_entrance(panel: VisualComicPanel) -> Dictionary:
	var final_position := panel.position
	var final_scale := panel.scale
	var final_rotation := panel.rotation
	var final_alpha := panel.modulate.a
	panel.modulate.a = 0.0
	panel.pivot_offset = panel.size * 0.5
	if Settings.reduce_motion:
		panel.scale = final_scale * 0.99
		return {
			"node": panel,
			"position": final_position,
			"scale": final_scale,
			"rotation": final_rotation,
			"alpha": final_alpha,
		}
	match panel.entrada:
		VisualComicPanel.Entrance.IZQUIERDA:
			panel.position.x = -panel.size.x - 40.0
		VisualComicPanel.Entrance.DERECHA:
			panel.position.x = 1320.0
		VisualComicPanel.Entrance.ARRIBA:
			panel.position.y = -panel.size.y - 40.0
		VisualComicPanel.Entrance.ABAJO:
			panel.position.y = 760.0
		VisualComicPanel.Entrance.ARRIBA_IZQUIERDA:
			panel.position = Vector2(-panel.size.x, -panel.size.y)
		VisualComicPanel.Entrance.ABAJO_DERECHA:
			panel.position = Vector2(1320.0, 760.0)
		VisualComicPanel.Entrance.CORTE_IZQUIERDA:
			panel.position.x -= 80.0
			panel.rotation_degrees = rad_to_deg(final_rotation) - 2.5
		VisualComicPanel.Entrance.CORTE_DERECHA:
			panel.position.x += 80.0
			panel.rotation_degrees = rad_to_deg(final_rotation) + 2.5
		_:
			panel.scale = final_scale * 0.90
	return {
		"node": panel,
		"position": final_position,
		"scale": final_scale,
		"rotation": final_rotation,
		"alpha": final_alpha,
	}


func _complete_motion(increment_generation := true) -> void:
	if not _busy:
		return
	if increment_generation:
		_generation += 1
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	for final_state in _active_finals:
		var panel := final_state["node"] as VisualComicPanel
		if is_instance_valid(panel):
			panel.position = final_state["position"]
			panel.scale = final_state["scale"]
			panel.rotation = final_state["rotation"]
			panel.modulate.a = final_state["alpha"]
	if is_instance_valid(_outgoing_page):
		_outgoing_page.queue_free()
	_outgoing_page = null
	_busy = false
	_advance_hint.modulate.a = 0.0
	_advance_hint.show()
	create_tween().tween_property(_advance_hint, "modulate:a", 1.0, 0.18)
	_schedule_autoplay(_generation)


func _schedule_autoplay(local_generation: int) -> void:
	if not Settings.autoplay_cinematics or _current_page == null:
		return
	var speed := maxf(Settings.cinematic_speed, 0.05)
	await get_tree().create_timer(_current_page.espera / speed, false).timeout
	if local_generation == _generation and not _busy and not _finishing and not get_tree().paused:
		advance()


func _layout_pages() -> void:
	if is_instance_valid(_current_page):
		_fit_page(_current_page)
	if is_instance_valid(_outgoing_page):
		_fit_page(_outgoing_page)


func _fit_page(page: VisualComicPage) -> void:
	var design_size := page.get_design_size()
	var factor := minf(size.x / design_size.x, size.y / design_size.y)
	page.scale = Vector2.ONE * factor
	page.position = (size - design_size * factor) * 0.5


func _finish_sequence(animate_panel: bool) -> void:
	_finishing = true
	_generation += 1
	_advance_hint.hide()
	_progress_label.hide()
	if animate_panel and _current_page != null and _current_page.expandir_al_terminar:
		var panel := _current_page.get_node_or_null(_current_page.panel_a_expandir) as VisualComicPanel
		if panel == null and not _current_panels.is_empty():
			panel = _current_panels.back() as VisualComicPanel
		if panel != null:
			panel.reparent(self, true)
			panel.z_index = 60
			panel.set_border_opacity(1.0)
			var duration := 0.85 if not Settings.reduce_motion else 0.18
			var expand_tween := create_tween().set_parallel(true)
			expand_tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
			expand_tween.tween_property(panel, "position", Vector2.ZERO, duration)
			expand_tween.tween_property(panel, "size", size, duration)
			expand_tween.tween_property(panel, "scale", Vector2.ONE, duration)
			expand_tween.tween_method(panel.set_border_opacity, 1.0, 0.0, duration * 0.8)
			await expand_tween.finished
			await get_tree().create_timer(0.2, false).timeout
	SceneRouter.go_to(secuencia.escena_siguiente, secuencia.texto_de_carga)


func _play_audio_stream(stream: AudioStream, is_music: bool) -> void:
	if stream == null or stream.resource_path.is_empty():
		return
	if is_music:
		Audio.play_music(stream.resource_path)
	else:
		Audio.play_ambience(stream.resource_path)


func _show_error(message: String) -> void:
	_error_label.text = message
	_error_label.show()
	push_error(message)

