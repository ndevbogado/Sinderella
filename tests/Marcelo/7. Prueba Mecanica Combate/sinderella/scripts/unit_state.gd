class_name BattleUnitState
extends RefCounted
var data: BattleUnitData
var uid: int
var team: int
var slot: int
var hp: int
var impulse: int = 1
var shield: int = 0
var shield_expiry: int = 0
var guard: bool = false
var marked: bool = false
var mark_expiry: int = 0
var role: String
var echo: String = ""

func _init(definition: BattleUnitData, unit_id: int, side: int, position_index: int) -> void:
	data = definition
	uid = unit_id
	team = side
	slot = position_index
	hp = data.max_hp
	role = data.starting_role

func alive() -> bool:
	return hp > 0
