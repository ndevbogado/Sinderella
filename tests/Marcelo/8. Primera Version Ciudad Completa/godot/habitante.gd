extends Node2D
## A resident follows a collision-checked path authored in ciudad.json.
var data: Dictionary
var route: PackedVector2Array
var index = 0
var direction_step = 1
var wait = 0.0
var phase = 0.0
var direction = 0
var moving = false
var sprite: Sprite2D
var is_boat = false

func setup(item: Dictionary, boat: bool, texture: Texture2D) -> void:
	data = item
	is_boat = boat
	for p in item.route:
		route.append(Vector2(p[0], p[1]))
	index = int(item.get("start_index", 0))
	position = route[index]
	direction_step = -1 if index == route.size() - 1 else 1
	wait = float(int(item.id) % 7) * 0.12
	phase = float(item.id) * 0.21
	sprite = Sprite2D.new()
	sprite.texture = texture
	if boat:
		sprite.position.y = -texture.get_height() * 0.1
	else:
		sprite.hframes = 8
		sprite.vframes = 6
		sprite.position.y = -32
		sprite.frame = int(item.role) * 8
	add_child(sprite)
	queue_redraw()

func _draw() -> void:
	if not is_boat:
		draw_rect(Rect2(-10, -3, 20, 6), Color(0.03, 0.13, 0.1, 0.33))

func step(delta: float) -> void:
	moving = false
	if wait > 0:
		wait -= delta
		return
	var target = index + direction_step
	if target < 0 or target >= route.size():
		direction_step = -direction_step
		wait = 0.4 if is_boat else float(data.pause)
		return
	var difference = route[target] - position
	var distance = difference.length()
	var travel = float(data.speed) * delta
	if distance <= travel:
		position = route[target]
		index = target
	else:
		position += difference / distance * travel
	direction = (1 if difference.x < 0 else 2) if absf(difference.x) > absf(difference.y) else (3 if difference.y < 0 else 0)
	phase += delta
	moving = true
	if not is_boat:
		sprite.frame = int(data.role) * 8 + direction * 2 + int(phase * 6) % 2
