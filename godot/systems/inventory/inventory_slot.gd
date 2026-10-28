## InventorySlot: una celda del inventario.
## Un slot vacío tiene item == null y quantity == 0.
class_name InventorySlot
extends Resource

## Tipo de ítem guardado en este slot (null = vacío).
@export var item: ItemData
## Cantidad de unidades almacenadas.
@export var quantity: int = 0

## Devuelve true si el slot no contiene nada.
func is_empty() -> bool:
	return item == null
