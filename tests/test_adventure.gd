extends RefCounted
## Adventure state: exactly-once rewards, quest progress, save round trip,
## and world consequences applied idempotently on every visit.

var t


func test_once_grants_exactly_once() -> void:
	GameState.reset()
	var n := [0]
	t.check(GameState.once(&"reward_a", func() -> void: n[0] += 1), "first claim runs")
	t.check(not GameState.once(&"reward_a", func() -> void: n[0] += 1), "second claim refused")
	t.eq(n[0], 1, "grant ran once")


func test_quests_only_move_forward() -> void:
	GameState.reset()
	GameState.start_quest(Quests.MAIN)
	GameState.advance(Quests.MAIN, 3)
	GameState.advance(Quests.MAIN, 1)
	t.eq(GameState.quest_step(Quests.MAIN), 3, "cannot step backwards")
	GameState.advance(Quests.MAIN, -1)
	t.check(GameState.quest_done(Quests.MAIN), "finished")
	GameState.advance(Quests.MAIN, 5)
	t.check(GameState.quest_done(Quests.MAIN), "a finished quest stays finished")
	GameState.start_quest(Quests.MAIN)
	t.check(GameState.quest_done(Quests.MAIN), "restarting a finished quest does nothing")


func test_state_roundtrip() -> void:
	GameState.reset()
	GameState.wizard_name = "Alder"
	GameState.set_flag(&"isolde_home", "village")
	GameState.once(&"troll_reward")
	GameState.unlock(&"levitate")
	GameState.start_quest(&"fawn")
	GameState.learn_place(&"old_ward")
	var d: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(d)
	t.eq(GameState.wizard_name, "Alder", "name kept")
	t.eq(GameState.flag(&"isolde_home", ""), "village", "choice kept")
	t.check(not GameState.once(&"troll_reward"), "claimed rewards stay claimed after loading")
	t.check(GameState.has_unlock(&"levitate"), "unlock kept")
	t.eq(GameState.quest_step(&"fawn"), 0, "quest step kept")
	t.check(GameState.known.has(&"old_ward"), "known places kept")
	GameState.reset()


func test_restoration_applies_idempotently() -> void:
	GameState.reset()
	GameState.set_flag(&"ward_restored")
	GameState.set_flag(&"travelers_rescued")
	GameState.set_flag(&"isolde_home", "village")
	var v: Region = load("res://game/world/hearthmere.gd").new()
	t.world.add_child(v)
	await t.frames(1)
	v.apply_state()
	v.apply_state()
	t.check((v.wardlight.light as OmniLight3D).visible, "wardlight lit")
	for l: Dictionary in v.lanterns:
		t.check((l.light as OmniLight3D).visible, "lantern lit")
	for n in v.returnees:
		t.check(n.visible and n.enabled, "travellers are home")
	t.check(v.isolde.visible, "Isolde's stall is in the village")
	for r in v.road_roots:
		t.check(not r.visible, "roots cleared from the road")
	v.queue_free()
	GameState.reset()
