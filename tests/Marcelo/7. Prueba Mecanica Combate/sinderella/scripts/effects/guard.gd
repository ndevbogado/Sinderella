class_name GuardEffect
extends BattleEffect
func apply(context, _caster, target) -> void:
	target.guard = true
	context.report(target, "GUARDIA", "shield")

func estimate(_context, _caster, _target) -> float:
	return 7.0
