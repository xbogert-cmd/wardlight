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


## Every walk-off exit must be reachable inside the edge walls, lead to an
## entry that exists, and no entry may stand inside an exit.
func test_exits_reachable() -> void:
	var reach := 0.3 + 0.32 + 0.05   # half wall + wizard radius + slack
	var paths: Dictionary = load("res://game/main.gd").REGIONS
	var regions := {}
	for id: StringName in paths:
		var r: Region = load(paths[id]).new()
		r._layout()
		regions[id] = r
	for id: StringName in regions:
		var r: Region = regions[id]
		for ex: Dictionary in r.exits:
			t.check((ex.rect as Rect2).intersects(r.bounds.grow(-reach)), "%s exit to %s can be walked into" % [id, ex.to])
			t.check((regions[ex.to] as Region).entries.has(ex.entry), "%s exit to %s:%s has a landing" % [id, ex.to, ex.entry])
		for en: StringName in r.entries:
			var p: Vector3 = r.entries[en][0]
			for ex: Dictionary in r.exits:
				t.check(not (ex.rect as Rect2).has_point(Vector2(p.x, p.z)), "%s entry %s is clear of exits" % [id, en])
	for r: Region in regions.values():
		r.free()
