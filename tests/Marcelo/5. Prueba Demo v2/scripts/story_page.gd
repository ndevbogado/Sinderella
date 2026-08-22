class_name StoryPage
extends Control

## Una pagina contiene varios StoryPanel. El orden se decide con story_order.

@export var page_title: String = "Pagina"
@export_range(0.1, 2.0, 0.05) var page_fade_duration: float = 0.25

var _panels: Array[StoryPanel] = []
var _revealed_count: int = 0
var _page_tween: Tween


func _ready() -> void:
	_collect_panels(self)
	_panels.sort_custom(func(a: StoryPanel, b: StoryPanel) -> bool: return a.story_order < b.story_order)
	prepare()


func _collect_panels(node: Node) -> void:
	for child in node.get_children():
		if child is StoryPanel:
			_panels.append(child as StoryPanel)
		else:
			_collect_panels(child)


func prepare() -> void:
	if _page_tween and _page_tween.is_valid():
		_page_tween.kill()
	_revealed_count = 0
	modulate.a = 1.0
	visible = false
	for panel in _panels:
		panel.reset_panel()


func enter_page() -> void:
	visible = true
	modulate.a = 0.0
	_page_tween = create_tween()
	_page_tween.tween_property(self, "modulate:a", 1.0, page_fade_duration)
	await _page_tween.finished


func exit_page() -> void:
	if _page_tween and _page_tween.is_valid():
		_page_tween.kill()
	_page_tween = create_tween()
	_page_tween.tween_property(self, "modulate:a", 0.0, page_fade_duration)
	await _page_tween.finished
	visible = false


func reveal_next_panel() -> bool:
	if not has_more_panels():
		return false
	var panel := _panels[_revealed_count]
	_revealed_count += 1
	await panel.animate_in(size)
	return true


func hide_last_panel() -> bool:
	if _revealed_count <= 1:
		return false
	_revealed_count -= 1
	_panels[_revealed_count].reset_panel()
	return true


func reveal_all_immediately() -> void:
	for panel in _panels:
		panel.show_immediately()
	_revealed_count = _panels.size()


func has_more_panels() -> bool:
	return _revealed_count < _panels.size()


func panel_progress() -> String:
	return "%d/%d" % [_revealed_count, _panels.size()]

