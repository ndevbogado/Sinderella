extends Node2D
var city: Node2D
var clock = 0.0
func _process(delta: float) -> void:
	if is_instance_valid(city) and is_instance_valid(city.hero):
		clock += minf(delta, 0.1)
		queue_redraw()
func _draw() -> void:
	if not is_instance_valid(city) or not is_instance_valid(city.hero):
		return
	var p = city.hero.position
	for effect in city.map_data.effects:
		var at = Vector2(effect.x, effect.y)
		if absf(at.x - p.x) > 650 or absf(at.y - p.y) > 600:
			continue
		if effect.type == "smoke":
			for k in range(4):
				var age = fmod(clock * 15 + k * 18 + fmod(at.x, 37), 82)
				var offset = Vector2(round(sin(age * 0.07 + at.x) * 5 + age * 0.07), -round(age))
				draw_rect(Rect2(at + offset, Vector2(5, 5)), Color(0.87, 0.87, 0.79, 0.28 * (1.0 - age / 82.0)))
		if effect.type == "fountain":
			for k in range(3):
				draw_rect(Rect2(at + Vector2(-17 + k * 16, round(sin(clock * 5 + k) * 2)), Vector2(5, 2)), Color("b5f3e3"))
		if effect.type == "lamp" and city.night:
			for r in [38, 28, 18, 8]:
				draw_circle(at, r, Color(1.0, 0.79, 0.45, 0.035))
				draw_rect(Rect2(at, Vector2(3, 3)), Color("fff0a7"))
	for y in range(maxi(0, int((p.y - 480) / 32)), mini(int(city.map_data.height), int((p.y + 320) / 32))):
		for x in range(maxi(0, int((p.x - 520) / 32)), mini(int(city.map_data.width), int((p.x + 520) / 32))):
			var index = y * int(city.map_data.width) + x
			if city.overlay_bytes.decode_u16(index * 2) == 208 and (x * 7 + y * 11) % 4 == 0:
				draw_rect(Rect2(x * 32 + (int(clock * 8) + x * 3) % 24, y * 32 + 12, 6, 1), Color(0.67, 0.94, 0.85, 0.16))
