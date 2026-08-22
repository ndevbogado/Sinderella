extends Node

## Estado mínimo que viaja del bosque a la arena y luego a la cinemática final.

enum EncounterMode {
	GUARD,
	CHARGE,
	FLEE,
}

var encounter_mode: EncounterMode = EncounterMode.GUARD
var battle_result: String = ""


func reset() -> void:
	encounter_mode = EncounterMode.GUARD
	battle_result = ""
