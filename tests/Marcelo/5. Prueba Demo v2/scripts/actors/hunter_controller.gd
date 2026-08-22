class_name RedHoodController
extends CharacterBody2D

@export var speed: float = 120.0
@export var target_path: NodePath
@export var movement_bounds := Rect2(54.0, 86.0, 1172.0, 560.0)

var chase_enabled := false
@onready var _target: Node2D = get_node_or_null(target_path)


func _physics_process(_delta: float) -> void:
	if not chase_enabled or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(_target.global_position) * speed
	move_and_slide()
	global_position.x = clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x)
	global_position.y = clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)
