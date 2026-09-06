@tool
@icon("res://assets/ui/briar_icon.svg")
class_name ComicSequence
extends Resource

## Lista visual de páginas que forman una cinemática.

@export_category("Identidad")
@export var titulo := "Nueva cinemática"
@export_range(0.0, 10.0, 0.05) var demora_inicial := 0.45

@export_category("Audio continuo")
@export var musica: AudioStream
@export var ambiente: AudioStream

@export_category("Páginas, en orden")
@export var paginas: Array[PackedScene] = []

@export_category("Destino al terminar")
@export_file("*.tscn") var escena_siguiente := "res://scenes/elias_room.tscn"
@export var texto_de_carga := "Entrando en casa…"

