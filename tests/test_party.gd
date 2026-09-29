extends RefCounted
## Party membership, its limit, and loading Chapter 1 saves.

var t


func test_party_limit() -> void:
	GameState.reset()
	GameState.recruit(&"tamsin", true)
	GameState.recruit(&"kess", true)
	t.eq(GameState.party, [&"tamsin", &"kess"] as Array[StringName], "two can follow")
	GameState.recruit(&"orla", true)
	t.check(GameState.recruited.has(&"orla"), "a third can still be recruited")
	t.check(not GameState.in_party(&"orla"), "but waits at the camp")
	t.check(GameState.join_party(&"orla") != "", "joining a full party is refused")
	GameState.leave_party(&"tamsin")
	t.eq(GameState.join_party(&"orla"), "", "room again after someone rests")
	t.check(GameState.join_party(&"nobody") != "", "only recruited companions can join")
	GameState.reset()


func test_party_round_trip() -> void:
	GameState.reset()
	GameState.recruit(&"tamsin", false)
	GameState.recruit(&"kess", true)
	var d: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(d)
	t.check(GameState.recruited.has(&"tamsin") and GameState.recruited.has(&"kess"), "recruits kept")
	t.eq(GameState.party, [&"kess"] as Array[StringName], "party kept")
	GameState.reset()


func test_version1_save_migrates() -> void:
	var v1 := {"name": "Wren", "companion": {"recruited": true, "following": true},
		"inv": {"items": [{"uid": 1, "id": "stormcoil"}], "equipped": {"staff": 1}}}
	GameState.from_dict(v1)
	t.check(GameState.recruited.has(&"tamsin"), "Chapter 1's Tamsin stays recruited")
	t.eq(GameState.party, [&"tamsin"] as Array[StringName], "and still follows")
	t.eq(int(GameState.inv.find(1).tier), 1, "an untiered staff loads as tier I")
	GameState.from_dict({"companion": {"recruited": true, "following": false}})
	t.eq(GameState.party.size(), 0, "a resting Tamsin stays at the sanctuary")
	var junk := {"recruited": ["tamsin", "kess", "orla"], "party": ["tamsin", "kess", "orla", "tamsin", "ghost"]}
	GameState.from_dict(junk)
	t.eq(GameState.party, [&"tamsin", &"kess"] as Array[StringName], "a damaged party list is trimmed to recruits, no repeats, max 2")
	GameState.reset()
	t.eq(SaveSystem.VERSION, 2, "saves are version 2")


func test_companion_make() -> void:
	var a := Companion.make(&"tamsin")
	var b := Companion.make(&"kess")
	t.check(a is Shieldbearer and b is Scout, "each id makes its own kind")
	t.eq(a.display, "Tamsin", "Tamsin is named")
	t.eq(b.display, "Kess", "Kess is named")
	t.check(Companion.make(&"nobody") == null, "unknown ids make nothing")
	a.free()
	b.free()


func test_mark_used_by_one_spell_hit() -> void:
	GameState.reset()
	var p: Player = t.make_player("storm")
	await t.frames(2)
	var e: Enemy = t.make_enemy(Vector3(3, 0, 0))
	var ctrl: Enemy = t.make_enemy(Vector3(3, 0, 4))
	var spell := CastContext.new()
	spell.caster = p
	spell.data = SpellDB.get_spell(&"arc_lance")
	var hp_c := ctrl.health.hp
	spell.hit(ctrl, Damage.make(20.0, p, &"storm"))
	var plain := hp_c - ctrl.health.hp
	e.statuses.apply(&"mark", 8.0)
	var hp0 := e.health.hp
	spell.hit(e, Damage.make(20.0, p, &"storm"))
	t.near(hp0 - e.health.hp, plain * 1.25, "the marked hit deals +25%")
	t.check(not e.statuses.has(&"mark"), "the mark is used up")
	var hp1 := e.health.hp
	spell.hit(e, Damage.make(20.0, p, &"storm"))
	t.near(hp1 - e.health.hp, plain, "the next hit is normal")
	e.statuses.apply(&"mark", 8.0)
	var basic := CastContext.new()
	basic.caster = p
	basic.data = SpellDB.get_spell(&"storm_gust")
	basic.hit(e, Damage.make(7.0, p, &"storm"))
	t.check(e.statuses.has(&"mark"), "a staff attack leaves the mark for a spell")
	GameState.reset()


func test_kess_shoots_and_marks() -> void:
	GameState.reset()
	var p: Player = t.make_player("storm")
	var k := Companion.make(&"kess")
	t.world.add_child(k)
	k.global_position = Vector3(-1.5, 0, 0)
	var e: Enemy = t.make_enemy(Vector3(5, 0, 0))
	var hp0 := e.health.hp
	var marked := false
	for i in 240:
		await t.frames(1)
		marked = marked or e.statuses.has(&"mark")
	t.check(e.health.hp < hp0, "Kess's arrows hurt the enemy")
	t.check(marked, "within ~4 s one of her arrows marks it")
	t.check(k.is_alive(), "she's still standing")
	GameState.reset()
