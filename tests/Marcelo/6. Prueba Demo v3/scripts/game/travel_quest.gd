@tool
@icon("res://assets/ui/briar_icon.svg")
class_name TravelQuest
extends Resource

## Todo el contenido narrativo y los objetos requeridos se editan en este recurso.

@export_category("Presentación")
@export var titulo := "Preparativos para el viaje"
@export_multiline var dialogo_al_llegar := (
	"Me iré de la capital por un tiempo. Antes de partir, tengo que prepararme. "
	+ "En casa debería encontrar todo lo necesario para el viaje."
)

@export_category("Objetivo")
@export var objetos_requeridos: Array[InventoryItem] = []
@export_multiline var mensaje_incompleto := (
	"Aún no estoy listo. Debo reunir todo lo necesario antes de abandonar la capital."
)
@export_multiline var mensaje_completado := (
	"Capa, mapa, agua y provisiones. Ya estoy listo para dejar la capital."
)

