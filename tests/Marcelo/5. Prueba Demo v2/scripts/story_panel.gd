@tool
class_name StoryPanel
extends Control

## Panel responsive para una secuencia narrativa tipo comic.
## La posicion y el tamano se definen con anchors (valores entre 0 y 1).

enum EntryFrom {
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
	CENTER,
}

@export_category("Story")
@export_range(0, 999, 1) var story_order: int = 0
@export var panel_title: String = "PANEL" : set = _set_panel_title
@export_multiline var caption: String = "" : set = _set_caption
@export var image: Texture2D : set = _set_image
@export var placeholder_color: Color = Color("435b7a") : set = _set_placeholder_color

@export_category("Entrance")
@export var entry_from: EntryFrom = EntryFrom.LEFT : set = _set_entry_from
@export_range(0.1, 3.0, 0.05) var enter_duration: float = 0.55
@export_range(0.0, 2.0, 0.05) var enter_delay: float = 0.0
@export_range(0.5, 2.5, 0.05) var travel_multiplier: float = 1.15
@export var fade_in: bool = true
@export var scale_in: bool = true
@export_range(0.5, 1.2, 0.01) var initial_scale: float = 0.92
@export_range(-15.0, 15.0, 0.1) var initial_rotation_degrees: float = 0.0

var _active_tween: Tween
var _rest_offsets := Vector4.ZERO
var _layout_captured := false

@onready var _background: Panel = %Background
@onready var _texture: TextureRect = %Image
@onready var _placeholder: Label = %Placeholder
@onready var _caption_box: PanelContainer = %CaptionBox
@onready var _caption_label: Label = %Caption


func _ready() -> void:
	_capture_layout()
	pivot_offset = size * 0.5
	_update_visuals()
	if not Engine.is_editor_hint():
		reset_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func _capture_layout() -> void:
	_rest_offsets = Vector4(offset_left, offset_top, offset_right, offset_bottom)
	_layout_captured = true


func _restore_layout() -> void:
	if not _layout_captured:
		_capture_layout()
	offset_left = _rest_offsets.x
	offset_top = _rest_offsets.y
	offset_right = _rest_offsets.z
	offset_bottom = _rest_offsets.w


func reset_panel() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_restore_layout()
	visible = false
	modulate.a = 1.0
	scale = Vector2.ONE
	rotation_degrees = 0.0


func show_immediately() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_restore_layout()
	visible = true
	modulate.a = 1.0
	scale = Vector2.ONE
	rotation_degrees = 0.0


func animate_in(available_size: Vector2) -> void:
	_restore_layout()
	var target_position := position
	var direction := _entry_vector()
	var travel := maxf(available_size.x, available_size.y) * travel_multiplier

	visible = true
	position = target_position + direction * travel
	modulate.a = 0.0 if fade_in else 1.0
	scale = Vector2.ONE * initial_scale if scale_in else Vector2.ONE
	rotation_degrees = initial_rotation_degrees

	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(self, "position", target_position, enter_duration).set_delay(enter_delay)
	_active_tween.tween_property(self, "modulate:a", 1.0, enter_duration * 0.65).set_delay(enter_delay)
	_active_tween.tween_property(self, "scale", Vector2.ONE, enter_duration).set_delay(enter_delay)
	_active_tween.tween_property(self, "rotation_degrees", 0.0, enter_duration).set_delay(enter_delay)
	await _active_tween.finished
	_restore_layout()


func _entry_vector() -> Vector2:
	match entry_from:
		EntryFrom.LEFT:
			return Vector2.LEFT
		EntryFrom.RIGHT:
			return Vector2.RIGHT
		EntryFrom.TOP:
			return Vector2.UP
		EntryFrom.BOTTOM:
			return Vector2.DOWN
		EntryFrom.TOP_LEFT:
			return Vector2(-1.0, -1.0).normalized()
		EntryFrom.TOP_RIGHT:
			return Vector2(1.0, -1.0).normalized()
		EntryFrom.BOTTOM_LEFT:
			return Vector2(-1.0, 1.0).normalized()
		EntryFrom.BOTTOM_RIGHT:
			return Vector2(1.0, 1.0).normalized()
		EntryFrom.CENTER:
			return Vector2.ZERO
	return Vector2.LEFT


func _update_visuals() -> void:
	if not is_node_ready():
		return

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = placeholder_color
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 3
	panel_style.corner_radius_top_right = 3
	panel_style.corner_radius_bottom_left = 3
	panel_style.corner_radius_bottom_right = 3
	_background.add_theme_stylebox_override("panel", panel_style)

	_texture.texture = image
	_texture.visible = image != null
	_placeholder.visible = image == null
	_placeholder.text = "%s\n%s" % [panel_title, _entry_name()]
	_caption_label.text = caption
	_caption_box.visible = not caption.strip_edges().is_empty()


func _entry_name() -> String:
	return EntryFrom.keys()[entry_from].capitalize().replace("_", " ")


func _set_panel_title(value: String) -> void:
	panel_title = value
	_update_visuals()


func _set_caption(value: String) -> void:
	caption = value
	_update_visuals()


func _set_image(value: Texture2D) -> void:
	image = value
	_update_visuals()


func _set_placeholder_color(value: Color) -> void:
	placeholder_color = value
	_update_visuals()


func _set_entry_from(value: EntryFrom) -> void:
	entry_from = value
	_update_visuals()

