extends RefCounted
## Passives and the bounded spell interactions.

var t


func _ctx(p: Player, id: StringName) -> CastContext:
	var c := CastContext.new()
	c.caster = p
	c.data = SpellDB.get_spell(id)
	c.native = p.wiz.is_native(c.data.school)
	c.power = p.wiz.affinity_mult(c.data.school)
	c.world = p.get_parent()
	return c


func test_heat_one_charge_per_cast_and_spend() -> void:
	var p: Player = t.make_player("fire")
	var e: Enemy = t.make_enemy(Vector3(2.5, 0, 0))
	await t.frames(2)
	var c := _ctx(p, &"cinder_fan")
	for k in 3:
		c.hit(e, c.dmg())
	t.eq(p.passives.heat, 1, "a cast awards at most one charge")
	for k in 2:
		var c2 := _ctx(p, &"ember_spear")
		c2.hit(e, c2.dmg())
	t.eq(p.passives.heat, 3, "capped at three")
	var c3 := _ctx(p, &"ember_spear")
	p.passives.on_release(c3)
	t.eq(p.passives.heat, 0, "next damaging native fire spell spends them")
	t.near(c3.power, 1.45, "+15% per charge")
	c3.hit(e, c3.dmg())
	t.eq(p.passives.heat, 0, "spending cast does not grant a new charge")


func test_only_active_school_passive() -> void:
	var p: Player = t.make_player("hex")
	p.wiz.unlocked[&"arc_lance"] = true
	p.wiz.unlocked[&"ember_spear"] = true
	var e: Enemy = t.make_enemy(Vector3(2.5, 0, 0))
	await t.frames(2)
	for k in 4:
		var c := _ctx(p, &"arc_lance")
		c.hit(e, c.dmg())
		var f := _ctx(p, &"ember_spear")
		f.hit(e, f.dmg())
	t.eq(p.passives.storm_count, 0, "storm passive inactive as hexbinder")
	t.eq(p.passives.heat, 0, "fire passive inactive as hexbinder")


func test_conduction_every_third_cast_no_recursion() -> void:
	var p: Player = t.make_player("storm")
	var a: Enemy = t.make_enemy(Vector3(2.5, 0, 0))
	var b: Enemy = t.make_enemy(Vector3(4.2, 0, 0))
	await t.frames(2)
	a.health.hp = 9999.0  # keep the first target alive through all casts
	var hp_b := b.health.hp
	for k in 2:
		var c := _ctx(p, &"arc_lance")
		c.hit(a, c.dmg())
		c.hit(a, c.dmg())  # a second hit in the same cast does not count again
	t.eq(p.passives.storm_count, 2, "each cast counted once")
	t.near(b.health.hp, hp_b, "no chain before the third cast")
	var c3 := _ctx(p, &"arc_lance")
	c3.hit(a, c3.dmg())
	t.eq(p.passives.storm_count, 0, "counter resets on the third cast")
	t.near(b.health.hp, hp_b - SpellDB.get_spell(&"arc_lance").damage * 0.5, "one reduced chain to the nearby enemy")


func test_grave_current_bounded() -> void:
	var p: Player = t.make_player("fire")
	p.wiz.unlocked[&"arc_lance"] = true
	var a: Enemy = t.make_enemy(Vector3(2.5, 0, 0))
	var b: Enemy = t.make_enemy(Vector3(4.2, 0, 0))
	var c: Enemy = t.make_enemy(Vector3(5.8, 0, 0))
	b.statuses.apply(&"curse", 5.0)
	c.statuses.apply(&"curse", 5.0)
	await t.frames(2)
	var hb := b.health.hp
	var hc := c.health.hp
	var ctx := _ctx(p, &"arc_lance")
	ctx.hit(a, ctx.dmg())
	t.check(b.health.hp < hb, "lightning conducted to the nearest cursed enemy")
	t.near(c.health.hp, hc, "chain count bounded to one")


func test_haunted_ember_once_per_victim() -> void:
	var p: Player = t.make_player("fire")
	var v: Enemy = t.make_enemy(Vector3(2.5, 0, 0))
	await t.frames(2)
	v.statuses.apply(&"burn", 5.0, 1.0, p)
	v.statuses.apply(&"curse", 5.0)
	var embers_before := _count_embers()
	var d := Damage.make(999.0, p, &"fire")
	v.take_hit(d)
	t.eq(_count_embers() - embers_before, 1, "one spectral ember released")
	Interactions.on_enemy_died(v, d)
	t.eq(_count_embers() - embers_before, 1, "never a second ember from the same victim")
	var v2: Enemy = t.make_enemy(Vector3(5.0, 0, 0))
	v2.statuses.apply(&"burn", 5.0, 1.0, p)
	v2.statuses.apply(&"curse", 5.0)
	var ember_hit := Damage.make(999.0, p, &"hex")
	ember_hit.spell_id = &"haunted_ember"
	ember_hit.is_proc = true
	var n := _count_embers()
	v2.take_hit(ember_hit)
	t.eq(_count_embers(), n, "ember damage cannot spawn more embers")


func _count_embers() -> int:
	var n := 0
	for node in (Engine.get_main_loop() as SceneTree).root.find_children("*", "Projectile", true, false):
		if node.style == &"spectral":
			n += 1
	return n


func test_soul_echo_capped() -> void:
	var p: Player = t.make_player("hex")
	await t.frames(2)
	p.health.hp = 50.0
	for k in 3:
		var e: Enemy = t.make_enemy(Vector3(2.5 + k * 0.8, 0, 0))
		e.statuses.apply(&"curse", 5.0)
		e.take_hit(Damage.make(999.0, p, &"hex"))
	t.near(p.health.hp, 55.0, "only one recovery pulse per second")


## Area spells act where they were aimed, not at the world origin (their
## nodes must be placed before they enter the tree).
func test_area_spells_land_at_aim_point() -> void:
	var p: Player = t.make_player("hex")
	var far: Enemy = t.make_enemy(Vector3(6, 0, -3))
	var near_origin: Enemy = t.make_enemy(Vector3(0.5, 0, 0.5))
	await t.frames(2)
	var hp_far := far.health.hp
	var hp_near := near_origin.health.hp
	var c := _ctx(p, &"binding_roots")
	c.aim_point = far.global_position
	(c.data.effect.new() as SpellEffect).cast(c)
	await t.frames(40)
	t.check(far.statuses.has(&"root"), "roots hold the enemy at the aimed spot")
	t.check(far.health.hp < hp_far, "roots damage the enemy at the aimed spot")
	t.eq(near_origin.health.hp, hp_near, "nothing happens at the world origin")
	p.queue_free()
	far.queue_free()
	near_origin.queue_free()


func test_curse_amplifies_damage() -> void:
	var a: Enemy = t.make_enemy(Vector3(3, 0, 0))
	var b: Enemy = t.make_enemy(Vector3(-3, 0, 0))
	await t.frames(1)
	b.statuses.apply(&"curse", 5.0)
	a.take_hit(Damage.make(10.0, null, &"fire"))
	b.take_hit(Damage.make(10.0, null, &"fire"))
	t.near(a.health.max_hp - a.health.hp, 10.0, "plain hit")
	t.near(b.health.max_hp - b.health.hp, 10.0 * Statuses.CURSE_MULT, "cursed target takes more")
	a.queue_free()
	b.queue_free()


## Chapter 2's lake spells: the chain weakens as it leaps; the grasp drags
## toward its centre and slows.
func test_chain_current_leaps_and_weakens() -> void:
	var p: Player = t.make_player("storm")
	var es: Array[Enemy] = []
	for k in 3:
		es.append(t.make_enemy(Vector3(4 + k * 2.5, 0, 0)))
	await t.frames(2)
	var c := _ctx(p, &"chain_current")
	c.target = es[0]
	c.aim_point = es[0].global_position
	(c.data.effect.new() as SpellEffect).cast(c)
	await t.frames(30)
	var lost: Array = es.map(func(e: Enemy) -> float: return e.health.max_hp - e.health.hp)
	t.check(lost[0] > 0.0 and lost[1] > 0.0 and lost[2] > 0.0, "the bolt reaches all three")
	t.check(lost[0] > lost[1] and lost[1] > lost[2], "each jump is weaker (%s)" % str(lost))
	p.queue_free()


func test_drowning_grasp_drags_and_slows() -> void:
	var p: Player = t.make_player("hex")
	var e: Enemy = t.make_enemy(Vector3(6.5, 0, 0))
	await t.frames(2)
	var c := _ctx(p, &"drowning_grasp")
	c.aim_point = Vector3(4.5, 0, 0)
	(c.data.effect.new() as SpellEffect).cast(c)
	t.check(e.statuses.has(&"slow"), "the grasped enemy is slowed")
	t.check(e._knock.x < -1.0, "and dragged toward the centre")
	p.queue_free()
