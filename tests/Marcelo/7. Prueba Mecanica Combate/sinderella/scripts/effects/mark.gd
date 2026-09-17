class_name MarkEffect
extends BattleEffect
func apply(context, _caster, target) -> void:
	target.marked = true
	target.mark_expiry = context.round_number + 1
	context.report(target, "MARCADO", "role")

func estimate(_context, _caster, target) -> float:
	return 0.0 if target.marked else 6.0
