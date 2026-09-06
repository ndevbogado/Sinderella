class_name InventoryStore
extends Node

signal changed
signal item_added(item: InventoryItem)

## El autoload conserva el inventario cuando se cambia de escena.

@export_range(1, 32, 1) var capacidad := 8

var _items: Array[InventoryItem] = []


func add_item(item: InventoryItem) -> bool:
	if item == null or has_item(item) or _items.size() >= capacidad:
		return false
	_items.append(item)
	item_added.emit(item)
	changed.emit()
	return true


func has_item(item: InventoryItem) -> bool:
	if item == null:
		return false
	return has_item_id(item.identificador)


func has_item_id(item_id: StringName) -> bool:
	for stored_item in _items:
		if stored_item != null and stored_item.identificador == item_id:
			return true
	return false


func get_items() -> Array[InventoryItem]:
	return _items.duplicate()


func count_from(required_items: Array[InventoryItem]) -> int:
	var total := 0
	for required_item in required_items:
		if has_item(required_item):
			total += 1
	return total


func contains_all(required_items: Array[InventoryItem]) -> bool:
	return count_from(required_items) == required_items.size()


func clear() -> void:
	if _items.is_empty():
		return
	_items.clear()
	changed.emit()

