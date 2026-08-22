class_name CinderellaController
extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 80.0
@export var movement_bounds := Rect2(54.0, 86.0, 1172.0, 560.0)

var controls_enabled := false
var facing_direction := Vector2.RIGHT
var movement_input := Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		movement_input = Vector2.ZERO
		return

	movement_input = Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
			- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
			- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	if movement_input.length_squared() > 1.0:
		movement_input = movement_input.normalized()
	velocity = movement_input * speed
	if movement_input.length_squared() > 0.01:
		facing_direction = movement_input.normalized()
	move_and_slide()
	global_position.x = clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x)
	global_position.y = clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)


func is_charging_toward(target_position: Vector2) -> bool:
	if movement_input.length_squared() < 0.25:
		return false
	return movement_input.normalized().dot(global_position.direction_to(target_position)) > 0.55


func is_target_behind(target_position: Vector2) -> bool:
	return facing_direction.dot(global_position.direction_to(target_position)) < -0.35
