extends TileMapLayer

@onready var cape_alert: Label = $"../BriarPlayer/CapeAlert"
@onready var briar: CharacterBody2D = $"../BriarPlayer"
@onready var grass_audio: AudioStreamPlayer2D = $GrassAudio
@onready var cape_grass_audio: AudioStreamPlayer2D = $CapeGrassAudio

# =========================================================
# PASTO NORMAL / BRIAR
# =========================================================

@export var grass_sound_interval: float = 0.18
var grass_sound_cooldown: float = 0.0


# =========================================================
# EVENTO DE CAPERUZA
# =========================================================

# 0.90 para probar. Luego bajar a 0.10.
@export_range(0.0, 1.0, 0.01) var cape_event_chance: float = 0.10

@export var normal_music: AudioStreamPlayer
@export var tension_music: AudioStreamPlayer

# Arrastra aquí rose_battle.tscn.
@export var battle_scene: PackedScene

# Distancia inicial de la presencia invisible.
@export var cape_start_min_distance: float = 8.0
@export var cape_start_max_distance: float = 15.0

# Velocidad de avance entre una mata y la siguiente.
# Como ya NO esperamos a que termine toda la animación anterior,
# 0.055 da una persecución bastante agresiva.
@export var cape_step_pause: float = 0.1

# 90 % de las veces intenta acercarse.
# 10 % puede desviarse para que no vaya perfectamente recta.
@export_range(0.0, 1.0, 0.05) var cape_approach_bias: float = 0.90

# Limita la frecuencia del sonido de la mata perseguidora.
@export var cape_sound_interval: float = 0.12
var cape_sound_cooldown: float = 0.0

var cape_event_started: bool = false
var cape_chase_running: bool = false

var last_cell := Vector2i(999999, 999999)
var animating_cells: Dictionary = {}

var rng := RandomNumberGenerator.new()

const GRASS_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1)
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	rng.randomize()

	# CapeGrassAudio usa el mismo sonido que GrassAudio.
	if cape_grass_audio.stream == null:
		cape_grass_audio.stream = grass_audio.stream

	cape_grass_audio.max_polyphony = 1

	# Evita que el evento se active apenas inicia la escena
	# si Briar ya aparece encima de una mata.
	var local_position := to_local(briar.global_position)
	last_cell = local_to_map(local_position)


func _physics_process(delta: float) -> void:
	grass_sound_cooldown = max(
		grass_sound_cooldown - delta,
		0.0
	)

	cape_sound_cooldown = max(
		cape_sound_cooldown - delta,
		0.0
	)

	var local_position := to_local(briar.global_position)
	var current_cell := local_to_map(local_position)

	if current_cell == last_cell:
		return

	last_cell = current_cell

	# Briar no entró en pasto alto.
	if get_cell_source_id(current_cell) == -1:
		return

	# Animación normal producida por Briar.
	animate_grass(current_cell)

	# Solo hacemos la tirada mientras el evento todavía no empezó.
	if not cape_event_started:
		try_start_cape_event()


# =========================================================
# ANIMACIÓN NORMAL DEL PASTO
# =========================================================

func animate_grass(cell: Vector2i) -> void:
	if animating_cells.has(cell):
		return

	animating_cells[cell] = true
	play_grass_sound()

	var source_id := get_cell_source_id(cell)
	var alternative_id := get_cell_alternative_tile(cell)

	var frames := [
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(4, 0),
		Vector2i(3, 0),
		Vector2i(2, 0),
		Vector2i(1, 0),
		Vector2i(0, 0)
	]

	for atlas_coords in frames:
		# IMPORTANTE:
		# Al cambiar a rose_battle esta escena desaparece.
		# Sin esta comprobación, get_tree() puede pasar a ser null
		# y causar el crash que viste.
		if not is_inside_tree():
			return

		set_cell(cell, source_id, atlas_coords, alternative_id)

		var tree := get_tree()
		if tree == null:
			return

		await tree.create_timer(0.06).timeout

	if is_inside_tree():
		animating_cells.erase(cell)


func play_grass_sound() -> void:
	if grass_sound_cooldown > 0.0:
		return

	grass_sound_cooldown = grass_sound_interval
	grass_audio.global_position = briar.global_position
	grass_audio.play()


# =========================================================
# INICIO DEL EVENTO DE CAPERUZA
# =========================================================

func try_start_cape_event() -> void:
	if cape_event_started:
		return

	if rng.randf() > cape_event_chance:
		return

	cape_event_started = true

	# Cortamos la música normal inmediatamente.
	if normal_music != null:
		normal_music.stop()

	print("EVENTO DE CAPERUZA ACTIVADO")

	# Congelamos el juego y mostramos la exclamación.
	await cape_warning_freeze()

	# Al terminar el segundo empieza la tensión.
	if tension_music != null:
		tension_music.play()

	# Y recién ahora comienza a moverse el pasto.
	run_cape_chase()


# =========================================================
# PERSECUCIÓN INVISIBLE
# =========================================================

func run_cape_chase() -> void:
	if cape_chase_running:
		return

	cape_chase_running = true

	var briar_cell := get_briar_cell()
	var cape_cell := choose_cape_start_cell(briar_cell)

	if cape_cell == briar_cell:
		push_warning("No encontré una mata lejana para iniciar la persecución.")
		cape_chase_running = false
		return

	var previous_cell := Vector2i(999999, 999999)

	while cape_chase_running:
		if not is_inside_tree():
			return

		# Briar puede moverse: recalculamos su posición en cada paso.
		briar_cell = get_briar_cell()

		# IMPORTANTE:
		# No usamos await aquí.
		# La persecución puede pasar a la siguiente mata mientras la anterior
		# todavía termina de moverse. Esto la vuelve mucho más agresiva.
		animate_cape_grass(cape_cell)

		# Si la presencia ya llegó al lado de Briar, empieza el combate.
		if cell_distance(cape_cell, briar_cell) <= 1.5:
			var tree_before_battle := get_tree()
			if tree_before_battle == null:
				return

			await tree_before_battle.create_timer(0.18).timeout

			if not is_inside_tree():
				return

			start_battle()
			return

		var next_cell := choose_random_approach_cell(
			cape_cell,
			briar_cell,
			previous_cell
		)

		if next_cell == cape_cell:
			var blocked_tree := get_tree()
			if blocked_tree == null:
				return

			await blocked_tree.create_timer(0.03).timeout
			continue

		previous_cell = cape_cell
		cape_cell = next_cell

		var tree := get_tree()
		if tree == null:
			return

		await tree.create_timer(cape_step_pause).timeout


func animate_cape_grass(cell: Vector2i) -> void:
	if not is_inside_tree():
		return

	if get_cell_source_id(cell) == -1:
		return

	# Si esa mata ya está siendo animada por Briar o por otra parte
	# de la estela, no intentamos controlarla dos veces.
	if animating_cells.has(cell):
		play_cape_grass_sound(cell)
		return

	animating_cells[cell] = true
	play_cape_grass_sound(cell)

	var source_id := get_cell_source_id(cell)
	var alternative_id := get_cell_alternative_tile(cell)

	var frames := [
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(4, 0),
		Vector2i(2, 0),
		Vector2i(0, 0)
	]

	for atlas_coords in frames:
		if not is_inside_tree():
			return

		set_cell(cell, source_id, atlas_coords, alternative_id)

		var tree := get_tree()
		if tree == null:
			return

		await tree.create_timer(0.035).timeout

	if is_inside_tree():
		animating_cells.erase(cell)


func play_cape_grass_sound(cell: Vector2i) -> void:
	if cape_sound_cooldown > 0.0:
		return

	if cape_grass_audio.stream == null:
		return

	cape_sound_cooldown = cape_sound_interval

	# El sonido sale desde la mata que se está moviendo.
	cape_grass_audio.global_position = to_global(map_to_local(cell))
	cape_grass_audio.play()


# =========================================================
# ELECCIÓN DE MATAS
# =========================================================

func choose_cape_start_cell(briar_cell: Vector2i) -> Vector2i:
	# Solo usa el conjunto de pasto conectado donde está Briar.
	var connected_grass := get_connected_grass(briar_cell)

	if connected_grass.is_empty():
		return briar_cell

	var candidates: Array[Vector2i] = []

	for cell in connected_grass:
		var distance := cell_distance(cell, briar_cell)

		if distance >= cape_start_min_distance and distance <= cape_start_max_distance:
			candidates.append(cell)

	if not candidates.is_empty():
		return candidates[rng.randi_range(0, candidates.size() - 1)]

	# Si no encuentra una dentro del rango, elige la más lejana.
	var farthest_cell: Vector2i = connected_grass[0]
	var farthest_distance: float = -1.0

	for cell in connected_grass:
		var distance := cell_distance(cell, briar_cell)

		if distance > farthest_distance:
			farthest_distance = distance
			farthest_cell = cell

	return farthest_cell


func choose_random_approach_cell(
	current_cell: Vector2i,
	target_cell: Vector2i,
	previous_cell: Vector2i
) -> Vector2i:

	var options: Array[Vector2i] = []

	for direction in GRASS_NEIGHBORS:
		var candidate := current_cell + direction

		if get_cell_source_id(candidate) != -1:
			options.append(candidate)

	if options.is_empty():
		return current_cell

	# Evita ir A-B-A-B todo el tiempo.
	if options.size() > 1 and options.has(previous_cell):
		options.erase(previous_cell)

	var current_distance := cell_distance(current_cell, target_cell)
	var closer_options: Array[Vector2i] = []

	for candidate in options:
		if cell_distance(candidate, target_cell) < current_distance:
			closer_options.append(candidate)

	# Casi siempre se acerca.
	if not closer_options.is_empty() and rng.randf() < cape_approach_bias:
		return closer_options[rng.randi_range(0, closer_options.size() - 1)]

	# A veces toma una dirección lateral/aleatoria.
	return options[rng.randi_range(0, options.size() - 1)]


func get_connected_grass(start_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if get_cell_source_id(start_cell) == -1:
		return result

	var queue: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {}
	visited[start_cell] = true

	var index := 0

	while index < queue.size():
		var cell := queue[index]
		index += 1
		result.append(cell)

		for direction in GRASS_NEIGHBORS:
			var next_cell := cell + direction

			if visited.has(next_cell):
				continue

			if get_cell_source_id(next_cell) == -1:
				continue

			visited[next_cell] = true
			queue.append(next_cell)

	return result


func get_briar_cell() -> Vector2i:
	return local_to_map(to_local(briar.global_position))


func cell_distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a).distance_to(Vector2(b))


# =========================================================
# COMBATE
# =========================================================

func start_battle() -> void:
	cape_chase_running = false

	if battle_scene == null:
		push_warning("Falta asignar rose_battle.tscn en Battle Scene.")
		return

	var tree := get_tree()
	if tree == null:
		return

	tree.change_scene_to_packed(battle_scene)

func cape_warning_freeze() -> void:
	# Congelamos todo.
	get_tree().paused = true

	# Signo sobre Briar.
	cape_alert.show()

	# Esperamos 1 segundo REAL aunque el juego esté pausado.
	await get_tree().create_timer(
		1.0,
		true,
		false,
		true
	).timeout

	cape_alert.hide()

	# El mundo vuelve a moverse.
	get_tree().paused = false
