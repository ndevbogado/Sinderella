class_name OptionsPanel
extends PanelContainer

signal close_requested

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _ambience_slider: HSlider = %AmbienceSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _master_value: Label = %MasterValue
@onready var _music_value: Label = %MusicValue
@onready var _ambience_value: Label = %AmbienceValue
@onready var _sfx_value: Label = %SfxValue
@onready var _fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var _reduce_motion_toggle: CheckButton = %ReduceMotionToggle
@onready var _autoplay_toggle: CheckButton = %AutoplayToggle
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_bind_slider(_master_slider, _master_value, "master_volume", Settings.master_volume)
	_bind_slider(_music_slider, _music_value, "music_volume", Settings.music_volume)
	_bind_slider(_ambience_slider, _ambience_value, "ambience_volume", Settings.ambience_volume)
	_bind_slider(_sfx_slider, _sfx_value, "sfx_volume", Settings.sfx_volume)
	_fullscreen_toggle.button_pressed = Settings.fullscreen
	_reduce_motion_toggle.button_pressed = Settings.reduce_motion
	_autoplay_toggle.button_pressed = Settings.autoplay_cinematics
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_reduce_motion_toggle.toggled.connect(_on_reduce_motion_toggled)
	_autoplay_toggle.toggled.connect(_on_autoplay_toggled)
	_close_button.pressed.connect(_on_close_pressed)


func _bind_slider(
	slider: HSlider, value_label: Label, property_name: StringName, initial_value: float
) -> void:
	slider.value = initial_value
	value_label.text = str(roundi(initial_value * 100.0))
	slider.value_changed.connect(_on_slider_changed.bind(property_name, value_label))


func _on_slider_changed(value: float, property_name: StringName, value_label: Label) -> void:
	value_label.text = str(roundi(value * 100.0))
	Settings.update_value(property_name, value)


func _on_fullscreen_toggled(value: bool) -> void:
	Settings.update_value("fullscreen", value)


func _on_reduce_motion_toggled(value: bool) -> void:
	Settings.update_value("reduce_motion", value)


func _on_autoplay_toggled(value: bool) -> void:
	Settings.update_value("autoplay_cinematics", value)


func _on_close_pressed() -> void:
	Audio.play_sfx("res://assets/audio/sfx/ui_back.wav", -4.0)
	close_requested.emit()

