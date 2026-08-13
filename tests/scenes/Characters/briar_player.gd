extends CharacterBody2D


# =========================================================
# MOVIMIENTO
# =========================================================

# Velocidad caminando.
@export var speed: float = 120.0

# Velocidad corriendo.
@export var run_speed: float = 220.0


# =========================================================
# REFERENCIAS
# =========================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D


# =========================================================
# CÁMARA
# =========================================================

@export_range(1, 4, 1)
var initial_zoom: int = 1

var zoom_level: int


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	zoom_level = initial_zoom
	camera.zoom = Vector2.ONE * zoom_level

	animated_sprite.play("idle")


# =========================================================
# MOVIMIENTO DEL PERSONAJE
# =========================================================

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	var is_running: bool = Input.is_action_pressed("run")

	# Elegimos la velocidad según Shift.
	if is_running:
		velocity = direction * run_speed
	else:
		velocity = direction * speed

	move_and_slide()

	# Si Briar está quieta, vuelve al idle.
	if direction == Vector2.ZERO:
		animated_sprite.flip_h = false

		if animated_sprite.animation != &"idle":
			animated_sprite.play("idle")

		return

	# Elegimos caminar o correr.
	if is_running:
		update_run_animation(direction)
	else:
		update_walk_animation(direction)


# =========================================================
# ANIMACIONES DE CAMINAR
# =========================================================

func update_walk_animation(direction: Vector2) -> void:
	var horizontal := direction.x
	var vertical := direction.y

	# Norte y diagonales superiores.
	if vertical < -0.1:
		if horizontal > 0.1:
			set_walk_animation(&"walk_NE", false)

		elif horizontal < -0.1:
			set_walk_animation(&"walk_NE", true)

		else:
			set_walk_animation(&"walk_N", false)

	# Sur y diagonales inferiores.
	elif vertical > 0.1:
		if horizontal > 0.1:
			set_walk_animation(&"walk_SE", false)

		elif horizontal < -0.1:
			set_walk_animation(&"walk_SE", true)

		else:
			set_walk_animation(&"walk_S", false)

	# Este y oeste.
	else:
		if horizontal > 0.0:
			set_walk_animation(&"walk_E", false)

		else:
			set_walk_animation(&"walk_E", true)


func set_walk_animation(
	animation_name: StringName,
	flipped: bool
) -> void:
	animated_sprite.flip_h = flipped

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


# =========================================================
# ANIMACIONES DE CORRER
# =========================================================

func update_run_animation(direction: Vector2) -> void:
	var horizontal := direction.x
	var vertical := direction.y

	# IMPORTANTE:
	# Tus nuevas animaciones tienen las 8 direcciones reales.
	# Por eso NO necesitamos espejar ninguna.

	animated_sprite.flip_h = false

	# Norte.
	if vertical < -0.1:
		if horizontal > 0.1:
			play_run_animation(&"run_NE")

		elif horizontal < -0.1:
			play_run_animation(&"run_NW")

		else:
			play_run_animation(&"run_N")

	# Sur.
	elif vertical > 0.1:
		if horizontal > 0.1:
			play_run_animation(&"run_SE")

		elif horizontal < -0.1:
			play_run_animation(&"run_SW")

		else:
			play_run_animation(&"run_S")

	# Este / Oeste.
	else:
		if horizontal > 0.0:
			play_run_animation(&"run_E")

		else:
			play_run_animation(&"run_W")


func play_run_animation(
	animation_name: StringName
) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


# =========================================================
# ZOOM DE CÁMARA
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = mini(
				zoom_level + 1,
				4
			)

			update_camera_zoom()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = maxi(
				zoom_level - 1,
				1
			)

			update_camera_zoom()


func update_camera_zoom() -> void:
	camera.zoom = Vector2.ONE * zoom_level
