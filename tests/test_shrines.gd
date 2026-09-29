extends RefCounted
## Chapter 2's lake shrines: their rewards (new relics, staff, robe) and the
## shrine areas' rules.

var t


func _wear(id: StringName, tier: int, slot: String) -> void:
	var it := GameState.inv.add(id, tier)
	GameState.inv.equip(slot, int(it.uid))


func test_bogheart_weakens_slows() -> void:
	GameState.reset()
	var p: Player = t.make_player("fire")
	await t.frames(1)
	p.statuses.apply(&"slow", 1.0, 0.4)
	t.near(p.statuses.move_scale(), 0.6, "without the pearl, a 40% slow")
	p.statuses.remove(&"slow")
	_wear(&"bogheart", 1, "relic1")
	p.statuses.apply(&"slow", 1.0, 0.4)
	t.near(p.statuses.move_scale(), 0.76, "tier I pearl: the slow is 40% weaker")
	p.statuses.remove(&"slow")
	GameState.reset()
	_wear(&"bogheart", 3, "relic1")
	p.statuses.apply(&"slow", 1.0, 0.4)
	t.near(p.statuses.move_scale(), 1.0, "tier III pearl: no slow at all")
	GameState.reset()


func test_lakeweave_below_half_health() -> void:
	GameState.reset()
	_wear(&"lakeweave", 1, "robe")
	var p: Player = t.make_player("fire")
	await t.frames(1)
	p.health.hp = 80.0
	p.take_hit(Damage.make(10.0, null, &""))
	t.near(p.health.hp, 70.0, "above half health: full damage")
	p._iframes = 0.0
	p.health.hp = 40.0
	p.take_hit(Damage.make(10.0, null, &""))
	t.near(p.health.hp, 31.0, "below half: 10% less")
	GameState.reset()


func test_vesper_candle_restores_mana_on_kills() -> void:
	GameState.reset()
	_wear(&"vesper_candle", 2, "relic1")
	var p: Player = t.make_player("fire")
	await t.frames(1)
	p.mana.mp = 0.0
	p.mana.regen = 0.0
	var e: Enemy = t.make_enemy(Vector3(3, 0, 0))
	e.take_hit(Damage.make(999.0, p, &"fire"))
	await t.frames(1)
	t.near(p.mana.mp, 5.0, "a tier II candle gives 5 mana per kill")
	GameState.reset()


func test_shrine_relics_are_not_random_drops() -> void:
	var drops := Items.drop_relics()
	for id: StringName in [&"vesper_candle", &"bogheart", &"stillwater"]:
		t.check(not drops.has(id), "%s is a shrine reward only" % id)
		t.check(Items.fusable(id), "%s still fuses" % id)
	t.check(drops.has(&"moonstone"), "Chapter 1 relics still drop")


func test_reedwhistle_slows() -> void:
	GameState.reset()
	_wear(&"reedwhistle", 3, "staff")
	var ctx := CastContext.new()
	var d := Damage.make(5.0, null, &"")
	var e: Enemy = t.make_enemy(Vector3(3, 0, 0))
	ctx._staff_identity(e, d)
	t.eq(d.statuses.size(), 1, "the staff adds a slow")
	t.near(float(d.statuses[0].power), 0.4, "tier III slows by 40%")
	GameState.reset()
