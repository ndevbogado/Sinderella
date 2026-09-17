extends SceneTree
var screen
var result_seen: bool = false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	screen = load("res://sinderella/scenes/battle.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.views.size() == 8)
	assert(screen.cards.size() == 4)
	assert(screen.skill_buttons.size() == 6)
	assert(screen.confirm.disabled)
	screen.select_skill(0)
	assert(screen.selected_skill.id == "crystal")
	screen.on_unit_clicked(4)
	assert(screen.state.plans.is_empty())
	assert(screen.pending_uid == 4 and not screen.last_preview.is_empty())
	screen.confirm_action()
	assert(screen.state.plans.size() == 1)
	assert(screen.active_uid == 1)
	screen.select_ally(0)
	screen.select_skill(5)
	screen.confirm_action()
	assert(screen.state.plans[0].skill.id == "guard")
	screen.auto_plan()
	assert(not screen.confirm.disabled)
	screen.action_delay = 0.001
	screen.reduced_motion = true
	await screen.resolve_round()
	assert(screen.state.round_number == 2)
	assert(not screen.busy)
	screen.show_help()
	assert(screen.overlay.visible)
	screen.overlay.hide()
	screen.start_battle(screen.encounter)
	assert(screen.state.round_number == 1 and screen.views.size() == 8)
	# Restart safely invalidates any asynchronous resolution from an old battle.
	screen.auto_plan()
	screen.resolve_round()
	screen.start_battle(screen.encounter)
	await create_timer(0.04).timeout
	assert(screen.state.round_number == 1 and not screen.busy)
	screen.battle_finished.connect(func(_r, _s): result_seen = true)
	for enemy in screen.state.living(1):
		enemy.hp = 1
	var rounds: int = 0
	while screen.state.phase != "finished" and rounds < 20:
		screen.auto_plan()
		await screen.resolve_round()
		rounds += 1
	assert(result_seen and screen.state.result == "victory")
	print("SCENE TESTS: selection, edit plan, resolution, restart, async cancellation, victory signal OK")
	# Free tweens before exit; no late callbacks to deleted views.
	screen.queue_free()
	await process_frame
	quit()
