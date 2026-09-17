extends Area2D

@onready var grass_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	grass_sprite.play("idle")
	body_entered.connect(_on_body_entered)
	grass_sprite.animation_finished.connect(_on_animation_finished)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "BriarPlayer":
		grass_sprite.play("rustle")


func _on_animation_finished() -> void:
	if grass_sprite.animation == &"rustle":
		grass_sprite.play("idle")
