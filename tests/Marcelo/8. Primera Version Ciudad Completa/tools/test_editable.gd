extends SceneTree
## Checks a temporary instance; never saves over the user's scene.
var errors: Array[String] = []
var report: Dictionary = {}
var city: Node2D
func _initialize() -> void: call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		push_error(message)
func settle() -> void:
	await physics_frame
	await physics_frame
func traverse(start: Vector2, finish: Vector2) -> bool:
	city.hero.global_position = start
	for i in 1800:
		var offset: Vector2 = finish-city.hero.global_position
		if offset.length()<4: return true
		city.hero.step(offset,1.0/60.0,true)
	return false
func run() -> void:
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mapa/ciudad.json"))
	var packed: PackedScene = load("res://godot/ciudad.tscn")
	city = packed.instantiate()
	report["saved_nodes"] = city.find_children("*","",true,false).size()+1
	root.add_child(city)
	city.set_physics_process(false)
	city.get_node("Ambiente").set_process(false)
	await settle()
	report["objects"] = get_nodes_in_group("briar_objeto").size()
	report["floor_tiles"] = city.floor_layer.get_used_cells().size()
	report["residents"] = city.population.size()
	report["boats"] = city.boats.size()
	check(report.objects==1766,"Object count changed")
	check(report.floor_tiles==91200,"Original terrain missing cells")
	check(report.residents==388 and report.boats==7,"Population count changed")
	var visits: int = 0
	for marker in city.pois:
		if city.visit(str(marker.get_meta("id"))): visits += 1
		else: check(false,"Blocked destination: "+marker.name)
	report["destinations_accessible"] = visits
	var crossings: int = 0
	for bridge in original.bridges:
		var a := Vector2(bridge.a[0],bridge.a[1])
		var b := Vector2(bridge.b[0],bridge.b[1])
		var direction := a.direction_to(b)
		for endpoints in [[a-direction*24,b+direction*24],[b+direction*24,a-direction*24]]:
			if traverse(endpoints[0],endpoints[1]): crossings += 1
			else: check(false,"Bridge crossing failed: "+str(bridge.id))
	report["bridge_crossings"] = crossings
	var gates: int = 0
	for gate in original.gates:
		var center := Vector2(gate.x,gate.y)
		var axis := Vector2.DOWN if gate.id in ["norte","sur"] else Vector2.RIGHT
		for sign_value in [-1,1]:
			if traverse(center-axis*112*sign_value,center+axis*112*sign_value): gates += 1
			else: check(false,"Gate crossing failed: "+str(gate.id))
	report["gate_crossings"] = gates
	var raster := FileAccess.get_file_as_bytes("res://mapa/colision8.bin")
	var samples: int = 0
	var differences: int = 0
	for y in range(84,9701,40):
		for x in range(20,9581,40):
			var expected: bool = raster[(y/8)*int(original.collision_width)+(x/8)]!=0
			if city.blocked(Vector2(x,y),false)!=expected: differences += 1
			samples += 1
	report["collision_samples"] = samples
	report["collision_differences"] = differences
	check(differences==0,"Native collisions differ from the original raster at %d sampled cell centers"%differences)
	var building: Node2D = city.get_node("Actores/Edificios").get_child(0)
	var poly: CollisionPolygon2D = building.get_node("Colision").get_child(0)
	var point: Vector2 = poly.to_global((poly.polygon[0]+poly.polygon[2])/2)
	check(city._hits(point,1),"Building must initially collide")
	building.position.x += 20000
	await settle()
	check(not city._hits(point,1),"Moving a building left its old collision behind")
	check(city._hits(point+Vector2(20000,0),1),"Moving a building lost its collision")
	var duplicate: Node2D = building.duplicate()
	building.get_parent().add_child(duplicate)
	duplicate.position.x += 2000
	await settle()
	check(city._hits(point+Vector2(22000,0),1),"Duplicated building lost its collision")
	duplicate.queue_free()
	await settle()
	check(not city._hits(point+Vector2(22000,0),1),"Deleted building left a collision behind")
	report["move_duplicate_delete_collision"] = true
	var water_point := Vector2.ZERO
	for cell in city.water_layer.get_used_cells():
		var p: Vector2 = city.water_layer.to_global(city.water_layer.map_to_local(cell))
		if p.x>100 and p.y>100 and not city._hits(p,1) and not city._hits(p,4,true):
			water_point = p
			break
	check(water_point!=Vector2.ZERO,"No water sample found")
	var paint_cell: Vector2i = city.paint_layer.local_to_map(city.paint_layer.to_local(water_point))
	check(city.blocked(water_point,false),"Original water must block passage")
	city.paint_layer.set_cell(paint_cell,3,Vector2i.ZERO)
	check(not city.blocked(water_point,false),"Painting dry ground must allow passage")
	city.paint_layer.set_cell(paint_cell,100,Vector2i.ZERO)
	check(city.blocked(water_point,false),"Painting water must block passage")
	city.paint_layer.erase_cell(paint_cell)
	check(city.blocked(water_point,false),"Erasing paint must restore original water collision")
	city.paint_layer.set_cell(paint_cell,3,Vector2i.ZERO)
	report["terrain_paint_updates_passage"] = true
	var hero_start := Vector2(original.spawn[0],original.spawn[1])
	var animation_cycles: int = 0
	for running in [false,true]:
		for direction in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP]:
			var frames: Dictionary = {}
			city.hero.phase = 0
			for i in 90:
				city.hero.global_position = hero_start
				city.hero.step(direction,1.0/60.0,running)
				frames[int(city.hero.sprite.frame)%17] = true
			check(frames.size()==8,"Missing walk/run animation poses")
			if frames.size()==8: animation_cycles += 1
	city.hero.step(Vector2.ZERO,1.0/60.0)
	check(int(city.hero.sprite.frame)%17==16,"Missing idle pose")
	report["animation_cycles_with_eight_poses"] = animation_cycles
	city.hero.position = hero_start+Vector2(8,0)
	var new_start: Vector2 = city.hero.position
	var moved_position: Vector2 = building.position
	var building_path: NodePath = city.get_path_to(building)
	var roundtrip := PackedScene.new()
	check(roundtrip.pack(city)==OK,"Cannot pack edited scene")
	var temporary := "user://briar_test_editable_roundtrip.tscn"
	check(ResourceSaver.save(roundtrip,temporary)==OK,"Cannot save edited scene")
	city.free()
	await settle()
	city = (ResourceLoader.load(temporary,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	root.add_child(city)
	city.set_physics_process(false)
	await settle()
	check(city.hero.position==new_start,"Runtime replaced the edited spawn")
	check(city.get_node(building_path).position==moved_position,"Edited building position was not preserved")
	check(city.paint_layer.get_cell_source_id(paint_cell)==3,"Painted cells were not preserved")
	check(not city.blocked(water_point,false),"Reloaded dry ground lost its passage data")
	report["saved_edits_survive_reload_and_start"] = true
	city.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	report["engine"] = Engine.get_version_info().string
	report["checked_at_utc"] = Time.get_datetime_string_from_system(true)
	report["errors"] = errors
	report["passed"] = errors.is_empty()
	report["scope"] = "Original F.C migration; temporary edits only. No user scene overwritten."
	var file := FileAccess.open("res://docs/validacion_edicion_visual.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)
