extends SceneTree
var checks: int = 0
var failures: int = 0
var fixture: BattleEncounter

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func skill(id: String) -> BattleSkill:
	return load("res://sinderella/data/skills/" + id + ".tres")

func fresh() -> BattleState:
	return BattleState.new(fixture)

func _initialize() -> void:
	fixture = load("res://sinderella/data/encounter.tres")
	var s = fresh()
	check(s.units.size() == 8, "4 vs 4")
	check(s.intentions.size() == 4, "four announced intentions")
	check(s.units[0].hp == 90 and s.units[0].impulse == 1, "initial stats")
	check(not s.begin_resolution(), "cannot confirm incomplete plan")
	check(not s.plan(s.units[0], skill("heal"), s.units[0]), "cannot use unequipped skills")
	check(not s.can_use(s.units[0], skill("cut"), s.units[1]), "enemy targeting")
	check(not s.can_use(s.units[0], skill("midnight"), s.units[4]), "cost and contradiction requirements")
	var d: DamageEffect = skill("cut").effects[0]
	check(d.amount(s, s.units[0], s.units[4]) == 19, "physical formula")
	s.units[4].guard = true
	check(d.amount(s, s.units[0], s.units[4]) == 12, "guard 40 percent")
	s.units[4].guard = false
	s.units[4].echo = "Intruso"
	check(s.is_contradiction(s.units[4]), "opposed roles create contradiction")
	check(d.amount(s, s.units[0], s.units[4]) == 24, "contradiction 25 percent")
	s.units[4].echo = ""
	var before: int = s.units[4].hp
	s.units[4].shield = 8
	s.hurt(s.units[4], 20)
	check(s.units[4].hp == before - 12 and s.units[4].shield == 0, "shield absorbs damage")
	s.units[0].hp = 89
	skill("heal").effects[0].apply(s, s.units[3], s.units[0])
	check(s.units[0].hp == 90, "healing capped")
	skill("shield").effects[0].apply(s, s.units[2], s.units[0])
	var shield_value: int = s.units[0].shield
	skill("shield").effects[0].apply(s, s.units[2], s.units[0])
	check(s.units[0].shield == shield_value, "shields do not stack")
	s = fresh()
	skill("swap").effects[0].apply(s, s.units[0], s.units[4])
	check(s.units[0].role == "Guardián" and s.units[4].role == "Intruso", "swap principal roles")
	skill("echo").effects[0].apply(s, s.units[0], s.units[4])
	check(s.is_contradiction(s.units[4]), "echo creates contradiction after swap")
	before = s.units[4].hp
	s.law.resolve(s)
	check(s.units[4].hp == before - 32, "broken law")
	check(s.units[4].echo.is_empty(), "echo cleanup after law")
	check(s.units[0].hp == 90, "former intruder no longer hit")
	s = fresh()
	s.units[3].impulse = 3
	check(not s.can_use(s.units[3], skill("delay"), s.units[3]), "cannot delay beat one")
	s.beat = 3
	check(s.can_use(s.units[3], skill("delay"), s.units[3]), "can delay final beat")
	skill("delay").effects[0].apply(s, s.units[3], s.units[3])
	check(s.beat == 2 and not s.can_use(s.units[3], skill("delay"), s.units[3]), "one beat change per cycle")
	s = fresh()
	for ally in s.living(0):
		s.plan(ally, skill("guard"), ally)
	check(s.ready_to_resolve(), "all allied plans ready")
	check(s.timeline()[0].caster == s.units[1], "priority plus speed order")
	s.begin_resolution()
	var step_count: int = 0
	while s.phase == "resolving" and step_count < 20:
		s.step()
		step_count += 1
	check(step_count == 9 and s.round_number == 2 and s.beat == 2, "eight actions plus closure")
	check(s.units[0].impulse == 2, "generator impulse")
	check(s.plans.is_empty(), "clear plans between rounds")
	check(s.units[0].guard, "guard persists until next action")
	# Dead targets are not silently redirected and don't consume impulse.
	s = fresh()
	s.units[0].impulse = 3
	s.units[4].echo = "Intruso"
	s.queue = [{"caster": s.units[0], "skill": skill("midnight"), "target": s.units[4]}]
	s.phase = "resolving"
	s.units[4].hp = 0
	s.step()
	check(s.units[0].impulse == 3, "invalid target has no cost")
	# Defeat and victory are actually reachable, not a visual mockup.
	s = fresh()
	for enemy in s.living(1):
		enemy.hp = 0
	check(s.check_end() and s.result == "victory", "victory state")
	s = fresh()
	for ally in s.living(0):
		ally.hp = 0
	check(s.check_end() and s.result == "defeat", "defeat state")
	check(fixture.allies[0].max_hp == 90 and fixture.allies[0].starting_role == "Intruso", "resource definitions not mutated")
	# Deterministic full simulation and bounds, twice.
	var first: String = simulate()
	var second: String = simulate()
	check(first == second, "repeatable simulation")
	print("TESTS: %s checks, %s failures. Simulation: %s" % [checks, failures, first])
	quit(1 if failures else 0)

func simulate() -> String:
	var s = fresh()
	var steps: int = 0
	while s.phase != "finished" and s.round_number <= 40:
		for ally in s.living(0):
			var a: Dictionary = s.choose_ai(ally)
			check(not a.is_empty(), "AI has a valid action")
			s.plan(ally, a.skill, a.target)
		check(s.begin_resolution(), "AI full plan resolves")
		while s.phase == "resolving":
			s.step()
			steps += 1
			for u in s.units:
				check(u.hp >= 0 and u.hp <= u.data.max_hp and u.impulse >= 0 and u.impulse <= 3 and u.shield >= 0, "state invariants")
	check(s.phase == "finished", "simulation terminates")
	return "%s / round %s / steps %s / HP %s" % [s.result, s.round_number, steps, s.units.map(func(u): return u.hp)]
