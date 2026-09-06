class_name AtmosphereOverlay
extends Control

var mode := "none"
var intensity := 1.0
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 73451
	set_process(true)


func set_atmosphere(new_mode: String, new_intensity := 1.0) -> void:
	mode = new_mode
	intensity = new_intensity
	_rebuild_particles()
	queue_redraw()


func _rebuild_particles() -> void:
	_particles.clear()
	var count := 0
	match mode:
		"rain":
			count = 78
		"ash":
			count = 58
		"mist":
			count = 18
		"mist_ash":
			count = 48
		_:
			count = 0
	for index in count:
		_particles.append(
			{
				"position":
				Vector2(
					_rng.randf_range(0.0, maxf(size.x, 1280.0)),
					_rng.randf_range(0.0, maxf(size.y, 720.0))
				),
				"speed": _rng.randf_range(14.0, 52.0),
				"drift": _rng.randf_range(-14.0, 14.0),
				"radius": _rng.randf_range(1.0, 4.0),
				"phase": _rng.randf_range(0.0, TAU),
				"alpha": _rng.randf_range(0.08, 0.35)
			}
		)


func _process(delta: float) -> void:
	if mode == "none" or get_tree().paused:
		return
	var bounds := size
	for particle in _particles:
		var p: Vector2 = particle["position"]
		var speed: float = particle["speed"]
		match mode:
			"rain":
				p += Vector2(-speed * 0.22, speed * 3.4) * delta * intensity
			"mist":
				p.x += speed * 0.22 * delta * intensity
			"ash", "mist_ash":
				p += Vector2(particle["drift"], -speed * 0.34) * delta * intensity
				p.x += sin(Time.get_ticks_msec() * 0.0015 + float(particle["phase"])) * 7.0 * delta
		if p.x < -80.0:
			p.x = bounds.x + 60.0
		if p.x > bounds.x + 80.0:
			p.x = -60.0
		if p.y < -80.0:
			p.y = bounds.y + 60.0
		if p.y > bounds.y + 80.0:
			p.y = -60.0
		particle["position"] = p
	queue_redraw()


func _draw() -> void:
	for particle in _particles:
		var p: Vector2 = particle["position"]
		var alpha := float(particle["alpha"]) * intensity
		match mode:
			"rain":
				draw_line(p, p + Vector2(-4.0, 20.0), Color(0.68, 0.78, 0.9, alpha), 1.2)
			"mist":
				draw_circle(
					p, float(particle["radius"]) * 20.0, Color(0.65, 0.72, 0.82, alpha * 0.12)
				)
			"ash", "mist_ash":
				draw_circle(p, float(particle["radius"]), Color(0.86, 0.87, 0.88, alpha))
