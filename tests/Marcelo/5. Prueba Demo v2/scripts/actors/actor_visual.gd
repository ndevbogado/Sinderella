@tool
class_name EditableActorVisual
extends Node2D

@export_category("Replaceable artwork")
@export var character_texture: Texture2D : set = _set_character_texture
@export var placeholder_color := Color("79a8d8") : set = _set_placeholder_color
@export var character_name := "PERSONAJE" : set = _set_character_name
@export var texture_scale := Vector2.ONE : set = _set_texture_scale

@onready var _artwork: Sprite2D = %Artwork
@onready var _placeholder: Polygon2D = %PlaceholderBody
@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	_apply_visuals()


func _apply_visuals() -> void:
	if not is_node_ready():
		return
	_artwork.texture = character_texture
	_artwork.scale = texture_scale
	_artwork.visible = character_texture != null
	_placeholder.visible = character_texture == null
	_placeholder.color = placeholder_color
	_name_label.text = character_name
	_name_label.visible = character_texture == null


func _set_character_texture(value: Texture2D) -> void:
	character_texture = value
	_apply_visuals()


func _set_placeholder_color(value: Color) -> void:
	placeholder_color = value
	_apply_visuals()


func _set_character_name(value: String) -> void:
	character_name = value
	_apply_visuals()


func _set_texture_scale(value: Vector2) -> void:
	texture_scale = value
	_apply_visuals()
