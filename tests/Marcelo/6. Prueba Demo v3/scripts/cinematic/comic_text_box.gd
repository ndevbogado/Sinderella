@tool
@icon("res://assets/ui/briar_icon.svg")
class_name ComicTextBox
extends Panel

## Globo o cartela reutilizable. El rectángulo se edita en 2D y el contenido en el Inspector.

@export_multiline var texto := "Texto editable":
	set(value):
		texto = value
		_sync_label()
@export_range(8, 72, 1) var tamano_de_letra := 18:
	set(value):
		tamano_de_letra = value
		_sync_label()
@export var color_de_texto := Color(0.08, 0.09, 0.12, 1.0):
	set(value):
		color_de_texto = value
		_sync_label()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_label()


func _sync_label() -> void:
	var label := get_node_or_null("Margin/Text") as Label
	if label == null:
		return
	label.text = texto
	label.add_theme_font_size_override("font_size", tamano_de_letra)
	label.add_theme_color_override("font_color", color_de_texto)

