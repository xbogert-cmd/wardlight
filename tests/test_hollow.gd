extends RefCounted
## Chapter 2's creatures: spore patches, the hidden Lurker, the moth's spores.

var t


func _spawn(script: GDScript, data: EnemyData, pos: Vector3) -> Enemy:
	var e: Enemy = script.new()
	e.data = data
	t.world.add_child(e)
	e.global_position = pos
	return e


func test_spore_patch_slows_then_fades() -> void:
	GameState.reset()
	var p: Player = t.make_player("fire")
	await t.frames(2)
	var sp := Husk.SporePatch.new()
	sp.radius = 1.6
	sp.life = 0.5
	t.world.add_child(sp)
	sp.global_position = Vector3(0.5, 0, 0)
	await t.frames(3)
	t.near(p.statuses.move_scale(), 0.6, "inside the spores the wizard walks 40% slower")
	p.global_position = Vector3(6, 0, 0)
	await t.frames(20)
	t.near(p.statuses.move_scale(), 1.0, "outside them, full speed again")
	await t.frames(20)
	t.check(not is_instance_valid(sp), "the patch is gone after its life")
	GameState.reset()


func test_husk_leaves_spores() -> void:
	var h := _spawn(Husk, preload("res://data/enemies/husk.tres"), Vector3(4, 0, 0))
	h.set_physics_process(false)
	await t.frames(1)
	h.take_hit(Damage.make(999.0, null, &"fire"))
	await t.frames(2)
	var found := false
	for n in t.world.get_children():
		found = found or n is Husk.SporePatch
	t.check(found, "a dead Husk leaves a spore patch")


func test_lurker_untouchable_while_hidden() -> void:
	var l := _spawn(Lurker, preload("res://data/enemies/lurker.tres"), Vector3(5, 0, 0))
	await t.frames(1)
	t.check(not l.is_in_group(&"enemy"), "a hidden Lurker can't be targeted")
	var hp := l.health.hp
	l.take_hit(Damage.make(30.0, null, &"storm"))
	t.near(l.health.hp, hp, "or hurt")
	l.set_state(&"exposed")
	l._show()
	l.take_hit(Damage.make(30.0, null, &"storm"))
	t.check(l.health.hp < hp, "exposed, it takes damage")
	t.check(l.is_in_group(&"enemy"), "and can be targeted")


func test_spore_pops_to_one_hit_without_rewards() -> void:
	GameState.reset()
	var p: Player = t.make_player("hex")
	var s: Spore = Spore.new()
	s.data = preload("res://data/enemies/spore.tres")
	s.target = p
	t.world.add_child(s)
	s.global_position = Vector3(6, 1, 0)
	await t.frames(1)
	var xp := GameState.inv.xp
	s.take_hit(Damage.make(1.0, p, &"hex"))
	t.check(not s.is_alive(), "any hit pops a spore")
	t.eq(GameState.inv.xp, xp, "no experience for spores")
	GameState.reset()
