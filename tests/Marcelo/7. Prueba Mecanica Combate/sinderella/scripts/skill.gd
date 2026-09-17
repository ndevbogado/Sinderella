class_name BattleSkill
extends Resource
@export var id: String = "attack"
@export var display_name: String = "Ataque"
@export_multiline var description: String = ""
@export_range(0, 3) var impulse_cost: int = 0
@export_range(0, 1) var impulse_gain: int = 0
@export var priority: int = 0
@export_enum("enemy", "ally", "self", "any") var target_rule: String = "enemy"
@export var requires_contradiction: bool = false
@export var effects: Array[BattleEffect] = []

func estimate(context, caster, target) -> float:
	var score: float = 0.0
	for effect in effects:
		score += effect.estimate(context, caster, target)
	return score
