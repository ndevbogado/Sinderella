extends Camera2D


# Sensibilidad del arrastre horizontal.
@export_range(0.10, 3.0, 0.05)
var drag_sensitivity: float = 0.28

# Espacio de seguridad en ambos extremos.
@export_range(0.0, 500.0, 1.0)
var edge_safety_px: float = 140.0

# Velocidad del regreso automático de la cámara al centro.
@export_range(0.1, 20.0, 0.1)
var return_speed: float = 4.0

# Imagen usada para calcular el ancho del escenario
# y para aplicar el aplanamiento vertical.
@export var stage_reference_path: NodePath = NodePath(
	"../StageTest/PerspectiveFloor"
)

# Personajes que deben mantenerse pegados al suelo.
@export var briar_path: NodePath = NodePath(
	"../Node2D/AnimatedSprite2D"
)

@export var enemy_path: NodePath = NodePath(
	"../Node2D/Asdsadasdadas"
)


# =========================================================
# APLANAMIENTO VERTICAL DEL SUELO
# =========================================================

# Compresión máxima del suelo.
# 0.10 significa que, al máximo, conserva el 90 % de su altura.
@export_range(0.0, 0.30, 0.01)
var max_floor_flatten: float = 0.10

# Cuánto responde el aplanamiento al arrastre vertical.
@export_range(0.0001, 0.0200, 0.0001)
var vertical_drag_sensitivity: float = 0.0025

# Evita que pequeños temblores verticales del mouse
# activen el aplanamiento durante un arrastre horizontal.
@export_range(0.0, 10.0, 0.1)
var vertical_drag_deadzone_px: float = 1.0

# Altura normalizada donde se une el suelo con el fondo.
# 0.54 = 54 % de la altura de la textura.
# Ese punto se mantiene fijo mientras el suelo se aplana.
@export_range(0.0, 1.0, 0.01)
var floor_pivot_ratio_y: float = 0.54

# Velocidad con la que el suelo recupera su altura al soltar.
@export_range(0.1, 20.0, 0.1)
var floor_return_speed: float = 5.0

# Correcciones opcionales por si el punto de origen visual
# de un sprite no coincide exactamente con sus pies.
@export_range(-100.0, 100.0, 1.0)
var briar_floor_follow_correction_y: float = -10.0

@export_range(-100.0, 100.0, 1.0)
var enemy_floor_follow_correction_y: float = -10.0


@onready var stage_reference: Sprite2D = get_node_or_null(
	stage_reference_path
) as Sprite2D

@onready var briar: Node2D = get_node_or_null(
	briar_path
) as Node2D

@onready var enemy: Node2D = get_node_or_null(
	enemy_path
) as Node2D


var is_dragging: bool = false
var cinematic_locked: bool = false

var fixed_y: float = 0.0
var center_camera_x: float = 0.0

var minimum_camera_x: float = 0.0
var maximum_camera_x: float = 0.0

# Estado original del suelo.
var floor_original_position: Vector2 = Vector2.ZERO
var floor_original_scale: Vector2 = Vector2.ONE
var floor_pivot_local_y: float = 0.0
var floor_pivot_global_y: float = 0.0

# Alturas originales de los personajes y sus sombras.
var briar_original_global_y: float = 0.0
var enemy_original_global_y: float = 0.0

var briar_shadow: Node2D = null
var enemy_shadow: Node2D = null
var briar_shadow_original_global_y: float = 0.0
var enemy_shadow_original_global_y: float = 0.0

var followers_ready: bool = false

# 0.0 = altura normal.
# 1.0 = máximo aplanamiento permitido.
var floor_flatten_amount: float = 0.0


func _ready() -> void:
	enabled = true
	position_smoothing_enabled = false

	fixed_y = position.y

	if not prepare_floor_reference():
		set_process_input(false)
		return

	calculate_horizontal_limits()

	center_camera_x = (
		minimum_camera_x
		+ maximum_camera_x
	) * 0.5

	position.x = center_camera_x
	position.y = fixed_y

	# Las sombras se crean en _ready() del nodo Rose.
	# Esperamos un instante y luego guardamos sus posiciones.
	call_deferred("capture_floor_followers")

	apply_floor_flatten()


func capture_floor_followers() -> void:
	if briar == null:
		push_error("No se encontró a Briar en la ruta configurada.")
		return

	if enemy == null:
		push_error("No se encontró al enemigo en la ruta configurada.")
		return

	briar_original_global_y = briar.global_position.y
	enemy_original_global_y = enemy.global_position.y

	# Rose guarda las sombras en estas dos variables públicas.
	var battle_root: Node = get_parent()

	if battle_root != null:
		briar_shadow = battle_root.get("briar_shadow") as Node2D
		enemy_shadow = battle_root.get("enemy_shadow") as Node2D

	if briar_shadow != null:
		briar_shadow_original_global_y = briar_shadow.global_position.y

	if enemy_shadow != null:
		enemy_shadow_original_global_y = enemy_shadow.global_position.y

	followers_ready = true
	apply_floor_flatten()


func _input(event: InputEvent) -> void:
	# Durante un Perfect Hit, rose_battle.gd controla la cámara.
	if cinematic_locked:
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = mouse_button.pressed

	elif event is InputEventMouseMotion and is_dragging:
		var mouse_motion := event as InputEventMouseMotion

		# Movimiento horizontal de la cámara.
		position.x -= (
			mouse_motion.relative.x
			* drag_sensitivity
			/ zoom.x
		)

		position.x = clampf(
			position.x,
			minimum_camera_x,
			maximum_camera_x
		)

		# Arrastrar hacia abajo aumenta el aplanamiento.
		# Arrastrar hacia arriba lo reduce.
		var vertical_delta: float = mouse_motion.relative.y

		if vertical_delta > vertical_drag_deadzone_px:
			vertical_delta -= vertical_drag_deadzone_px
		elif vertical_delta < -vertical_drag_deadzone_px:
			vertical_delta += vertical_drag_deadzone_px
		else:
			vertical_delta = 0.0

		floor_flatten_amount = clampf(
			floor_flatten_amount
			+ vertical_delta * vertical_drag_sensitivity,
			0.0,
			1.0
		)

		apply_floor_flatten()

		# El movimiento libre de la cámara sigue siendo horizontal.
		position.y = fixed_y


func _process(delta: float) -> void:
	if cinematic_locked:
		is_dragging = false
		return

	# Seguridad por si soltás el botón fuera de la ventana.
	if (
		is_dragging
		and not Input.is_mouse_button_pressed(
			MOUSE_BUTTON_LEFT
		)
	):
		is_dragging = false

	# Al soltar, la cámara vuelve al centro y el suelo
	# recupera suavemente su altura original.
	if not is_dragging:
		var return_weight: float = (
			1.0
			- exp(-return_speed * delta)
		)

		position.x = lerpf(
			position.x,
			center_camera_x,
			return_weight
		)

		if absf(position.x - center_camera_x) < 0.1:
			position.x = center_camera_x

		return_floor_to_normal(delta)

	position.x = clampf(
		position.x,
		minimum_camera_x,
		maximum_camera_x
	)

	position.y = fixed_y


# Activa o desactiva el control cinematográfico.
# Lo usa rose_battle.gd durante el Perfect Hit.
func set_cinematic_lock(value: bool) -> void:
	cinematic_locked = value
	is_dragging = false

	# Antes del acercamiento, devolvemos inmediatamente el suelo
	# y los personajes a su estado normal. Así el temblor del enemigo
	# no pelea contra el aplanamiento vertical.
	if cinematic_locked:
		floor_flatten_amount = 0.0
		apply_floor_flatten()


# Devuelve una posición segura para encuadrar un objetivo.
func get_focus_camera_position(
	target_global_position: Vector2,
	target_zoom: Vector2,
	screen_ratio: Vector2
) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size

	var desired_screen_offset: Vector2 = Vector2(
		(screen_ratio.x - 0.5) * viewport_size.x,
		(screen_ratio.y - 0.5) * viewport_size.y
	)

	var desired_camera_position: Vector2 = (
		target_global_position
		- Vector2(
			desired_screen_offset.x / target_zoom.x,
			desired_screen_offset.y / target_zoom.y
		)
	)

	desired_camera_position.x = clampf(
		desired_camera_position.x,
		minimum_camera_x,
		maximum_camera_x
	)

	return desired_camera_position


func prepare_floor_reference() -> bool:
	if stage_reference == null:
		push_error(
			"No se encontró StageTest/PerspectiveFloor."
		)
		return false

	if stage_reference.texture == null:
		push_error(
			"PerspectiveFloor no tiene textura."
		)
		return false

	floor_original_position = stage_reference.position
	floor_original_scale = stage_reference.scale

	var texture_height: float = float(
		stage_reference.texture.get_height()
	)

	floor_pivot_local_y = (
		stage_reference.offset.y
		+ texture_height * floor_pivot_ratio_y
	)

	if stage_reference.centered:
		floor_pivot_local_y -= texture_height * 0.5

	# Guardamos el punto real del mundo donde el suelo se une
	# con la mitad superior del escenario.
	floor_pivot_global_y = stage_reference.to_global(
		Vector2(0.0, floor_pivot_local_y)
	).y

	return true


func apply_floor_flatten() -> void:
	if stage_reference == null:
		return

	var height_factor: float = lerpf(
		1.0,
		1.0 - max_floor_flatten,
		floor_flatten_amount
	)

	var new_scale_y: float = (
		floor_original_scale.y
		* height_factor
	)

	stage_reference.scale = Vector2(
		floor_original_scale.x,
		new_scale_y
	)

	# Mantiene fija la línea donde el suelo se une con el fondo.
	stage_reference.position = Vector2(
		floor_original_position.x,
		floor_original_position.y
		+ floor_pivot_local_y
		* (floor_original_scale.y - new_scale_y)
	)

	# Los personajes no se escalan. Solo trasladamos su altura
	# usando la misma transformación vertical que recibió el suelo.
	apply_followers_to_floor(height_factor)


func apply_followers_to_floor(height_factor: float) -> void:
	if not followers_ready:
		return

	if briar != null:
		var briar_position: Vector2 = briar.global_position
		briar_position.y = floor_pivot_global_y + (
			briar_original_global_y - floor_pivot_global_y
		) * height_factor + (
			briar_floor_follow_correction_y
			* floor_flatten_amount
		)
		briar.global_position = briar_position

	if enemy != null:
		var enemy_position: Vector2 = enemy.global_position
		enemy_position.y = floor_pivot_global_y + (
			enemy_original_global_y - floor_pivot_global_y
		) * height_factor + (
			enemy_floor_follow_correction_y
			* floor_flatten_amount
		)
		enemy.global_position = enemy_position

	if briar_shadow != null:
		var briar_shadow_position: Vector2 = briar_shadow.global_position
		briar_shadow_position.y = floor_pivot_global_y + (
			briar_shadow_original_global_y - floor_pivot_global_y
		) * height_factor + (
			briar_floor_follow_correction_y
			* floor_flatten_amount
		)
		briar_shadow.global_position = briar_shadow_position

	if enemy_shadow != null:
		var enemy_shadow_position: Vector2 = enemy_shadow.global_position
		enemy_shadow_position.y = floor_pivot_global_y + (
			enemy_shadow_original_global_y - floor_pivot_global_y
		) * height_factor + (
			enemy_floor_follow_correction_y
			* floor_flatten_amount
		)
		enemy_shadow.global_position = enemy_shadow_position


func return_floor_to_normal(delta: float) -> void:
	if floor_flatten_amount <= 0.0:
		return

	var return_weight: float = (
		1.0
		- exp(-floor_return_speed * delta)
	)

	floor_flatten_amount = lerpf(
		floor_flatten_amount,
		0.0,
		return_weight
	)

	if floor_flatten_amount < 0.001:
		floor_flatten_amount = 0.0

	apply_floor_flatten()


func calculate_horizontal_limits() -> void:
	if stage_reference == null:
		return

	var viewport_width: float = get_viewport_rect().size.x

	var visible_world_width: float = (
		viewport_width
		/ zoom.x
	)

	var half_visible_width: float = (
		visible_world_width
		* 0.5
	)

	var texture_width: float = float(
		stage_reference.texture.get_width()
	)

	var stage_width: float = (
		texture_width
		* absf(stage_reference.global_scale.x)
	)

	var stage_left: float = (
		stage_reference.global_position.x
	)

	if stage_reference.centered:
		stage_left -= stage_width * 0.5

	var stage_right: float = (
		stage_left
		+ stage_width
	)

	minimum_camera_x = (
		stage_left
		+ half_visible_width
		+ edge_safety_px
	)

	maximum_camera_x = (
		stage_right
		- half_visible_width
		- edge_safety_px
	)

	if maximum_camera_x < minimum_camera_x:
		var stage_center: float = (
			stage_left
			+ stage_right
		) * 0.5

		minimum_camera_x = stage_center
		maximum_camera_x = stage_center
