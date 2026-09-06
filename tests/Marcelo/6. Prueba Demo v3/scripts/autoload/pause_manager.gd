extends CanvasLayer

var _pause_enabled := false

@onready var _overlay: Control = %Overlay
@onready var _menu_card: Control = %MenuCard
@onready var _options_holder: Control = %OptionsHolder
@onready var _skip_button: Button = %SkipButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.hide()


func _unhandled_input(event: InputEvent) -> void:
	if _pause_enabled and event.is_action_pressed("pause_game"):
		var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
		if (
			inventory_ui != null
			and inventory_ui.has_method("is_open")
			and bool(inventory_ui.call("is_open"))
		):
			inventory_ui.call("close_inventory")
			get_viewport().set_input_as_handled()
			return
		get_viewport().set_input_as_handled()
		toggle_pause()


func set_pause_enabled(value: bool) -> void:
	_pause_enabled = value
	if not value and is_instance_valid(_overlay):
		get_tree().paused = false
		_overlay.hide()


func toggle_pause() -> void:
	if not _pause_enabled:
		return
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	if should_pause:
		_refresh_context_buttons()
		_menu_card.show()
		_options_holder.hide()
		_overlay.show()
		Audio.play_sfx("res://assets/audio/sfx/ui_open.wav", -5.0)
	else:
		_overlay.hide()
		Audio.play_sfx("res://assets/audio/sfx/ui_back.wav", -6.0)


func _on_resume_pressed() -> void:
	toggle_pause()


func _on_options_pressed() -> void:
	Audio.play_sfx("res://assets/audio/sfx/ui_open.wav", -5.0)
	_menu_card.hide()
	_options_holder.show()


func _on_options_panel_close_requested() -> void:
	_options_holder.hide()
	_menu_card.show()


func _on_skip_pressed() -> void:
	var cinematic := get_tree().get_first_node_in_group("cinematic")
	get_tree().paused = false
	_overlay.hide()
	if cinematic != null and cinematic.has_method("skip"):
		cinematic.skip()


func _on_restart_pressed() -> void:
	var current_path := get_tree().current_scene.scene_file_path
	get_tree().paused = false
	_overlay.hide()
	SceneRouter.go_to(current_path, "Reiniciando…")


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneRouter.go_to("res://scenes/main_menu.tscn", "Volviendo al menú…")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _refresh_context_buttons() -> void:
	_skip_button.visible = get_tree().get_first_node_in_group("cinematic") != null
