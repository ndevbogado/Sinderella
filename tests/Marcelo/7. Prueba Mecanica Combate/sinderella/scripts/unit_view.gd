class_name BattleUnitView
extends Control
signal selected(uid: int)
signal hovered(uid: int)
var unit: BattleUnitState
var art: TextureRect
var hp: ProgressBar
var role_label: Label
var intent: Label
var name_label: Label
var ring_color: Color = Color.TRANSPARENT
var age: float = 0.0
var animated: bool = true
var is_active: bool = false
var is_target: bool = false
var show_prediction: bool = false
var predicted_hp: int = 0
var effect_label: Label

func setup(state: BattleUnitState) -> void:
	unit = state
	size = Vector2(220, 245)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	art = TextureRect.new()
	# Set the policy first: otherwise the texture clamps size to its native pixels.
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = state.data.texture
	art.modulate = state.data.tint
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	art.position = Vector2(0, 38)
	art.size = Vector2(220, 144)
	if state.data.chroma_key:
		var mat = ShaderMaterial.new()
		mat.shader = load("res://sinderella/assets/chroma.gdshader")
		art.material = mat
	intent = make_label(Vector2(0, 2), Vector2(220, 35), 13)
	name_label = make_label(Vector2(0, 184), Vector2(220, 23), 16)
	name_label.text = state.data.display_name
	hp = ProgressBar.new()
	hp.show_percentage = false
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp.add_theme_stylebox_override("background", BattleStyle.bar_box(Color("060c0f")))
	hp.add_theme_stylebox_override("fill", BattleStyle.bar_box(Color("c64d5b") if unit.team == 1 else Color("48ab78")))
	add_child(hp)
	hp.position = Vector2(15, 210)
	hp.size = Vector2(190, 8)
	role_label = make_label(Vector2(0, 222), Vector2(220, 21), 12)
	effect_label = make_label(Vector2(0, 144), Vector2(220, 34), 23)
	effect_label.add_theme_constant_override("outline_size", 7)
	effect_label.add_theme_color_override("font_outline_color", Color("050b10"))
	gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected.emit(unit.uid))
	mouse_entered.connect(func(): hovered.emit(unit.uid))
	age = state.uid * 0.7

func make_label(pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label = BattleStyle.label("", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(label)
	label.position = pos
	label.size = dimensions
	return label

func refresh(context: BattleState, active: bool, targetable: bool, selected_target: bool = false, selecting: bool = false, color: Color = BattleStyle.RED) -> void:
	is_active = active
	is_target = selected_target
	hp.max_value = unit.data.max_hp
	hp.value = unit.hp
	role_label.text = "%s/%s Vida · %s" % [unit.hp, unit.data.max_hp, unit.role]
	if unit.shield:
		role_label.text += " · E%s" % unit.shield
	modulate.a = 0.25 if not unit.alive() else (0.48 if selecting and not active and not selected_target and not targetable else 1.0)
	ring_color = color if selected_target else (BattleStyle.CYAN if active else (Color("8c9c9880") if targetable else Color.TRANSPARENT))
	intent.text = ""
	intent.add_theme_color_override("font_color", BattleStyle.MUTED)
	if active:
		intent.text = "▼ ACTÚA" + (" / SOBRE SÍ" if selected_target else "")
		intent.add_theme_color_override("font_color", BattleStyle.CYAN)
	elif selected_target:
		intent.text = "▼ OBJETIVO ELEGIDO"
		intent.add_theme_color_override("font_color", color)
	elif unit.team == 1 and unit.alive() and context.intentions.has(unit.uid):
		var a: Dictionary = context.intentions[unit.uid]
		if not a.is_empty():
			intent.text = "%s\n→ %s" % [a.skill.display_name, a.target.data.display_name]
	else:
		intent.text = "ALIADO" if unit.team == 0 else "ENEMIGO"
	show_prediction = false
	effect_label.text = ""
	tooltip_text = "%s\nPapel: %s%s\nVida %s/%s · Escudo %s\nGuardia: %s · Marcado: %s" % [unit.data.display_name, unit.role, " + " + unit.echo if unit.echo else "", unit.hp, unit.data.max_hp, unit.shield, "sí" if unit.guard else "no", "sí" if unit.marked else "no"]
	queue_redraw()

func set_prediction(value: Dictionary, text: String, color: Color) -> void:
	show_prediction = not value.is_empty()
	if show_prediction:
		predicted_hp = value.hp_after
		effect_label.text = text
		effect_label.add_theme_color_override("font_color", color)
	queue_redraw()

func _process(delta: float) -> void:
	if art and unit.alive() and animated:
		age += delta
		art.position.y = 38 + sin(age * 1.8) * 1.2

func _draw() -> void:
	draw_style_box(BattleStyle.box(Color("40535190"), Color("081318ae")), Rect2(Vector2.ZERO, size))
	if ring_color.a > 0:
		draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), ring_color, false, 4.0 if is_active or is_target else 1.0)
	if is_active and is_target:
		draw_rect(Rect2(Vector2(7, 7), size - Vector2(14, 14)), BattleStyle.CYAN, false, 2.0)
	# A separate strip previews the change without touching the real health bar.
	if show_prediction:
		var before: float = float(unit.hp) / unit.data.max_hp * 190.0
		var after: float = float(predicted_hp) / unit.data.max_hp * 190.0
		draw_rect(Rect2(15, 218, 190, 3), Color("122429"))
		draw_rect(Rect2(15, 218, minf(before, after), 3), BattleStyle.GREEN)
		draw_rect(Rect2(15 + minf(before, after), 218, absf(after - before), 3), BattleStyle.RED if after < before else BattleStyle.GREEN)
