class_name BeatEffect
extends BattleEffect
@export var change: int = -1

func apply(context, caster, _target) -> void:
	context.beat = clampi(context.beat + change, 1, context.law.beat_length)
	context.beat_used[caster.team] = true
	context.report(caster, "COMPÁS ALTERADO", "role")

func estimate(context, _caster, _target) -> float:
	return 8.0 if context.beat == context.law.beat_length else 0.0
