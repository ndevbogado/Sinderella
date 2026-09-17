class_name HealEffect
extends BattleEffect
@export var power: int = 18

func amount(caster) -> int:
	return roundi(power * (100.0 + caster.data.wit) / 130.0)

func apply(context, caster, target) -> void:
	var value: int = mini(amount(caster), target.data.max_hp - target.hp)
	target.hp += value
	context.report(target, "+%s VIDA" % value, "heal")

func estimate(_context, caster, target) -> float:
	return minf(amount(caster), target.data.max_hp - target.hp) * 1.15
