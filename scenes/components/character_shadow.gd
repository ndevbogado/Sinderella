@tool
class_name CharacterShadow
extends Node2D


@export var shadow_size: Vector2 = Vector2(100.0, 24.0)
@export_range(0.0, 1.0, 0.01) var shadow_opacity: float = 0.32
@export_range(12, 64, 1) var point_count: int = 40


func _ready() -> void:
	z_index = -1
	queue_redraw()


func _process(_delta: float) -> void:
	# Permite actualizar la sombra mientras trabajamos en el editor.
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	# Tres óvalos superpuestos para simular un borde suave.
	draw_shadow_layer(
		shadow_size * 1.22,
		shadow_opacity * 0.18
	)

	draw_shadow_layer(
		shadow_size,
		shadow_opacity * 0.45
	)

	draw_shadow_layer(
		shadow_size * 0.70,
		shadow_opacity
	)


func draw_shadow_layer(size: Vector2, opacity: float) -> void:
	var polygon := PackedVector2Array()

	for i in range(point_count):
		var angle: float = (
			TAU * float(i) / float(point_count)
		)

		polygon.append(
			Vector2(
				cos(angle) * size.x * 0.5,
				sin(angle) * size.y * 0.5
			)
		)

	draw_colored_polygon(
		polygon,
		Color(0.0, 0.0, 0.0, opacity)
	)
