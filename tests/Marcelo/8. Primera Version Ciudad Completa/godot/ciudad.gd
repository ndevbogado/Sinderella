extends Node2D
## Stream the terrain around the camera; retain independent Y-sorted art modules.
const Resident = preload("res://godot/habitante.gd")
const Atmosphere = preload("res://godot/ambiente.gd")
const Hero = preload("res://godot/explorador.gd")
var map_data: Dictionary
var catalog: Dictionary
var assets = {}
var base_bytes: PackedByteArray
var overlay_bytes: PackedByteArray
var collision_bytes: PackedByteArray
var floor_layer: TileMapLayer
var transition_layer: TileMapLayer
var actors: Node2D
var hero: CharacterBody2D
var camera: Camera2D
var sprites: Array[Sprite2D] = []
var tile_bucket = Vector2i(-999, -999)
var title_label: Label
var position_label: Label
var map_panel: PanelContainer
var map_marker: ColorRect
var map_texture: TextureRect
var collision_visible = false
var debug_overlay: Node2D
var population: Array = []
var boats: Array = []
var night = false
var tint: CanvasModulate
var speech: Label
var speech_time = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_data = JSON.parse_string(FileAccess.get_file_as_string("res://mapa/ciudad.json"))
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://catalogo.json"))
	base_bytes = FileAccess.get_file_as_bytes("res://mapa/base.bin")
	overlay_bytes = FileAccess.get_file_as_bytes("res://mapa/overlay.bin")
	collision_bytes = FileAccess.get_file_as_bytes("res://" + map_data.layers.collision)
	for asset in catalog.assets:
		assets[asset.id] = asset
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(512, 512)
	floor_layer = TileMapLayer.new()
	floor_layer.tile_set = tileset
	floor_layer.name = "Suelo"
	add_child(floor_layer)
	transition_layer = TileMapLayer.new()
	transition_layer.tile_set = tileset
	transition_layer.name = "Transiciones"
	add_child(transition_layer)
	var water_actors = Node2D.new()
	water_actors.name = "Barcas"
	add_child(water_actors)
	for boat in map_data.boats:
		var vessel = Resident.new()
		vessel.setup(boat, true, load("res://" + assets[boat.asset].file))
		water_actors.add_child(vessel)
		boats.append(vessel)
	var ground = Node2D.new()
	ground.name = "Puentes_y_suelo"
	add_child(ground)
	actors = Node2D.new()
	actors.name = "Edificios_y_personaje"
	actors.y_sort_enabled = true
	add_child(actors)
	var bridge_front = Node2D.new()
	bridge_front.name = "Barandas_delanteras"
	bridge_front.z_index = 1
	add_child(bridge_front)
	for object in map_data.objects:
		var asset = assets[object.id]
		var object_position = Vector2(object.x, object.y)
		var anchor = Vector2(asset.anchor[0], asset.anchor[1])
		if asset.has("foreground"):
			var front = Sprite2D.new()
			front.texture = load("res://" + asset.foreground)
			front.centered = false
			front.position = object_position - anchor
			bridge_front.add_child(front)
		var slice_width = int(asset.get("depth_slices", asset.width))
		for sx in range(0, int(asset.width), slice_width):
			var sprite = Sprite2D.new()
			sprite.name = object.id
			sprite.texture = load("res://" + asset.file)
			sprite.centered = false
			var sw = mini(slice_width, int(asset.width) - sx)
			var depth = 0.0
			if asset.has("baseline"):
				depth = -anchor.y + asset.baseline.intercept + asset.baseline.slope * (sx + sw / 2.0)
			sprite.region_enabled = true
			sprite.region_rect = Rect2(sx, 0, sw, asset.height)
			sprite.offset = Vector2(-anchor.x + sx, -anchor.y - depth)
			sprite.position = object_position + Vector2(0, depth)
			sprite.set_meta("asset_id", object.id)
			sprite.set_meta("object_position", object_position)
			if asset.ground:
				ground.add_child(sprite)
			else:
				actors.add_child(sprite)
				sprites.append(sprite)
	for person in map_data.residents:
		var resident = Resident.new()
		resident.setup(person, false, load("res://" + catalog.npcs.file))
		actors.add_child(resident)
		population.append(resident)
	hero = Hero.new()
	hero.name = "Elias"
	hero.setup(self)
	hero.position = Vector2(map_data.spawn[0], map_data.spawn[1])
	actors.add_child(hero)
	camera = Camera2D.new()
	camera.name = "Camara"
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_data.pixel_width)
	camera.limit_bottom = int(map_data.pixel_height)
	add_child(camera)
	camera.make_current()
	tint = CanvasModulate.new()
	add_child(tint)
	var atmosphere = Atmosphere.new()
	atmosphere.city = self
	add_child(atmosphere)
	_build_ui()
	debug_overlay = Node2D.new()
	debug_overlay.z_index = 4095
	debug_overlay.draw.connect(_draw_collision)
	add_child(debug_overlay)
	_update_world()
	if "--verify" in OS.get_cmdline_user_args():
		call_deferred("_verify")

func blocked(point: Vector2) -> bool:
	if point.x < 12 or point.x > map_data.pixel_width - 12 or point.y < 64 or point.y > map_data.pixel_height - 12:
		return true
	for offset in [Vector2.ZERO, Vector2(-7, -3), Vector2(7, -3), Vector2(-7, 3), Vector2(7, 3)]:
		var cell = Vector2i(floor((point.x + offset.x) / 8.0), floor((point.y + offset.y) / 8.0))
		if collision_bytes[cell.y * int(map_data.collision_width) + cell.x] == 1:
			return true
	return false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero):
		return
	var axis = Vector2.ZERO
	if not map_panel.visible:
		axis.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		axis.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	if not map_panel.visible:
		for person in population:
			person.step(delta)
		for boat in boats:
			boat.step(delta)
	speech_time -= delta
	speech.visible = speech_time > 0
	hero.step(axis, delta, Input.is_key_pressed(KEY_SHIFT))
	_update_world()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_M or event.keycode == KEY_ESCAPE:
			map_panel.visible = not map_panel.visible
		if event.keycode == KEY_E and not map_panel.visible:
			_interact()
		if event.keycode == KEY_N:
			night = not night
			tint.color = Color("9daed8") if night else Color.WHITE
		if event.keycode == KEY_C:
			collision_visible = not collision_visible
			debug_overlay.queue_redraw()

func _interact() -> void:
	var nearest = null
	var distance = 88.0
	for person in population:
		var d = hero.position.distance_to(person.position)
		if d < distance:
			distance = d
			nearest = person
	if nearest != null:
		nearest.wait = 4.0
		speech.text = nearest.data.name + "  —  " + nearest.data.line
	else:
		speech.text = "Acercate a un habitante y presioná E para conversar."
	speech_time = 6.5

func visit(id: String) -> bool:
	for point in map_data.pois:
		if point.id == id:
			var target = Vector2(point.x, point.y)
			if blocked(target):
				return false
			hero.position = target
			map_panel.hide()
			_update_world()
			return true
	return false

func _update_world() -> void:
	camera.position = Vector2(round(hero.position.x), round(hero.position.y - 64))
	var bucket = Vector2i(floor(hero.position.x / 512), floor(hero.position.y / 512))
	if bucket != tile_bucket:
		tile_bucket = bucket
		_stream_tiles(bucket)
	var view = Rect2(hero.position - Vector2(600, 760), Vector2(1200, 1000))
	for sprite in sprites:
		var asset = assets[sprite.get_meta("asset_id")]
		var object_position: Vector2 = sprite.get_meta("object_position")
		var rect = Rect2(object_position - Vector2(asset.anchor[0], asset.anchor[1]), Vector2(asset.width, asset.height))
		if view.intersects(rect):
			var hidden = hero.position.y < object_position.y - 8 and hero.position.y > object_position.y - asset.height + 16 and absf(hero.position.x - object_position.x) < asset.width * 0.42
			if asset.has("baseline"):
				var local_x = hero.position.x - rect.position.x
				var foot = rect.position.y + asset.baseline.intercept + asset.baseline.slope * local_x
				hidden = local_x >= 0 and local_x < asset.width and hero.position.y < foot - 8 and hero.position.y > foot - asset.wall_height
			sprite.modulate.a = 0.42 if hidden else 1.0
	var district = "Calles de Briar"
	for region in map_data.regions:
		var r = region.rect
		if Rect2(r[0], r[1], r[2], r[3]).has_point(hero.position):
			district = region.name
	title_label.text = "BRIAR  /  " + district
	position_label.text = "Sector %02d · %02d    WASD · Mayús correr · E conversar · M mapa · N atardecer" % [int(hero.position.x / 960) + 1, int(hero.position.y / 540) + 1]
	if map_panel.visible:
		map_marker.position = Vector2(hero.position.x / map_data.pixel_width * 438.0 - 3, hero.position.y / map_data.pixel_height * 444.0 - 3)
	if collision_visible:
		debug_overlay.queue_redraw()

func _stream_tiles(center: Vector2i) -> void:
	floor_layer.clear()
	var wanted = {}
	var tileset = floor_layer.tile_set
	var columns = ceili(float(map_data.pixel_width) / 512.0)
	var rows = ceili(float(map_data.pixel_height) / 512.0)
	for y in range(maxi(0, center.y - 2), mini(rows, center.y + 2)):
		for x in range(maxi(0, center.x - 2), mini(columns, center.x + 2)):
			var source_id = y * columns + x
			wanted[source_id] = true
			if not tileset.has_source(source_id):
				var source = TileSetAtlasSource.new()
				source.texture = load("res://terrenos/chunks/%d_%d.png" % [x, y])
				source.texture_region_size = Vector2i(512, 512)
				source.create_tile(Vector2i.ZERO)
				tileset.add_source(source, source_id)
			floor_layer.set_cell(Vector2i(x, y), source_id, Vector2i.ZERO)
	var remove = []
	for i in range(tileset.get_source_count()):
		var id = tileset.get_source_id(i)
		if not wanted.has(id): remove.append(id)
	for id in remove: tileset.remove_source(id)

func _draw_collision() -> void:
	if not collision_visible or not is_instance_valid(hero): return
	for y in range(maxi(0, int(hero.position.y / 8) - 48), mini(int(map_data.collision_height), int(hero.position.y / 8) + 40)):
		for x in range(maxi(0, int(hero.position.x / 8) - 64), mini(int(map_data.collision_width), int(hero.position.x / 8) + 64)):
			if collision_bytes[y * int(map_data.collision_width) + x]:
				debug_overlay.draw_rect(Rect2(x * 8, y * 8, 8, 8), Color(1, 0.2, 0.1, 0.4))

func _build_ui() -> void:
	var ui = CanvasLayer.new()
	add_child(ui)
	var top = ColorRect.new()
	top.color = Color(0.025, 0.07, 0.052, 0.88)
	top.size = Vector2(960, 44)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	title_label = Label.new()
	title_label.position = Vector2(16, 9)
	title_label.add_theme_color_override("font_color", Color("e7d9ad"))
	ui.add_child(title_label)
	var button = Button.new()
	button.text = "M  ·  Mapa y destinos"
	button.position = Vector2(770, 5)
	button.size = Vector2(178, 34)
	button.pressed.connect(func(): map_panel.visible = not map_panel.visible)
	ui.add_child(button)
	position_label = Label.new()
	position_label.position = Vector2(16, 514)
	position_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	position_label.add_theme_constant_override("shadow_offset_x", 2)
	position_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(position_label)
	speech = Label.new()
	speech.position = Vector2(20, 460)
	speech.size = Vector2(900, 46)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.add_theme_color_override("font_color", Color("fff0c6"))
	speech.add_theme_color_override("font_shadow_color", Color.BLACK)
	speech.add_theme_constant_override("shadow_offset_x", 2)
	speech.add_theme_constant_override("shadow_offset_y", 2)
	speech.hide()
	ui.add_child(speech)
	map_panel = PanelContainer.new()
	map_panel.position = Vector2(27, 19)
	map_panel.size = Vector2(906, 502)
	ui.add_child(map_panel)
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	map_panel.add_child(margin)
	var stack = VBoxContainer.new()
	margin.add_child(stack)
	var heading = Label.new()
	heading.text = "REINO DE BRIAR  ·  Viajar a un lugar para inspeccionar el mapa"
	stack.add_child(heading)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	stack.add_child(row)
	map_texture = TextureRect.new()
	map_texture.texture = load("res://previews/Briar_Plano_Sin_Rotulos.png")
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_SCALE
	map_texture.custom_minimum_size = Vector2(438, 444)
	row.add_child(map_texture)
	map_marker = ColorRect.new()
	map_marker.color = Color("fff2b1")
	map_marker.size = Vector2(6, 6)
	map_texture.add_child(map_marker)
	var grid = GridContainer.new()
	grid.columns = 2
	row.add_child(grid)
	for point in map_data.pois:
		var travel = Button.new()
		travel.text = point.name
		travel.custom_minimum_size = Vector2(164, 22)
		travel.add_theme_font_size_override("font_size", 10)
		travel.pressed.connect(visit.bind(point.id))
		grid.add_child(travel)
	map_panel.hide()

func _verify() -> void:
	var failures = []
	var visited = 0
	for point in map_data.pois:
		if visit(point.id): visited += 1
		else: failures.append("Blocked POI: " + point.id)
	var crossed = 0
	for bridge in map_data.bridges:
		var a = Vector2(bridge.a[0], bridge.a[1])
		var b = Vector2(bridge.b[0], bridge.b[1])
		hero.position = a
		var axis = (b - a).normalized()
		for i in range(ceili(a.distance_to(b) / 320.0 * 60.0)):
			hero.step(axis, 1.0 / 60.0, true)
		if hero.position.distance_to(b) < 8: crossed += 1
		else: failures.append("Bridge crossing: " + bridge.id)
	if not blocked(Vector2(map_data.river_path[150][0], map_data.river_path[150][1])): failures.append("River collision")
	if not blocked(Vector2(map_data.wall_polygon[0][0] + 320, map_data.wall_polygon[0][1])): failures.append("Wall collision")
	for gate in map_data.gates:
		if blocked(Vector2(gate.x, gate.y)): failures.append("Gate blocked: " + gate.id)
	var animation_checks = []
	var directions = [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]
	for d in range(4):
		var clear_origin = Vector2.ZERO
		for yy in range(1000, int(map_data.pixel_height) - 800, 64):
			if clear_origin != Vector2.ZERO: break
			for xx in range(1000, int(map_data.pixel_width) - 800, 64):
				var clear_area = true
				for dd in range(0, 353, 8):
					if blocked(Vector2(xx, yy) + directions[d] * dd):
						clear_area = false
						break
				if clear_area:
					clear_origin = Vector2(xx, yy)
					break
		if clear_origin == Vector2.ZERO:
			failures.append("Elias motion area " + str(d))
			continue
		for running in [false, true]:
			hero.position = clear_origin
			hero.phase = 0.0
			var seen_frames = {}
			for k in range(60):
				hero.step(directions[d], 1.0 / 60.0, running)
				seen_frames[hero.sprite.frame % hero.columns] = true
			var mode = "run" if running else "walk"
			var correct = seen_frames.size() == 8 and hero.animation == mode
			for frame in catalog.player.animations[mode].frames:
				if not seen_frames.has(int(frame)): correct = false
			hero.step(Vector2.ZERO, 1.0 / 60.0)
			correct = correct and hero.sprite.frame == d * hero.columns + hero.idle_frame
			animation_checks.append({"direction": d, "mode": mode, "frames": seen_frames.size(), "passed": correct})
			if not correct: failures.append("Elias " + mode + " direction " + str(d))
	if hero.sprite.texture.get_size() != Vector2(1088, 256): failures.append("Elias texture dimensions")
	var shifted = 0
	for person in population:
		var before = person.position
		for j in range(120): person.step(1.0 / 60.0)
		if person.position.distance_to(before) > 1: shifted += 1
	if shifted < population.size() * 0.8: failures.append("Resident motion")
	for point in [Vector2(16, 80), Vector2(map_data.pixel_width - 16, 80), Vector2(16, map_data.pixel_height - 16), Vector2(map_data.pixel_width - 16, map_data.pixel_height - 16)]:
		hero.position = point
		_update_world()
		var origin = Vector2(clampf(point.x - 480, 0, map_data.pixel_width - 960), clampf(point.y - 334, 0, map_data.pixel_height - 540))
		for offset in [Vector2.ZERO, Vector2(959, 0), Vector2(0, 539), Vector2(959, 539)]:
			var corner = Vector2i((origin + offset) / 512)
			if floor_layer.get_cell_source_id(corner) == -1: failures.append("Missing edge terrain")
	visit("mercado")
	camera.force_update_scroll()
	if camera.get_screen_center_position().distance_to(hero.position + Vector2(0, -64)) > 1: failures.append("Camera follow")
	var report = {"engine": Engine.get_version_info().string, "pois_visited": visited, "bridges_crossed": crossed, "player_animation": animation_checks, "residents": population.size(), "residents_moved": shifted, "terrain_cells_loaded": floor_layer.get_used_cells().size(), "failures": failures, "passed": failures.is_empty()}
	var output = FileAccess.open("res://docs/godot_validation.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  "))
	print("BRIAR_VERIFICATION " + JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
