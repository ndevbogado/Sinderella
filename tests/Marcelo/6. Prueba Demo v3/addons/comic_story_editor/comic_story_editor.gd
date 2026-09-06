@tool
extends EditorPlugin

const PAGES_DIR := "res://scenes/cinematic/pages"
const SEQUENCE_PATH := "res://resources/cinematics/elias_intro.tres"
const TRAVEL_QUEST_PATH := "res://resources/quests/prepare_journey.tres"

var _dock: VBoxContainer
var _content: VBoxContainer
var _pages_box: VBoxContainer


func _enter_tree() -> void:
	_build_dock()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()


func _build_dock() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "Historia visual"
	_dock.custom_minimum_size = Vector2(250, 0)

	var title := Label.new()
	title.text = "HISTORIA VISUAL"
	title.add_theme_font_size_override("font_size", 18)
	_dock.add_child(title)

	var help := Label.new()
	help.text = "Abrí una página, seleccioná un panel y movelo o redimensionalo en el editor 2D. Sus animaciones aparecen en el Inspector."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_dock.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	_add_button("Editar orden y audio", _edit_sequence)
	_add_button("Abrir reproductor", _open_scene.bind("res://scenes/cinematic_intro.tscn"))
	_add_button("Probar cinemática", _play_cinematic)

	var separator := HSeparator.new()
	_content.add_child(separator)
	var pages_title := Label.new()
	pages_title.text = "PÁGINAS"
	_content.add_child(pages_title)
	_pages_box = VBoxContainer.new()
	_content.add_child(_pages_box)
	_refresh_page_buttons()
	_add_button(
		"Plantilla de diálogo",
		_open_scene.bind("res://scenes/cinematic/components/dialogue_box.tscn")
	)
	_add_button(
		"Plantilla de narración",
		_open_scene.bind("res://scenes/cinematic/components/narration_box.tscn")
	)

	var scenes_separator := HSeparator.new()
	_content.add_child(scenes_separator)
	var scenes_title := Label.new()
	scenes_title.text = "OTRAS ESCENAS VISUALES"
	_content.add_child(scenes_title)
	_add_button("Menú principal", _open_scene.bind("res://scenes/main_menu.tscn"))
	_add_button("Pantalla de controles", _open_scene.bind("res://scenes/controls_screen.tscn"))
	_add_button("Pantalla de carga", _open_scene.bind("res://scenes/loading_screen.tscn"))
	_add_button("Casa de Elías", _open_scene.bind("res://scenes/elias_room.tscn"))
	_add_button("Personaje Elías", _open_scene.bind("res://scenes/game/elias.tscn"))
	_add_button("Inventario visual", _open_scene.bind("res://scenes/ui/inventory_panel.tscn"))
	_add_button("Reglas del inventario", _open_scene.bind("res://scenes/game/inventory_manager.tscn"))
	_add_button("Globo de Elías", _open_scene.bind("res://scenes/ui/world_speech_bubble.tscn"))
	_add_button("Misión: preparar viaje", _edit_resource.bind(TRAVEL_QUEST_PATH))
	_add_button("Objeto: capa y manta", _edit_resource.bind("res://resources/items/travel_cloak.tres"))
	_add_button("Objeto: mapa", _edit_resource.bind("res://resources/items/road_map.tres"))
	_add_button("Objeto: cantimplora", _edit_resource.bind("res://resources/items/waterskin.tres"))
	_add_button("Objeto: provisiones", _edit_resource.bind("res://resources/items/provisions.tres"))
	_add_button("Menú de pausa", _open_scene.bind("res://scenes/ui/pause_manager.tscn"))
	_add_button("Opciones", _open_scene.bind("res://scenes/ui/options_panel.tscn"))


func _add_button(label_text: String, callable: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.pressed.connect(callable)
	_content.add_child(button)


func _refresh_page_buttons() -> void:
	for child in _pages_box.get_children():
		child.queue_free()
	var files := DirAccess.get_files_at(PAGES_DIR)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tscn"):
			continue
		var button := Button.new()
		button.text = file_name.get_basename().replace("_", " ").capitalize()
		button.pressed.connect(_open_scene.bind(PAGES_DIR.path_join(file_name)))
		_pages_box.add_child(button)


func _open_scene(path: String) -> void:
	get_editor_interface().open_scene_from_path(path)


func _edit_sequence() -> void:
	var sequence := load(SEQUENCE_PATH)
	if sequence != null:
		get_editor_interface().edit_resource(sequence)


func _edit_resource(path: String) -> void:
	var resource := load(path)
	if resource != null:
		get_editor_interface().edit_resource(resource)


func _play_cinematic() -> void:
	get_editor_interface().play_custom_scene("res://scenes/cinematic_intro.tscn")
