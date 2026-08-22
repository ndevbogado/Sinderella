class_name StoryReader
extends Control

## Controlador general. Avanza panel por panel y despues cambia de pagina.

signal story_finished
signal page_changed(page_index: int, page_title: String)
signal panel_revealed(page_index: int, panel_progress: String)

@export_category("Playback")
@export var start_in_auto_play: bool = true
@export_range(0.2, 10.0, 0.1) var auto_panel_interval: float = 1.8
@export_range(0.2, 10.0, 0.1) var auto_page_interval: float = 2.4
@export_range(0.2, 10.0, 0.1) var final_panel_hold: float = 3.0
@export var loop_at_end: bool = false

@export_category("Scene transition")
@export_file("*.tscn") var next_scene_path: String = ""
@export_range(0.1, 3.0, 0.05) var transition_duration: float = 0.65

var _pages: Array[StoryPage] = []
var _page_index: int = 0
var _busy: bool = false
var _auto_play: bool = false
var _auto_generation: int = 0
var _finished_emitted: bool = false

@onready var _pages_root: Control = %Pages
@onready var _status_label: Label = %StatusLabel
@onready var _auto_button: Button = %AutoButton


func _ready() -> void:
	for child in _pages_root.get_children():
		if child is StoryPage:
			_pages.append(child as StoryPage)

	%PreviousButton.pressed.connect(previous)
	%AutoButton.pressed.connect(toggle_auto_play)
	%NextButton.pressed.connect(advance)
	_auto_play = start_in_auto_play
	_update_hud()
	call_deferred("_start_story")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_RIGHT, KEY_SPACE, KEY_ENTER:
				advance()
			KEY_LEFT:
				previous()
			KEY_A:
				toggle_auto_play()
			KEY_R:
				restart()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		advance()


func _start_story() -> void:
	if _pages.is_empty():
		_status_label.text = "Agrega un nodo StoryPage dentro de Pages."
		return
	await _show_page(0, true)
	if _auto_play:
		_start_auto_loop()


func advance() -> void:
	if _busy or _pages.is_empty():
		return
	_busy = true
	var page := _pages[_page_index]

	if page.has_more_panels():
		await page.reveal_next_panel()
		panel_revealed.emit(_page_index, page.panel_progress())
	elif _page_index < _pages.size() - 1:
		await _show_page(_page_index + 1, true)
	elif loop_at_end:
		await _show_page(0, true)
	else:
		_set_auto_play(false)
		if not _finished_emitted:
			_finished_emitted = true
			story_finished.emit()
			if not next_scene_path.is_empty():
				await _change_to_next_scene()

	_busy = false
	_update_hud()


func previous() -> void:
	if _busy or _pages.is_empty():
		return
	_busy = true
	var page := _pages[_page_index]

	if page.hide_last_panel():
		pass
	elif _page_index > 0:
		await _show_page(_page_index - 1, false)
		_pages[_page_index].reveal_all_immediately()

	_busy = false
	_update_hud()


func restart() -> void:
	if _busy or _pages.is_empty():
		return
	_auto_generation += 1
	_finished_emitted = false
	_busy = true
	await _show_page(0, true)
	_busy = false
	_update_hud()
	if _auto_play:
		_start_auto_loop()


func toggle_auto_play() -> void:
	_set_auto_play(not _auto_play)
	if _auto_play:
		_start_auto_loop()


func _set_auto_play(value: bool) -> void:
	_auto_play = value
	_auto_generation += 1
	_update_hud()


func _start_auto_loop() -> void:
	_auto_generation += 1
	var my_generation := _auto_generation
	_auto_loop(my_generation)


func _auto_loop(generation: int) -> void:
	while _auto_play and generation == _auto_generation:
		var is_final_panel := (
			_page_index == _pages.size() - 1
			and not _pages[_page_index].has_more_panels()
		)
		var delay := final_panel_hold if is_final_panel else (
			auto_panel_interval if _pages[_page_index].has_more_panels() else auto_page_interval
		)
		await get_tree().create_timer(delay).timeout
		if not _auto_play or generation != _auto_generation:
			return
		advance()
		while _busy and _auto_play and generation == _auto_generation:
			await get_tree().process_frame


func _show_page(new_index: int, reveal_first: bool) -> void:
	if not _pages.is_empty() and _pages[_page_index].visible:
		await _pages[_page_index].exit_page()

	for page in _pages:
		page.prepare()

	_page_index = clampi(new_index, 0, _pages.size() - 1)
	_finished_emitted = false
	await _pages[_page_index].enter_page()
	if reveal_first:
		await _pages[_page_index].reveal_next_panel()
		panel_revealed.emit(_page_index, _pages[_page_index].panel_progress())
	page_changed.emit(_page_index, _pages[_page_index].page_title)


func _change_to_next_scene() -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition and transition.has_method("change_scene"):
		await transition.change_scene(next_scene_path, transition_duration)
	else:
		get_tree().change_scene_to_file(next_scene_path)


func _update_hud() -> void:
	_auto_button.text = "AUTO: ON" if _auto_play else "AUTO: OFF"
	if _pages.is_empty():
		return
	var page := _pages[_page_index]
	_status_label.text = "%s   ·   Pagina %d/%d   ·   Panel %s" % [
		page.page_title,
		_page_index + 1,
		_pages.size(),
		page.panel_progress(),
	]
