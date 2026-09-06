extends Control

@onready var _options_layer: Control = %OptionsLayer
@onready var _new_game_button: Button = %NewGameButton


func _ready() -> void:
	PauseManager.set_pause_enabled(false)
	Audio.stop_ambience()
	Audio.play_music("res://assets/audio/music/menu_theme.wav")
	_new_game_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and _options_layer.visible:
		_options_layer.hide()
		_new_game_button.grab_focus()
		get_viewport().set_input_as_handled()


func _on_new_game_pressed() -> void:
	Inventory.clear()
	Audio.play_sfx("res://assets/audio/sfx/ui_confirm.wav", -3.0)
	SceneRouter.go_to_immediate("res://scenes/controls_screen.tscn")


func _on_options_pressed() -> void:
	Audio.play_sfx("res://assets/audio/sfx/ui_open.wav", -4.0)
	_options_layer.show()


func _on_options_panel_close_requested() -> void:
	_options_layer.hide()
	_new_game_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
