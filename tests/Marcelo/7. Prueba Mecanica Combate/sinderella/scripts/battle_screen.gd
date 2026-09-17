extends Control
## Reusable entry point. Assign an Encounter in the Inspector or call start_battle.
signal battle_finished(result: String, survivors: Array)
@export var encounter: BattleEncounter
@export_range(0.05, 2.0) var action_delay: float = 0.7
@export var reduced_motion: bool = false
var state: BattleState
var views: Dictionary = {}
var cards: Dictionary = {}
var skill_buttons: Array[Button] = []
var active_uid: int = 0
var selected_skill: BattleSkill
var hovered_uid: int = -1
var busy: bool = false
var history: Array[String] = []
var heading: Label
var skill_info: Label
var law_title: Label
var beat_label: Label
var law_preview: Label
var status_label: Label
var confirm: Button
var auto_button: Button
var round_label: Label
var overlay: Panel
var overlay_text: RichTextLabel
var generation: int = 0
var pending_uid: int = -1
var preview_panel: Panel
var preview_text: RichTextLabel
var add_action: Button
var last_preview: Dictionary = {}

func _ready() -> void:
	$Slots.hide() # Static editor previews; runtime views use the same markers.
	theme = BattleStyle.make_theme()
	build_interface()
	start_battle(encounter)

func put(parent: Node, child: Control, pos: Vector2, dimensions: Vector2) -> Control:
	parent.add_child(child)
	child.position = pos
	child.size = dimensions
	return child

func button(parent: Node, text: String, pos: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var b = Button.new()
	b.focus_mode = Control.FOCUS_NONE # Enter is reserved for confirming the preview.
	b.text = text
	put(parent, b, pos, dimensions)
	b.pressed.connect(callback)
	return b

func build_interface() -> void:
	var brand = BattleStyle.label("S I N D E R E L L A", 19, BattleStyle.GOLD)
	brand.add_theme_font_override("font", load("res://sinderella/assets/title.ttf"))
	put(self, brand, Vector2(22, 27), Vector2(265, 32))
	put(self, BattleStyle.label("PAPELES Y COMPASES\nPROTOTIPO JUGABLE · 01", 12, BattleStyle.MUTED), Vector2(24, 65), Vector2(260, 45))
	button(self, "?  Cómo jugar", Vector2(1385, 23), Vector2(195, 36), show_help)
	button(self, "Registro  [L]", Vector2(1385, 67), Vector2(195, 32), show_log)
	law_title = BattleStyle.label("", 23, BattleStyle.PALE)
	law_title.add_theme_font_override("font", load("res://sinderella/assets/title.ttf"))
	law_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	put($LawPanel, law_title, Vector2(12, 12), Vector2(986, 36))
	beat_label = BattleStyle.label("", 20, BattleStyle.CYAN)
	beat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	put($LawPanel, beat_label, Vector2(12, 52), Vector2(986, 32))
	law_preview = BattleStyle.label("", 14, BattleStyle.MUTED)
	law_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	law_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	put($LawPanel, law_preview, Vector2(16, 86), Vector2(978, 37))
	heading = BattleStyle.label("", 19, BattleStyle.GOLD)
	put($Commands, heading, Vector2(14, 12), Vector2(272, 32))
	for index in 6:
		var b = button($Commands, "", Vector2(12, 54 + index * 58), Vector2(276, 52), select_skill.bind(index))
		b.add_theme_font_size_override("font_size", 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		skill_buttons.append(b)
	skill_info = BattleStyle.label("", 14, BattleStyle.MUTED)
	skill_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	put($Commands, skill_info, Vector2(15, 414), Vector2(272, 86))
	round_label = BattleStyle.label("", 16, BattleStyle.GOLD)
	put($RoundControls, round_label, Vector2(14, 6), Vector2(370, 25))
	confirm = button($RoundControls, "RESOLVER RONDA  [Espacio]", Vector2(12, 37), Vector2(378, 43), resolve_round)
	confirm.add_theme_font_size_override("font_size", 16)
	auto_button = button($RoundControls, "Completar plan", Vector2(12, 88), Vector2(157, 33), auto_plan)
	auto_button.add_theme_font_size_override("font_size", 13)
	button($RoundControls, "×1 / ×3", Vector2(175, 88), Vector2(95, 33), func():
		action_delay = 0.23 if action_delay > 0.3 else 0.7
		set_status("Velocidad de animación: " + ("×3" if action_delay < 0.3 else "×1")))
	button($RoundControls, "Reiniciar", Vector2(278, 88), Vector2(112, 33), ask_restart).add_theme_font_size_override("font_size", 13)
	status_label = BattleStyle.label("", 14)
	put($StatusPanel, status_label, Vector2(12, 6), Vector2(1538, 27))
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	preview_panel = Panel.new()
	put(self, preview_panel, Vector2(795, 190), Vector2(260, 496))
	preview_panel.add_theme_stylebox_override("panel", BattleStyle.box(BattleStyle.CYAN, Color("091519fa")))
	preview_text = RichTextLabel.new()
	preview_text.bbcode_enabled = true
	preview_text.add_theme_font_size_override("normal_font_size", 15)
	preview_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(preview_panel, preview_text, Vector2(16, 14), Vector2(228, 382))
	add_action = button(preview_panel, "Añadir al plan  [Enter]", Vector2(14, 408), Vector2(232, 44), confirm_action)
	add_action.add_theme_font_size_override("font_size", 15)
	button(preview_panel, "Cancelar selección", Vector2(14, 460), Vector2(232, 27), func():
		selected_skill = null
		pending_uid = -1
		refresh()).add_theme_font_size_override("font_size", 13)
	create_overlay()

func create_overlay() -> void:
	overlay = Panel.new()
	put(self, overlay, Vector2(320, 185), Vector2(960, 495))
	overlay.z_index = 20
	# Full-screen blocker prevents clicks reaching the arena while a dialog is open.
	var blocker = ColorRect.new()
	blocker.color = Color(0.0, 0.0, 0.0, 0.67)
	put(overlay, blocker, Vector2(-320, -185), Vector2(1600, 900))
	blocker.show_behind_parent = true
	overlay_text = RichTextLabel.new()
	overlay_text.bbcode_enabled = true
	put(overlay, overlay_text, Vector2(30, 28), Vector2(900, 365))
	button(overlay, "Cerrar  [Esc]", Vector2(30, 425), Vector2(200, 42), func(): overlay.hide())
	button(overlay, "Movimiento: sí / no", Vector2(260, 425), Vector2(235, 42), func():
		reduced_motion = not reduced_motion
		for view in views.values():
			view.animated = not reduced_motion)
	button(overlay, "Nueva partida", Vector2(710, 425), Vector2(220, 42), func():
		overlay.hide()
		start_battle(encounter))
	overlay.hide()

func start_battle(definition: BattleEncounter) -> void:
	generation += 1
	encounter = definition
	state = BattleState.new(encounter)
	busy = false
	history.clear()
	views.clear()
	cards.clear()
	for child in $Arena.get_children():
		child.free()
	for child in $Party.get_children():
		child.free()
	for child in $Effects.get_children():
		child.queue_free()
	$Background.texture = encounter.background
	var slots = $Slots.get_children()
	for unit in state.units:
		var view = BattleUnitView.new()
		$Arena.add_child(view)
		view.position = slots[unit.team * 4 + unit.slot].position
		view.setup(unit)
		view.animated = not reduced_motion
		view.selected.connect(on_unit_clicked)
		view.hovered.connect(on_unit_hovered)
		views[unit.uid] = view
		if unit.team == 0:
			create_card(unit)
	active_uid = state.living(0)[0].uid
	pending_uid = -1
	selected_skill = null
	hovered_uid = -1
	set_status("1 · Elegí una habilidad.  2 · Clic en el objetivo.  3 · Revisá el resultado y añadí la acción al plan.")
	refresh()

func create_card(unit) -> void:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(270, 146)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$Party.add_child(panel)
	var portrait = TextureRect.new()
	portrait.texture = unit.data.portrait if unit.data.portrait else unit.data.texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat = ShaderMaterial.new()
	mat.shader = load("res://sinderella/assets/chroma.gdshader")
	if unit.data.chroma_key:
		portrait.material = mat
	put(panel, portrait, Vector2(3, 5), Vector2(79, 122))
	var title = BattleStyle.label("%s · %s" % [unit.slot + 1, unit.data.display_name], 15, BattleStyle.GOLD)
	put(panel, title, Vector2(84, 10), Vector2(180, 25))
	var health = BattleStyle.label("", 13)
	put(panel, health, Vector2(84, 37), Vector2(180, 22))
	var bar = ProgressBar.new()
	bar.show_percentage = false
	put(panel, bar, Vector2(84, 63), Vector2(176, 9))
	var impulse = BattleStyle.label("", 18, BattleStyle.CYAN)
	put(panel, impulse, Vector2(84, 77), Vector2(180, 25))
	var plan_label = BattleStyle.label("", 12, BattleStyle.MUTED)
	plan_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	put(panel, plan_label, Vector2(12, 113), Vector2(250, 25))
	var hit = Button.new()
	hit.focus_mode = Control.FOCUS_NONE
	hit.flat = true
	hit.tooltip_text = "Seleccionar " + unit.data.display_name
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(hit)
	hit.pressed.connect(select_ally.bind(unit.uid))
	cards[unit.uid] = {"panel": panel, "health": health, "bar": bar, "impulse": impulse, "plan": plan_label, "hit": hit}

func select_ally(uid: int) -> void:
	if busy or state.phase != "planning" or not state.units[uid].alive():
		return
	active_uid = uid
	selected_skill = null
	pending_uid = -1
	if state.plans.has(uid):
		selected_skill = state.plans[uid].skill
		pending_uid = state.plans[uid].target.uid
	hovered_uid = -1
	refresh()

func select_skill(index: int) -> void:
	if busy or state.phase != "planning":
		return
	var unit = state.units[active_uid]
	if index >= mini(6, unit.data.skills.size()):
		return
	var candidate: BattleSkill = unit.data.skills[index]
	var valid: Array = state.targets(unit, candidate).filter(func(t): return state.can_use(unit, candidate, t))
	if valid.is_empty():
		set_status("Esa habilidad no está disponible: revisá Impulso y condiciones.")
		return
	selected_skill = candidate
	if not valid.any(func(t): return t.uid == pending_uid):
		pending_uid = valid[0].uid
	set_status("Elegí el objetivo resaltado, revisá la vista previa y presioná Añadir al plan.")
	refresh()

func on_unit_clicked(uid: int) -> void:
	if busy or state.phase != "planning":
		return
	var target = state.units[uid]
	if selected_skill == null:
		if target.team == 0:
			select_ally(uid)
		return
	var caster = state.units[active_uid]
	if not state.can_use(caster, selected_skill, target):
		set_status("Ese objetivo no es válido para la habilidad. Los objetivos disponibles tienen borde claro.")
		return
	pending_uid = uid
	refresh()

func confirm_action() -> void:
	if busy or selected_skill == null or pending_uid < 0 or overlay.visible:
		return
	var caster = state.units[active_uid]
	var target = state.units[pending_uid]
	if not state.plan(caster, selected_skill, target):
		set_status("La acción ya no es válida. Revisá el objetivo y los recursos.")
		return
	set_status("Añadida: %s → %s → %s. Seleccioná su retrato para revisar o cambiar." % [caster.data.display_name, selected_skill.display_name, target.data.display_name])
	selected_skill = null
	pending_uid = -1
	hovered_uid = -1
	for ally in state.living(0):
		if not state.plans.has(ally.uid):
			active_uid = ally.uid
			break
	refresh()

func on_unit_hovered(uid: int) -> void:
	if busy:
		return
	hovered_uid = uid
	refresh()

func auto_plan() -> void:
	if busy or state.phase != "planning":
		return
	for ally in state.living(0):
		if not state.plans.has(ally.uid):
			var action: Dictionary = state.choose_ai(ally)
			if not action.is_empty():
				state.plan(ally, action.skill, action.target)
	selected_skill = null
	set_status("Plan completado con acciones sugeridas. Revisalo antes de confirmar; la IA no predice combinaciones futuras.")
	pending_uid = -1
	refresh()

func refresh() -> void:
	var caster = state.units[active_uid]
	law_title.text = "LEY  /  " + state.law.display_name.to_upper()
	var beats: Array[String] = []
	for i in state.law.beat_length:
		beats.append("◆ %s" % (i + 1) if i + 1 == state.beat else "◇ %s" % (i + 1))
	beat_label.text = "     —     ".join(beats) + "      ·      RONDA %s" % state.round_number
	law_preview.text = "Al cierre del último tiempo · " + state.law.preview(state)
	law_preview.tooltip_text = "Predicción del estado actual; las acciones previstas todavía pueden cambiar los Papeles. Guardia reduce la Ley un 40%; el escudo absorbe daño."
	heading.text = caster.data.display_name.to_upper()
	for i in skill_buttons.size():
		var b: Button = skill_buttons[i]
		b.visible = i < caster.data.skills.size()
		if not b.visible:
			continue
		var skill: BattleSkill = caster.data.skills[i]
		var valid: bool = false
		for target in state.targets(caster, skill):
			if state.can_use(caster, skill, target):
				valid = true
		b.disabled = busy or state.phase != "planning" or not valid
		var cost_text: String = "%s Impulso" % skill.impulse_cost if skill.impulse_cost else "Gratis"
		b.text = "%s  %s\n%s · %s%s" % [i + 1, skill.display_name, skill_category(skill), cost_text, " · +1 Impulso" if skill.impulse_gain else ""]
		b.tooltip_text = skill.description + "\nPrioridad: %+d · Coste: %d · Genera: %d" % [skill.priority, skill.impulse_cost, skill.impulse_gain]
		b.add_theme_stylebox_override("normal", BattleStyle.box(BattleStyle.CYAN if selected_skill == skill else Color("645b46")))
	skill_info.text = "ACTÚA: " + caster.data.display_name + "\nElegí una habilidad. Después seleccioná un objetivo en la arena."
	if selected_skill:
		skill_info.text = selected_skill.description
	var color: Color = action_color(selected_skill)
	for unit in state.units:
		var valid_target: bool = selected_skill != null and state.can_use(caster, selected_skill, unit)
		views[unit.uid].refresh(state, unit.uid == active_uid and not busy, valid_target, valid_target and unit.uid == pending_uid, selected_skill != null, color)
	update_preview()
	for uid in cards:
		var unit = state.units[uid]
		var c: Dictionary = cards[uid]
		c.panel.add_theme_stylebox_override("panel", BattleStyle.box(BattleStyle.CYAN if uid == active_uid else BattleStyle.GOLD))
		c.health.text = "%s / %s PV   E:%s" % [unit.hp, unit.data.max_hp, unit.shield]
		c.bar.max_value = unit.data.max_hp
		c.bar.value = unit.hp
		c.impulse.text = "Impulso %s / 3" % unit.impulse
		c.plan.text = "Sin acción" if unit.alive() else "Fuera de escena"
		if state.plans.has(uid):
			var a: Dictionary = state.plans[uid]
			c.plan.text = "%s → %s" % [a.skill.display_name, a.target.data.display_name]
		c.hit.disabled = busy or not unit.alive()
	confirm.disabled = busy or selected_skill != null or not state.ready_to_resolve()
	auto_button.disabled = busy or state.phase != "planning"
	round_label.text = "RESOLVIENDO…" if busy else "PLANIFICACIÓN · %s / %s acciones" % [state.plans.size(), state.living(0).size()]
	if state.phase == "finished":
		round_label.text = "COMBATE FINALIZADO"
	var order: Array[String] = []
	for a in state.timeline():
		order.append("%s (%s)" % [a.caster.data.display_name.left(10), a.caster.data.speed + a.skill.priority])
	$Timeline.text = "INICIATIVA  /  " + "  ›  ".join(order)

func skill_category(skill: BattleSkill) -> String:
	for effect in skill.effects:
		if effect is DamageEffect:
			return "DAÑO"
		if effect is HealEffect:
			return "CURACIÓN"
		if effect is ShieldEffect:
			return "ESCUDO"
		if effect is GuardEffect:
			return "DEFENSA"
		if effect is RoleEffect:
			return "PAPEL"
	return "COMPÁS"

func action_color(skill: BattleSkill) -> Color:
	if skill == null:
		return BattleStyle.GOLD
	var kind: String = skill_category(skill)
	if kind == "DAÑO":
		return BattleStyle.RED
	if kind == "CURACIÓN":
		return BattleStyle.GREEN
	if kind in ["ESCUDO", "DEFENSA"]:
		return BattleStyle.CYAN
	return BattleStyle.GOLD

func update_preview() -> void:
	last_preview = {}
	add_action.disabled = true
	if busy or state.phase != "planning":
		preview_text.text = "[font_size=24]Resolución[/font_size]\n\nLas acciones se ejecutan por iniciativa.\n\nConsultá el registro para ver cada resultado."
		return
	var caster = state.units[active_uid]
	var intro: String = "[color=#75ded7]ACTÚA[/color]\n[font_size=24]%s[/font_size]\n\n" % caster.data.display_name
	if selected_skill == null or pending_uid < 0:
		preview_text.text = intro + "[font_size=20]1. Elegí una habilidad\n\n2. Elegí su objetivo\n\n3. Revisá el resultado[/font_size]\n\nLa acción se guarda al pulsar Añadir al plan."
		if state.ready_to_resolve():
			preview_text.text = "[font_size=26]Plan completo[/font_size]\n\nLas cuatro acciones están preparadas.\n\nSeleccioná un retrato para revisar o cambiar su acción.\n\n[color=#75ded7]Resolver ronda ejecuta el plan.[/color]"
		return
	var target = state.units[pending_uid]
	var p: Dictionary = state.preview_action(caster, selected_skill, target)
	if p.is_empty():
		preview_text.text = intro + "Elegí un objetivo válido."
		return
	last_preview = p
	var color: Color = action_color(selected_skill)
	var kind: String = skill_category(selected_skill)
	var change: String = ""
	var detail: String = ""
	if kind == "DAÑO":
		change = "−%s VIDA" % (p.hp_before - p.hp_after)
		detail = "Vida: %s → %s / %s" % [p.hp_before, p.hp_after, target.data.max_hp]
		if p.shield_before > p.shield_after:
			detail += "\nEscudo absorbe: %s\nEscudo: %s → %s" % [p.shield_before - p.shield_after, p.shield_before, p.shield_after]
	elif kind == "CURACIÓN":
		change = "+%s VIDA" % (p.hp_after - p.hp_before)
		detail = "Vida: %s → %s / %s" % [p.hp_before, p.hp_after, target.data.max_hp]
		if p.hp_after == p.hp_before:
			detail += "\nYa tiene toda su Vida."
	elif kind == "ESCUDO":
		change = "+%s ESCUDO" % (p.shield_after - p.shield_before)
		detail = "Escudo: %s → %s\nSe conserva el mayor." % [p.shield_before, p.shield_after]
	elif kind == "DEFENSA":
		change = "−40% DAÑO"
		detail = "Guardia hasta su próxima acción."
	elif kind == "COMPÁS":
		change = "COMPÁS %s → %s" % [p.beat_before, p.beat_after]
		detail = "Una vez por bando y ciclo."
	else:
		change = "CONTRADICCIÓN" if p.contradiction else "CAMBIA PAPEL"
		detail = "%s → %s%s" % [p.role_before, p.role_after, " + " + p.echo_after if p.echo_after else ""]
		if p.caster_role_after != caster.role:
			detail += "\n%s: %s" % [caster.data.display_name, p.caster_role_after]
	# Show secondary effects of combined skills without inventing a numeric total.
	for event in p.events:
		if event.kind == "role" and kind == "DAÑO":
			detail += "\n" + event.text
	var intent_text: String = ""
	if target.team == 1 and state.intentions.has(target.uid) and not state.intentions[target.uid].is_empty():
		var a: Dictionary = state.intentions[target.uid]
		intent_text = "\n[font_size=12]Intención: %s → %s[/font_size]" % [a.skill.display_name, a.target.data.display_name]
	preview_text.text = intro + "[font_size=18]%s[/font_size]\n\n[color=#%s]OBJETIVO\n[font_size=22]%s[/font_size]\n\n[font_size=27]%s[/font_size][/color]\n%s\n\nImpulso: %s → %s\n[font_size=12]Con el estado actual. Puede cambiar si otra acción se resuelve antes.[/font_size]%s" % [selected_skill.display_name, color.to_html(false), target.data.display_name, change, detail, p.impulse_before, p.impulse_after, intent_text]
	views[target.uid].set_prediction(p, change, color)
	add_action.disabled = false
	add_action.text = "Actualizar plan  [Enter]" if state.plans.has(caster.uid) else "Añadir al plan  [Enter]"
	add_action.add_theme_stylebox_override("normal", BattleStyle.box(color, Color("163033")))

func resolve_round() -> void:
	if busy or selected_skill != null or overlay.visible or not state.begin_resolution():
		return
	busy = true
	selected_skill = null
	var token: int = generation
	refresh()
	while state.phase == "resolving":
		var result: Dictionary = state.step()
		set_status(result.label)
		history.append(result.label)
		if result.caster >= 0 and not reduced_motion:
			var view = views[result.caster]
			var origin: Vector2 = view.position
			var tween = create_tween()
			tween.tween_property(view, "position:x", origin.x + (20 if state.units[result.caster].team == 0 else -20), action_delay * 0.2)
			tween.tween_property(view, "position:x", origin.x, action_delay * 0.35)
		var offset: int = 0
		for event in result.events:
			history.append("  %s: %s" % [state.units[event.target].data.display_name, event.text])
			float_text(event, offset)
			offset += 24
		refresh()
		await get_tree().create_timer(action_delay).timeout
		if token != generation or not is_inside_tree():
			return
	busy = false
	if state.phase == "finished":
		var survivors: Array = state.living(0).map(func(u): return {"id": u.data.id, "hp": u.hp, "impulse": u.impulse})
		battle_finished.emit(state.result, survivors)
		show_result()
	else:
		active_uid = state.living(0)[0].uid
		set_status("Ronda %s: nuevas intenciones reveladas. Prepará las acciones del grupo." % state.round_number)
	refresh()

func float_text(event: Dictionary, offset: int) -> void:
	var color: Color = BattleStyle.RED if event.kind == "damage" else BattleStyle.CYAN
	if event.kind == "heal":
		color = BattleStyle.GREEN
	if event.kind in ["role", "law"]:
		color = BattleStyle.GOLD
	var label = BattleStyle.label(event.text, 22, color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color("060b10"))
	put($Effects, label, views[event.target].position + Vector2(-25, 115 + offset), Vector2(330, 35))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tween = create_tween().set_parallel(true)
	if not reduced_motion:
		tween.tween_property(label, "position:y", label.position.y - 42, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func set_status(text: String) -> void:
	status_label.text = text

func show_help() -> void:
	overlay_text.text = "[font_size=26][color=#ba9660]Cómo jugar · El umbral de Briar[/color][/font_size]\n\n1. Seleccioná un aliado con su retrato o F1–F4. Elegí una habilidad (1–6) y hacé clic sobre un objetivo. Revisá el daño, curación o escudo en el panel central y presioná Añadir al plan (Enter), también para Guardia.\n2. Prepará una acción por aliado. Podés cambiarlas libremente. Espacio confirma; la iniciativa suma Velocidad + Prioridad.\n3. Al tercer Compás, la Ley golpea a quienes tengan Intruso. Si también tienen Guardián, sufren el desenlace roto. Podés pasar Intruso con Cambio de dueña y crear un eco con Nombre impuesto.\n4. Atacar y guardar generan Impulso; las firmas lo consumen. Máximo 3. Guardia reduce 40%; el escudo no se suma: conserva el mayor.\n5. Si un objetivo cae o deja de cumplir condiciones antes de la acción, esta falla sin coste. No hay redirecciones sorpresa.\n\n[b]Controles:[/b] clic · F1–F4 aliados · 1–6 acciones · Enter añadir al plan · Espacio resolver · Esc cancelar/cerrar · L registro · F11 pantalla completa.\n[b]Demo:[/b] reglas y cifras de prueba, sin QTE, inventario, progresión ni jefe multifase."
	overlay.show()

func show_log() -> void:
	overlay_text.text = "[font_size=26]Registro de combate[/font_size]\n\n" + "\n".join(history)
	overlay.show()

func ask_restart() -> void:
	if busy:
		set_status("Esperá a que termine la ronda para reiniciar.")
		return
	overlay_text.text = "[font_size=26]¿Reiniciar el encuentro?[/font_size]\n\nNueva partida restablece toda la Vida, Impulso, Papeles y enemigos. Cerrar conserva el combate actual."
	overlay.show()

func show_result() -> void:
	var title: String = "VICTORIA" if state.result == "victory" else ("EMPATE" if state.result == "draw" else "DERROTA")
	overlay_text.text = "[font_size=32][color=#ba9660]%s[/color][/font_size]\n\nEl encuentro terminó en la ronda %s.\n\nAliados en pie: %s / %s\n\nEl resultado se emite mediante battle_finished para conectarlo con tu mapa, recompensas o historia.\n\nPodés cerrar esta ventana para consultar el registro o iniciar otra partida." % [title, state.round_number, state.living(0).size(), encounter.allies.size()]
	overlay.show()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F11:
		var window = get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif event.keycode == KEY_ESCAPE:
		if overlay.visible:
			overlay.hide()
		else:
			selected_skill = null
			refresh()
	elif not overlay.visible:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			confirm_action()
		elif event.keycode == KEY_SPACE:
			resolve_round()
		elif event.keycode == KEY_L:
			show_log()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			select_skill(event.keycode - KEY_1)
		elif event.keycode >= KEY_F1 and event.keycode <= KEY_F4:
			var i: int = event.keycode - KEY_F1
			if i < encounter.allies.size():
				select_ally(i)
