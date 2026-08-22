@tool
extends Node2D

@export var ground_color := Color("211b20")
@export var distant_fire_color := Color("8f2d20")
@export var tree_color := Color("171014")
@export var flame_color := Color("ff6b24")
@export var flame_core_color := Color("ffd35a")
@export var map_size := Vector2(2400.0, 1350.0)

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), ground_color)
	draw_rect(Rect2(0, 0, map_size.x, 330), distant_fire_color.darkened(0.48))

	for row in range(4):
		var row_y := 250.0 + float(row) * 285.0
		for x in range(20 + row * 37, int(map_size.x) + 100, 96):
			var height := 115.0 + float((x * 13 + row * 41) % 100)
			draw_rect(Rect2(x, row_y - height, 18, height + 120), tree_color)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 42, row_y - 28),
				Vector2(x + 9, row_y - height - 55),
				Vector2(x + 58, row_y - 28),
			]), tree_color.lightened(0.035))

	for row in range(3):
		var fire_y := 520.0 + float(row) * 350.0
		for x in range(42 + row * 24, int(map_size.x), 104):
			_draw_flame(Vector2(x, fire_y - float((x * 7) % 55)))

	draw_rect(Rect2(0, map_size.y - 120.0, map_size.x, 120.0), Color(0.08, 0.055, 0.06, 0.78))


func _draw_flame(base: Vector2) -> void:
	var flicker := sin(_time * 7.0 + base.x + base.y) * 7.0
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-18, 0),
		base + Vector2(-7, -40 - flicker),
		base + Vector2(2, -24 + flicker * 0.3),
		base + Vector2(17, 0),
	]), flame_color)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-8, 0),
		base + Vector2(0, -23 - flicker * 0.4),
		base + Vector2(8, 0),
	]), flame_core_color)
