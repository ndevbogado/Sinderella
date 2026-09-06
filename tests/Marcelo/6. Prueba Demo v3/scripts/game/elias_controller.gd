class_name EliasController
extends CharacterBody2D

## Solo contiene el comportamiento. Sprite, sombra y colisión viven en el .tscn.

@export_range(20.0, 600.0, 5.0) var movement_speed := 180.0
@export_range(0.1, 1.0, 0.01) var footstep_interval := 0.39
@export_file("*.wav","*.ogg") var footstep_sound := "res://assets/audio/sfx/footstep_wood.wav"

@onready var _sprite: Sprite2D = get_node_or_null("EliasArtwork") as Sprite2D

var _direction := 0
var _walk_time := 0.0
var _footstep_time := 0.0
var _controls_enabled := true


func _ready() -> void:
	add_to_group("player_character")


func _physics_process(delta: float) -> void:
	if not _controls_enabled:
		velocity = Vector2.ZERO
		_update_frame(false)
		return
	var input_vector := _read_movement_input()
	velocity = input_vector * movement_speed
	if input_vector.length_squared() > 0.01:
		_update_direction(input_vector)
		_walk_time += delta
		_footstep_time -= delta
		if _footstep_time <= 0.0:
			_footstep_time = footstep_interval
			Audio.play_sfx(footstep_sound, -15.0, randf_range(0.92, 1.08))
	else:
		_walk_time = 0.0
		_footstep_time = 0.0
	move_and_slide()
	_update_frame(input_vector.length_squared() > 0.01)


func set_controls_enabled(value: bool) -> void:
	_controls_enabled = value
	if not value:
		velocity = Vector2.ZERO


func _read_movement_input() -> Vector2:
	# Las acciones permiten remapear los controles desde Proyecto > Ajustes del
	# proyecto > Mapa de entradas. La lectura física conserva el movimiento aun
	# si un proyecto importado mantuvo una caché vieja sin esas acciones.
	var action_vector := Vector2.ZERO
	if (
		InputMap.has_action("move_left")
		and InputMap.has_action("move_right")
		and InputMap.has_action("move_up")
		and InputMap.has_action("move_down")
	):
		action_vector = Input.get_vector(
			"move_left", "move_right", "move_up", "move_down"
		)
	if action_vector.length_squared() > 0.01:
		return action_vector

	var physical_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		physical_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		physical_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		physical_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		physical_vector.y += 1.0
	return physical_vector.normalized()


func _update_direction(input_vector: Vector2) -> void:
	if absf(input_vector.x) > absf(input_vector.y):
		_direction = 3 if input_vector.x > 0.0 else 1
	else:
		_direction = 0 if input_vector.y > 0.0 else 2


func _update_frame(is_moving: bool) -> void:
	if _sprite == null:
		return
	var use_step_frame := is_moving and int(_walk_time * 5.5) % 2 == 0
	_sprite.frame_coords = Vector2i(_direction, 1 if use_step_frame else 0)
	_sprite.position.y = -50.0 + (-2.0 if use_step_frame else 0.0)
