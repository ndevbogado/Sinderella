class_name BattleLaw
extends Resource
@export var display_name: String = "El intruso será expulsado"
@export_range(2, 4) var beat_length: int = 3
@export var threatened_role: String = "Intruso"
@export var opposing_role: String = "Guardián"
@export var damage: int = 24
@export var broken_damage: int = 32

func opposed(a: String, b: String) -> bool:
	return (a == threatened_role and b == opposing_role) or (b == threatened_role and a == opposing_role)

func affected(context) -> Array:
	return context.units.filter(func(u): return u.alive() and (u.role == threatened_role or u.echo == threatened_role))

func preview(context) -> String:
	var names: Array[String] = []
	for unit in affected(context):
		names.append("%s: %s" % [unit.data.display_name, "ROTA · %s daño" % broken_damage if context.is_contradiction(unit) else "%s daño" % damage])
	return "Sin objetivos" if names.is_empty() else " / ".join(names)

func resolve(context) -> void:
	for unit in affected(context):
		var broken: bool = context.is_contradiction(unit)
		context.report(unit, "LEY ROTA" if broken else "DESENLACE", "law")
		# Law damage ignores armor and shields absorb it; guard still mitigates.
		context.hurt(unit, roundi((broken_damage if broken else damage) * (0.6 if unit.guard else 1.0)))
	for unit in context.units:
		unit.echo = ""
