extends Region
## The Old Ward: ruins on a misty rise, reached by waystone. A path climbs
## north through broken walls (two mixed encounters) to a checkpoint and the
## round plaza where the corrupted guardian stands before the choked ward
## stone. Cleansing it relights the ward (and with it Hearthmere's
## wardlight), withers the roots and leaves the guardian's gift.

const ARENA := Vector2(0, -30)
const ARENA_R := 9.5

var ward: Dictionary
var guardian: Guardian
var arena_wall: StaticBody3D
var roots: Array[Node3D] = []
var home_stone: Interactable


func _layout() -> void:
	id = &"old_ward"
	display_name = "The Old Ward"
	music = "ruins"
	env_preset = &"ruins"
	seed_value = 313
	origin = Vector2(-40, -54)
	grid = Vector2i(80, 84)
	bounds = Rect2(-17, -41, 34, 53)
	paths = [[Vector2(0, 10), Vector2(-1.5, 2), Vector2(1.5, -6), Vector2(-0.5, -14), Vector2(0, -21)]]
	hills = [[-14, 4, 3.0, 6.0], [13, -4, 3.5, 6.5], [-12, -16, 2.5, 6.0], [14, -20, 3.0, 6.0], [0, -44, 5.0, 8.0]]
	pads = [[ARENA.x, ARENA.y, ARENA_R + 0.5, 1.2], [0, 8, 3.0, 0.0]]
	dirt_spots = [[ARENA.x, ARENA.y, ARENA_R + 1.5], [0, -2, 4.0], [0, -14, 4.0]]
	entries = {&"waystone": [Vector3(1.8, 0, 7.0), -1.0], &"start": [Vector3(1.8, 0, 7.0), -1.0]}
	respawn_entry = &"waystone"
	spawns = [[&"raider", -1.5, -3.0], [&"hexer", 2.5, -6.5], [&"hound", 5.0, -1.0], [&"knot", -4.5, -13.0], [&"sentinel", 2.0, -15.5]]
	if not GameState.flag(&"guardian_defeated"):
		spawns.append([&"guardian", ARENA.x, ARENA.y - 1.0])


func _build() -> void:
	home_stone = waystone(-1.5, 9.5, "Travel home to Briarwood")
	home_stone.activated.connect(func(_p: Player) -> void: exit_requested.emit(&"briarwood", &"waystone"))
	# broken walls and pillars along the climb
	for w: Array in [[-5.0, 3.0, 4.0, 0.0], [5.5, -1.5, 3.0, 0.4], [-5.5, -8.0, 3.5, -0.3], [6.0, -11.0, 4.0, 0.2], [-4.0, -18.0, 3.0, 0.1], [4.5, -18.5, 3.0, -0.2]]:
		var g := _ground(w[0], w[1])
		box(Vector3(w[2], randf_range(1.0, 2.2), 0.7), g + Vector3(0, 0.6, 0), "bricks.png", Vector3(0, w[3], 0))
	for p: Vector2 in [Vector2(-3.0, 0.0), Vector2(3.5, -4.0), Vector2(-3.5, -11.0), Vector2(3.0, -9.0), Vector2(-2.5, -20.5), Vector2(2.5, -20.5)]:
		var h := randf_range(2.0, 4.0)
		box(Vector3(0.8, h, 0.8), _ground(p.x, p.y) + Vector3(0, h * 0.5 - 0.2, 0), "rune_bricks.png", Vector3(0, randf(), randf_range(-0.08, 0.08)))
	checkpoint_stone(1.5, -21.5, &"arena")
	chest(-7.0, -10.2, &"chest_old_ward", [[&"whisper_bone"], [&"moonstone"]], 25, -0.3)
	# the plaza: a ring of low broken wall with a gap to the south
	for k in 20:
		var a := k * TAU / 20.0
		if absf(wrapf(a - PI / 2, -PI, PI)) < 0.35:
			continue
		var p := ARENA + Vector2(cos(a), sin(a)) * (ARENA_R + 0.6)
		box(Vector3(2.8, randf_range(0.6, 1.3), 0.6), _ground(p.x, p.y) + Vector3(0, 0.4, 0), "bricks.png", Vector3(0, -a + PI / 2, 0))
	ward = ward_stone(ARENA.x, ARENA.y - 6.0, GameState.flag(&"guardian_defeated"), true)
	for k in 26:
		var a := randf() * TAU
		var r := sqrt(randf()) * ARENA_R
		var root := bill(load(D + ("roots.png" if k % 3 else "thorns.png")), _ground(ARENA.x + cos(a) * r, ARENA.y + sin(a) * r), randf_range(0.8, 1.3))
		roots.append(root)
	for k in 10:
		var a := k * TAU / 10.0
		roots.append(bill(load(D + "roots.png"), _ground(ARENA.x + cos(a) * 1.2, ARENA.y - 6.0 + sin(a) * 1.0), 1.3))
	var keep := func(p: Vector2) -> bool:
		return path_dist(p) > 3.0 and p.distance_to(ARENA) > ARENA_R + 2.5
	trees(Rect2(-34, -50, 68, 70), 80, func(p: Vector2) -> bool: return keep.call(p) and (not bounds.grow(-2.0).has_point(p) or rng.randf() < 0.3),
		["dead_tree.png", "pine_b.png", "dead_tree.png", "pine_a.png"])
	scenery(Rect2(-17, -41, 34, 53), 170, func(p: Vector2) -> bool: return path_dist(p) > 1.4 and p.distance_to(ARENA) > 2.0,
		["roots", "rock_s", "rock_l", "tuft_c", "shrooms", "stump", "roots", "fern"])
	# drifting mist motes
	var t := Timer.new()
	t.wait_time = 0.08
	t.autostart = true
	t.timeout.connect(func() -> void:
		if player:
			var at := player.global_position + Vector3(randf_range(-14, 14), randf_range(0.2, 2.0), randf_range(-10, 6))
			FX3.burst(at, 1, [Color("a898d8", 0.25), Color("8878b8", 0.18), Color("685898", 0.1)], Vector2(0.1, 0.3), Vector2(2.0, 3.5), {"size": 3.0}))
	add_child(t)
	arena_wall = StaticBody3D.new()
	add_child(arena_wall)
	_wall(arena_wall, Vector3(ARENA.x, 0, ARENA.y + ARENA_R + 1.2), Vector3(5.0, 40, 0.6))
	arena_wall.collision_layer = 0


func spawn(kind: StringName, x: float, z: float) -> Enemy:
	var e := super.spawn(kind, x, z)
	if kind == &"guardian":
		guardian = e as Guardian
		guardian.died.connect(func(_e: Enemy) -> void: _cleansed())
		guardian.phase_changed.connect(func(_p: int) -> void:
			var hud := get_tree().get_first_node_in_group(&"hud") as HUD
			if hud:
				hud.banner("The Warden's ward-stones crack"))
	return e


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# seal the plaza while the guardian fights
	if guardian and is_instance_valid(guardian):
		var sealed := guardian.engaged and guardian.is_alive() and player and player.is_alive() \
			and Vector2(player.global_position.x, player.global_position.z).distance_to(ARENA) < ARENA_R
		arena_wall.collision_layer = INVISIBLE if sealed else 0


func _on_respawn() -> void:
	arena_wall.collision_layer = 0


func _cleansed() -> void:
	GameState.set_flag(&"guardian_defeated")
	GameState.set_flag(&"ward_restored")
	GameState.advance(Quests.MAIN, 6)
	arena_wall.collision_layer = 0
	await get_tree().create_timer(1.2).timeout
	set_ward(ward, true)
	ward_flare(ward)
	for r in roots:
		var tw := r.create_tween()
		tw.tween_property(r, "position:y", r.position.y - 1.5, 1.4).set_delay(randf() * 0.8)
	var ramp := [Color("ffffff"), Color("d8f8ff"), Color("9ae8ff"), Color("3a78c0")]
	for k in 5:
		SpellEffect.later(0.25 * k, func() -> void:
			FX3.ring(_ground(ARENA.x, ARENA.y) + Vector3(0, 0.1, 0), 0.5, ARENA_R + k * 2.0, 0.8, ramp, 2.0))
	var at := _ground(ARENA.x, ARENA.y - 1.0) + Vector3(0, 1.0, 0)
	GameState.once(&"wardheart", func() -> void:
		GameState.set_flag(&"mana_bonus", 20.0)
		player.apply_bonuses()
		player.mana.refill()
		give(&"wardweave")
		give(&"moonstone")
		give_point(2)
		FX3.burst(at, 40, [Color("fff0c0"), Color("f0c870"), Color("a07840")], Vector2(1.0, 4.0), Vector2(0.5, 1.0), {"gravity": 3.0})
		SaveSystem.autosave())
	await get_tree().create_timer(1.6).timeout
	var lines := [
		["", "The roots slacken. Light climbs the ward stone, and the guardian's shape softens into moss and pale glow."],
		["", "For a moment its carved face turns to you, and it bows. Then it is only an old tree, standing guard again."],
		["", "Where it stood lies a warm stone heart, humming with the ward's light (+20 mana), and the guardian's gifts."],
	]
	await Dialogue.i.talk(lines)


func apply_state() -> void:
	if GameState.flag(&"guardian_defeated"):
		set_ward(ward, true)
		for r in roots:
			r.visible = false
