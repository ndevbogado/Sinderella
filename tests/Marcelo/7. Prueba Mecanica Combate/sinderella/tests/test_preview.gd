extends SceneTree
var count: int = 0
var failures: int = 0
var encounter: BattleEncounter

func check(value: bool, message: String) -> void:
	count += 1
	if not value:
		failures += 1
		printerr("FAIL " + message)

func _initialize() -> void:
	encounter = load("res://sinderella/data/encounter.tres")
	call_deferred("run")

func skill(id: String) -> BattleSkill:
	return load("res://sinderella/data/skills/" + id + ".tres")

func run() -> void:
	var s = BattleState.new(encounter)
	s.units[0].hp = 89
	var p: Dictionary = s.preview_action(s.units[3], skill("heal"), s.units[0])
	check(p.hp_after == 90 and p.hp_before == 89, "healing is capped at max HP")
	check(s.units[0].hp == 89 and s.units[3].impulse == 1 and s.events.is_empty(), "preview has no side effects")
	s.units[0].shield = 60
	p = s.preview_action(s.units[2], skill("shield"), s.units[0])
	check(p.shield_before == 60 and p.shield_after == 60, "shield keeps larger existing amount")
	s.units[4].shield = 50
	p = s.preview_action(s.units[0], skill("cut"), s.units[4])
	check(p.hp_before == p.hp_after and p.shield_after < 50, "damage fully absorbed by shield")
	s.units[4].shield = 0
	s.units[4].hp = 2
	p = s.preview_action(s.units[0], skill("cut"), s.units[4])
	check(p.hp_before - p.hp_after == 2, "overkill does not claim more lost HP than exists")
	p = s.preview_action(s.units[0], skill("midnight"), s.units[4])
	check(p.is_empty(), "invalid action has no forecast")
	# Compare every valid effect combination against a real single-action resolution.
	for actor_index in 4:
		for ability in encounter.allies[actor_index].skills:
			for target_index in 8:
				s = BattleState.new(encounter)
				s.beat = 3
				for u in s.units:
					u.hp -= 12
					u.shield = 7
					u.impulse = 3
					u.guard = true
					u.marked = true
				s.units[4].echo = "Intruso"
				var actor = s.units[actor_index]
				var target = s.units[target_index]
				if not s.can_use(actor, ability, target):
					continue
				p = s.preview_action(actor, ability, target)
				s.queue = [{"caster": actor, "skill": ability, "target": target}]
				s.phase = "resolving"
				s.step()
				check(p.hp_after == target.hp and p.shield_after == target.shield and p.impulse_after == actor.impulse and p.role_after == target.role and p.echo_after == target.echo and p.beat_after == s.beat, "forecast matches actual effects: " + ability.id)
	# UI regression: reproduce the screenshot's texture-size and health-bar problems.
	var screen = load("res://sinderella/scenes/battle.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	for view in screen.views.values():
		check(view.art.size == Vector2(220, 144), "native texture cannot enlarge the sprite")
		check(view.hp.size.y == 8, "HP bar stays thin")
		check(view.art.get_rect().end.y < view.name_label.position.y, "art does not overlap name")
		check(view.position.y + view.size.y <= 690, "unit fits above party cards")
	for uid in screen.cards:
		check(screen.cards[uid].bar.size.y == 9, "party HP bar stays thin")
	screen.select_skill(0)
	screen.on_unit_clicked(4)
	check(screen.state.plans.is_empty() and screen.state.units[0].impulse == 1, "target selection doesn't commit or spend")
	check(screen.views[0].is_active and screen.views[4].is_target, "actor and enemy visibly selected")
	screen.on_unit_hovered(5)
	check(screen.pending_uid == 4, "hover cannot silently change selected target")
	check(screen.views[4].effect_label.text.contains("VIDA"), "on-target damage forecast")
	# Heal preview is also persistent and shows actual recovery.
	screen.select_ally(3)
	screen.state.units[0].hp = 80
	screen.select_skill(1)
	screen.on_unit_clicked(0)
	check(screen.last_preview.hp_after == 90, "UI actual healing amount")
	check(screen.views[3].is_active and screen.views[0].is_target, "healer and ally separately highlighted")
	check(screen.views[0].effect_label.text == "+10 VIDA", "capped healing printed on ally")
	screen.confirm_action()
	check(screen.state.plans.has(3) and screen.state.units[0].hp == 80, "add to plan does not execute heal")
	screen.select_ally(2)
	screen.select_skill(2)
	screen.on_unit_clicked(0)
	check(screen.last_preview.shield_after == 24, "shield preview")
	check(screen.views[0].effect_label.text == "+24 ESCUDO", "on-target shield forecast")
	# Check text layout for each valid equipped action and representative target.
	for u in screen.state.living(0):
		u.impulse = 3
	for a in screen.state.living(0):
		for index in a.data.skills.size():
			screen.state.beat = 3
			screen.state.units[4].echo = "Intruso"
			screen.select_ally(a.uid)
			screen.select_skill(index)
			await process_frame
			await process_frame
			if screen.selected_skill:
				check(screen.preview_text.get_content_height() <= screen.preview_text.size.y, "preview fits: " + a.data.skills[index].id + " height=" + str(screen.preview_text.get_content_height()))
				check(screen.skill_buttons[index].size.x <= 276, "skill button fits panel")
	screen.queue_free()
	await process_frame
	print("PREVIEW/UI: %s checks, %s failures" % [count, failures])
	quit(1 if failures else 0)
