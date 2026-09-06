extends Node

const LOADING_SCENE := "res://scenes/loading_screen.tscn"

var target_scene := ""
var loading_caption := "Cargando…"
var minimum_loading_time := 0.75


func go_to(path: String, caption := "Cargando…") -> void:
	if path.is_empty():
		return
	target_scene = path
	loading_caption = caption
	get_tree().paused = false
	_disable_pause_manager()
	get_tree().change_scene_to_file(LOADING_SCENE)


func go_to_immediate(path: String) -> void:
	get_tree().paused = false
	_disable_pause_manager()
	get_tree().change_scene_to_file(path)


# Se busca por ruta en lugar de referenciar el autoload directamente. Esto evita
# una dependencia circular: PauseManager usa SceneRouter para cambiar de escena.
func _disable_pause_manager() -> void:
	var pause_manager := get_node_or_null("/root/PauseManager")
	if pause_manager != null and pause_manager.has_method("set_pause_enabled"):
		pause_manager.call("set_pause_enabled", false)
