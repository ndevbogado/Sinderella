extends Node2D

func _ready() -> void:
	$AnimationPlayer.play("parpadeo")
func _input(event):
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://mundo.tscn")
