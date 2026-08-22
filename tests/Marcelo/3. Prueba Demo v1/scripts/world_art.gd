class_name WorldArt
extends Node2D

const FOREST_TEX: Texture2D = preload("res://assets/maps/forest_burned.png")
const CITY_TEX: Texture2D = preload("res://assets/maps/city_map.png")

const FOREST_SIZE := Vector2(1775, 998)
const CITY_SIZE := Vector2(2132, 2132)

var map_name: String = "forest"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func set_map(value: String) -> void:
	map_name = value
	queue_redraw()

func _draw() -> void:
	match map_name:
		"forest":
			_draw_forest()
		"kingdom":
			_draw_kingdom()
		"university":
			_draw_university()
		"blacksmith":
			_draw_blacksmith()
		"prison":
			_draw_prison()
		"tower":
			_draw_tower()

func _draw_forest() -> void:
	if FOREST_TEX != null:
		draw_texture_rect(FOREST_TEX, Rect2(Vector2.ZERO, FOREST_SIZE), false)
	else:
		draw_rect(Rect2(0, 0, FOREST_SIZE.x, FOREST_SIZE.y), Color("271d24"), true)
	# Un leve viñeteado para que los sprites destaquen mejor.
	_draw_top_bottom_shade(FOREST_SIZE)

func _draw_kingdom() -> void:
	if CITY_TEX != null:
		draw_texture_rect(CITY_TEX, Rect2(Vector2.ZERO, CITY_SIZE), false)
	else:
		draw_rect(Rect2(0, 0, CITY_SIZE.x, CITY_SIZE.y), Color("817c91"), true)
	# Sombra ligera para mejorar legibilidad y separar personajes del fondo.
	_draw_top_bottom_shade(CITY_SIZE, 0.14)

func _draw_top_bottom_shade(area_size: Vector2, strength: float = 0.22) -> void:
	for i in range(8):
		var c := Color(0, 0, 0, strength * (1.0 - float(i) / 8.0))
		draw_rect(Rect2(0, i * 12.0, area_size.x, 12.0), c, true)
		draw_rect(Rect2(0, area_size.y - (i + 1) * 16.0, area_size.x, 16.0), c, true)

func _draw_university() -> void:
	draw_rect(Rect2(0, 0, 1280, 760), Color("28293d"), true)
	draw_rect(Rect2(90, 80, 1100, 600), Color("4b4f6b"), true)
	# Piso de práctica y tres estaciones de observación.
	for x in range(7):
		for y in range(4):
			var tile_color := Color("636983") if (x + y) % 2 == 0 else Color("5a607a")
			draw_rect(Rect2(145 + x * 145, 135 + y * 115, 145, 115), tile_color, true)
	draw_rect(Rect2(220, 180, 280, 280), Color("394861"), true)
	draw_rect(Rect2(500, 155, 280, 330), Color("4b3f62"), true)
	draw_rect(Rect2(780, 180, 280, 280), Color("5b493d"), true)
	draw_string(ThemeDB.fallback_font, Vector2(350, 120), "AULA DE TÁCTICAS DEL REINO", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, Color("eeeaf6"))
	draw_string(ThemeDB.fallback_font, Vector2(278, 220), "FORMACIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("cbd8ee"))
	draw_string(ThemeDB.fallback_font, Vector2(598, 195), "GUARDIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ddd2ee"))
	draw_string(ThemeDB.fallback_font, Vector2(848, 220), "CONTRAATAQUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ead4bd"))

func _draw_blacksmith() -> void:
	draw_rect(Rect2(0, 0, 1280, 760), Color("211c1a"), true)
	draw_rect(Rect2(80, 80, 1120, 600), Color("44342b"), true)
	draw_rect(Rect2(680, 130, 410, 300), Color("30251f"), true)
	draw_circle(Vector2(955, 280), 86.0, Color("8e3d22"))
	draw_circle(Vector2(955, 280), 58.0, Color("ed7d35"))
	draw_rect(Rect2(470, 300, 190, 70), Color("282a31"), true)
	draw_rect(Rect2(220, 160, 240, 300), Color("5b4638"), true)
	draw_string(ThemeDB.fallback_font, Vector2(420, 120), "HERRERÍA DEL REINO", HORIZONTAL_ALIGNMENT_LEFT, -1, 31, Color("f1e1ce"))
	draw_string(ThemeDB.fallback_font, Vector2(220, 500), "Espada del guardia — 80 monedas", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("e7caa9"))

func _draw_prison() -> void:
	draw_rect(Rect2(0, 0, 1280, 760), Color("1e1a25"), true)
	draw_rect(Rect2(80, 100, 1120, 580), Color("302a38"), true)
	for x in range(8):
		draw_line(Vector2(210 + x * 120, 135), Vector2(210 + x * 120, 645), Color("0e0c11"), 12.0)
	for y in range(5):
		draw_line(Vector2(150, 190 + y * 105), Vector2(1130, 190 + y * 105), Color("0e0c11"), 7.0)
	draw_rect(Rect2(70, 310, 95, 170), Color("51455d"), true)
	draw_string(ThemeDB.fallback_font, Vector2(470, 70), "LA PRISIÓN QUE EL REINO OLVIDÓ", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("c7b8d3"))

func _draw_tower() -> void:
	draw_rect(Rect2(0, 0, 1280, 1250), Color("2c2535"), true)
	draw_rect(Rect2(360, 0, 560, 1250), Color("4b4155"), true)
	for y in range(8):
		var yy := 95.0 + y * 145.0
		draw_circle(Vector2(395, yy), 32.0, Color(0.77, 0.72, 0.85, 0.26))
		draw_circle(Vector2(885, yy + 65), 28.0, Color(0.77, 0.72, 0.85, 0.20))
		draw_line(Vector2(425, yy), Vector2(855, yy + 65), Color(0.68, 0.61, 0.76, 0.19), 3.0)
	draw_circle(Vector2(640, 150), 205.0, Color("5d5069"))
	draw_circle(Vector2(640, 150), 190.0, Color("332b3c"))
