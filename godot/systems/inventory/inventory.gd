## Inventory: el MODELO DE DATOS. No sabe nada de la interfaz.
##
## Guarda un arreglo de slots y ofrece funciones para agregar y quitar ítems.
## Cuando su contenido cambia emite la señal `changedSlot`; la interfaz escucha esa
## señal y se redibuja. Separar datos de interfaz facilita probar y modificar
## cada parte por separado.
class_name Inventory
extends Resource

## Se emite después de cualquier cambio en los slots. La interfaz se conecta a esta señal.
signal changedSlot

## Todos los slots, en orden.
var slots: Array[InventorySlot] = []

## Crea un inventario con `size` slots vacíos.
## Uso: var inv: Inventory = Inventory.new(12)
func _init(size: int = 20) -> void:
	for i in size:
		slots.append(InventorySlot.new())

## Agrega `amount` unidades de `item`.
## Devuelve cuántas unidades NO entraron (0 = se agregó todo).
func add_item(item: ItemData, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return amount

	# Paso 1: completar pilas existentes, parcialmente llenas, del mismo ítem.
	if item.stackable:
		for slot in slots:
			if slot.item == item and slot.quantity < item.max_stack:
				var added: int = mini(item.max_stack - slot.quantity, amount)
				slot.quantity += added
				amount -= added
				if amount == 0:
					changedSlot.emit()
					return 0

	# Paso 2: usar slots vacíos para lo que quede.
	var per_slot: int = item.max_stack if item.stackable else 1
	for slot in slots:
		if slot.is_empty():
			var added: int = mini(per_slot, amount)
			slot.item = item
			slot.quantity = added
			amount -= added
			if amount == 0:
				break

	changedSlot.emit()
	return amount

## Quita `amount` unidades de `item`, buscando en todos los slots.
## Devuelve false (sin cambiar nada) si no hay unidades suficientes.
func remove_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0 or count_item(item) < amount:
		return false
	for slot in slots:
		if slot.item == item:
			var removed: int = mini(slot.quantity, amount)
			slot.quantity -= removed
			amount -= removed
			if slot.quantity == 0:
				slot.item = null
			if amount == 0:
				break
	changedSlot.emit()
	return true

## Quita `amount` unidades de un slot específico (se usa al hacer clic en un slot).
func remove_from_slot(index: int, amount: int = 1) -> void:
	if index < 0 or index >= slots.size():
		return
	var slot: InventorySlot = slots[index]
	if slot.is_empty():
		return
	slot.quantity -= amount
	if slot.quantity <= 0:
		slot.quantity = 0
		slot.item = null
	changedSlot.emit()

## Total de unidades de `item` sumando todos los slots.
func count_item(item: ItemData) -> int:
	var total: int = 0
	for slot in slots:
		if slot.item == item:
			total += slot.quantity
	return total
