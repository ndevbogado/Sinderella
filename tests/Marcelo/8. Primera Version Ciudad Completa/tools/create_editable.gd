extends SceneTree
## One-time migration; normal editing never runs this script.
var m: Dictionary
var c: Dictionary
var assets: Dictionary = {}
var scene: Node2D
var placed: Array[Node2D] = []
func _initialize() -> void: call_deferred("build")
func add(parent: Node, node: Node, own: Node) -> Node:
	parent.add_child(node)
	node.owner = own
	return node
func folder(parent: Node,label: String,sorted: bool=false) -> Node2D:
	var node := Node2D.new()
	node.name = label
	node.y_sort_enabled = sorted
	add(parent,node,scene)
	return node
func collision(parent: Node2D,rects: Array,mask: int,own: Node,passage: bool=false) -> void:
	if rects.is_empty(): return
	var body: CollisionObject2D = Area2D.new() if passage else StaticBody2D.new()
	body.name = "Paso_sobre_agua" if passage else "Colision"
	body.collision_layer = mask
	body.collision_mask = 0
	if passage:
		body.monitoring = false
		body.monitorable = true
	add(parent,body,own)
	for i in rects.size():
		var r: Array = rects[i]
		var poly := CollisionPolygon2D.new()
		poly.name = "Forma_%03d"%i
		poly.visible = false
		poly.polygon = PackedVector2Array([Vector2(r[0],r[1]),Vector2(r[0]+r[2],r[1]),Vector2(r[0]+r[2],r[1]+r[3]),Vector2(r[0],r[1]+r[3])])
		add(body,poly,own)
func piece(a: Dictionary,obj: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.name = str(a.id)
	node.set_meta("_edit_group_",true)
	node.set_meta("asset_id",str(a.id))
	node.set_meta("nombre",str(a.label))
	node.add_to_group("briar_objeto",true)
	var anchor := Vector2(a.anchor[0],a.anchor[1])
	var sw := int(a.get("depth_slices",a.width))
	node.y_sort_enabled = a.has("depth_slices")
	for x in range(0,int(a.width),sw):
		var sprite := Sprite2D.new()
		sprite.name = "Aspecto" if x==0 else "Profundidad_%03d"%x
		sprite.texture = load("res://"+str(a.file))
		sprite.centered = false
		sprite.region_enabled = true
		var width := mini(sw,int(a.width)-x)
		sprite.region_rect = Rect2(x,0,width,a.height)
		var depth := 0.0
		if a.has("baseline"): depth = -anchor.y+float(a.baseline.intercept)+float(a.baseline.slope)*(x+width/2.0)
		sprite.position = Vector2(0,depth)
		sprite.offset = Vector2(x-anchor.x,-anchor.y-depth)
		add(node,sprite,node)
	if a.has("foreground"):
		var front := Sprite2D.new()
		front.name = "Baranda_delantera"
		front.texture = load("res://"+str(a.foreground))
		front.centered = false
		front.offset = -anchor
		front.z_index = 2
		add(node,front,node)
	collision(node,obj.get("editable_collision_rects",a.get("editable_collision_rects",[])),1,node)
	collision(node,obj.get("editable_passage_rects",a.get("editable_passage_rects",[])),4,node,true)
	return node
func own_children(node: Node,own: Node) -> void:
	for child in node.get_children():
		child.owner = own
		own_children(child,own)
func save_scene(node: Node,path: String) -> void:
	var packed := PackedScene.new()
	assert(packed.pack(node)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
func atlas(set: TileSet,path: String,label: String,id: int,tile_size: int,passage: int=0) -> void:
	var source := TileSetAtlasSource.new()
	source.resource_name = label
	source.texture = load(path)
	source.texture_region_size = Vector2i(tile_size,tile_size)
	set.add_source(source,id)
	var size: Vector2i = source.texture.get_size()/tile_size
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x,y)
			source.create_tile(cell)
			if set.get_custom_data_layers_count()>0: source.get_tile_data(cell,0).set_custom_data("paso",passage)
func build() -> void:
	if FileAccess.file_exists("res://godot/recursos/suelos_fc.tres") and not "--overwrite-editable" in OS.get_cmdline_user_args():
		push_error("La escena editable existe. No ejecutes la migracion sobre tus cambios manuales.")
		quit(2)
		return
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://godot/migracion/conversion.json"))
	m = input.map
	c = input.catalog
	for a in c.assets: assets[a.id] = a
	for dir in ["res://godot/recursos","res://godot/piezas"]: DirAccess.make_dir_recursive_absolute(dir)
	scene = Node2D.new()
	scene.name = "Briar"
	scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.set_script(load("res://godot/mundo_editable.gd"))
	var terrain := folder(scene,"Terreno")
	terrain.z_index = -10
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(32,32)
	var columns := ceili(float(m.pixel_width)/512.0)
	var rows := ceili(float(m.pixel_height)/512.0)
	for y in rows:
		for x in columns: atlas(tileset,"res://terrenos/chunks/%d_%d.png"%[x,y],"F.C %02d-%02d"%[x,y],y*columns+x,32)
	assert(ResourceSaver.save(tileset,"res://godot/recursos/suelos_fc.tres")==OK)
	var floor_node := TileMapLayer.new()
	floor_node.name = "Suelo_FC_32px"
	floor_node.tile_set = tileset
	floor_node.navigation_enabled = false
	add(terrain,floor_node,scene)
	for y in ceili(float(m.pixel_height)/32.0):
		for x in ceili(float(m.pixel_width)/32.0): floor_node.set_cell(Vector2i(x,y),int(y/16)*columns+int(x/16),Vector2i(x%16,y%16))
	print("Editable floor: ",floor_node.get_used_cells().size())
	var brushset := TileSet.new()
	brushset.tile_size = Vector2i(32,32)
	brushset.add_custom_data_layer()
	brushset.set_custom_data_layer_name(0,"paso")
	brushset.set_custom_data_layer_type(0,TYPE_INT)
	for mat in c.materials: atlas(brushset,"res://"+str(mat.field),str(mat.name),int(mat.id),32,1)
	for i in c.terrain_revision.water.size(): atlas(brushset,"res://"+str(c.terrain_revision.water[i]),["Rio profundo","Rio medio","Rio somero","Sedimento"][i],100+i,32,-1 if i<3 else 1)
	assert(ResourceSaver.save(brushset,"res://godot/recursos/paleta_suelos.tres")==OK)
	var paint := TileMapLayer.new()
	paint.name = "Pintar_suelos_32px"
	paint.tile_set = brushset
	paint.navigation_enabled = false
	add(terrain,paint,scene)
	var details := TileMapLayer.new()
	details.name = "Bordes_y_detalles_32px"
	var borders := TileSet.new()
	borders.tile_size = Vector2i(32,32)
	var n := 0
	for item in c.transitions+c.diagonal_transitions:
		atlas(borders,"res://"+str(item.file),str(item.family)+" "+str(n),n,32)
		n += 1
	assert(ResourceSaver.save(borders,"res://godot/recursos/bordes.tres")==OK)
	details.tile_set = borders
	details.navigation_enabled = false
	add(terrain,details,scene)
	var water_set := TileSet.new()
	water_set.tile_size = Vector2i(8,8)
	water_set.add_physics_layer()
	water_set.set_physics_layer_collision_layer(0,2)
	water_set.set_physics_layer_collision_mask(0,0)
	var source := TileSetAtlasSource.new()
	var texture := GradientTexture2D.new()
	texture.width = 8
	texture.height = 8
	texture.gradient = Gradient.new()
	texture.gradient.colors = PackedColorArray([Color(1,0.25,0.15,0.55),Color(1,0.25,0.15,0.55)])
	source.texture = texture
	source.texture_region_size = Vector2i(8,8)
	water_set.add_source(source,0)
	source.create_tile(Vector2i.ZERO)
	var td := source.get_tile_data(Vector2i.ZERO,0)
	td.set_collision_polygons_count(0,1)
	td.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-4,-4),Vector2(4,-4),Vector2(4,4),Vector2(-4,4)]))
	assert(ResourceSaver.save(water_set,"res://godot/recursos/colision_rio.tres")==OK)
	var water_node := TileMapLayer.new()
	water_node.name = "Colision_rio_8px"
	water_node.tile_set = water_set
	water_node.visible = false
	water_node.z_index = 20
	water_node.navigation_enabled = false
	add(terrain,water_node,scene)
	var mask := FileAccess.get_file_as_bytes("res://godot/migracion/agua8.bin")
	for y in int(m.collision_height):
		for x in int(m.collision_width):
			if mask[y*int(m.collision_width)+x]: water_node.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	var ground := folder(scene,"Suelo_decorado")
	ground.z_index = -2
	var bridges := folder(scene,"Puentes_y_muelles")
	bridges.z_index = -1
	var bridge_nodes := {}
	for bridge in m.bridges:
		var node := folder(bridges,str(bridge.id))
		node.position = Vector2(bridge.a[0],bridge.a[1])
		node.set_meta("nombre",bridge.name)
		node.set_meta("_edit_group_",true)
		bridge_nodes[bridge.id] = node
	var actors := folder(scene,"Actores",true)
	var categories := {}
	for name in ["Monumentos","Edificios","Vegetacion","Murallas","Decoracion"]: categories[name] = folder(actors,name,true)
	for a in c.assets:
		var prefab := piece(a,{})
		save_scene(prefab,"res://godot/piezas/"+str(a.id)+".tscn")
		prefab.free()
	for o in m.objects:
		var a: Dictionary = assets[o.id]
		var node := piece(a,o)
		node.name = "%s_%04d"%[o.id,placed.size()+1]
		node.position = Vector2(o.x,o.y)
		node.set_meta("migration_id",int(o.migration_id))
		node.set_meta("tipo",str(o.kind))
		var parent: Node2D
		if o.has("bridge_id"):
			parent = bridge_nodes[o.bridge_id]
			node.position -= parent.position
		elif o.kind=="dock": parent = bridges
		elif a.ground: parent = ground
		else:
			var cat: String = "Monumentos" if o.kind=="landmark" else "Edificios" if o.kind=="building" else "Vegetacion" if o.kind=="outside" else "Murallas" if o.kind in ["wall","gate","watergate"] else "Decoracion"
			parent = categories[cat]
		add(parent,node,scene)
		own_children(node,scene)
		placed.append(node)
	print("Persistent objects: ",placed.size())
	var people := folder(actors,"Habitantes",true)
	var boats := folder(scene,"Barcas")
	boats.z_index = -3
	for item in m.residents: resident(item,people,false)
	for item in m.boats: resident(item,boats,true)
	var hero := CharacterBody2D.new()
	hero.name = "Elias"
	hero.collision_layer = 0
	hero.collision_mask = 0
	hero.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	hero.position = Vector2(m.spawn[0],m.spawn[1])
	hero.set_script(load("res://godot/elias_editable.gd"))
	hero.set_meta("_edit_group_",true)
	add(actors,hero,scene)
	var feet := CollisionShape2D.new()
	feet.name = "Pies"
	feet.shape = RectangleShape2D.new()
	feet.shape.size = Vector2(14,6)
	feet.visible = false
	add(hero,feet,scene)
	var sprite := Sprite2D.new()
	sprite.name = "Aspecto"
	sprite.texture = load("res://"+str(c.player.file))
	sprite.hframes = 17
	sprite.vframes = 4
	sprite.frame = 16
	sprite.position = Vector2(0,-32)
	add(hero,sprite,scene)
	var camera := Camera2D.new()
	camera.name = "Camara"
	camera.position = Vector2(0,-64)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(m.pixel_width)
	camera.limit_bottom = int(m.pixel_height)
	add(hero,camera,scene)
	var destinations := folder(scene,"Destinos")
	for p in m.pois:
		var marker := Marker2D.new()
		marker.name = str(p.id)
		marker.position = Vector2(p.x,p.y)
		marker.set_meta("id",p.id)
		marker.set_meta("nombre",p.name)
		marker.set_meta("descripcion",p.description)
		marker.add_to_group("briar_destino",true)
		add(destinations,marker,scene)
	var zones := folder(scene,"Zonas")
	for region in m.regions:
		var node := Marker2D.new()
		node.name = str(region.id)
		node.position = Vector2(region.rect[0],region.rect[1])
		node.set_meta("nombre",region.name)
		node.set_meta("rect",Rect2(0,0,region.rect[2],region.rect[3]))
		add(zones,node,scene)
	for effect in m.effects:
		var closest: Node2D = null
		var best := INF
		var at := Vector2(effect.x,effect.y)
		for node in placed:
			var id: String = node.get_meta("asset_id")
			if (effect.type=="lamp" and id!="farola") or (effect.type=="fountain" and id!="fuente") or (effect.type=="smoke" and not "herreria" in id): continue
			var distance := node.position.distance_to(at)
			if distance<best:
				closest = node
				best = distance
		if closest!=null:
			var marker := Marker2D.new()
			marker.name = "Efecto_"+str(effect.type)
			marker.position = at-closest.position
			marker.set_meta("tipo",effect.type)
			marker.add_to_group("briar_efecto",true)
			add(closest,marker,scene)
	var light := CanvasModulate.new()
	light.name = "Luz"
	add(scene,light,scene)
	var atmosphere := Node2D.new()
	atmosphere.name = "Ambiente"
	atmosphere.set_script(load("res://godot/ambiente_editable.gd"))
	add(scene,atmosphere,scene)
	save_scene(scene,"res://godot/ciudad.tscn")
	print("EDITABLE_SCENE_SAVED")
	scene.free()
	quit()
func resident(item: Dictionary,parent: Node2D,boat: bool) -> void:
	var node := Node2D.new()
	node.name = ("Barca_" if boat else "Vecino_")+str(item.id).pad_zeros(3)
	node.set_script(load("res://godot/vecino_editable.gd"))
	node.set_meta("_edit_group_",true)
	node.add_to_group("briar_vecino",true)
	node.nombre = str(item.get("name","Barca"))
	node.dialogo = str(item.get("line",""))
	node.oficio = int(item.get("role",0))
	node.velocidad = float(item.speed)
	node.pausa = float(item.get("pause",0.4))
	node.punto_inicial = int(item.get("start_index",0))
	node.es_barca = boat
	var pos: Array = item.route[node.punto_inicial]
	node.position = Vector2(pos[0],pos[1])
	add(parent,node,scene)
	var sprite := Sprite2D.new()
	sprite.name = "Aspecto"
	sprite.texture = load("res://"+str(assets[item.asset].file if boat else c.npcs.file))
	if boat: sprite.position.y = -sprite.texture.get_height()*0.1
	else:
		sprite.hframes = 8
		sprite.vframes = 6
		sprite.frame = int(item.role)*8
		sprite.position.y = -32
	add(node,sprite,scene)
	var path := Path2D.new()
	path.name = "Ruta"
	path.visible = false
	path.curve = Curve2D.new()
	path.curve.resource_local_to_scene = true
	for p in item.route: path.curve.add_point(Vector2(p[0],p[1])-node.position)
	add(node,path,scene)
