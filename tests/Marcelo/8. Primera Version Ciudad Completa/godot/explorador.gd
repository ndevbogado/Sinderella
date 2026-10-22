extends CharacterBody2D
## Foot position is the actor origin. Pixel collision is shared with the HTML build.
var world: Node
var sprite: Sprite2D
var direction = 0
var phase = 0.0
var moving = false
var columns = 17
var walk_frames = 8
var idle_frame = 16
var walk_fps = 12.0
var run_fps = 16.0
var animation = "idle"

func setup(city: Node) -> void:
	world = city
	collision_layer = 0
	collision_mask = 0
	sprite = Sprite2D.new()
	columns = int(world.catalog.player.columns)
	walk_frames = int(world.catalog.player.frames_per_direction)
	idle_frame = int(world.catalog.player.idle_frame)
	walk_fps = float(world.catalog.player.fps)
	run_fps = float(world.catalog.player.run_fps)
	sprite.texture = load("res://" + world.catalog.player.file)
	sprite.hframes = columns
	sprite.vframes = world.catalog.player.rows.size()
	sprite.position = Vector2(0, -32)
	sprite.frame = idle_frame
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-11, -3, 22, 6), Color(0.025, 0.10, 0.08, 0.4))

func step(axis: Vector2, delta: float, running: bool = false) -> void:
	axis = axis.normalized()
	var old = position
	var speed = float(world.catalog.player.run_speed if running else world.catalog.player.walk_speed)
	var distance = speed * minf(delta, 0.1)
	var parts = maxi(1, ceili(distance / 4.0))
	var unit = axis * distance / parts
	for i in range(parts):
		if not world.blocked(position + Vector2(unit.x, 0)):
			position.x += unit.x
		if not world.blocked(position + Vector2(0, unit.y)):
			position.y += unit.y
	moving = position.distance_to(old) > 0.01
	velocity = axis * speed if moving else Vector2.ZERO
	if axis != Vector2.ZERO:
		if absf(axis.x) > absf(axis.y):
			direction = 1 if axis.x < 0 else 2
		else:
			direction = 3 if axis.y < 0 else 0
	if moving:
		animation = "run" if running else "walk"
		var clip = world.catalog.player.animations[animation]
		phase = fmod(phase + position.distance_to(old) / speed * float(clip.fps) / clip.frames.size(), 1.0)
		sprite.frame = direction * columns + int(clip.frames[int(phase * clip.frames.size()) % clip.frames.size()])
	else:
		phase = 0.0
		animation = "idle"
		sprite.frame = direction * columns + idle_frame
