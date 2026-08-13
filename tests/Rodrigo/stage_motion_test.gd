extends Node2D


# Velocidad general del movimiento.
@export_range(0.0, 3.0, 0.01)
var movement_speed: float = 0.36

# Intensidad del desplazamiento del suelo.
@export_range(0.0, 0.30, 0.001)
var floor_movement: float = 0.045

# Movimiento rígido de la parte superior.
@export_range(0.0, 100.0, 1.0)
var upper_movement: float = 14.0

# Movimiento del plano cercano, donde está Briar.
# Conservamos el nombre para no perder tu valor 56 del Inspector.
@export_range(0.0, 150.0, 1.0)
var characters_movement: float = 56.0

# Movimiento del monstruo, que está más cerca del horizonte.
@export_range(0.0, 150.0, 1.0)
var enemy_movement: float = 24.0


@onready var upper_background: Sprite2D = $UpperBackground
@onready var perspective_floor: Sprite2D = $PerspectiveFloor

@onready var characters_container: Node2D = $"../Node2D"
@onready var enemy_sprite: Node2D = (
	$"../Node2D/Asdsadasdadas"
)


var movement_time: float = 0.0

var upper_original_x: float = 0.0
var characters_original_x: float = 0.0

var floor_material: ShaderMaterial

# Contenedor creado automáticamente para dar al monstruo
# una velocidad diferente sin afectar su temblor.
var enemy_depth_container: Node2D = null
var enemy_depth_original_x: float = 0.0


func _ready() -> void:
	upper_original_x = upper_background.position.x
	characters_original_x = characters_container.position.x

	floor_material = perspective_floor.material as ShaderMaterial

	if floor_material == null:
		push_error(
			"PerspectiveFloor no tiene un ShaderMaterial."
		)
		set_process(false)
		return

	# Esperamos a que Rose termine de crear las sombras.
	call_deferred("_setup_enemy_depth_container")


func _setup_enemy_depth_container() -> void:
	if enemy_depth_container != null:
		return

	enemy_depth_container = Node2D.new()
	enemy_depth_container.name = "EnemyDepthMotion"

	characters_container.add_child(
		enemy_depth_container
	)

	enemy_depth_container.position = Vector2.ZERO
	enemy_depth_original_x = 0.0

	# El monstruo pasa al nuevo contenedor,
	# pero conserva su posición visual.
	enemy_sprite.reparent(
		enemy_depth_container,
		true
	)

	# También movemos su sombra al mismo contenedor.
	var shadow_candidate: Variant = (
		get_parent().get("enemy_shadow")
	)

	if shadow_candidate is Node2D:
		var enemy_shadow := shadow_candidate as Node2D

		enemy_shadow.reparent(
			enemy_depth_container,
			true
		)


func _process(delta: float) -> void:
	movement_time += delta * movement_speed

	# Oscila suavemente entre -1 y 1.
	var horizontal_motion: float = sin(
		movement_time
	)

	# El suelo se desplaza con perspectiva.
	floor_material.set_shader_parameter(
		"scroll_offset",
		horizontal_motion * floor_movement
	)

	# La mitad superior se mueve rígidamente.
	upper_background.position.x = (
		upper_original_x
		- horizontal_motion * upper_movement
	)

	# Briar conserva exactamente el movimiento 56
	# que ya estaba bien sincronizado.
	characters_container.position.x = (
		characters_original_x
		- horizontal_motion * characters_movement
	)

	# El contenedor del monstruo contrarresta parte
	# del movimiento del plano cercano.
	if enemy_depth_container != null:
		var depth_correction: float = (
			characters_movement
			- enemy_movement
		)

		enemy_depth_container.position.x = (
			enemy_depth_original_x
			+ horizontal_motion * depth_correction
		)
