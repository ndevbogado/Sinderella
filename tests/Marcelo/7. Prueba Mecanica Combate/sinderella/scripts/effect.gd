class_name BattleEffect
extends Resource
## Extend this resource to add a new mechanic without changing the resolver.
func apply(_context, _caster, _target) -> void:
	pass

func estimate(_context, _caster, _target) -> float:
	return 0.0
