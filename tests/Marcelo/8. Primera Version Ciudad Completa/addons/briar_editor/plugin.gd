@tool
extends EditorPlugin
var dock: VBoxContainer
var info: Label
func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Briar"
	var heading := Label.new()
	heading.text = "BRIAR · EDICIÓN VISUAL"
	dock.add_child(heading)
	info = Label.new()
	info.text = "Elegí una capa. Luego poné el cursor sobre la vista 2D y pulsá F para encuadrar."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 220
	dock.add_child(info)
	for item in [["Elías / punto de inicio","Actores/Elias"],["Edificios","Actores/Edificios"],["Monumentos","Actores/Monumentos"],["Bosque y árboles","Actores/Vegetacion"],["Murallas","Actores/Murallas"],["Puentes y muelles","Puentes_y_muelles"],["Pintar suelos","Terreno/Pintar_suelos_32px"],["Terreno original F.C","Terreno/Suelo_FC_32px"],["Bordes y detalles","Terreno/Bordes_y_detalles_32px"],["Colisión del río","Terreno/Colision_rio_8px"],["Habitantes y rutas","Actores/Habitantes"],["Destinos de viaje","Destinos"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_select.bind(item[1]))
		dock.add_child(button)
	var check := CheckButton.new()
	check.text = "Mostrar colisiones"
	check.toggled.connect(_show_collision)
	dock.add_child(check)
	var routes := CheckButton.new()
	routes.text = "Mostrar rutas"
	routes.toggled.connect(_show_routes)
	dock.add_child(routes)
	var guide := Button.new()
	guide.text = "Abrir guía de edición"
	guide.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("res://docs/GUIA_EDICION_VISUAL.html")))
	dock.add_child(guide)
	add_control_to_dock(DOCK_SLOT_LEFT_BR,dock)
	scene_changed.connect(_scene_opened)
	call_deferred("_open_2d")
func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()
func _open_2d() -> void:
	# The editor restores its main screen after the scene_changed signal.
	await get_tree().create_timer(0.5).timeout
	var root: Node = EditorInterface.get_edited_scene_root()
	if root!=null and root.has_node("Terreno/Suelo_FC_32px"): EditorInterface.set_main_screen_editor("2D")
func _scene_opened(_root: Node) -> void: call_deferred("_open_2d")
func _select(path: String) -> void:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root==null or not root.has_node(path):
		info.text = "Abrí godot/ciudad.tscn para editar Briar."
		return
	var node: Node = root.get_node(path)
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(node)
	EditorInterface.edit_node(node)
	EditorInterface.set_main_screen_editor("2D")
	info.text = "Seleccionado: "+node.name+". Cursor sobre la vista 2D → F para encuadrar."
func _show_collision(visible: bool) -> void:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root!=null and root.has_node("Terreno/Colision_rio_8px"):
		root.get_node("Terreno/Colision_rio_8px").visible = visible
		for type in ["CollisionPolygon2D","CollisionShape2D"]:
			for node in root.find_children("*",type,true,false): node.visible = visible
func _show_routes(visible: bool) -> void:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root!=null:
		for node in root.find_children("*","Path2D",true,false): node.visible = visible
