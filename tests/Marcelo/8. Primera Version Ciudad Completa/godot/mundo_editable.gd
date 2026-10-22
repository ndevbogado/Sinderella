extends Node2D
## The saved scene is authoritative. No map objects or positions are generated here.
@export var tamano_mapa: Vector2i = Vector2i(9600,9720)
@export var poblacion_activa: bool = true
@onready var hero: CharacterBody2D = $Actores/Elias
@onready var camera: Camera2D = $Actores/Elias/Camara
@onready var floor_layer: TileMapLayer = $Terreno/Suelo_FC_32px
@onready var paint_layer: TileMapLayer = $Terreno/Pintar_suelos_32px
@onready var water_layer: TileMapLayer = $Terreno/Colision_rio_8px
@onready var tint: CanvasModulate = $Luz
var population: Array = []
var boats: Array = []
var pois: Array = []
var night: bool = false
var map_panel: PanelContainer
var title_label: Label
var position_label: Label
var speech: Label
var speech_time: float = 0.0
var map_marker: ColorRect
var map_view: SubViewport
var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
func _ready() -> void:
	water_layer.hide()
	water_layer.collision_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_DEFAULT
	for type in ["CollisionPolygon2D","CollisionShape2D","Path2D"]:
		for node in find_children("*",type,true,false): node.hide()
	hero.world = self
	for person in get_tree().get_nodes_in_group("briar_vecino"):
		person.initialize(self)
		if person.es_barca: boats.append(person)
		else: population.append(person)
	pois = get_tree().get_nodes_in_group("briar_destino")
	$Ambiente.city = self
	_build_ui()
	_update_ui()
func _hits(point: Vector2, mask: int, areas: bool = false) -> bool:
	query.position = point
	query.collision_mask = mask
	query.collide_with_areas = areas
	query.collide_with_bodies = not areas
	return not get_world_2d().direct_space_state.intersect_point(query,1).is_empty()
func blocked(point: Vector2, feet: bool = true) -> bool:
	if point.x<12 or point.y<64 or point.x>tamano_mapa.x-12 or point.y>tamano_mapa.y-12: return true
	var offsets: Array = [Vector2.ZERO,Vector2(-7,-3),Vector2(7,-3),Vector2(-7,3),Vector2(7,3)] if feet else [Vector2.ZERO]
	for offset in offsets:
		var p: Vector2 = point+offset
		if _hits(p,1): return true
		if _hits(p,4,true): continue
		var tile: TileData = paint_layer.get_cell_tile_data(paint_layer.local_to_map(paint_layer.to_local(p)))
		if tile!=null:
			var passage: int = tile.get_custom_data("paso")
			if passage<0: return true
			if passage>0: continue
		if _hits(p,2): return true
	return false
func _physics_process(delta: float) -> void:
	if not is_instance_valid(map_panel): return
	var axis: Vector2 = Vector2.ZERO
	if not map_panel.visible:
		axis.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		axis.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
		if poblacion_activa:
			for person in population: person.step(delta)
			for boat in boats: boat.step(delta)
	hero.step(axis,delta,Input.is_key_pressed(KEY_SHIFT))
	speech_time -= delta
	speech.visible = speech_time>0
	_update_ui()
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_M, KEY_ESCAPE: _toggle_map()
			KEY_N:
				night = not night
				tint.color = Color("9daed8") if night else Color.WHITE
			KEY_C:
				var show_shapes: bool = not get_tree().debug_collisions_hint
				get_tree().debug_collisions_hint = show_shapes
				water_layer.visible = show_shapes
				for type in ["CollisionPolygon2D","CollisionShape2D"]:
					for node in find_children("*",type,true,false): node.visible = show_shapes
			KEY_E:
				if not map_panel.visible: _interact()
func _interact() -> void:
	var nearest: Node2D = null
	var distance: float = 88.0
	for person in population:
		var d: float = hero.global_position.distance_to(person.global_position)
		if d<distance:
			distance = d
			nearest = person
	if nearest!=null:
		nearest.wait = 4.0
		speech.text = nearest.nombre+" — "+nearest.dialogo
	else: speech.text = "Acercate a un habitante y presioná E para conversar."
	speech_time = 6.5
func visit(id: String) -> bool:
	for point in pois:
		if point.get_meta("id")==id:
			if blocked(point.global_position): return false
			hero.global_position = point.global_position
			map_panel.hide()
			map_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
			return true
	return false
func _toggle_map() -> void:
	map_panel.visible = not map_panel.visible
	map_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if map_panel.visible else SubViewport.UPDATE_DISABLED
func _update_ui() -> void:
	title_label.text = "BRIAR / F.C"
	for region in $Zonas.get_children():
		var rect: Rect2 = region.get_meta("rect")
		if Rect2(region.global_position+rect.position,rect.size).has_point(hero.global_position): title_label.text = "BRIAR / "+str(region.get_meta("nombre"))
	position_label.text = "Sector %02d · %02d    WASD · Mayús correr · E conversar · M mapa · N atardecer"%[int(hero.global_position.x/960)+1,int(hero.global_position.y/540)+1]
	if map_panel.visible: map_marker.position = hero.global_position/Vector2(tamano_mapa)*Vector2(438,444)-Vector2(3,3)
func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "Interfaz"
	add_child(ui)
	var top := ColorRect.new()
	top.color = Color(0.025,0.07,0.052,0.88)
	top.size = Vector2(960,44)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	title_label = Label.new()
	title_label.position = Vector2(16,9)
	title_label.add_theme_color_override("font_color",Color("e7d9ad"))
	ui.add_child(title_label)
	var button := Button.new()
	button.text = "M · Mapa y destinos"
	button.position = Vector2(770,5)
	button.size = Vector2(178,34)
	button.pressed.connect(_toggle_map)
	ui.add_child(button)
	position_label = Label.new()
	position_label.position = Vector2(16,514)
	position_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	position_label.add_theme_constant_override("shadow_offset_x",2)
	position_label.add_theme_constant_override("shadow_offset_y",2)
	ui.add_child(position_label)
	speech = Label.new()
	speech.position = Vector2(20,460)
	speech.size = Vector2(900,46)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.add_theme_color_override("font_color",Color("fff0c6"))
	speech.add_theme_color_override("font_shadow_color",Color.BLACK)
	speech.add_theme_constant_override("shadow_offset_x",2)
	speech.add_theme_constant_override("shadow_offset_y",2)
	speech.hide()
	ui.add_child(speech)
	map_panel = PanelContainer.new()
	map_panel.position = Vector2(27,19)
	map_panel.size = Vector2(906,502)
	ui.add_child(map_panel)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,14)
	map_panel.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	var heading := Label.new()
	heading.text = "BRIAR · Mapa actual de la escena"
	stack.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	stack.add_child(row)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(438,444)
	row.add_child(holder)
	var container := SubViewportContainer.new()
	container.size = Vector2(438,444)
	holder.add_child(container)
	map_view = SubViewport.new()
	map_view.size = Vector2i(438,444)
	map_view.world_2d = get_world_2d()
	map_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	container.add_child(map_view)
	var map_camera := Camera2D.new()
	map_camera.position = Vector2(tamano_mapa)/2
	map_camera.zoom = Vector2(438,444)/Vector2(tamano_mapa)
	map_view.add_child(map_camera)
	map_marker = ColorRect.new()
	map_marker.color = Color("fff2b1")
	map_marker.size = Vector2(6,6)
	holder.add_child(map_marker)
	var grid := GridContainer.new()
	grid.columns = 2
	row.add_child(grid)
	for point in pois:
		var travel := Button.new()
		travel.text = str(point.get_meta("nombre"))
		travel.custom_minimum_size = Vector2(164,22)
		travel.add_theme_font_size_override("font_size",10)
		travel.pressed.connect(visit.bind(str(point.get_meta("id"))))
		grid.add_child(travel)
	map_panel.hide()
