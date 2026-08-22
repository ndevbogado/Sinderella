class_name SpeechManager
extends Node

signal setting_changed(enabled: bool)

const SPEAKER_PROFILES: Dictionary = {
	"NARRADOR": {"voice_offset": 0, "pitch": 0.88, "rate": 0.90},
	"CENDRA": {"voice_offset": 0, "pitch": 0.94, "rate": 0.96},
	"CAPERUCITA": {"voice_offset": 1, "pitch": 1.10, "rate": 1.06},
	"BRIAR": {"voice_offset": 2, "pitch": 1.02, "rate": 0.84},
	"PRÍNCIPE": {"voice_offset": 1, "pitch": 0.82, "rate": 0.92},
	"CUSTODIO": {"voice_offset": 0, "pitch": 0.66, "rate": 0.76},
	"RECUERDO": {"voice_offset": 2, "pitch": 1.18, "rate": 0.82}
}

var enabled: bool = true
var volume: int = 72
var voice_ids: PackedStringArray = PackedStringArray()
var available: bool = false
var utterance_id: int = 0

func _ready() -> void:
	_refresh_voices()

func _refresh_voices() -> void:
	voice_ids = DisplayServer.tts_get_voices_for_language("es")
	if voice_ids.is_empty():
		voice_ids = DisplayServer.tts_get_voices_for_language("es-AR")
	if voice_ids.is_empty():
		voice_ids = DisplayServer.tts_get_voices_for_language("es-ES")
	available = not voice_ids.is_empty()

func toggle() -> bool:
	enabled = not enabled
	if not enabled:
		stop()
	setting_changed.emit(enabled)
	return enabled

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop()
	setting_changed.emit(enabled)

func speak(speaker: String, text: String) -> void:
	if not enabled or not available:
		return
	var cleaned_text: String = _clean_for_speech(text)
	if cleaned_text.is_empty():
		return
	var profile_variant: Variant = SPEAKER_PROFILES.get(speaker, SPEAKER_PROFILES["NARRADOR"])
	var profile: Dictionary = profile_variant
	var offset: int = int(profile.get("voice_offset", 0))
	var voice_index: int = offset % voice_ids.size()
	var voice_id: String = voice_ids[voice_index]
	var pitch: float = float(profile.get("pitch", 1.0))
	var rate: float = float(profile.get("rate", 1.0))
	utterance_id += 1
	DisplayServer.tts_speak(cleaned_text, voice_id, volume, pitch, rate, utterance_id, true)

func stop() -> void:
	DisplayServer.tts_stop()

func status_text() -> String:
	if not available:
		return "Voces: no hay una voz española instalada"
	return "Voces: ACTIVADAS" if enabled else "Voces: DESACTIVADAS"

func _clean_for_speech(text: String) -> String:
	var cleaned: String = text
	cleaned = cleaned.replace("[b]", "")
	cleaned = cleaned.replace("[/b]", "")
	cleaned = cleaned.replace("[center]", "")
	cleaned = cleaned.replace("[/center]", "")
	cleaned = cleaned.replace("«", "")
	cleaned = cleaned.replace("»", "")
	return cleaned.strip_edges()
