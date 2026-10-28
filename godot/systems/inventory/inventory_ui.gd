## InventoryUI: the VIEW. Draws an Inventory as a grid of buttons.
##
## Scene tree (see scenes/inventory_ui.tscn):
##   InventoryUI (CanvasLayer)   <- this script; a layer drawn above the game
##   └ Center (CenterContainer)  <- centers its child on screen
##     └ Panel (PanelContainer)  <- background box
##       └ Margin (MarginContainer)
##         └ VBox (VBoxContainer)<- stacks children vertically
##           ├ Title (Label)
##           ├ Grid (GridContainer) <- slot buttons are created here by code
##           └ Hint (Label)
##
## This script never changes inventory data itself. When a slot is clicked it
## emits `slot_clicked` and lets the owner decide what to do.
class_name InventoryUI
extends CanvasLayer

## Emitted when the player clicks a slot button. `index` is the slot number.
signal slot_clicked(index: int)

const SLOT_SIZE := Vector2(110, 60)

## @onready: this variable is assigned when the node enters the scene tree,
## the moment the child nodes exist and `$Path` can find them.
@onready var grid: GridContainer = $Center/Panel/Margin/VBox/Grid

var _inventory: Inventory
var _buttons: Array[Button] = []

func _ready() -> void:
	visible = false  # start closed

## Connects this UI to an inventory and builds one button per slot.
## Must be called by whoever owns the inventory (see main.gd).
func setup(inventory: Inventory) -> void:
	if _inventory != null:
		_inventory.changedSlot.disconnect(_refresh)
	_inventory = inventory
	_inventory.changedSlot.connect(_refresh)  # redraw whenever data changes

	for b in _buttons:
		b.queue_free()
	_buttons.clear()

	for i in _inventory.slots.size():
		var button := Button.new()
		button.custom_minimum_size = SLOT_SIZE
		button.expand_icon = true   # scale the icon to fit the button
		# bind(i) passes the slot index to the handler when pressed.
		button.pressed.connect(_on_slot_pressed.bind(i))
		grid.add_child(button)  # adding a child puts it in the scene tree
		_buttons.append(button)
	_refresh()

## Shows the inventory if hidden, hides it if shown.
func toggle() -> void:
	visible = not visible

## True while the inventory window is open.
func is_open() -> bool:
	return visible

## Updates every button from the inventory data.
func _refresh() -> void:
	for i in _buttons.size():
		var slot := _inventory.slots[i]
		var button := _buttons[i]

		if slot.is_empty():
			button.icon = null
			button.text = "empty slot"
			button.tooltip_text = ""
			continue

		button.tooltip_text = "%s\n%s" % [slot.item.display_name, slot.item.description]

		if slot.item.icon != null:
			# Icon available: show it, plus the quantity if there is a stack.
			button.icon = slot.item.icon
			button.text = ("x%d" % slot.quantity if slot.quantity > 1 else "")
		else:
			# No icon assigned: fall back to the old text display.
			button.icon = null
			button.text = slot.item.display_name
			if slot.quantity > 1:
				button.text += "\nx%d" % slot.quantity

func _on_slot_pressed(index: int) -> void:
	slot_clicked.emit(index)
