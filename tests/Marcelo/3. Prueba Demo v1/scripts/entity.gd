class_name StoryEntity
extends Node2D

const TEX_PRINCE: Texture2D = preload("res://assets/actors/prince_world.png")
const TEX_BRIAR: Texture2D = preload("res://assets/actors/briar_world.png")
const TEX_CAPERUCITA: Texture2D = preload("res://assets/actors/caperucita_world.png")
const TEX_CUSTODIO: Texture2D = preload("res://assets/actors/custodio_world.png")

var entity_id: String = ""
var display_name: String = ""
var kind: String = "npc"
var body_color: Color = Color("a78bbb")
var enabled: bool = true
var pulse: float = 0.0
var label_node: Label

func setup(id_value: String, name_value: String, kind_value: String, color_value: Color) -> void:
	entity_id = id_value
	display_name = name_value
	kind = kind_value
	body_color = color_value
	label_node = Label.new()
	label_node.text = display_name
	label_node.position = Vector2(-100, -136)
	label_node.size = Vector2(200, 28)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.add_theme_font_size_override("font_size", 14)
	label_node.add_theme_color_override("font_color", Color("f5eef8"))
	label_node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label_node.add_theme_constant_override("shadow_offset_x", 2)
	label_node.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label_node)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func set_completed(value: bool) -> void:
	if value:
		body_color = body_color.darkened(0.45)
		label_node.modulate = Color(0.65, 0.65, 0.7, 1.0)
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	var bob := sin(pulse * 2.0) * 2.0
	if kind == "memory":
		var glow := 18.0 + sin(pulse * 3.0) * 2.0
		var glow_color := body_color
		glow_color.a = 0.18
		draw_circle(Vector2(0, -5 + bob), glow, glow_color)
		draw_circle(Vector2(0, -5 + bob), 10.0, body_color)
		draw_polyline(PackedVector2Array([
			Vector2(0, -23 + bob), Vector2(10, -5 + bob),
			Vector2(0, 13 + bob), Vector2(-10, -5 + bob), Vector2(0, -23 + bob)
		]), Color("fff4ce"), 2.0)
		return
	if kind == "door":
		draw_rect(Rect2(Vector2(-28, -47), Vector2(56, 72)), Color("30273b"), true)
		draw_rect(Rect2(Vector2(-28, -47), Vector2(56, 72)), body_color, false, 5.0)
		draw_circle(Vector2(17, -9), 4.0, Color("e8d8a3"))
		return

	# Personajes con retrato/silueta completa en el mapa.
	var texture := _world_texture_for_entity()
	if texture != null:
		_draw_shadow(texture, 108.0 if kind == "bed" else 116.0)
		_draw_world_texture(texture, 108.0 if kind == "bed" else 116.0, bob)
		if kind == "bed":
			var aura := body_color
			aura.a = 0.14
			draw_circle(Vector2(0, -30 + bob), 36.0, aura)
		return

	# Fallback simple.
	draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 20.0, Color(0.02, 0.01, 0.03, 0.38))
	draw_set_transform(Vector2.ZERO)
	var cloak := PackedVector2Array([
		Vector2(-18, -10 + bob), Vector2(18, -10 + bob),
		Vector2(24, 30 + bob), Vector2(-24, 30 + bob)
	])
	draw_colored_polygon(cloak, body_color)
	draw_circle(Vector2(0, -29 + bob), 13.0, Color("dfc0aa"))
	if kind == "enemy":
		draw_arc(Vector2(0, -29 + bob), 15.0, PI, TAU, 16, Color("5c1e2a"), 8.0)
		draw_line(Vector2(-8, -30 + bob), Vector2(-3, -27 + bob), Color("fff1de"), 2.0)
		draw_line(Vector2(8, -30 + bob), Vector2(3, -27 + bob), Color("fff1de"), 2.0)
	else:
		draw_arc(Vector2(0, -30 + bob), 14.0, PI, TAU, 16, body_color.lightened(0.3), 7.0)

func _world_texture_for_entity() -> Texture2D:
	match entity_id:
		"prince", "prince_follower":
			return TEX_PRINCE
		"briar":
			return TEX_BRIAR
		"caperucita":
			return TEX_CAPERUCITA
		"tower_guard":
			return TEX_CUSTODIO
		_:
			return null

func _draw_shadow(texture: Texture2D, target_height: float) -> void:
	var tex_size := texture.get_size()
	if tex_size.y <= 0.0:
		return
	var scale := target_height / tex_size.y
	var width := tex_size.x * scale
	draw_set_transform(Vector2(0, 28), 0.0, Vector2(1.0, 0.50))
	draw_circle(Vector2.ZERO, clampf(width * 0.20, 16.0, 26.0), Color(0.02, 0.01, 0.03, 0.38))
	draw_set_transform(Vector2.ZERO)

func _draw_world_texture(texture: Texture2D, target_height: float, bob: float) -> void:
	if texture == null:
		return
	var tex_size := texture.get_size()
	if tex_size.y <= 0.0:
		return
	var scale := target_height / tex_size.y
	var size := tex_size * scale
	var rect := Rect2(Vector2(-size.x * 0.5, 30.0 - size.y + bob), size)
	draw_texture_rect(texture, rect, false)
