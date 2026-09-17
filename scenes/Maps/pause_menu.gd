extends CanvasLayer

@onready var pause_ui: Control = $PauseUI
@onready var continue_button: Button = $PauseUI/CenterContainer/PanelContainer/VBoxContainer/Continuar
@onready var exit_button: Button = $PauseUI/CenterContainer/PanelContainer/VBoxContainer/Salir


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	pause_ui.hide()

	continue_button.pressed.connect(resume_game)
	exit_button.pressed.connect(exit_game)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()


func pause_game() -> void:
	get_tree().paused = true
	pause_ui.show()


func resume_game() -> void:
	pause_ui.hide()
	get_tree().paused = false


func exit_game() -> void:
	get_tree().quit()
