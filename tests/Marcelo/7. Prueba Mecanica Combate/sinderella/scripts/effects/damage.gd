class_name DamageEffect
extends BattleEffect
@export var power: int = 20
@export_enum("physical", "mental") var channel: String = "physical"
@export var ranged: bool = true
@export var consume_echo: bool = false
@export var marked_bonus: float = 1.0

func amount(context, caster, target) -> int:
	var attack: float = caster.data.strength if channel == "physical" else caster.data.wit
	var defense: float = target.data.armor if channel == "physical" else target.data.will
	var multiplier: float = 1.0
	if target.guard:
		multiplier *= 0.6
	if context.is_contradiction(target):
		multiplier *= 1.25
	if ranged and channel == "physical" and target.slot >= 2:
		multiplier *= 0.85
	if target.marked:
		multiplier *= marked_bonus
	return maxi(1, roundi(power * (100.0 + attack) / (100.0 + defense) * clampf(multiplier, 0.35, 2.0)))

func apply(context, caster, target) -> void:
	context.hurt(target, amount(context, caster, target))
	if consume_echo:
		target.echo = ""

func estimate(context, caster, target) -> float:
	var value: int = amount(context, caster, target)
	return minf(value, target.hp + target.shield) + (25.0 if value >= target.hp + target.shield else 0.0)
