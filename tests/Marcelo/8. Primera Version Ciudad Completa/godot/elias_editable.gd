extends CharacterBody2D
@export var velocidad_caminar: float = 160.0
@export var velocidad_correr: float = 320.0
var world: Node2D
@onready var sprite: Sprite2D = $Aspecto
var direction: int = 0
var phase: float = 0.0
var moving: bool = false
var animation: String = "idle"
const columns: int = 17
const idle_frame: int = 16
func step(axis: Vector2, delta: float, running: bool = false) -> void:
	axis = axis.normalized()
	var old: Vector2 = global_position
	var speed: float = velocidad_correr if running else velocidad_caminar
	var distance: float = speed*minf(delta,0.1)
	var parts: int = maxi(1,ceili(distance/4.0))
	var unit: Vector2 = axis*distance/parts
	for i in parts:
		if not world.blocked(global_position+Vector2(unit.x,0)): global_position.x += unit.x
		if not world.blocked(global_position+Vector2(0,unit.y)): global_position.y += unit.y
	moving = global_position.distance_to(old)>0.01
	velocity = axis*speed if moving else Vector2.ZERO
	if axis!=Vector2.ZERO: direction = (1 if axis.x<0 else 2) if absf(axis.x)>absf(axis.y) else (3 if axis.y<0 else 0)
	if moving:
		animation = "run" if running else "walk"
		phase = fmod(phase+global_position.distance_to(old)/speed*(16.0 if running else 12.0)/8.0,1.0)
		sprite.frame = direction*17+(8 if running else 0)+int(phase*8)%8
	else:
		phase = 0.0
		animation = "idle"
		sprite.frame = direction*17+16
