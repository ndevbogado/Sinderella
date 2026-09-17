extends Node2D


# =========================================================
# ÁRBOLES
# =========================================================

@export var tree_scene: PackedScene
@export var tree_count: int = 20
@export var minimum_distance: float = 160.0
@export var random_seed: int = 12345


# =========================================================
# PASTO ALTO
# =========================================================

@export var grass_scene: PackedScene
@export var grass_count: int = 300
@export var grass_minimum_distance: float = 20.0
@export var grass_seed: int = 67890


# =========================================================
# TILEMAP
# =========================================================

@onready var terrain: TileMapLayer = $Terrain32


func _ready() -> void:
	spawn_random_trees()
	#spawn_random_grass()


# =========================================================
# GENERAR ÁRBOLES
# =========================================================

func spawn_random_trees() -> void:
	if tree_scene == null:
		print("Falta asignar tree_scene.")
		return

	var cells := terrain.get_used_cells()

	if cells.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed

	var placed_positions: Array[Vector2] = []

	var attempts := 0
	var max_attempts := tree_count * 100

	while placed_positions.size() < tree_count and attempts < max_attempts:
		attempts += 1

		var cell: Vector2i = cells[
			rng.randi_range(0, cells.size() - 1)
		]

		var spawn_position := terrain.map_to_local(cell)

		spawn_position += Vector2(
			rng.randf_range(-16.0, 16.0),
			rng.randf_range(-16.0, 16.0)
		)

		var valid := true

		for existing_position in placed_positions:
			if spawn_position.distance_to(existing_position) < minimum_distance:
				valid = false
				break

		if not valid:
			continue

		var tree := tree_scene.instantiate()
		add_child(tree)

		tree.position = spawn_position
		placed_positions.append(spawn_position)


# =========================================================
# GENERAR PASTO ALTO
# =========================================================

func spawn_random_grass() -> void:
	if grass_scene == null:
		print("Falta asignar grass_scene.")
		return

	var cells := terrain.get_used_cells()

	if cells.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = grass_seed

	var placed_positions: Array[Vector2] = []

	var attempts := 0
	var max_attempts := grass_count * 100

	while placed_positions.size() < grass_count and attempts < max_attempts:
		attempts += 1

		var cell: Vector2i = cells[
			rng.randi_range(0, cells.size() - 1)
		]

		var spawn_position := terrain.map_to_local(cell)

		# Evita que el pasto quede perfectamente alineado con la cuadrícula.
		spawn_position += Vector2(
			rng.randf_range(-12.0, 12.0),
			rng.randf_range(-12.0, 12.0)
		)

		var valid := true

		for existing_position in placed_positions:
			if spawn_position.distance_to(existing_position) < grass_minimum_distance:
				valid = false
				break

		if not valid:
			continue

		var grass := grass_scene.instantiate()
		add_child(grass)

		grass.position = spawn_position
		placed_positions.append(spawn_position)
