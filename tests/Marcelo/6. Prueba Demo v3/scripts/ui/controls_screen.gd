extends Control

@onready var _begin_button: Button = %BeginButton


func _ready() -> void:
	PauseManager.set_pause_enabled(false)
	_begin_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _on_back_pressed() -> void:
	SceneRouter.go_to_immediate("res://scenes/main_menu.tscn")


func _on_begin_pressed() -> void:
	Audio.play_sfx("res://assets/audio/sfx/ui_confirm.wav", -3.0)
	SceneRouter.go_to("res://scenes/cinematic_intro.tscn", "Abriendo el relato…")

