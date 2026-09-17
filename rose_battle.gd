extends Node2D


# =========================================================
# REFERENCIAS DE LA ESCENA
# =========================================================

@onready var enemy_hp = $UI/enemyhp
@onready var briar_sprite = $Node2D/AnimatedSprite2D
@onready var enemy_sprite = $Node2D/Asdsadasdadas

@onready var perfect_hit_bar = $UI/perfect_hit_bar
@onready var needle = $UI/perfect_hit_bar/Needle
@onready var flash = $UI/perfect_hit_bar/Flash

# Nodo que contiene a Briar, al enemigo y las sombras.
@onready var battle_world: Node2D = $Node2D

# Cámara real del combate, controlada también por mouse_camera.gd.
@onready var mouse_camera: Camera2D = $MouseCamera

# Música y letras.
@onready var battle_music: AudioStreamPlayer = $BattleMusic
@onready var lyrics_layer: Node2D = $LyricsLayer
@onready var lyric_label: Label = $LyricsLayer/LyricLabel

# Perfect hit sonido
@onready var perfect_hit_sound: AudioStreamPlayer = $PerfectHitSound

# =========================================================
# LETRAS SINCRONIZADAS CON LA MÚSICA
# =========================================================

var current_lyric_index: int = -1

var lyrics_base_position: Vector2 = Vector2.ZERO
var lyrics_base_scale: Vector2 = Vector2.ONE

# Tiempos expresados en segundos desde el inicio de la canción.
# start: empieza a aparecer.
# reveal_end: termina de escribirse.
# end: desaparece.
var lyric_lines: Array[Dictionary] = [
	{
		"start": 1.0,
		"reveal_end": 3.0,
		"end": 5.5,
		"text": "esta es una prueba para...",
		"angle": -12.0
	},
	{
		"start": 6.0,
		"reveal_end": 8.0,
		"end": 10.5,
		"text": "probar los angulos de las frases",
		"angle": 12.0
	},
	{
		"start": 11.0,
		"reveal_end": 13.0,
		"end": 15.0,
		"text": "y ver que mas podemos lograr",
		"angle": -8.0
	}
]


# =========================================================
# SOMBRAS AUTOMÁTICAS
# =========================================================

var briar_shadow: CharacterShadow
var enemy_shadow: CharacterShadow

@export_range(0.30, 0.90, 0.01)
var auto_shadow_width_ratio: float = 0.58

@export_range(0.08, 0.30, 0.01)
var auto_shadow_height_ratio: float = 0.16

@export_range(0.30, 0.60, 0.01)
var auto_shadow_vertical_ratio: float = 0.45

@export_range(0.0, 1.0, 0.01)
var auto_shadow_opacity: float = 0.44

@export var auto_shadow_min_width: float = 70.0
@export var auto_shadow_max_width: float = 260.0


# =========================================================
# VIDA DEL ENEMIGO
# =========================================================

var enemy_current_hp: int = 1000
var enemy_max_hp: int = 1000


# =========================================================
# PERFECT HIT
# =========================================================

var timing_active: bool = false

var needle_speed: float = 440.0
var needle_direction: int = 1

var needle_left_x: float = 45.0
var needle_right_x: float = 445.0

var perfect_center_x: float = 250.0
var perfect_left_margin: float = 5.0
var perfect_right_margin: float = 2.0

var good_center_x: float = 256.0
var good_margin: float = 42.0

# La aguja mide 24 píxeles de ancho.
var needle_hit_offset_x: float = 12.0


# =========================================================
# CÁMARA DEL PERFECT HIT
# =========================================================

# Multiplicador del zoom actual de MouseCamera.
# 1.30 significa un acercamiento del 30 %.
@export_range(1.0, 2.0, 0.01)
var perfect_zoom: float = 1.30

@export var perfect_zoom_in_time: float = 0.10
@export var perfect_zoom_out_time: float = 0.24

# Lugar de la pantalla donde queremos dejar al enemigo.
# X 0.50 = centro horizontal.
# X 0.62 = un poco a la derecha.
@export var perfect_focus_screen_ratio: Vector2 = Vector2(0.62, 0.42)

var camera_focus_strength: float = 0.0
var camera_zoom_factor: float = 1.0

var camera_return_position: Vector2 = Vector2.ZERO
var camera_return_zoom: Vector2 = Vector2.ONE

var impact_active: bool = false

# Posición local original del enemigo dentro de $Node2D.
var enemy_base_position: Vector2 = Vector2.ZERO


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	enemy_hp.min_value = 0
	enemy_hp.max_value = enemy_max_hp
	enemy_hp.value = enemy_current_hp

	briar_sprite.play("default")

	perfect_hit_bar.visible = false
	flash.visible = false

	perfect_hit_bar.position = Vector2(470.0, 360.0)

	needle.position = Vector2(needle_left_x, -8.0)
	flash.position = Vector2(224.0, 0.0)

	# Guardamos la posición local normal del enemigo.
	# El contenedor completo puede seguir moviéndose con el suelo.
	enemy_base_position = enemy_sprite.position

	# Generamos las sombras.
	briar_shadow = create_character_shadow(
		briar_sprite,
		1.06,
		1.05,
		-46.0
	)

	enemy_shadow = create_character_shadow(enemy_sprite)

	# Preparamos la capa de letra.
	setup_lyrics()


func _process(delta: float) -> void:
	update_perfect_hit_needle(delta)
	update_perfect_hit_camera()
	update_lyrics()


# =========================================================
# AGUJA DEL PERFECT HIT
# =========================================================

func update_perfect_hit_needle(delta: float) -> void:
	if not timing_active:
		return

	needle.position.x += (
		needle_speed
		* needle_direction
		* delta
	)

	if needle.position.x >= needle_right_x:
		needle.position.x = needle_right_x
		needle_direction = -1

	if needle.position.x <= needle_left_x:
		needle.position.x = needle_left_x
		needle_direction = 1


# =========================================================
# CÁMARA REAL DEL PERFECT HIT
# =========================================================

func update_perfect_hit_camera() -> void:
	if not impact_active:
		return

	# El zoom se aplica a Camera2D.
	# Por eso se acercan juntos el escenario y el enemigo,
	# en vez de agrandar solamente el contenedor de personajes.
	var current_zoom: Vector2 = (
		camera_return_zoom
		* camera_zoom_factor
	)

	mouse_camera.zoom = current_zoom

	# Usamos la posición normal del enemigo dentro del contenedor.
	# Así la cámara no copia cada pequeño salto del temblor,
	# pero sí acompaña el movimiento general del suelo.
	var enemy_focus_global_position: Vector2 = (
		battle_world.to_global(enemy_base_position)
	)

	var target_camera_position: Vector2 = enemy_focus_global_position

	# mouse_camera.gd calcula el encuadre y respeta
	# los límites horizontales del escenario.
	if mouse_camera.has_method("get_focus_camera_position"):
		var calculated_focus: Variant = mouse_camera.call(
			"get_focus_camera_position",
			enemy_focus_global_position,
			current_zoom,
			perfect_focus_screen_ratio
		)

		if calculated_focus is Vector2:
			target_camera_position = calculated_focus

	else:
		# Respaldo por si MouseCamera todavía no tiene
		# el script actualizado.
		var viewport_size: Vector2 = get_viewport_rect().size

		var desired_screen_offset: Vector2 = Vector2(
			(
				perfect_focus_screen_ratio.x
				- 0.5
			) * viewport_size.x,
			(
				perfect_focus_screen_ratio.y
				- 0.5
			) * viewport_size.y
		)

		target_camera_position = (
			enemy_focus_global_position
			- Vector2(
				desired_screen_offset.x / current_zoom.x,
				desired_screen_offset.y / current_zoom.y
			)
		)

	# El enfoque entra y sale suavemente.
	mouse_camera.position = camera_return_position.lerp(
		target_camera_position,
		camera_focus_strength
	)


# =========================================================
# LETRAS DE LA MÚSICA
# =========================================================

func setup_lyrics() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	# La frase queda detrás de los personajes y delante del fondo.
	lyrics_layer.z_index = -5

	# Centro aproximado de la frase.
	lyrics_layer.position = Vector2(
		viewport_size.x * 0.50,
		viewport_size.y * 0.28
	)

	lyrics_base_position = lyrics_layer.position
	lyrics_base_scale = lyrics_layer.scale

	# El Label se extiende a ambos lados del origen del LyricsLayer.
	lyric_label.position = Vector2(
		-viewport_size.x * 0.45,
		-60.0
	)

	lyric_label.size = Vector2(
		viewport_size.x * 0.90,
		120.0
	)

	lyric_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lyric_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	lyric_label.text = ""
	lyric_label.visible_characters = 0
	lyric_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Estilo provisional.
	lyric_label.add_theme_font_size_override(
		"font_size",
		64
	)

	lyric_label.add_theme_constant_override(
		"outline_size",
		8
	)

	lyric_label.add_theme_color_override(
		"font_color",
		Color(0.253, 0.0, 0.671, 0.82)
	)

	lyric_label.add_theme_color_override(
		"font_outline_color",
		Color(0.725, 0.665, 0.943, 0.9)
	)


func get_battle_music_time() -> float:
	if not battle_music.playing:
		return 0.0

	var music_time: float = (
		battle_music.get_playback_position()
		+ AudioServer.get_time_since_last_mix()
		- AudioServer.get_output_latency()
	)

	return maxf(music_time, 0.0)


func update_lyrics() -> void:
	if not battle_music.playing:
		lyric_label.text = ""
		lyric_label.visible_characters = 0
		current_lyric_index = -1
		return

	var music_time: float = get_battle_music_time()
	var matching_line_index: int = -1

	for i in range(lyric_lines.size()):
		var line: Dictionary = lyric_lines[i]

		var line_start: float = float(line["start"])
		var line_end: float = float(line["end"])

		if music_time >= line_start and music_time < line_end:
			matching_line_index = i
			break

	if matching_line_index == -1:
		lyric_label.text = ""
		lyric_label.visible_characters = 0
		current_lyric_index = -1
		return

	var active_line: Dictionary = lyric_lines[matching_line_index]

	var start_time: float = float(active_line["start"])
	var reveal_end_time: float = float(active_line["reveal_end"])
	var lyric_text: String = String(active_line["text"])

	if current_lyric_index != matching_line_index:
		current_lyric_index = matching_line_index

		lyric_label.text = lyric_text
		lyric_label.visible_characters = 0

		# Cada frase puede tener su propia inclinación.
		var lyric_angle: float = float(
			active_line.get("angle", 0.0)
		)

		lyrics_layer.rotation_degrees = lyric_angle

	var reveal_duration: float = maxf(
		reveal_end_time - start_time,
		0.01
	)

	var reveal_progress: float = clampf(
		(music_time - start_time) / reveal_duration,
		0.0,
		1.0
	)

	var total_characters: int = lyric_label.get_total_character_count()

	var calculated_characters: int = int(
		floor(
			reveal_progress
			* float(total_characters)
		)
	)

	lyric_label.visible_characters = maxi(
		lyric_label.visible_characters,
		calculated_characters
	)


# =========================================================
# ENTRADA
# =========================================================

func _input(event: InputEvent) -> void:
	if impact_active:
		return

	if event.is_action_pressed("ui_accept"):
		if timing_active:
			resolve_perfect_hit()
		else:
			start_perfect_hit()


# =========================================================
# PERFECT HIT
# =========================================================

func start_perfect_hit() -> void:
	timing_active = true

	perfect_hit_bar.visible = true
	flash.visible = false

	needle.position.x = needle_left_x
	needle_direction = 1

	print("Timing iniciado")


func resolve_perfect_hit() -> void:
	timing_active = false

	var hit_x: float = (
		needle.position.x
		+ needle_hit_offset_x
	)

	print(
		"Needle X:",
		needle.position.x,
		" Hit X:",
		hit_x
	)

	print(
		"Rango PERFECT:",
		perfect_center_x - perfect_left_margin,
		" hasta ",
		perfect_center_x + perfect_right_margin
	)

	var damage: int = 0

	if (
		hit_x >= perfect_center_x - perfect_left_margin
		and hit_x <= perfect_center_x + perfect_right_margin
	):
		damage = 250

		print("PERFECT HIT")

		show_flash(hit_x)
		perfect_hit_impact()

	elif absf(hit_x - good_center_x) <= good_margin:
		damage = 100
		print("GOOD HIT")

	else:
		damage = 25
		print("MISS / golpe débil")

	attack_enemy(damage)

	await get_tree().create_timer(0.35).timeout

	perfect_hit_bar.visible = false
	flash.visible = false


func show_flash(hit_x: float) -> void:
	var flash_visual_offset_x: float = 8.0

	flash.position.x = (
		hit_x
		- 32.0
		+ flash_visual_offset_x
	)

	flash.position.y = 0.0
	flash.visible = true


func attack_enemy(damage: int) -> void:
	enemy_current_hp = max(
		enemy_current_hp - damage,
		0
	)

	enemy_hp.value = enemy_current_hp

	print(
		"Briar atacó. Daño:",
		damage,
		" Vida enemiga:",
		enemy_current_hp
	)


# =========================================================
# IMPACTO: ZOOM + TEMBLOR + REGRESO
# =========================================================

func perfect_hit_impact() -> void:
	perfect_hit_sound.play()
	if impact_active:
		return

	impact_active = true

	# Guardamos el lugar exacto donde estaba la cámara libre.
	camera_return_position = mouse_camera.position
	camera_return_zoom = mouse_camera.zoom

	camera_focus_strength = 0.0
	camera_zoom_factor = 1.0

	# Mientras dura el impacto, el script del mouse
	# deja de arrastrar o devolver la cámara al centro.
	if mouse_camera.has_method("set_cinematic_lock"):
		mouse_camera.call(
			"set_cinematic_lock",
			true
		)

	var zoom_in: Tween = create_tween()
	zoom_in.set_parallel(true)

	zoom_in.tween_property(
		self,
		"camera_focus_strength",
		1.0,
		perfect_zoom_in_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	zoom_in.tween_property(
		self,
		"camera_zoom_factor",
		perfect_zoom,
		perfect_zoom_in_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await zoom_in.finished

	# La cámara permanece enfocando al enemigo
	# durante todo el temblor.
	await shake_enemy()

	var zoom_out: Tween = create_tween()
	zoom_out.set_parallel(true)

	zoom_out.tween_property(
		self,
		"camera_focus_strength",
		0.0,
		perfect_zoom_out_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	zoom_out.tween_property(
		self,
		"camera_zoom_factor",
		1.0,
		perfect_zoom_out_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	await zoom_out.finished

	# Restauración exacta para evitar acumulación de errores.
	camera_focus_strength = 0.0
	camera_zoom_factor = 1.0

	mouse_camera.position = camera_return_position
	mouse_camera.zoom = camera_return_zoom

	if mouse_camera.has_method("set_cinematic_lock"):
		mouse_camera.call(
			"set_cinematic_lock",
			false
		)

	impact_active = false


# =========================================================
# TEMBLOR DEL ENEMIGO
# =========================================================

func shake_enemy() -> void:
	var shake_strength: float = 16.0
	var shake_times: int = 16
	var shake_delay: float = 0.080

	for _i in range(shake_times):
		enemy_sprite.position = (
			enemy_base_position
			+ Vector2(
				randf_range(
					-shake_strength,
					shake_strength
				),
				randf_range(
					-shake_strength * 0.5,
					shake_strength * 0.5
				)
			)
		)

		await get_tree().create_timer(
			shake_delay
		).timeout

	enemy_sprite.position = enemy_base_position


# =========================================================
# SOMBRAS UNIVERSALES
# =========================================================

func get_character_visual_size(target: Node2D) -> Vector2:
	if target is AnimatedSprite2D:
		var animated_sprite := target as AnimatedSprite2D

		var frame_texture: Texture2D = (
			animated_sprite.sprite_frames.get_frame_texture(
				animated_sprite.animation,
				animated_sprite.frame
			)
		)

		if frame_texture != null:
			return frame_texture.get_size()

	if target is Sprite2D:
		var normal_sprite := target as Sprite2D

		if normal_sprite.texture != null:
			return normal_sprite.texture.get_size()

	return Vector2(100.0, 100.0)


func create_character_shadow(
	target: Node2D,
	width_multiplier: float = 1.0,
	vertical_multiplier: float = 1.0,
	horizontal_offset: float = 0.0
) -> CharacterShadow:
	var texture_size: Vector2 = get_character_visual_size(target)

	var visual_size: Vector2 = Vector2(
		texture_size.x * absf(target.scale.x),
		texture_size.y * absf(target.scale.y)
	)

	var calculated_width: float = (
		visual_size.x
		* auto_shadow_width_ratio
		* width_multiplier
	)

	calculated_width = clampf(
		calculated_width,
		auto_shadow_min_width,
		auto_shadow_max_width
	)

	var calculated_height: float = (
		calculated_width
		* auto_shadow_height_ratio
	)

	var calculated_offset_y: float = (
		visual_size.y
		* auto_shadow_vertical_ratio
		* vertical_multiplier
	)

	var shadow: CharacterShadow = CharacterShadow.new()

	shadow.shadow_size = Vector2(
		calculated_width,
		calculated_height
	)

	shadow.shadow_opacity = auto_shadow_opacity

	shadow.position = (
		target.position
		+ Vector2(
			horizontal_offset,
			calculated_offset_y
		)
	)

	shadow.z_index = target.z_index - 1

	target.get_parent().add_child(shadow)

	return shadow
