class_name InventoryPanel
extends CanvasLayer

signal open_changed(is_open: bool)

@export var quest: TravelQuest

@onready var _overlay: Control = %InventoryOverlay
@onready var _objective_title: Label = %ObjectiveTitle
@onready var _objective_progress: Label = %ObjectiveProgress
@onready var _inventory_count: Label = %InventoryCount
@onready var _toast: Control = %PickupToast
@onready var _toast_icon: TextureRect = %PickupIcon
@onready var _toast_label: Label = %PickupLabel

var input_enabled := true
var _open := false
var _toast_generation := 0
var _slots: Array[Control] = []


func _ready() -> void:
	add_to_group("inventory_ui")
	_slots = [
		%Slot01 as Control,
		%Slot02 as Control,
		%Slot03 as Control,
		%Slot04 as Control,
		%Slot05 as Control,
		%Slot06 as Control,
		%Slot07 as Control,
		%Slot08 as Control,
	]
	_overlay.hide()
	_toast.hide()
	Inventory.changed.connect(_refresh)
	Inventory.item_added.connect(_on_item_added)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event.is_action_pressed("toggle_inventory"):
		get_viewport().set_input_as_handled()
		set_open(not _open)


func configure(new_quest: TravelQuest) -> void:
	quest = new_quest
	if is_node_ready():
		_refresh()


func set_open(value: bool) -> void:
	if _open == value:
		return
	_open = value
	_overlay.visible = _open
	get_tree().call_group("player_character", "set_controls_enabled", not _open)
	Audio.play_sfx(
		"res://assets/audio/sfx/ui_open.wav" if _open else "res://assets/audio/sfx/ui_back.wav",
		-7.0
	)
	open_changed.emit(_open)


func close_inventory() -> void:
	set_open(false)


func is_open() -> bool:
	return _open


func _refresh() -> void:
	var items := Inventory.get_items()
	_inventory_count.text = "%d / %d" % [items.size(), Inventory.capacidad]
	for index in range(_slots.size()):
		var item: InventoryItem = null
		if index < items.size():
			item = items[index]
		_refresh_slot(_slots[index], item)

	if quest == null:
		_objective_title.text = "SIN OBJETIVO ACTIVO"
		_objective_progress.text = ""
		return
	var found := Inventory.count_from(quest.objetos_requeridos)
	var total := quest.objetos_requeridos.size()
	_objective_title.text = quest.titulo.to_upper()
	_objective_progress.text = "%d / %d" % [found, total]
	if total > 0 and found == total:
		_objective_progress.text += "  ·  LISTO"


func _refresh_slot(slot: Control, item: InventoryItem) -> void:
	var icon := slot.get_node("Margin/Content/Icon") as TextureRect
	var name_label := slot.get_node("Margin/Content/Name") as Label
	var state_label := slot.get_node("Margin/Content/State") as Label
	if item == null:
		icon.texture = null
		icon.modulate = Color(1.0, 1.0, 1.0, 0.2)
		name_label.text = "VACÍO"
		state_label.text = "ESPACIO DISPONIBLE"
		slot.tooltip_text = ""
		return
	icon.texture = item.icono
	icon.modulate = Color.WHITE
	name_label.text = item.nombre.to_upper()
	state_label.text = "OBJETO CLAVE" if item.objeto_clave else "EN LA MOCHILA"
	slot.tooltip_text = item.descripcion


func _on_item_added(item: InventoryItem) -> void:
	_refresh()
	show_pickup(item)


func show_pickup(item: InventoryItem) -> void:
	if item == null:
		return
	_toast_generation += 1
	var local_generation := _toast_generation
	_toast_icon.texture = item.icono
	_toast_label.text = "AÑADIDO  ·  " + item.nombre.to_upper()
	_toast.modulate.a = 0.0
	_toast.position.y = -12.0
	_toast.show()
	var entrance := create_tween().set_parallel(true)
	entrance.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entrance.tween_property(_toast, "modulate:a", 1.0, 0.2)
	entrance.tween_property(_toast, "position:y", 0.0, 0.25)
	await get_tree().create_timer(2.2, false).timeout
	if local_generation != _toast_generation:
		return
	var exit_tween := create_tween()
	exit_tween.tween_property(_toast, "modulate:a", 0.0, 0.25)
	await exit_tween.finished
	if local_generation == _toast_generation:
		_toast.hide()


func _on_close_pressed() -> void:
	close_inventory()
