class_name ShieldEffect
extends BattleEffect
@export var power: int = 18

func apply(context, caster, target) -> void:
	var value: int = roundi(power * (100.0 + caster.data.wit) / 130.0)
	target.shield = maxi(target.shield, value)
	target.shield_expiry = context.round_number + 1
	context.report(target, "%s ESCUDO" % target.shield, "shield")

func estimate(_context, caster, target) -> float:
	return maxf(0.0, power * (100.0 + caster.data.wit) / 130.0 - target.shield) * 0.65
