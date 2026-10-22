extends Node2D
var city: Node2D
var clock: float = 0.0
func _process(delta: float) -> void:
	if is_instance_valid(city):
		clock += minf(delta,0.1)
		queue_redraw()
func _draw() -> void:
	if not is_instance_valid(city): return
	var p: Vector2 = city.hero.global_position
	for effect in get_tree().get_nodes_in_group("briar_efecto"):
		var at: Vector2 = to_local(effect.global_position)
		if absf(at.x-p.x)>650 or absf(at.y-p.y)>600: continue
		match effect.get_meta("tipo",""):
			"smoke":
				for k in 4:
					var age: float = fmod(clock*15+k*18+fmod(at.x,37),82)
					var offset: Vector2 = Vector2(round(sin(age*0.07+at.x)*5+age*0.07),-round(age))
					draw_rect(Rect2(at+offset,Vector2(5,5)),Color(0.87,0.87,0.79,0.28*(1-age/82)))
			"fountain":
				for k in 3: draw_rect(Rect2(at+Vector2(-17+k*16,round(sin(clock*5+k)*2)),Vector2(5,2)),Color("b5f3e3"))
			"lamp":
				if city.night:
					for r in [38,28,18,8]: draw_circle(at,r,Color(1,0.79,0.45,0.035))
					draw_rect(Rect2(at,Vector2(3,3)),Color("fff0a7"))
