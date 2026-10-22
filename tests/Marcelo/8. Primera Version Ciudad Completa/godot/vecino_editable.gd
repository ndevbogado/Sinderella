extends Node2D
@export var nombre: String = "Habitante"
@export_multiline var dialogo: String = ""
@export_range(0,5) var oficio: int = 0
@export var velocidad: float = 40.0
@export var pausa: float = 1.5
@export var punto_inicial: int = 0
@export var es_barca: bool = false
var route: PackedVector2Array
var index: int = 0
var direction_step: int = 1
var wait: float = 0.0
var phase: float = 0.0
var sprite: Sprite2D
var world: Node2D
func initialize(city: Node2D) -> void:
	world = city
	sprite = $Aspecto
	var path: Path2D = $Ruta
	for i in path.curve.point_count: route.append(path.to_global(path.curve.get_point_position(i)))
	index = clampi(punto_inicial,0,maxi(0,route.size()-1))
	direction_step = -1 if index==route.size()-1 else 1
	wait = float(get_index()%7)*0.12
	phase = get_index()*0.21
func step(delta: float) -> void:
	if route.size()<2: return
	if wait>0:
		wait -= delta
		return
	var target: int = index+direction_step
	if target<0 or target>=route.size():
		direction_step *= -1
		wait = 0.4 if es_barca else pausa
		return
	var difference: Vector2 = route[target]-global_position
	var next: Vector2 = global_position.move_toward(route[target],velocidad*delta)
	if not es_barca and world.blocked(next,false):
		direction_step *= -1
		wait = pausa
		return
	global_position = next
	if global_position.distance_to(route[target])<0.01: index = target
	var direction: int = (1 if difference.x<0 else 2) if absf(difference.x)>absf(difference.y) else (3 if difference.y<0 else 0)
	phase += delta
	if not es_barca: sprite.frame = oficio*8+direction*2+int(phase*6)%2
