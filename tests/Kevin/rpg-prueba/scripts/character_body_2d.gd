extends CharacterBody2D


const velocidad = 150.0
@onready var player = $".."    #Node2D
@onready var animation = $AnimatedSprite2D 

func _physics_process(_delta):
	if Input.is_action_pressed("ui_up"):
		player.position.y -= velocidad * _delta
		animation.flip_h = false
		animation.play("arriba")
	elif Input.is_action_pressed("ui_down"):
		player.position.y += velocidad * _delta
		animation.flip_h = false
		animation.play("abajo")
	elif Input.is_action_pressed("ui_left"):    #Sprite derecha invertido para izquierda
		player.position.x -= velocidad * _delta
		animation.flip_h = true
		animation.play("derecha")
	elif Input.is_action_pressed("ui_right"):
		player.position.x += velocidad * _delta
		animation.flip_h = false
		animation.play("derecha")
	else:
		animation.stop()
	move_and_slide()


func _on_area_2d_jugador_area_entered(area: Area2D) -> void:
	if area.name == "AlJardin":
		get_tree().change_scene_to_file("res://jardin.tscn")
