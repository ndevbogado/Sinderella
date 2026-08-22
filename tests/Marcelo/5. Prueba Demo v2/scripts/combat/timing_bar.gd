class_name AttackTimingBar
extends Control

signal resolved(multiplier: float, grade: String)

@export_range(0.2, 3.0, 0.05) var marker_speed: float = 1.15
@export_range(0.02, 0.15, 0.005) var perfect_zone_width: float = 0.055
@export_range(0.08, 0.35, 0.01) var good_zone_width: float = 0.16

var _active := false
var _marker_ratio := 0.0
var _marker_direction := 1.0
var _target_center := 0.5

@onready var _bar: Control = %TimingTrack
@onready var _good_zone: ColorRect = %GoodZone
@onready var _perfect_zone: ColorRect = %PerfectZone
@onready var _marker: ColorRect = %TimingMarker
@onready var _result_label: Label = %TimingResult
@onready var _stop_button: Button = %StopTimingButton


func _ready() -> void:
	_stop_button.pressed.connect(_resolve)
	visibility_changed.connect(_layout_zones)


func start_timing() -> void:
	visible = true
	_active = true
	_marker_ratio = 0.0
	_marker_direction = 1.0
	_target_center = randf_range(good_zone_width * 0.5 + 0.04, 0.96 - good_zone_width * 0.5)
	_result_label.text = "Presioná ESPACIO, ENTER o DETENER"
	_result_label.modulate = Color.WHITE
	_stop_button.disabled = false
	_layout_zones.call_deferred()


func _process(delta: float) -> void:
	if not _active:
		return
	_marker_ratio += marker_speed * _marker_direction * delta
	if _marker_ratio >= 1.0:
		_marker_ratio = 1.0
		_marker_direction = -1.0
	elif _marker_ratio <= 0.0:
		_marker_ratio = 0.0
		_marker_direction = 1.0
	_layout_marker()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER]:
			_resolve()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _bar.get_global_rect().has_point(event.position):
			_resolve()
			get_viewport().set_input_as_handled()


func _layout_zones() -> void:
	if not is_node_ready() or _bar.size.x <= 0.0:
		return
	var width := _bar.size.x
	_good_zone.position.x = (_target_center - good_zone_width * 0.5) * width
	_good_zone.size.x = good_zone_width * width
	_perfect_zone.position.x = (_target_center - perfect_zone_width * 0.5) * width
	_perfect_zone.size.x = perfect_zone_width * width
	_layout_marker()


func _layout_marker() -> void:
	if not is_node_ready():
		return
	_marker.position.x = _marker_ratio * _bar.size.x - _marker.size.x * 0.5


func _resolve() -> void:
	if not _active:
		return
	_active = false
	_stop_button.disabled = true
	var distance := absf(_marker_ratio - _target_center)
	var multiplier := 1.0
	var grade := "FUERA DE ZONA  ×1"
	if distance <= perfect_zone_width * 0.5:
		multiplier = 3.0
		grade = "PERFECTO  ×3"
		_result_label.modulate = Color("ffe66d")
	elif distance <= good_zone_width * 0.5:
		multiplier = 2.0
		grade = "BUENO  ×2"
		_result_label.modulate = Color("79e6a5")
	else:
		_result_label.modulate = Color("ff7770")
	_result_label.text = grade
	var pulse := create_tween()
	pulse.tween_property(_marker, "scale", Vector2(1.8, 1.0), 0.09)
	pulse.tween_property(_marker, "scale", Vector2.ONE, 0.12)
	await get_tree().create_timer(0.55).timeout
	visible = false
	resolved.emit(multiplier, grade)
