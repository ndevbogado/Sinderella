class_name PortraitView
extends Control

const TEX_CENDRA: Texture2D = preload("res://assets/portraits/cendra.png")
const TEX_CAPERUCITA: Texture2D = preload("res://assets/portraits/caperucita.png")
const TEX_BRIAR: Texture2D = preload("res://assets/portraits/briar.png")
const TEX_PRINCIPE: Texture2D = preload("res://assets/portraits/principe.png")
const TEX_CUSTODIO: Texture2D = preload("res://assets/portraits/custodio.png")

@export var speaker_name: String = "CENDRA" : set = set_speaker_name
@export var mirror: bool = false : set = set_mirror
@export var show_nameplate: bool = false : set = set_show_nameplate

var accent: Color = Color("a790bb")
var secondary: Color = Color("d9cbe5")
var skin: Color = Color("ebcdb8")
var frame_t: float = 0.0
var portrait_texture: Texture2D
var portrait_zoom: float = 1.0
var portrait_focus_y: float = 0.35
var portrait_focus_x: float = 0.5

func _ready() -> void:
	custom_minimum_size = Vector2(250, 250)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_palette()

func set_speaker_name(value: String) -> void:
	speaker_name = value.to_upper()
	_refresh_palette()
	queue_redraw()

func set_mirror(value: bool) -> void:
	mirror = value
	queue_redraw()

func set_show_nameplate(value: bool) -> void:
	show_nameplate = value
	queue_redraw()

func _process(delta: float) -> void:
	frame_t += delta
	if portrait_texture == null:
		queue_redraw()

func _refresh_palette() -> void:
	portrait_texture = null
	portrait_zoom = 1.0
	portrait_focus_y = 0.35
	portrait_focus_x = 0.5
	match speaker_name:
		"CENDRA":
			accent = Color("8f7ca7")
			secondary = Color("ebe3f0")
			skin = Color("ebcdb8")
			portrait_texture = TEX_CENDRA
			portrait_zoom = 1.18
			portrait_focus_y = 0.29
		"CAPERUCITA":
			accent = Color("8a3345")
			secondary = Color("f0d7dd")
			skin = Color("f0c7af")
			portrait_texture = TEX_CAPERUCITA
			portrait_zoom = 1.12
			portrait_focus_y = 0.28
		"BRIAR", "BELLA DURMIENTE":
			accent = Color("9f79ab")
			secondary = Color("eedff2")
			skin = Color("f0d7c8")
			portrait_texture = TEX_BRIAR
			portrait_zoom = 1.16
			portrait_focus_y = 0.22
		"PRÍNCIPE", "PRINCIPE":
			accent = Color("647ba3")
			secondary = Color("dde8f2")
			skin = Color("ebcfbf")
			portrait_texture = TEX_PRINCIPE
			portrait_zoom = 1.14
			portrait_focus_y = 0.27
		"CUSTODIO":
			accent = Color("5a5367")
			secondary = Color("ddd9e4")
			skin = Color("dbd6e0")
			portrait_texture = TEX_CUSTODIO
			portrait_zoom = 1.1
			portrait_focus_y = 0.24
		"NARRADOR", "RECUERDO":
			accent = Color("8e8aa1")
			secondary = Color("efeef6")
			skin = Color("ebe5db")
		_:
			accent = Color("857495")
			secondary = Color("ebe3f0")
			skin = Color("ebcdb8")

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	# Background glow
	var center := r.size * Vector2(0.5, 0.52)
	var aura_radius := minf(r.size.x, r.size.y) * 0.42
	for i in range(6, 0, -1):
		var alpha := 0.03 * float(i)
		var c := accent
		c.a = alpha
		draw_circle(center, aura_radius * (float(i) / 6.0), c)

	# Frame and panel
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.08, 0.065, 0.11, 0.84)
	frame.border_color = accent.lightened(0.28)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(22)
	frame.shadow_color = Color(0, 0, 0, 0.22)
	frame.shadow_size = 8
	frame.draw(get_canvas_item(), r)
	draw_rect(r.grow(-10), accent.darkened(0.15), false, 1.4)

	var inner := r.grow(-10)
	if portrait_texture != null:
		_draw_portrait_texture(inner)
	else:
		_draw_fallback(inner)

	# Gentle edge gradient overlay substitute
	var bottom_tint := Color(0.02, 0.015, 0.03, 0.42)
	bottom_tint.a = 0.36
	var fade_rect := Rect2(inner.position.x, inner.position.y + inner.size.y * 0.72, inner.size.x, inner.size.y * 0.28)
	for i in range(7):
		var step_rect := Rect2(fade_rect.position.x, fade_rect.position.y + i * (fade_rect.size.y / 7.0), fade_rect.size.x, fade_rect.size.y / 7.0)
		var c2 := bottom_tint
		c2.a *= float(i + 1) / 7.0
		draw_rect(step_rect, c2, true)

	if show_nameplate:
		var name_rect := Rect2(18, 16, size.x - 36, 34)
		draw_rect(name_rect, Color(0.13, 0.11, 0.17, 0.86), true)
		draw_rect(name_rect, accent.lightened(0.22), false, 1.6)
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(font, Vector2(name_rect.position.x + 14, name_rect.position.y + 24), _display_name(), HORIZONTAL_ALIGNMENT_LEFT, name_rect.size.x - 28, 18, secondary)

func _draw_portrait_texture(inner: Rect2) -> void:
	var texture_size := portrait_texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return
	var target_aspect := inner.size.x / inner.size.y
	var src_w := texture_size.x
	var src_h := texture_size.y
	var crop_w := src_w
	var crop_h := src_h
	if src_w / src_h > target_aspect:
		crop_h = src_h / portrait_zoom
		crop_w = crop_h * target_aspect
	else:
		crop_w = src_w / portrait_zoom
		crop_h = crop_w / target_aspect
	crop_w = minf(src_w, crop_w)
	crop_h = minf(src_h, crop_h)
	var focus_x := texture_size.x * portrait_focus_x
	var focus_y := texture_size.y * portrait_focus_y
	var src_x := clampf(focus_x - crop_w * 0.5, 0.0, src_w - crop_w)
	var src_y := clampf(focus_y - crop_h * 0.35, 0.0, src_h - crop_h)
	var src_rect := Rect2(src_x, src_y, crop_w, crop_h)
	if mirror:
		draw_set_transform(Vector2(inner.position.x + inner.size.x, inner.position.y), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(portrait_texture, Rect2(Vector2.ZERO, inner.size), src_rect)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(portrait_texture, inner, src_rect)
	# frame accent
	for i in range(3):
		var c := accent
		c.a = 0.08 - float(i) * 0.02
		draw_rect(inner.grow(-float(i) * 2.0), c, false, 1.0)

func _draw_fallback(inner: Rect2) -> void:
	var ox := size.x * (0.62 if mirror else 0.38)
	var bob := sin(frame_t * 1.8) * 2.0
	draw_set_transform(Vector2(ox, size.y * 0.82), 0.0, Vector2(1.0, 0.48))
	draw_circle(Vector2.ZERO, 44.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_set_transform(Vector2.ZERO)
	var base_y := size.y * 0.68 + bob
	var body := PackedVector2Array([
		Vector2(ox - 42, base_y - 30), Vector2(ox + 42, base_y - 30),
		Vector2(ox + 58, base_y + 72), Vector2(ox - 58, base_y + 72)
	])
	draw_colored_polygon(body, accent.darkened(0.08))
	var shoulder := PackedVector2Array([
		Vector2(ox - 55, base_y - 16), Vector2(ox + 55, base_y - 16),
		Vector2(ox + 44, base_y + 14), Vector2(ox - 44, base_y + 14)
	])
	draw_colored_polygon(shoulder, secondary)
	var head_c := Vector2(ox, size.y * 0.36 + bob)
	draw_circle(head_c, 33.0, skin)
	draw_arc(head_c + Vector2(0,-1), 36.0, PI, TAU, 24, accent.lightened(0.2), 11.0)
	_draw_eye_line(head_c, Color("5a5466"), false)
	draw_rect(Rect2(head_c + Vector2(-9,25), Vector2(18,10)), skin.darkened(0.05), true)

func _display_name() -> String:
	match speaker_name:
		"CENDRA":
			return "Cendra"
		"CAPERUCITA":
			return "Caperucita"
		"BRIAR", "BELLA DURMIENTE":
			return "Briar"
		"PRÍNCIPE", "PRINCIPE":
			return "Príncipe"
		"CUSTODIO":
			return "Custodio"
		"NARRADOR":
			return "Narrador"
		"RECUERDO":
			return "Recuerdo"
		_:
			return speaker_name.capitalize()

func _draw_eye_line(head_c: Vector2, color: Color, sharp: bool) -> void:
	var tilt := -2.0 if sharp else 0.0
	draw_line(head_c + Vector2(-13,-2 + tilt), head_c + Vector2(-4,-4), color, 2.2)
	draw_line(head_c + Vector2(4,-4), head_c + Vector2(13,-2 - tilt), color, 2.2)
	draw_line(head_c + Vector2(-7,13), head_c + Vector2(7,13), color, 1.8)
