@tool
@icon("res://assets/ui/briar_icon.svg")
class_name VisualComicPanel
extends Control

## Panel visual de una página de cómic.
## El rectángulo, la imagen y el marco se editan directamente en el editor 2D.

enum Entrance {
	DESVANECER_Y_ESCALAR,
	IZQUIERDA,
	DERECHA,
	ARRIBA,
	ABAJO,
	ARRIBA_IZQUIERDA,
	ABAJO_DERECHA,
	CORTE_IZQUIERDA,
	CORTE_DERECHA,
}

@export_category("Animación de entrada")
@export_enum(
	"Desvanecer y escalar",
	"Izquierda",
	"Derecha",
	"Arriba",
	"Abajo",
	"Arriba izquierda",
	"Abajo derecha",
	"Corte izquierda",
	"Corte derecha"
) var entrada: int = Entrance.DESVANECER_Y_ESCALAR
@export_range(0.0, 5.0, 0.01) var demora := 0.0
@export_range(0.05, 5.0, 0.01) var duracion := 0.62

@export_category("Movimiento dentro del panel")
@export_range(0.5, 2.0, 0.01) var zoom_inicial := 1.0
@export_range(0.5, 2.0, 0.01) var zoom_final := 1.0
@export var paneo_inicial := Vector2.ZERO
@export var paneo_final := Vector2.ZERO

@export_category("Notas para edición")
@export_multiline var notas := "Seleccioná este nodo y movelo o redimensionalo con las manijas del editor 2D."

@onready var _image: TextureRect = get_node_or_null("Image") as TextureRect
@onready var _frame: Control = get_node_or_null("Frame") as Control

var _base_image_position := Vector2.ZERO
var _base_image_scale := Vector2.ONE
var _motion_tween: Tween


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _image != null:
		_base_image_position = _image.position
		_base_image_scale = _image.scale
		_image.pivot_offset = _image.size * 0.5


func start_internal_motion(total_time: float) -> void:
	if Engine.is_editor_hint() or _image == null or Settings.reduce_motion:
		return
	if is_instance_valid(_motion_tween):
		_motion_tween.kill()
	_image.pivot_offset = _image.size * 0.5
	_image.position = _base_image_position + paneo_inicial
	_image.scale = _base_image_scale * zoom_inicial
	if (
		is_equal_approx(zoom_inicial, zoom_final)
		and paneo_inicial.is_equal_approx(paneo_final)
	):
		return
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(
		_image, "position", _base_image_position + paneo_final, maxf(total_time, 0.1)
	)
	_motion_tween.tween_property(
		_image, "scale", _base_image_scale * zoom_final, maxf(total_time, 0.1)
	)


func set_border_opacity(value: float) -> void:
	if _frame != null:
		_frame.modulate.a = value
