extends Control

@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _status_label: Label = %StatusLabel
@onready var _title_label: Label = %LoadingTitle

var _elapsed := 0.0
var _request_started := false
var _completed_resource: PackedScene
var _fallback_attempted := false
var _transition_requested := false


func _ready() -> void:
	PauseManager.set_pause_enabled(false)
	_title_label.text = SceneRouter.loading_caption.to_upper()
	_start_request()


func _process(delta: float) -> void:
	_elapsed += delta
	if _completed_resource != null:
		_change_scene_when_ready()
		return
	if not _request_started:
		return
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(SceneRouter.target_scene, progress)
	if not progress.is_empty():
		_progress_bar.value = lerpf(
			_progress_bar.value, float(progress[0]) * 100.0, minf(delta * 8.0, 1.0)
		)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			if _completed_resource == null:
				_completed_resource = (
					ResourceLoader.load_threaded_get(SceneRouter.target_scene) as PackedScene
				)
				if _completed_resource == null:
					_attempt_main_thread_fallback()
					return
				_progress_bar.value = 100.0
				_status_label.text = "Listo"
			_change_scene_when_ready()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_attempt_main_thread_fallback()


func _start_request() -> void:
	if SceneRouter.target_scene.is_empty():
		SceneRouter.target_scene = "res://scenes/main_menu.tscn"
	var error := ResourceLoader.load_threaded_request(SceneRouter.target_scene, "PackedScene")
	_request_started = error == OK
	if not _request_started:
		_attempt_main_thread_fallback()


func _attempt_main_thread_fallback() -> void:
	if _fallback_attempted:
		_show_load_error()
		return
	_fallback_attempted = true
	_request_started = false
	_status_label.text = "Comprobando escena…"
	_completed_resource = (
		ResourceLoader.load(
			SceneRouter.target_scene, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE
		) as PackedScene
	)
	if _completed_resource == null:
		_show_load_error()
		return
	_progress_bar.value = 100.0
	_status_label.text = "Listo"
	_change_scene_when_ready()


func _change_scene_when_ready() -> void:
	if (
		_transition_requested
		or _completed_resource == null
		or _elapsed < SceneRouter.minimum_loading_time
	):
		return
	_transition_requested = true
	set_process(false)
	call_deferred("_change_to_loaded_scene")


func _change_to_loaded_scene() -> void:
	var error := get_tree().change_scene_to_packed(_completed_resource)
	if error != OK:
		_transition_requested = false
		_show_load_error()


func _show_load_error() -> void:
	set_process(false)
	_status_label.text = "No se pudo cargar: " + SceneRouter.target_scene.get_file()
	push_error("No se pudo cargar la escena: " + SceneRouter.target_scene)

