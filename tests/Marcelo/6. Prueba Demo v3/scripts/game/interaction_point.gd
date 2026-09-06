@tool
@icon("res://assets/ui/briar_icon.svg")
class_name InteractionPoint
extends Marker2D

## Punto editable de interacción. El círculo solo se dibuja dentro del editor.

@export var habilitado := true
@export var etiqueta := "Examinar"
@export_multiline var mensaje := "Escribí aquí el texto que verá el jugador."
@export_range(16.0, 500.0, 1.0) var radio := 100.0:
	set(value):
		radio = value
		queue_redraw()
@export var mostrar_radio_en_editor := true:
	set(value):
		mostrar_radio_en_editor = value
		queue_redraw()
@export var color_editor := Color(0.79, 0.61, 0.25, 0.18):
	set(value):
		color_editor = value
		queue_redraw()

@export_category("Objeto de inventario")
@export var recoger_al_interactuar := false:
	set(value):
		recoger_al_interactuar = value
		queue_redraw()
@export var objeto: InventoryItem
@export_multiline var mensaje_al_recoger := "Objeto añadido al inventario."

@export_category("Salida")
@export var es_salida := false

var _pulse_time := 0.0


func _ready() -> void:
	set_process(recoger_al_interactuar)
	queue_redraw()


func _process(delta: float) -> void:
	if not recoger_al_interactuar or not habilitado:
		return
	_pulse_time += delta
	queue_redraw()


func mark_collected() -> void:
	habilitado = false
	set_process(false)
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint() and mostrar_radio_en_editor:
		draw_circle(Vector2.ZERO, radio, color_editor)
		var outline := color_editor
		outline.a = 0.85
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 64, outline, 2.0)
		draw_circle(Vector2.ZERO, 5.0, Color(0.95, 0.76, 0.34, 0.95))
	elif recoger_al_interactuar and habilitado:
		var pulse := 0.72 + sin(_pulse_time * 3.2) * 0.18
		draw_circle(Vector2.ZERO, 7.0, Color(0.95, 0.72, 0.28, 0.18 * pulse))
		draw_circle(Vector2.ZERO, 2.2, Color(1.0, 0.87, 0.52, pulse))
