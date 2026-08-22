extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EntityScript = preload("res://scripts/entity.gd")
const WorldArtScript = preload("res://scripts/world_art.gd")
const TimingScript = preload("res://scripts/timing_widget.gd")
const SpeechScript = preload("res://scripts/speech_manager.gd")
const PortraitScript = preload("res://scripts/portrait_view.gd")

const MODE_MENU := "menu"
const MODE_EXPLORE := "explore"
const MODE_DIALOGUE := "dialogue"
const MODE_CHOICE := "choice"
const MODE_BATTLE := "battle"
const MODE_TIMING := "timing"

const FOREST_WORLD_RECT := Rect2(0, 0, 1775, 998)
const KINGDOM_WORLD_RECT := Rect2(0, 0, 2132, 2132)

var mode: String = MODE_MENU
var current_map: String = "forest"

var world_art: WorldArt
var collision_root: Node2D
var entity_root: Node2D
var player: CendraPlayer
var camera: Camera2D
var entities: Array[StoryEntity] = []
var nearest_entity: StoryEntity
var prince_follower: StoryEntity

var ui_layer: CanvasLayer
var hud: Control
var objective_label: Label
var status_label: Label
var prompt_label: Label
var overlay_root: Control

var objective: String = ""
var memories := {"birth": false, "promise": false, "refusal": false}
var prince_joined: bool = false
var guardian_defeated: bool = false
var ending_reached: bool = false
var university_studied: bool = false
var university_lessons := {"formation": false, "guard": false, "counter": false}
var sword_owned: bool = false
var coins: int = 100

var dialogue_lines: Array = []
var dialogue_index: int = 0
var dialogue_callback: Callable
var dialogue_panel: Control
var dialogue_speaker: Label
var dialogue_text: Label
var dialogue_portrait: PortraitView

var battle_id: String = ""
var battle_turn: int = 0
var battle_player_value: int = 100
var battle_enemy_value: int = 100
var battle_hunt: int = 0
var battle_authority: int = 20
var guardian_timing_scores: Array[float] = []
var battle_panel: Control
var battle_log: RichTextLabel
var battle_player_bar: ProgressBar
var battle_enemy_bar: ProgressBar
var battle_player_value_label: Label
var battle_enemy_value_label: Label
var battle_extra_label: Label
var battle_hint_label: Label
var battle_action_buttons: Array[Button] = []
var pending_battle_action: String = ""
var timing_widget: TimingWidget
var speech_manager: SpeechManager
var dialogue_voice_button: Button

func _ready() -> void:
	_ensure_input_actions()
	_build_nodes()
	_build_forest(Vector2(205, 705))
	_show_title_menu()

func _ensure_input_actions() -> void:
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("move_up", [KEY_W, KEY_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_action("interact", [KEY_E])
	_ensure_action("ui_accept", [KEY_SPACE, KEY_ENTER])

func _ensure_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).size() > 0:
		return
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)

func _build_nodes() -> void:
	speech_manager = SpeechScript.new()
	speech_manager.name = "SpeechManager"
	add_child(speech_manager)

	world_art = WorldArtScript.new()
	add_child(world_art)

	collision_root = Node2D.new()
	collision_root.name = "WorldCollisions"
	add_child(collision_root)

	entity_root = Node2D.new()
	entity_root.name = "Entities"
	add_child(entity_root)

	player = PlayerScript.new()
	player.name = "Cendra"
	add_child(player)

	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	player.add_child(camera)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)

	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(hud)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(24, 20)
	top_panel.size = Vector2(1232, 86)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.028, 0.05, 0.90), Color("72627e"), 15))
	hud.add_child(top_panel)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.add_theme_constant_override("margin_top", 12)
	top_margin.add_theme_constant_override("margin_bottom", 12)
	top_panel.add_child(top_margin)
	var top_box := HBoxContainer.new()
	top_box.add_theme_constant_override("separation", 22)
	top_margin.add_child(top_box)

	objective_label = Label.new()
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color("f1e9f5"))
	top_box.add_child(objective_label)

	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(310, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("d6c6df"))
	top_box.add_child(status_label)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_label.offset_left = 270
	prompt_label.offset_right = -270
	prompt_label.offset_top = -78
	prompt_label.offset_bottom = -28
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color("fff4db"))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(prompt_label)

	overlay_root = Control.new()
	overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(overlay_root)

func _process(delta: float) -> void:
	if mode == MODE_EXPLORE:
		_update_nearest_entity()
		if prince_follower != null and is_instance_valid(prince_follower):
			var target := player.position - player.facing * 58.0 + Vector2(-26, 8)
			prince_follower.position = prince_follower.position.lerp(target, minf(delta * 4.2, 1.0))
	else:
		nearest_entity = null
		prompt_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if mode == MODE_EXPLORE:
			_interact_with_nearest()
		elif mode == MODE_DIALOGUE:
			_advance_dialogue()
	elif event.is_action_pressed("ui_accept"):
		if mode == MODE_DIALOGUE:
			_advance_dialogue()
		elif mode == MODE_TIMING and timing_widget != null:
			timing_widget.resolve_now()

func _show_title_menu() -> void:
	speech_manager.stop()
	mode = MODE_MENU
	player.movement_enabled = false
	hud.visible = false
	_clear_overlay()
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.03, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 510)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("17121f"), Color("7f688c"), 22))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 38)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)

	var title := Label.new()
	title.text = "CUENTOS ROTOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("f1e9f5"))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Demo explorable — El reino que no quería despertar"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 21)
	subtitle.add_theme_color_override("font_color", Color("cdbbd7"))
	box.add_child(subtitle)
	var description := Label.new()
	description.text = "Mové a Cendra libremente por los escenarios, buscá recuerdos, entrá en la prisión y llevá al príncipe hasta la torre. Los encuentros se resuelven mediante coherencia narrativa y timing."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 18)
	description.add_theme_color_override("font_color", Color("e1d7e6"))
	box.add_child(description)
	box.add_spacer(false)
	var start := _make_button("Comenzar", true)
	start.pressed.connect(_start_demo)
	box.add_child(start)
	var voice_button := _make_button(speech_manager.status_text(), false)
	voice_button.disabled = not speech_manager.available
	voice_button.pressed.connect(func():
		speech_manager.toggle()
		voice_button.text = speech_manager.status_text()
	)
	box.add_child(voice_button)

	var controls := Label.new()
	controls.text = "WASD o flechas: moverse  ·  E: interactuar  ·  Espacio: fijar timing"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color("baaac5"))
	box.add_child(controls)

func _start_demo() -> void:
	_reset_progress()
	_build_forest(Vector2(205, 705))
	hud.visible = true
	_clear_overlay()
	_show_dialogue([
		{"speaker": "NARRADOR", "text": "Cendra incendió el bosque durante tres noches. Sin árboles, sin sombras y sin rastros, Caperucita no tendría dónde esconderse."},
		{"speaker": "CENDRA", "text": "Sin árboles. Sin sombras. Sin rastros que cubrir. Esta vez vas a tener que pelear mirándome."},
		{"speaker": "CAPERUCITA", "text": "Quemaste el bosque para verme venir... y todavía pensás que el lobo vivía entre los árboles."}
	], func():
		_enter_exploration("Acercate a Caperucita y presioná E para enfrentarla.")
	)

func _reset_progress() -> void:
	memories = {"birth": false, "promise": false, "refusal": false}
	prince_joined = false
	guardian_defeated = false
	ending_reached = false
	university_studied = false
	university_lessons = {"formation": false, "guard": false, "counter": false}
	sword_owned = false
	coins = 100
	guardian_timing_scores.clear()

func _enter_exploration(new_objective: String = "") -> void:
	mode = MODE_EXPLORE
	player.movement_enabled = true
	if new_objective != "":
		objective = new_objective
	_refresh_hud()

func _refresh_hud() -> void:
	objective_label.text = "OBJETIVO: " + objective
	var memory_count: int = 0
	for key in memories:
		if bool(memories[key]):
			memory_count += 1
	status_label.text = "Rec. %d/3 · $%d" % [memory_count, coins]
	if university_studied:
		status_label.text += " · Univ. ✓"
	if sword_owned:
		status_label.text += " · Espada ✓"
	if prince_joined:
		status_label.text += " · Príncipe ✓"
	if guardian_defeated:
		status_label.text += " · Castillo ✓"

func _clear_world() -> void:
	for child in collision_root.get_children():
		child.queue_free()
	for child in entity_root.get_children():
		child.queue_free()
	entities.clear()
	nearest_entity = null
	prince_follower = null

func _build_forest(start_position: Vector2) -> void:
	_clear_world()
	current_map = "forest"
	world_art.set_map("forest")
	_add_boundaries(FOREST_WORLD_RECT)
	# Los troncos carbonizados bordean el claro; se dejan zonas amplias para el duelo.
	for rect in [
		Rect2(0, 0, 1775, 150), Rect2(0, 885, 1775, 113),
		Rect2(0, 150, 95, 735), Rect2(1680, 150, 95, 735),
		Rect2(260, 300, 95, 240), Rect2(265, 720, 110, 115),
		Rect2(1320, 260, 120, 205), Rect2(1380, 670, 110, 150)
	]:
		_add_wall(rect)
	_add_entity("caperucita", "Caperucita", "enemy", Vector2(900, 565), Color("7a2633"))
	player.position = start_position
	_set_camera_limits(FOREST_WORLD_RECT)

func _build_kingdom(start_position: Vector2 = Vector2(1035, 1830)) -> void:
	_clear_world()
	current_map = "kingdom"
	world_art.set_map("kingdom")
	_add_boundaries(KINGDOM_WORLD_RECT)
	# Colisiones sobre las estructuras principales del nuevo mapa.
	_add_wall(Rect2(255, 300, 430, 380)) # Universidad
	_add_wall(Rect2(760, 245, 625, 540)) # Castillo
	_add_wall(Rect2(1510, 315, 515, 430)) # Prisión
	_add_wall(Rect2(1655, 1030, 425, 285)) # Herrería
	_add_wall(Rect2(940, 1015, 250, 210)) # Plaza/fuente central

	var market := _add_entity("memory_birth", "Recuerdo del nacimiento", "memory", Vector2(650, 880), Color("efd69d"))
	market.set_completed(memories["birth"])
	var archive := _add_entity("memory_refusal", "Recuerdo de la negativa", "memory", Vector2(1490, 900), Color("b9cfe8"))
	archive.set_completed(memories["refusal"])
	var garden := _add_entity("memory_promise", "Recuerdo de la promesa", "memory", Vector2(1050, 1280), Color("d7afd4"))
	garden.set_completed(memories["promise"])
	_add_entity("university_door", "Universidad", "door", Vector2(470, 735), Color("8e6aaa"))
	_add_entity("blacksmith_door", "Herrería", "door", Vector2(1860, 1385), Color("b67b45"))
	_add_entity("prison_door", "Entrada a la prisión", "door", Vector2(1760, 835), Color("8b7798"))
	if not guardian_defeated:
		_add_entity("tower_guard", "Custodio sin rostro", "enemy", Vector2(1068, 785), Color("52465f"))
	else:
		_add_entity("tower_door", "Entrada al castillo", "door", Vector2(1068, 785), Color("d8c3e4"))
	if prince_joined:
		prince_follower = _add_entity("prince_follower", "El príncipe", "npc", start_position + Vector2(-55, 18), Color("697b9d"))
	player.position = start_position
	_set_camera_limits(KINGDOM_WORLD_RECT)

func _build_university() -> void:
	_clear_world()
	current_map = "university"
	world_art.set_map("university")
	_add_boundaries(Rect2(0, 0, 1280, 760))
	_add_wall(Rect2(90, 80, 1100, 55))
	_add_wall(Rect2(90, 625, 1100, 55))
	_add_wall(Rect2(90, 80, 55, 600))
	_add_wall(Rect2(1135, 80, 55, 600))
	var formation := _add_entity("lesson_formation", "Formación de escudos", "memory", Vector2(360, 310), Color("8fa5ca"))
	formation.set_completed(bool(university_lessons["formation"]))
	var guard_lesson := _add_entity("lesson_guard", "Guardia disciplinada", "memory", Vector2(640, 270), Color("b4a2d4"))
	guard_lesson.set_completed(bool(university_lessons["guard"]))
	var counter := _add_entity("lesson_counter", "Contraataque del reino", "memory", Vector2(920, 310), Color("d4b08d"))
	counter.set_completed(bool(university_lessons["counter"]))
	_add_entity("exit_university", "Salida de la universidad", "door", Vector2(640, 590), Color("8e6aaa"))
	player.position = Vector2(640, 530)
	_set_camera_limits(Rect2(0, 0, 1280, 760))

func _build_blacksmith() -> void:
	_clear_world()
	current_map = "blacksmith"
	world_art.set_map("blacksmith")
	_add_boundaries(Rect2(0, 0, 1280, 760))
	_add_wall(Rect2(80, 80, 1120, 55))
	_add_wall(Rect2(80, 625, 1120, 55))
	_add_wall(Rect2(80, 80, 55, 600))
	_add_wall(Rect2(1145, 80, 55, 600))
	_add_entity("blacksmith", "Maestro herrero", "npc", Vector2(800, 325), Color("8b674d"))
	_add_entity("exit_blacksmith", "Salida de la herrería", "door", Vector2(300, 565), Color("b67b45"))
	player.position = Vector2(360, 520)
	_set_camera_limits(Rect2(0, 0, 1280, 760))

func _build_prison() -> void:
	_clear_world()
	current_map = "prison"
	world_art.set_map("prison")
	_add_boundaries(Rect2(0, 0, 1280, 760))
	_add_wall(Rect2(160, 100, 50, 550))
	_add_wall(Rect2(1120, 100, 50, 550))
	_add_entity("prince", "El príncipe olvidado", "npc", Vector2(900, 390), Color("697b9d"))
	_add_entity("exit_prison", "Volver al reino", "door", Vector2(265, 390), Color("8b7798"))
	player.position = Vector2(330, 390)
	_set_camera_limits(Rect2(0, 0, 1280, 760))

func _build_tower() -> void:
	_clear_world()
	current_map = "tower"
	world_art.set_map("tower")
	_add_boundaries(Rect2(0, 0, 1280, 1250))
	# Bordes del pasillo, con desvíos oníricos.
	_add_wall(Rect2(0, 0, 360, 1250))
	_add_wall(Rect2(920, 0, 360, 1250))
	_add_wall(Rect2(360, 760, 190, 70))
	_add_wall(Rect2(730, 520, 190, 70))
	_add_wall(Rect2(360, 310, 190, 70))
	_add_entity("briar", "Bella Durmiente", "bed", Vector2(640, 165), Color("b99ac7"))
	player.position = Vector2(640, 1110)
	if prince_joined:
		prince_follower = _add_entity("prince_follower", "El príncipe", "npc", Vector2(595, 1160), Color("697b9d"))
	_set_camera_limits(Rect2(0, 0, 1280, 1250))

func _add_boundaries(rect: Rect2) -> void:
	var thickness := 48.0
	_add_wall(Rect2(rect.position.x - thickness, rect.position.y - thickness, rect.size.x + thickness * 2.0, thickness))
	_add_wall(Rect2(rect.position.x - thickness, rect.end.y, rect.size.x + thickness * 2.0, thickness))
	_add_wall(Rect2(rect.position.x - thickness, rect.position.y, thickness, rect.size.y))
	_add_wall(Rect2(rect.end.x, rect.position.y, thickness, rect.size.y))

func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = rect.position + rect.size * 0.5
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	collision_root.add_child(body)

func _add_entity(id_value: String, name_value: String, kind_value: String, position_value: Vector2, color_value: Color) -> StoryEntity:
	var entity: StoryEntity = EntityScript.new()
	entity.setup(id_value, name_value, kind_value, color_value)
	entity.position = position_value
	entity_root.add_child(entity)
	entities.append(entity)
	return entity

func _set_camera_limits(rect: Rect2) -> void:
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)

func _update_nearest_entity() -> void:
	nearest_entity = null
	var best_distance := 92.0
	for entity in entities:
		if entity == null or not is_instance_valid(entity) or not entity.enabled:
			continue
		if entity.entity_id == "prince_follower":
			continue
		var distance := player.position.distance_to(entity.position)
		if distance < best_distance:
			best_distance = distance
			nearest_entity = entity
	if nearest_entity == null:
		prompt_label.text = ""
	else:
		prompt_label.text = "[E] " + _interaction_text(nearest_entity)

func _interaction_text(entity: StoryEntity) -> String:
	match entity.entity_id:
		"caperucita", "tower_guard":
			return "Enfrentar a " + entity.display_name
		"memory_birth", "memory_promise", "memory_refusal", "lesson_formation", "lesson_guard", "lesson_counter":
			return "Examinar " + entity.display_name.to_lower()
		"university_door", "blacksmith_door", "prison_door", "tower_door":
			return "Entrar"
		"exit_university", "exit_blacksmith", "exit_prison":
			return "Salir"
		"prince":
			return "Hablar con el príncipe"
		"blacksmith":
			return "Hablar con el herrero"
		"briar":
			return "Acercar al príncipe al lecho"
		_:
			return "Interactuar"

func _interact_with_nearest() -> void:
	if nearest_entity == null:
		return
	match nearest_entity.entity_id:
		"caperucita":
			_show_dialogue([
				{"speaker": "CAPERUCITA", "text": "Dale, Cendra. Mostrame qué parte de vos sigue creyendo que puede ganar."}
			], func(): _start_battle("caperucita"))
		"memory_birth":
			_collect_memory("birth")
		"memory_promise":
			_collect_memory("promise")
		"memory_refusal":
			_collect_memory("refusal")
		"university_door":
			_build_university()
			_enter_exploration("Observá las tres prácticas militares para comprender al Custodio.")
		"blacksmith_door":
			_build_blacksmith()
			_enter_exploration("Hablá con el maestro herrero para comprar un arma.")
		"lesson_formation":
			_study_university_lesson("formation")
		"lesson_guard":
			_study_university_lesson("guard")
		"lesson_counter":
			_study_university_lesson("counter")
		"exit_university":
			_build_kingdom(Vector2(470, 790))
			_enter_exploration(_kingdom_objective())
		"blacksmith":
			_talk_to_blacksmith()
		"exit_blacksmith":
			_build_kingdom(Vector2(1860, 1445))
			_enter_exploration(_kingdom_objective())
		"prison_door":
			_try_enter_prison()
		"exit_prison":
			_build_kingdom(Vector2(1765, 930))
			_enter_exploration(_kingdom_objective())
		"prince":
			_talk_to_prince()
		"tower_guard":
			_try_fight_guardian()
		"tower_door":
			_build_tower()
			_enter_exploration("Ascendé por la torre interior del castillo y alcanzá el lecho de Bella Durmiente.")
		"briar":
			_awaken_briar()

func _join_optional_goals(extras: Array[String]) -> String:
	if extras.size() == 0:
		return ""
	if extras.size() == 1:
		return extras[0]
	return extras[0] + " y " + extras[1]

func _kingdom_objective() -> String:
	var extras: Array[String] = []
	if not university_studied:
		extras.append("estudiar las tácticas en la Universidad")
	if not sword_owned:
		extras.append("comprar una espada en la Herrería")
	if _memory_count() < 3:
		var memory_goal: String = "Reuní los tres recuerdos del príncipe"
		if extras.size() > 0:
			return memory_goal + ". Opcional: " + _join_optional_goals(extras) + "."
		return memory_goal + "."
	if not prince_joined:
		var prison_goal: String = "Entrá en la prisión y convencé al príncipe"
		if extras.size() > 0:
			return prison_goal + ". Antes del Custodio conviene " + _join_optional_goals(extras) + "."
		return prison_goal + "."
	if not guardian_defeated:
		return "Llevá al príncipe hasta el castillo. Preparación actual: " + _guardian_preparation_summary() + "."
	return "Entrá al castillo junto al príncipe."

func _university_lesson_count() -> int:
	var count: int = 0
	for lesson_key in university_lessons:
		if bool(university_lessons[lesson_key]):
			count += 1
	return count

func _study_university_lesson(key: String) -> void:
	if bool(university_lessons.get(key, false)):
		_show_dialogue([
			{"speaker": "CENDRA", "text": "Ya observé esta práctica. Lo importante es cómo el soldado recupera la postura después de atacar."}
		], func():
			if university_studied:
				_enter_exploration("Tácticas aprendidas. Podés volver a la ciudad.")
			else:
				_enter_exploration("Observá las prácticas restantes. (%d/3)" % _university_lesson_count())
		)
		return
	university_lessons[key] = true
	var lines: Array = []
	match key:
		"formation":
			lines = [
				{"speaker": "NARRADOR", "text": "Los soldados traban sus escudos antes de que el golpe llegue. No reaccionan al arma: reaccionan al cambio de peso del adversario."},
				{"speaker": "CENDRA", "text": "El Custodio también anunciará su defensa antes de cerrar el paso. Puedo reconocer ese instante."}
			]
		"guard":
			lines = [
				{"speaker": "NARRADOR", "text": "Cada guardia mantiene una reserva. Incluso después de bloquear, deja fuerza suficiente para corregir un segundo ataque."},
				{"speaker": "CENDRA", "text": "Un ataque apresurado no bastará. Tendré que sostener la afirmación hasta el final."}
			]
		"counter":
			lines = [
				{"speaker": "NARRADOR", "text": "El instructor permite deliberadamente un pequeño error y ataca cuando el rival intenta corregirlo."},
				{"speaker": "CENDRA", "text": "Así castigan la duda. Si fallo, no debo intentar arreglar la frase a mitad del movimiento."}
			]
	var completed_now: bool = _university_lesson_count() >= 3
	if completed_now:
		university_studied = true
		lines.append({"speaker": "CENDRA", "text": "Ya entiendo el patrón militar del reino. Contra el Custodio, cada timing perfecto será una apertura prevista, no un golpe de suerte."})
	_build_university()
	_show_dialogue(lines, func():
		if university_studied:
			_enter_exploration("Tácticas aprendidas. Podés volver a la ciudad o revisar las estaciones.")
		else:
			_enter_exploration("Observá las prácticas restantes. (%d/3)" % _university_lesson_count())
	)

func _talk_to_blacksmith() -> void:
	if sword_owned:
		_show_dialogue([
			{"speaker": "HERRERO", "text": "La espada está equilibrada para romper una guardia, no para cortar armadura. No la desperdicies golpeando sin leer al rival."},
			{"speaker": "CENDRA", "text": "Con una apertura correcta, será suficiente."}
		], func(): _enter_exploration("La espada ya está equipada. Volvé a la ciudad cuando estés lista."))
		return
	_show_dialogue([
		{"speaker": "HERRERO", "text": "Esta espada pertenecía a un guardia del castillo. Conoce la distancia de sus formaciones mejor que cualquier hoja extranjera."},
		{"speaker": "HERRERO", "text": "Ochenta monedas. No te hará precisa, pero convertirá una apertura pequeña en una herida real."}
	], func():
		_show_choices("Espada del guardia — 80 monedas", [
			{"text": "Comprar la espada (%d monedas disponibles)" % coins, "callback": func(): _buy_guard_sword()},
			{"text": "No comprar todavía", "callback": func(): _enter_exploration("Podés volver a comprarla antes de enfrentar al Custodio.")}
		])
	)

func _buy_guard_sword() -> void:
	if coins < 80:
		_show_dialogue([
			{"speaker": "HERRERO", "text": "No alcanza. No vendo promesas; vendo acero."}
		], func(): _enter_exploration())
		return
	coins -= 80
	sword_owned = true
	_refresh_hud()
	_show_dialogue([
		{"speaker": "NARRADOR", "text": "Cendra recibe una espada corta del reino. Su peso está pensado para atravesar la recuperación de una guardia disciplinada."},
		{"speaker": "CENDRA", "text": "No necesito vencer su armadura. Solo necesito que una apertura sea suficiente."}
	], func(): _enter_exploration("Espada equipada. Podés salir de la Herrería."))

func _guardian_preparation_summary() -> String:
	if university_studied and sword_owned:
		return "tácticas aprendidas y espada equipada; podés cometer un error"
	if sword_owned:
		return "espada equipada, sin estudio; casi todos los timings deberán ser perfectos y ninguno puede ser un fallo"
	if university_studied:
		return "tácticas aprendidas, sin espada; los cinco timings deberán ser perfectos"
	return "sin preparación; los cinco timings deberán ser centros absolutos"

func _collect_memory(key: String) -> void:
	if memories[key]:
		_show_dialogue([{"speaker": "CENDRA", "text": "Este recuerdo ya está unido al nombre del príncipe."}], func(): _enter_exploration())
		return
	memories[key] = true
	var lines: Array = []
	match key:
		"birth":
			lines = [
				{"speaker": "RECUERDO", "text": "Un niño fue presentado ante la cuna de la princesa. El reino entero lo llamó príncipe."},
				{"speaker": "CENDRA", "text": "Primer hilo: el reino reconoció su nacimiento."}
			]
		"promise":
			lines = [
				{"speaker": "RECUERDO", "text": "Antes de que las espinas cerraran la torre, él prometió que regresaría para despertarla."},
				{"speaker": "CENDRA", "text": "Segundo hilo: todavía existe una promesa sin cumplir."}
			]
		"refusal":
			lines = [
				{"speaker": "RECUERDO", "text": "Cuando vio la prosperidad creada por el sueño, el príncipe eligió no dar el beso."},
				{"speaker": "CENDRA", "text": "Tercer hilo: fue su decisión la que hizo real la prisión."}
			]
	_build_kingdom(player.position)
	_show_dialogue(lines, func():
		var count := _memory_count()
		_enter_exploration(_kingdom_objective())
	)

func _memory_count() -> int:
	var count := 0
	for key in memories:
		if memories[key]:
			count += 1
	return count

func _try_enter_prison() -> void:
	if _memory_count() < 3:
		_show_dialogue([
			{"speaker": "NARRADOR", "text": "La puerta no conduce a ninguna parte. El sueño niega que exista una prisión."},
			{"speaker": "CENDRA", "text": "Necesito los tres recuerdos. Solo entonces podré afirmar que el príncipe es real."}
		], func(): _enter_exploration())
		return
	_show_dialogue([
		{"speaker": "CENDRA", "text": "Nació príncipe. Hizo una promesa. Y eligió no cumplirla. La prisión existe porque él existe."},
		{"speaker": "NARRADOR", "text": "La pared recuerda que siempre tuvo una puerta."}
	], func():
		_build_prison()
		_enter_exploration("Encontrá al príncipe en la prisión olvidada.")
	)

func _talk_to_prince() -> void:
	if prince_joined:
		_show_dialogue([{"speaker": "PRÍNCIPE", "text": "No vuelvas a pedirme que olvide lo que ocurrirá cuando ella despierte."}], func(): _enter_exploration())
		return
	_show_dialogue([
		{"speaker": "PRÍNCIPE", "text": "Si la despierto, las cosechas fallarán. Los enfermos volverán a sufrir. Todo esto se sostiene porque yo sigo aquí."},
		{"speaker": "CENDRA", "text": "No vine a salvar tu reino. Vine porque enfrenté a uno de los nuestros y perdí. Si Briar sigue dormida, voy a perder otra vez."}
	], func():
		_show_choices("¿Qué debe decir Cendra?", [
			{"text": "La verdad: necesito convertirla en mi aliada.", "callback": func(): _prince_choice("truth")},
			{"text": "Prometer que el reino no sufrirá ninguna consecuencia.", "callback": func(): _prince_choice("lie")},
			{"text": "Recordarle que mantenerla dormida también es una condena.", "callback": func(): _prince_choice("freedom")}
		])
	)

func _prince_choice(choice: String) -> void:
	prince_joined = true
	var response := ""
	match choice:
		"truth":
			response = "No confío en tus motivos. Pero sos la primera persona que no llamó salvación a lo que quiere hacer. Voy a acompañarte."
		"lie":
			response = "Los dos sabemos que eso es mentira. Aun así... quizá sea hora de aceptar una realidad que pueda romperse."
		"freedom":
			response = "La protegimos del dolor hasta convertirla en una herramienta. Tenés razón. Debe poder elegir despierta."
	_show_dialogue([
		{"speaker": "PRÍNCIPE", "text": response},
		{"speaker": "NARRADOR", "text": "El príncipe recupera su nombre. El reino ya puede verlo avanzando hacia el castillo."}
	], func():
		_build_kingdom(Vector2(1765, 930))
		_enter_exploration(_kingdom_objective())
	)

func _try_fight_guardian() -> void:
	if not prince_joined:
		_show_dialogue([
			{"speaker": "CUSTODIO", "text": "El castillo no se abre ante una intrusa. Traé al príncipe si querés que la ley te reconozca."}
		], func(): _enter_exploration())
		return
	_show_dialogue([
		{"speaker": "CUSTODIO", "text": "Ningún príncipe alcanzará el castillo."},
		{"speaker": "CENDRA", "text": "Entonces voy a romper la palabra 'ningún'."},
		{"speaker": "NARRADOR", "text": "Preparación de Cendra: " + _guardian_preparation_summary().capitalize() + "."}
	], func(): _start_battle("guardian"))

func _awaken_briar() -> void:
	if not prince_joined:
		_show_dialogue([{"speaker": "NARRADOR", "text": "El beso no puede ocurrir sin el príncipe."}], func(): _enter_exploration())
		return
	ending_reached = true
	player.movement_enabled = false
	_show_dialogue([
		{"speaker": "PRÍNCIPE", "text": "No puedo prometerte un reino intacto cuando abras los ojos."},
		{"speaker": "PRÍNCIPE", "text": "Solo puedo prometer que, por primera vez, lo que ocurra después será una decisión tuya."},
		{"speaker": "NARRADOR", "text": "El príncipe besa a la durmiente. Las paredes pierden las grietas que nunca tuvieron y recuperan las que el sueño ocultó."},
		{"speaker": "BRIAR", "text": "¿Cuánto tiempo me mantuvieron soñando?"},
		{"speaker": "CENDRA", "text": "Demasiado. Y no voy a insultarte llamando rescate a lo que hice. Vine a despertarte porque necesito tu ayuda."},
		{"speaker": "BRIAR", "text": "Entonces empezamos con una deuda, no con una mentira. Es algo."}
	], _show_final_choice)

func _show_final_choice() -> void:
	_show_choices("Briar puede conservar un solo milagro antes de abandonar el reino.", [
		{"text": "Conservar las cosechas", "callback": func(): _finish_demo("Las cosechas seguirán creciendo. Los enfermos enfrentarán nuevamente el tiempo.")},
		{"text": "Conservar las curaciones", "callback": func(): _finish_demo("Las enfermedades permanecerán dormidas. La tierra deberá pagar el costo.")},
		{"text": "No conservar ningún milagro", "callback": func(): _finish_demo("El reino despierta por completo. Briar conserva más poder para enfrentar a los otros Cuentos.")}
	])

func _finish_demo(result_text: String) -> void:
	mode = MODE_MENU
	player.movement_enabled = false
	_clear_overlay()
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.03, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 470)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("17121f"), Color("8d759a"), 22))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)
	var title := Label.new()
	title.text = "FIN DE LA DEMO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("f1e9f5"))
	box.add_child(title)
	var body := Label.new()
	body.text = result_text + "\n\nCendra ya no está sola. La próxima cacería volverá a llevarlas hasta Caperucita."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Color("ded3e4"))
	box.add_child(body)
	var restart := _make_button("Volver al título", true)
	restart.pressed.connect(_show_title_menu)
	box.add_child(restart)

# -----------------------------------------------------------------------------
# Diálogos y elecciones
# -----------------------------------------------------------------------------

func _show_dialogue(lines: Array, callback: Callable = Callable()) -> void:
	mode = MODE_DIALOGUE
	player.movement_enabled = false
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_callback = callback
	_clear_overlay()

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.26)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(shade)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 38
	dialogue_panel.offset_right = -38
	dialogue_panel.offset_top = -334
	dialogue_panel.offset_bottom = -28
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.035, 0.06, 0.985), Color("89749a"), 24))
	overlay_root.add_child(dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	dialogue_panel.add_child(margin)

	var main_box := HBoxContainer.new()
	main_box.add_theme_constant_override("separation", 18)
	margin.add_child(main_box)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(258, 0)
	portrait_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.065, 0.11, 0.92), Color("6e5d79"), 20))
	main_box.add_child(portrait_frame)
	dialogue_portrait = PortraitScript.new()
	dialogue_portrait.show_nameplate = false
	dialogue_portrait.mirror = false
	dialogue_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_frame.add_child(dialogue_portrait)

	var content_box := VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 7)
	main_box.add_child(content_box)

	var name_plate := PanelContainer.new()
	name_plate.custom_minimum_size = Vector2(0, 48)
	name_plate.add_theme_stylebox_override("panel", _panel_style(Color(0.11, 0.09, 0.15, 0.95), Color("7b6689"), 14))
	content_box.add_child(name_plate)
	var name_margin := MarginContainer.new()
	name_margin.add_theme_constant_override("margin_left", 18)
	name_margin.add_theme_constant_override("margin_right", 18)
	name_margin.add_theme_constant_override("margin_top", 10)
	name_margin.add_theme_constant_override("margin_bottom", 10)
	name_plate.add_child(name_margin)
	dialogue_speaker = Label.new()
	dialogue_speaker.add_theme_font_size_override("font_size", 24)
	dialogue_speaker.add_theme_color_override("font_color", Color("f4eef7"))
	dialogue_speaker.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	name_margin.add_child(dialogue_speaker)

	var text_panel := PanelContainer.new()
	text_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.095, 0.078, 0.13, 0.78), Color("5f516c"), 18))
	content_box.add_child(text_panel)
	var text_margin := MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 20)
	text_margin.add_theme_constant_override("margin_right", 20)
	text_margin.add_theme_constant_override("margin_top", 16)
	text_margin.add_theme_constant_override("margin_bottom", 16)
	text_panel.add_child(text_margin)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialogue_text.add_theme_font_size_override("font_size", 24)
	dialogue_text.add_theme_color_override("font_color", Color("f2edf4"))
	text_margin.add_child(dialogue_text)

	var dialogue_controls := HBoxContainer.new()
	dialogue_controls.add_theme_constant_override("separation", 12)
	content_box.add_child(dialogue_controls)
	dialogue_voice_button = _make_button(speech_manager.status_text(), false)
	dialogue_voice_button.custom_minimum_size = Vector2(230, 44)
	dialogue_voice_button.disabled = not speech_manager.available
	dialogue_voice_button.pressed.connect(_toggle_dialogue_voice)
	dialogue_controls.add_child(dialogue_voice_button)
	var continue_label := Label.new()
	continue_label.text = "E / Espacio o el botón para continuar"
	continue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_label.add_theme_font_size_override("font_size", 15)
	continue_label.add_theme_color_override("font_color", Color("b9abca"))
	dialogue_controls.add_child(continue_label)
	var continue_button := _make_button("Continuar", true)
	continue_button.custom_minimum_size = Vector2(190, 44)
	continue_button.pressed.connect(_advance_dialogue)
	dialogue_controls.add_child(continue_button)
	_display_dialogue_line()

func _display_dialogue_line() -> void:

	if dialogue_index >= dialogue_lines.size():
		_close_dialogue()
		return
	var line: Dictionary = dialogue_lines[dialogue_index]
	var speaker: String = str(line.get("speaker", ""))
	var spoken_text: String = str(line.get("text", ""))
	dialogue_speaker.text = _display_name_for_speaker(speaker)
	dialogue_text.text = spoken_text
	if dialogue_portrait != null and is_instance_valid(dialogue_portrait):
		dialogue_portrait.speaker_name = speaker
	speech_manager.speak(speaker, spoken_text)

func _advance_dialogue() -> void:
	if mode != MODE_DIALOGUE:
		return
	speech_manager.stop()
	dialogue_index += 1
	_display_dialogue_line()

func _close_dialogue() -> void:
	speech_manager.stop()
	_clear_overlay()
	var callback := dialogue_callback
	dialogue_callback = Callable()
	if callback.is_valid():
		callback.call()
	else:
		_enter_exploration()

func _toggle_dialogue_voice() -> void:
	speech_manager.toggle()
	if dialogue_voice_button != null and is_instance_valid(dialogue_voice_button):
		dialogue_voice_button.text = speech_manager.status_text()
	if speech_manager.enabled and dialogue_index < dialogue_lines.size():
		var line: Dictionary = dialogue_lines[dialogue_index]
		var speaker: String = str(line.get("speaker", ""))
		var text: String = str(line.get("text", ""))
		speech_manager.speak(speaker, text)

func _show_choices(title_text: String, options: Array) -> void:
	speech_manager.stop()
	mode = MODE_CHOICE
	player.movement_enabled = false
	_clear_overlay()
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.01, 0.025, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("17121f"), Color("7b6688"), 20))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("f1e9f5"))
	box.add_child(title)
	for option_data in options:
		var button := _make_button(str(option_data["text"]), false)
		var callback: Callable = option_data["callback"]
		button.pressed.connect(func():
			_clear_overlay()
			callback.call()
		)
		box.add_child(button)

# -----------------------------------------------------------------------------
# Combate narrativo
# -----------------------------------------------------------------------------

func _start_battle(id_value: String) -> void:
	speech_manager.stop()
	battle_id = id_value
	battle_turn = 1
	battle_player_value = 100
	battle_hunt = 0
	battle_authority = 20
	guardian_timing_scores.clear()
	battle_enemy_value = 100
	mode = MODE_BATTLE
	player.movement_enabled = false
	_build_battle_ui()
	_battle_write_intro()

func _build_battle_ui() -> void:
	_clear_overlay()
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.01, 0.025, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(center)

	battle_panel = PanelContainer.new()
	battle_panel.custom_minimum_size = Vector2(1160, 650)
	battle_panel.add_theme_stylebox_override("panel", _panel_style(Color("17121f"), Color("735f80"), 24))
	center.add_child(battle_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	battle_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var title := Label.new()
	title.text = "DUELO DE CUENTOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f0e8f4"))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Caperucita — El lobo sin bosque" if battle_id == "caperucita" else "Custodio — La ley sin rostro"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("cabbd5"))
	box.add_child(subtitle)

	var duel_row := HBoxContainer.new()
	duel_row.add_theme_constant_override("separation", 12)
	box.add_child(duel_row)

	var player_card: Dictionary = _make_battle_status_card("CENDRA", "Tu posición dentro del cuento", "Integridad restante", true)
	duel_row.add_child(player_card["root"] as Control)
	battle_player_bar = player_card["bar"] as ProgressBar
	battle_player_value_label = player_card["value_label"] as Label

	var versus_panel := PanelContainer.new()
	versus_panel.custom_minimum_size = Vector2(130, 238)
	versus_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.075, 0.12, 0.82), Color("5b4d65"), 18))
	duel_row.add_child(versus_panel)
	var versus_center := CenterContainer.new()
	versus_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	versus_panel.add_child(versus_center)
	var versus_label := Label.new()
	versus_label.text = "VS"
	versus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	versus_label.add_theme_font_size_override("font_size", 34)
	versus_label.add_theme_color_override("font_color", Color("efe4f4"))
	versus_center.add_child(versus_label)

	var enemy_name := "CAPERUCITA" if battle_id == "caperucita" else "CUSTODIO"
	var enemy_subtitle := "Cazadora, presa y lobo a la vez" if battle_id == "caperucita" else "La torre hecha prohibición"
	var enemy_meter := "Coherencia del rival" if battle_id == "caperucita" else "Coherencia de la ley"
	var enemy_card: Dictionary = _make_battle_status_card(enemy_name, enemy_subtitle, enemy_meter, false)
	duel_row.add_child(enemy_card["root"] as Control)
	battle_enemy_bar = enemy_card["bar"] as ProgressBar
	battle_enemy_value_label = enemy_card["value_label"] as Label

	battle_extra_label = Label.new()
	battle_extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_extra_label.add_theme_font_size_override("font_size", 15)
	battle_extra_label.add_theme_color_override("font_color", Color("ddd0e5"))
	box.add_child(battle_extra_label)

	battle_log = RichTextLabel.new()
	battle_log.bbcode_enabled = true
	battle_log.fit_content = false
	battle_log.custom_minimum_size = Vector2(0, 82)
	battle_log.scroll_active = false
	battle_log.add_theme_font_size_override("normal_font_size", 15)
	battle_log.add_theme_color_override("default_color", Color("ebe3ef"))
	battle_log.add_theme_stylebox_override("normal", _panel_style(Color("211a29"), Color("4c4055"), 14))
	box.add_child(battle_log)

	battle_hint_label = Label.new()
	battle_hint_label.custom_minimum_size = Vector2(0, 26)
	battle_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_hint_label.add_theme_font_size_override("font_size", 14)
	battle_hint_label.add_theme_color_override("font_color", Color("cdbfda"))
	box.add_child(battle_hint_label)

	var action_box := HBoxContainer.new()
	action_box.name = "ActionBox"
	action_box.add_theme_constant_override("separation", 7)
	box.add_child(action_box)
	battle_action_buttons.clear()
	var actions: Array = []
	if battle_id == "caperucita":
		actions = [
			{"id": "attack", "text": "Atacar el cuerpo", "desc": "Daño alto. Sube bastante la Caza del lobo."},
			{"id": "rewrite", "text": "Reescribir la persecución", "desc": "Daño medio. Gana Autoridad y apenas aumenta la Caza."},
			{"id": "silence", "text": "Guardar silencio", "desc": "Daño bajo. Reduce Caza y acumula mucha Autoridad."}
		]
	else:
		actions = [
			{"id": "break", "text": "Romper la palabra «ningún»", "desc": "Daño alto a la ley. Buen progreso ofensivo."},
			{"id": "prince", "text": "Mostrar al príncipe", "desc": "Daño muy alto si acertás. No ofrece defensa adicional."},
			{"id": "guard", "text": "Soportar la corrección", "desc": "Daño menor. Reduce el castigo del turno enemigo."}
		]
	for action_data in actions:
		var button := _make_battle_action_button(str(action_data["text"]), str(action_data["desc"]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var action_id := str(action_data["id"])
		var desc := str(action_data["desc"])
		button.mouse_entered.connect(func():
			if battle_hint_label != null and is_instance_valid(battle_hint_label):
				battle_hint_label.text = desc
		)
		button.pressed.connect(func(): _begin_timing(action_id))
		action_box.add_child(button)
		battle_action_buttons.append(button)
	battle_hint_label.text = _default_battle_hint()
	_refresh_battle_ui()

func _battle_write_intro() -> void:

	if battle_id == "caperucita":
		battle_log.text = "[center]Caperucita ya perdió su bosque. No parece haber perdido nada más.\nCada reacción de Cendra alimentará la persecución.[/center]"
	else:
		battle_log.text = "[center]La ley habla a través de una armadura vacía:\n«Ningún príncipe alcanzará la torre».[/center]"

func _begin_timing(action: String) -> void:
	if mode != MODE_BATTLE:
		return
	pending_battle_action = action
	mode = MODE_TIMING
	for button in battle_action_buttons:
		button.disabled = true
		button.visible = false
	var action_box := battle_panel.find_child("ActionBox", true, false) as HBoxContainer
	if action_box != null:
		timing_widget = TimingScript.new()
		timing_widget.resolved.connect(_resolve_battle_action)
		action_box.add_child(timing_widget)
		timing_widget.begin(1.0 + battle_turn * 0.08)
	battle_log.text = "[center]Completá la acción cuando el cursor atraviese la zona clara.\nPresioná Espacio o hacé clic sobre la barra.[/center]"

func _resolve_battle_action(score: float) -> void:
	if mode != MODE_TIMING:
		return
	mode = MODE_BATTLE
	if timing_widget != null and is_instance_valid(timing_widget):
		timing_widget.queue_free()
		timing_widget = null
	for button in battle_action_buttons:
		button.visible = true
	if battle_id == "caperucita":
		_resolve_caperucita_turn(score)
	else:
		_resolve_guardian_turn(score)

func _resolve_caperucita_turn(score: float) -> void:
	var quality := _timing_quality(score)
	var text := "[b]%s[/b]\n" % quality
	match pending_battle_action:
		"attack":
			var damage := 9 + int(score * 18.0)
			battle_enemy_value = maxi(0, battle_enemy_value - damage)
			battle_hunt += 26
			text += "Cendra ataca el cuerpo y reduce %d puntos de coherencia. Caperucita sonríe: la presa decidió luchar." % damage
		"rewrite":
			var damage := 8 + int(score * 24.0)
			battle_enemy_value = maxi(0, battle_enemy_value - damage)
			battle_authority += 7 + int(score * 12.0)
			battle_hunt += 8
			text += "Cendra afirma que esto no es una cacería. La versión rival pierde %d puntos de coherencia." % damage
		"silence":
			var damage := int(score * 11.0)
			battle_enemy_value = maxi(0, battle_enemy_value - damage)
			battle_authority += 14 + int(score * 8.0)
			battle_hunt = maxi(0, battle_hunt - 10)
			text += "Cendra se niega a interpretar a la presa. El silencio acumula autoridad."
	var incoming := 17 + int(float(battle_hunt) * 0.16) + battle_turn * 3
	battle_player_value = maxi(0, battle_player_value - incoming)
	text += "\n\nEl lobo atraviesa las cenizas y causa %d de daño narrativo." % incoming
	battle_log.text = text
	_refresh_battle_ui()
	if battle_turn >= 3 or battle_player_value <= 0:
		_disable_battle_buttons()
		await get_tree().create_timer(1.0).timeout
		_finish_caperucita_battle()
		return
	battle_turn += 1
	_refresh_battle_ui()
	if battle_hint_label != null:
		battle_hint_label.text = _default_battle_hint()
	_enable_battle_buttons()

func _finish_caperucita_battle() -> void:
	_clear_overlay()
	_show_dialogue([
		{"speaker": "NARRADOR", "text": "Cendra calculó el terreno, las trampas y el humo. No calculó que Caperucita ya no necesitaba el bosque."},
		{"speaker": "CAPERUCITA", "text": "Quemaste todo para poder verme. Y ahora no te queda ningún lugar donde esconder la derrota."},
		{"speaker": "CENDRA", "text": "No puedo enfrentar a los otros Cuentos sola."},
		{"speaker": "CENDRA", "text": "Necesito a alguien capaz de cambiar las reglas. Necesito despertar a Briar."},
		{"speaker": "NARRADOR", "text": "En la ciudad, la Universidad conserva las tácticas de los soldados del reino. La Herrería todavía vende armas diseñadas para atravesar sus guardias."},
		{"speaker": "CENDRA", "text": "No son desvíos. Son la diferencia entre depender de un timing imposible y poder sobrevivir a un error."}
	], func():
		_build_kingdom(Vector2(1035, 1830))
		_enter_exploration(_kingdom_objective())
	)

func _guardian_perfect_count() -> int:
	var count: int = 0
	for value in guardian_timing_scores:
		if value >= 0.92:
			count += 1
	return count

func _guardian_center_count() -> int:
	var count: int = 0
	for value in guardian_timing_scores:
		if value >= 0.985:
			count += 1
	return count

func _guardian_failure_count() -> int:
	var count: int = 0
	for value in guardian_timing_scores:
		if value < 0.45:
			count += 1
	return count

func _guardian_battle_requirement_text() -> String:
	if university_studied and sword_owned:
		return "conseguí al menos cuatro timings perfectos; el quinto puede ser incluso un fallo"
	if sword_owned:
		return "conseguí al menos cuatro timings perfectos y evitá resultados de «Frase interrumpida»"
	if university_studied:
		return "los cinco timings deben ser perfectos"
	return "sin preparación, los cinco timings deben ser «Centro absoluto»"

func _guardian_requirement_met() -> bool:
	var perfects: int = _guardian_perfect_count()
	var failures: int = _guardian_failure_count()
	if university_studied and sword_owned:
		return perfects >= 4
	if sword_owned:
		return perfects >= 4 and failures == 0
	if university_studied:
		return perfects >= 5
	return _guardian_center_count() >= 5

func _resolve_guardian_turn(score: float) -> void:
	guardian_timing_scores.append(score)
	var quality: String = _timing_quality(score)
	var text: String = "[b]%s[/b]\n" % quality
	var reduction: int = 0
	var weapon_bonus: int = 8 if sword_owned else 0
	var study_bonus: int = 4 if university_studied else 0
	match pending_battle_action:
		"break":
			var damage: int = 9 + int(score * 18.0) + weapon_bonus + study_bonus
			battle_enemy_value = maxi(1, battle_enemy_value - damage)
			battle_authority += 5
			text += "Cendra separa «ningún» de «príncipe». La ley pierde %d puntos de coherencia." % damage
		"prince":
			var damage: int = 8 + int(score * 22.0) + weapon_bonus + study_bonus
			battle_enemy_value = maxi(1, battle_enemy_value - damage)
			text += "El príncipe avanza por voluntad propia. La prohibición pierde %d puntos de coherencia." % damage
		"guard":
			var damage: int = 3 + int(score * 9.0) + weapon_bonus + study_bonus
			battle_enemy_value = maxi(1, battle_enemy_value - damage)
			reduction = 7 + int(score * 10.0)
			text += "Cendra permite que la ley intente corregirla y conserva su lugar dentro de la escena."
	var incoming: int = maxi(2, 8 + battle_turn * 2 - reduction - (3 if university_studied else 0))
	battle_player_value = maxi(0, battle_player_value - incoming)
	text += "\n\nLa ley responde y causa %d de daño narrativo." % incoming
	text += "\n\nPerfectos: %d/%d · Fallos: %d" % [_guardian_perfect_count(), guardian_timing_scores.size(), _guardian_failure_count()]
	battle_log.text = text
	_refresh_battle_ui()
	if guardian_timing_scores.size() >= 5:
		var victory: bool = _guardian_requirement_met()
		if victory:
			battle_enemy_value = 0
		else:
			battle_enemy_value = maxi(15, battle_enemy_value)
		_refresh_battle_ui()
		_disable_battle_buttons()
		await get_tree().create_timer(0.9).timeout
		_finish_guardian_battle(victory)
		return
	battle_turn += 1
	_refresh_battle_ui()
	if battle_hint_label != null:
		battle_hint_label.text = _guardian_battle_requirement_text().capitalize() + "."
	_enable_battle_buttons()

func _finish_guardian_battle(victory: bool) -> void:
	_clear_overlay()
	var result_summary: String = "%d perfectos, %d fallos" % [_guardian_perfect_count(), _guardian_failure_count()]
	if victory:
		guardian_defeated = true
		_show_dialogue([
			{"speaker": "NARRADOR", "text": "Cendra supera la prueba con " + result_summary + ". " + _guardian_preparation_summary().capitalize() + "."},
			{"speaker": "CUSTODIO", "text": "La ley ya no puede recordar qué palabra debía impedir el paso."},
			{"speaker": "PRÍNCIPE", "text": "Entonces voy a continuar antes de que vuelva a recordarla."}
		], func():
			_build_kingdom(Vector2(1068, 905))
			_enter_exploration("El castillo está abierto. Entrá junto al príncipe.")
		)
	else:
		_show_dialogue([
			{"speaker": "NARRADOR", "text": "La ley resiste. Resultado: " + result_summary + ". Para vencer: " + _guardian_battle_requirement_text() + "."},
			{"speaker": "CENDRA", "text": "Ahora sé exactamente qué me faltó. Puedo volver a intentarlo o terminar mi preparación en la ciudad."}
		], func():
			_build_kingdom(Vector2(1205, 935))
			_enter_exploration(_kingdom_objective())
		)

func _refresh_battle_ui() -> void:
	if battle_player_bar == null:
		return
	battle_player_bar.value = battle_player_value
	battle_enemy_bar.value = battle_enemy_value
	if battle_player_value_label != null:
		battle_player_value_label.text = "%d / 100" % battle_player_value
	if battle_enemy_value_label != null:
		battle_enemy_value_label.text = "%d / 100" % battle_enemy_value
	if battle_id == "caperucita":
		battle_extra_label.text = "Ronda %d  ·  Caza actual: %d  ·  Autoridad narrativa: %d" % [battle_turn, battle_hunt, battle_authority]
	else:
		battle_extra_label.text = "Intento %d/5  ·  Perfectos: %d  ·  Fallos: %d" % [mini(guardian_timing_scores.size() + 1, 5), _guardian_perfect_count(), _guardian_failure_count()]

func _enable_battle_buttons() -> void:
	for button in battle_action_buttons:
		button.disabled = false

func _disable_battle_buttons() -> void:
	for button in battle_action_buttons:
		button.disabled = true

func _default_battle_hint() -> String:
	if battle_id == "caperucita":
		return "Pasá el cursor por cada opción para leer claramente lo que hace antes de decidir."
	return _guardian_battle_requirement_text().capitalize() + "."

func _timing_quality(score: float) -> String:
	if score >= 0.985:
		return "CENTRO ABSOLUTO"
	if score >= 0.92:
		return "PALABRA PERFECTA"
	if score >= 0.72:
		return "AFIRMACIÓN FIRME"
	if score >= 0.45:
		return "VERSIÓN INESTABLE"
	return "FRASE INTERRUMPIDA"

# -----------------------------------------------------------------------------
# UI helpers
# -----------------------------------------------------------------------------

func _display_name_for_speaker(speaker: String) -> String:
	match speaker.to_upper():
		"CENDRA":
			return "Cendra"
		"CAPERUCITA":
			return "Caperucita"
		"BRIAR":
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
			return speaker.capitalize()

func _speaker_accent_color(speaker: String) -> Color:
	match speaker.to_upper():
		"CENDRA":
			return Color("8f7ca7")
		"CAPERUCITA":
			return Color("8a3345")
		"BRIAR":
			return Color("9f79ab")
		"PRÍNCIPE", "PRINCIPE":
			return Color("647ba3")
		"CUSTODIO":
			return Color("5a5367")
		_:
			return Color("857495")

func _make_battle_status_card(speaker: String, subtitle_text: String, meter_text: String, is_player: bool) -> Dictionary:
	var accent := _speaker_accent_color(speaker)
	var root := PanelContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2(0, 238)
	root.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.065, 0.11, 0.9), accent.lightened(0.18), 18))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	root.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	var name_label := Label.new()
	name_label.text = _display_name_for_speaker(speaker)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color("f4eef7"))
	box.add_child(name_label)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("cabed4"))
	box.add_child(subtitle)
	var portrait := PortraitScript.new()
	portrait.custom_minimum_size = Vector2(0, 112)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.speaker_name = speaker
	portrait.mirror = not is_player
	box.add_child(portrait)
	var meter_label := Label.new()
	meter_label.text = meter_text
	meter_label.add_theme_font_size_override("font_size", 13)
	meter_label.add_theme_color_override("font_color", accent.lightened(0.55))
	box.add_child(meter_label)
	var meter_row := HBoxContainer.new()
	meter_row.add_theme_constant_override("separation", 10)
	box.add_child(meter_row)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 20)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("background", _button_box(Color("1d1723"), Color("473d50")))
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = accent
	fill_style.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill_style)
	meter_row.add_child(bar)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(74, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.add_theme_color_override("font_color", Color("f1ebf4"))
	meter_row.add_child(value_label)
	return {"root": root, "bar": bar, "value_label": value_label}

func _make_battle_action_button(title_text: String, description: String) -> Button:
	var button := _make_button(title_text + "\n" + description, false)
	button.custom_minimum_size = Vector2(0, 72)
	button.add_theme_font_size_override("font_size", 13)
	button.tooltip_text = description
	return button

func _clear_overlay() -> void:
	for child in overlay_root.get_children():
		child.queue_free()

func _make_button(text_value: String, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 52)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("f3edf5"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal_color := Color("4c365a") if accent else Color("2b2432")
	var hover_color := Color("6b4d7a") if accent else Color("41354a")
	button.add_theme_stylebox_override("normal", _button_box(normal_color, Color("65536f")))
	button.add_theme_stylebox_override("hover", _button_box(hover_color, Color("aa8fba")))
	button.add_theme_stylebox_override("pressed", _button_box(hover_color.darkened(0.17), Color("aa8fba")))
	button.add_theme_stylebox_override("disabled", _button_box(Color("211c26"), Color("3a3240")))
	return button

func _button_box(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	return style

func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 8
	return style
