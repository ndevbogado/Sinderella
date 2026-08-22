class_name CendraPlayer
extends CharacterBody2D

const TEX_CENDRA: Texture2D = preload("res://assets/actors/cendra_world.png")

@export var speed: float = 245.0
var movement_enabled: bool = true
var facing: Vector2 = Vector2.DOWN
var walk_time: float = 0.0
var name_label: Label

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 15.0
	capsule.height = 38.0
	shape.shape = capsule
	shape.position = Vector2(0, 5)
	add_child(shape)
	name_label = Label.new()
	name_label.text = "Cendra"
	name_label.position = Vector2(-72, -136)
	name_label.size = Vector2(144, 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color("f7f0fa"))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(name_label)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
		walk_time += delta * 9.0
	else:
		walk_time = 0.0
	velocity = direction * speed
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var bob := sin(walk_time) * 2.0 if walk_time > 0.0 else 0.0
	# Sombra
	draw_set_transform(Vector2(0, 28), 0.0, Vector2(1.0, 0.50))
	draw_circle(Vector2.ZERO, 24.0, Color(0.02, 0.01, 0.03, 0.42))
	draw_set_transform(Vector2.ZERO)
	_draw_world_texture(TEX_CENDRA, 118.0, bob)
	# Indicador de dirección suave
	var dir := facing.normalized() if facing.length_squared() > 0.0 else Vector2.DOWN
	var tip := dir * 36.0
	draw_line(dir * 22.0 + Vector2(0, 8), tip + Vector2(0, 8), Color(0.87, 0.96, 1.0, 0.35), 2.2)
	draw_circle(tip + Vector2(0, 8), 2.5, Color(0.94, 0.99, 1.0, 0.55))

func _draw_world_texture(texture: Texture2D, target_height: float, bob: float = 0.0) -> void:
	if texture == null:
		return
	var tex_size := texture.get_size()
	if tex_size.y <= 0.0:
		return
	var scale := target_height / tex_size.y
	var size := tex_size * scale
	var rect := Rect2(Vector2(-size.x * 0.5, 30.0 - size.y + bob), size)
	draw_texture_rect(texture, rect, false)
