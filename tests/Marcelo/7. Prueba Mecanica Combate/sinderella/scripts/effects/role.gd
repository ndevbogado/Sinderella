class_name RoleEffect
extends BattleEffect
@export_enum("echo_caster", "swap", "clear_echo") var operation: String = "echo_caster"

func apply(context, caster, target) -> void:
	if operation == "echo_caster":
		target.echo = caster.role
	elif operation == "swap":
		var previous: String = caster.role
		caster.role = target.role
		target.role = previous
	else:
		target.echo = ""
	context.report(target, "CONTRADICCIÓN" if context.is_contradiction(target) else "PAPEL ALTERADO", "role")

func estimate(context, caster, target) -> float:
	if operation == "clear_echo":
		return 12.0 if context.is_contradiction(target) else 0.0
	if operation == "echo_caster":
		return 18.0 if context.law.opposed(caster.role, target.role) and not context.is_contradiction(target) else 0.0
	return 8.0
