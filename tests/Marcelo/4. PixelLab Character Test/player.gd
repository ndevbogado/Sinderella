extends CharacterBody2D

@export var speed: float = 240.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Dirección inicial del personaje.
var last_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# Empieza quieto mirando hacia abajo.
	animated_sprite.play("idle_down")


func _physics_process(_delta: float) -> void:

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed

	move_and_slide()

	if direction != Vector2.ZERO:
		last_direction = direction
		play_walk_animation(direction)
	else:
		play_idle_animation(last_direction)


# ==========================================
# ANIMACIONES DE CAMINAR
# ==========================================

func play_walk_animation(direction: Vector2) -> void:

	var animation_name := get_direction_name(direction, "walk")

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


# ==========================================
# ANIMACIONES IDLE
# ==========================================

func play_idle_animation(direction: Vector2) -> void:

	var animation_name := get_direction_name(direction, "idle")

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


# ==========================================
# DETECTAR LAS 8 DIRECCIONES
# ==========================================

func get_direction_name(direction: Vector2, state: String) -> String:

	# ARRIBA
	if direction.y < -0.1:

		if direction.x < -0.1:
			return state + "_up_left"

		elif direction.x > 0.1:
			return state + "_up_right"

		else:
			return state + "_up"


	# ABAJO
	elif direction.y > 0.1:

		if direction.x < -0.1:
			return state + "_down_left"

		elif direction.x > 0.1:
			return state + "_down_right"

		else:
			return state + "_down"


	# IZQUIERDA
	elif direction.x < -0.1:
		return state + "_left"


	# DERECHA
	else:
		return state + "_right"
