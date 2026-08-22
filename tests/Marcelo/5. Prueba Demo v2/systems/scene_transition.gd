extends CanvasLayer

@export var default_duration: float = 0.65

var _busy := false
@onready var _fade: ColorRect = %Fade


func _ready() -> void:
	layer = 100
	_fade.modulate.a = 1.0
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, default_duration)
	await tween.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(scene_path: String, duration: float = -1.0) -> void:
	if _busy or scene_path.is_empty():
		return
	_busy = true
	var actual_duration := default_duration if duration <= 0.0 else duration
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_out := create_tween()
	fade_out.tween_property(_fade, "modulate:a", 1.0, actual_duration)
	await fade_out.finished

	var tree := get_tree()
	var error := tree.change_scene_to_file(scene_path)
	if error != OK:
		push_error("No se pudo abrir la escena: %s" % scene_path)
		_busy = false
		return

	await tree.scene_changed
	var fade_in := create_tween()
	fade_in.tween_property(_fade, "modulate:a", 0.0, actual_duration)
	await fade_in.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
