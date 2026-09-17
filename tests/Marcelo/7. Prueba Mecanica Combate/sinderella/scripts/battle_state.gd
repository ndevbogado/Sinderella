class_name BattleState
extends RefCounted
## Pure deterministic rules; no scene tree, animation or shared-resource mutation.
var units: Array = []
var law: BattleLaw
var round_number: int = 1
var beat: int = 1
var beat_used: Array[bool] = [false, false]
var plans: Dictionary = {}
var intentions: Dictionary = {}
var queue: Array = []
var events: Array = []
var phase: String = "planning"
var result: String = ""
var definition: BattleEncounter

func _init(encounter: BattleEncounter) -> void:
	definition = encounter
	assert(encounter != null and encounter.law != null, "Falta Encounter o Law")
	assert(encounter.allies.size() in range(1, 5) and encounter.enemies.size() in range(1, 5), "Cada equipo requiere 1–4 unidades")
	law = encounter.law
	for team in 2:
		var roster: Array = encounter.allies if team == 0 else encounter.enemies
		for slot in roster.size():
			units.append(BattleUnitState.new(roster[slot], units.size(), team, slot))
	announce()

func preview_action(caster, skill: BattleSkill, target) -> Dictionary:
	# Apply the real effects in order to an isolated snapshot; never mutate a plan.
	if not can_use(caster, skill, target):
		return {}
	var copy = BattleState.new(definition)
	copy.round_number = round_number
	copy.beat = beat
	copy.beat_used = beat_used.duplicate()
	for unit in units:
		for key in ["hp", "impulse", "shield", "shield_expiry", "guard", "marked", "mark_expiry", "role", "echo", "slot"]:
			copy.units[unit.uid].set(key, unit.get(key))
	var actor = copy.units[caster.uid]
	var recipient = copy.units[target.uid]
	actor.guard = false
	actor.impulse -= skill.impulse_cost
	for effect in skill.effects:
		effect.apply(copy, actor, recipient)
	actor.impulse = mini(3, actor.impulse + skill.impulse_gain)
	return {
		"hp_before": target.hp, "hp_after": recipient.hp,
		"shield_before": target.shield, "shield_after": recipient.shield,
		"impulse_before": caster.impulse, "impulse_after": actor.impulse,
		"role_before": target.role, "role_after": recipient.role,
		"echo_after": recipient.echo, "caster_role_after": actor.role,
		"contradiction": copy.is_contradiction(recipient),
		"beat_before": beat, "beat_after": copy.beat,
		"events": copy.events.duplicate(true)
	}

func living(team: int) -> Array:
	return units.filter(func(u): return u.team == team and u.alive())

func is_contradiction(unit) -> bool:
	return law.opposed(unit.role, unit.echo)

func targets(caster, skill: BattleSkill) -> Array:
	return units.filter(func(u): return u.alive() and (skill.target_rule == "any" or (skill.target_rule == "self" and u == caster) or (skill.target_rule == "ally" and u.team == caster.team) or (skill.target_rule == "enemy" and u.team != caster.team)))

func can_use(caster, skill: BattleSkill, target) -> bool:
	if not caster.alive() or caster.impulse < skill.impulse_cost or not targets(caster, skill).has(target):
		return false
	if skill.requires_contradiction and not is_contradiction(target):
		return false
	for effect in skill.effects:
		if effect is BeatEffect and (beat_used[caster.team] or (effect.change < 0 and beat <= 1)):
			return false
	return true

func choose_ai(caster) -> Dictionary:
	var best: Dictionary = {}
	var score: float = -INF
	for skill in caster.data.skills:
		for target in targets(caster, skill):
			if not can_use(caster, skill, target):
				continue
			var value: float = skill.estimate(self, caster, target) + skill.impulse_gain * 3.0 - skill.impulse_cost * 2.0
			if value > score:
				score = value
				best = {"caster": caster, "skill": skill, "target": target}
	return best

func announce() -> void:
	intentions.clear()
	for enemy in living(1):
		intentions[enemy.uid] = choose_ai(enemy)

func plan(caster, skill: BattleSkill, target) -> bool:
	if phase != "planning" or caster.team != 0 or not caster.data.skills.has(skill) or not can_use(caster, skill, target):
		return false
	plans[caster.uid] = {"caster": caster, "skill": skill, "target": target}
	return true

func ready_to_resolve() -> bool:
	for ally in living(0):
		if not plans.has(ally.uid):
			return false
	return phase == "planning"

func order_before(a: Dictionary, b: Dictionary) -> bool:
	var ai: int = a.caster.data.speed + a.skill.priority
	var bi: int = b.caster.data.speed + b.skill.priority
	if ai != bi:
		return ai > bi
	if a.caster.data.speed != b.caster.data.speed:
		return a.caster.data.speed > b.caster.data.speed
	return a.caster.uid < b.caster.uid

func timeline() -> Array:
	var actions: Array = plans.values() + intentions.values()
	actions = actions.filter(func(a): return not a.is_empty())
	actions.sort_custom(order_before)
	return actions

func begin_resolution() -> bool:
	if not ready_to_resolve():
		return false
	queue = timeline()
	phase = "resolving"
	return true

func report(target, text: String, kind: String) -> void:
	events.append({"target": target.uid, "text": text, "kind": kind})

func hurt(target, value: int) -> void:
	var absorbed: int = mini(target.shield, value)
	target.shield -= absorbed
	var actual: int = mini(target.hp, value - absorbed)
	target.hp -= actual
	report(target, "−%s" % actual + (" (%s escudo)" % absorbed if absorbed else ""), "damage")
	if target.hp == 0:
		report(target, "FUERA DE ESCENA", "down")

func check_end() -> bool:
	if living(0).is_empty() or living(1).is_empty():
		result = "draw" if living(0).is_empty() and living(1).is_empty() else ("victory" if living(1).is_empty() else "defeat")
		phase = "finished"
		queue.clear()
		return true
	return false

func step() -> Dictionary:
	events = []
	if phase != "resolving":
		return {}
	if queue.is_empty():
		var triggered: bool = beat >= law.beat_length
		if triggered:
			law.resolve(self)
			beat = 1
			beat_used = [false, false]
		else:
			beat += 1
		if not check_end():
			for unit in units:
				if unit.shield_expiry <= round_number:
					unit.shield = 0
				if unit.mark_expiry <= round_number:
					unit.marked = false
			round_number += 1
			plans.clear()
			phase = "planning"
			announce()
		return {"label": "DESENLACE DE LA LEY" if triggered else "CIERRE DE RONDA", "events": events.duplicate(), "caster": -1}
	var action: Dictionary = queue.pop_front()
	var caster = action.caster
	var target = action.target
	var skill: BattleSkill = action.skill
	var label: String = "%s · %s → %s" % [caster.data.display_name, skill.display_name, target.data.display_name]
	if not caster.alive():
		return {"label": label + " (fuera de escena)", "events": [], "caster": -1}
	# Guard persists until this unit's next action, including the next round.
	caster.guard = false
	if not can_use(caster, skill, target):
		report(caster, "SIN OBJETIVO VÁLIDO · SIN COSTE", "miss")
	else:
		caster.impulse -= skill.impulse_cost
		for effect in skill.effects:
			effect.apply(self, caster, target)
		caster.impulse = mini(3, caster.impulse + skill.impulse_gain)
	check_end()
	return {"label": label, "events": events.duplicate(), "caster": caster.uid, "target": target.uid}
