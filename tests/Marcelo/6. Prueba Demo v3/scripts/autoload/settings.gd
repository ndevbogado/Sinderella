extends Node

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

var master_volume := 0.90
var music_volume := 0.72
var ambience_volume := 0.78
var sfx_volume := 0.85
var fullscreen := false
var reduce_motion := false
var autoplay_cinematics := false
var cinematic_speed := 1.0


func _ready() -> void:
	_create_input_actions()
	load_settings()
	call_deferred("apply")


func _create_input_actions() -> void:
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("move_up", [KEY_W, KEY_UP])
	_bind_keys("move_down", [KEY_S, KEY_DOWN])
	_bind_keys("interact", [KEY_E])
	_bind_keys("toggle_inventory", [KEY_I])
	_bind_keys("advance_story", [KEY_SPACE, KEY_ENTER])
	_bind_keys("pause_game", [KEY_ESCAPE])

	if not InputMap.has_action("advance_story"):
		InputMap.add_action("advance_story")
	var has_mouse := false
	for input_event in InputMap.action_get_events("advance_story"):
		if input_event is InputEventMouseButton and input_event.button_index == MOUSE_BUTTON_LEFT:
			has_mouse = true
	if not has_mouse:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("advance_story", mouse_event)


func _bind_keys(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		var already_bound := false
		for input_event in InputMap.action_get_events(action):
			if (
				input_event is InputEventKey
				and (
					input_event.physical_keycode == keycode
					or input_event.keycode == keycode
				)
			):
				already_bound = true
		if not already_bound:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	master_volume = float(config.get_value("audio", "master", master_volume))
	music_volume = float(config.get_value("audio", "music", music_volume))
	ambience_volume = float(config.get_value("audio", "ambience", ambience_volume))
	sfx_volume = float(config.get_value("audio", "sfx", sfx_volume))
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	reduce_motion = bool(config.get_value("accessibility", "reduce_motion", reduce_motion))
	autoplay_cinematics = bool(config.get_value("cinematic", "autoplay", autoplay_cinematics))
	cinematic_speed = float(config.get_value("cinematic", "speed", cinematic_speed))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "ambience", ambience_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("accessibility", "reduce_motion", reduce_motion)
	config.set_value("cinematic", "autoplay", autoplay_cinematics)
	config.set_value("cinematic", "speed", cinematic_speed)
	config.save(SAVE_PATH)


func apply() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("Ambience", ambience_volume)
	_set_bus_volume("SFX", sfx_volume)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	settings_changed.emit()


func update_value(property_name: StringName, value: Variant) -> void:
	set(property_name, value)
	apply()
	save_settings()


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_value, 0.001)))
		AudioServer.set_bus_mute(bus_index, linear_value <= 0.001)
