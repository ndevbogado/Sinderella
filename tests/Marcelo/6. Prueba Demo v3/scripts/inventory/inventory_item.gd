@tool
@icon("res://assets/ui/briar_icon.svg")
class_name InventoryItem
extends Resource

## Recurso editable desde el Inspector. Cada .tres representa un objeto.

@export_category("Identidad")
@export var identificador: StringName = &"objeto"
@export var nombre := "Objeto"
@export_multiline var descripcion := "Descripción del objeto."

@export_category("Presentación")
@export var icono: Texture2D
@export var color_acento := Color(0.80, 0.61, 0.25, 1.0)

@export_category("Reglas")
@export var objeto_clave := false

