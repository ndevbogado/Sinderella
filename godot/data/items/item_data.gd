## ItemData: la DEFINICIÓN de un tipo de ítem (no un ítem suelto en el mundo).
##
## Es un Resource personalizado. Cada ítem (poción, espada...) es un archivo
## .tres dentro de data/items/entries/ que se edita desde el Inspector.
## Los Resources son solo datos: no son nodos y no aparecen en el árbol de escena.
class_name ItemData
extends Resource

## Identificador único y estable (snake_case). Igual al nombre del .tres.
## Las partidas guardadas usan este ID, por eso no se renombra.
@export var id: StringName
## Nombre que se muestra en la interfaz.
@export var display_name: String = "Item"
## Texto largo para tooltips.
@export_multiline var description: String = ""
## Ícono del ítem (opcional).
@export var icon: Texture2D
## Si es true, varias unidades comparten un slot hasta llegar a max_stack.
@export var stackable: bool = true
## Máximo de unidades por slot cuando el ítem es apilable.
@export var max_stack: int = 99
