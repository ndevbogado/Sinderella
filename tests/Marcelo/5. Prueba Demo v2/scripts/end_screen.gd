extends Control

@export_file("*.tscn") var restart_scene := "res://main.tscn"

@onready var _result_label: Label = %ResultLabel


func _ready() -> void:
	%RestartButton.pressed.connect(_restart)
	if BattleState.battle_result == "victory":
		_result_label.text = "CENICIENTA VENCIÓ\nLa historia tomó un camino imposible."
	else:
		_result_label.text = "CAPERUCITA VENCIÓ\nPero el cuento todavía no terminó."


func _restart() -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition:
		transition.change_scene(restart_scene, 0.7)
	else:
		get_tree().change_scene_to_file(restart_scene)
