extends Region
## Briarwood Road: the plateau road east of Hearthmere, over a stream and past
## a ruined rune arch, into a rock-walled gorge that ends at a broken gate and
## the waystone. Holds the roadside ward (relight it), the fallen trunk
## (lift it), the frightened fawn (calm it: levitation), a ledge over the
## cliff only a levitating wizard can reach, the Gatebreaker troll, and the
## missing travellers.

const CLIFF_GAP := Vector2(-5.0, -1.0)   # x range with no cliff wall (levitation ledge)
const LEDGE := Vector2(-3.0, -20.0)

var side_path := [Vector2(-7, 5), Vector2(-11, 1), Vector2(-15.5, -2.2)]
var ruins := Vector2(-17, -3)
var road_ward: Dictionary
var near_lanterns: Array = []
var trunk: Node3D
var fawn: Npc
var isolde: Npc
var traveler: Npc
var troll: Enemy
var gate_stone: Interactable
var tamsin: Npc
var tamsin_thorns: Array[PixelBillboard] = []


func _layout() -> void:
	id = &"briarwood"
	display_name = "Briarwood Road"
	env_preset = &"night"
	seed_value = 4242
	origin = Vector2(-50, -90)
	grid = Vector2i(112, 122)
	bounds = Rect2(-26, -30, 72, 52)
	roads = [[Vector2(-26, 20), Vector2(-15, 11), Vector2(-7, 5), Vector2(1, 1), Vector2(6.5, -1.5), Vector2(13, -5), Vector2(20, -9),
		Vector2(28, -12), Vector2(36, -12.4), Vector2(44, -12)]]
	paths = [side_path]
	streams = [{"pts": [Vector2(27, 21), Vector2(15, 9), Vector2(7, 1.8), Vector2(3.8, -0.5), Vector2(2.0, -6), Vector2(0.8, -12), Vector2(0.3, -17.5)],
		"width": 1.4, "depth": 1.5, "stop": func(b: Vector2) -> bool: return b.y < _cliff_z(b.x) + 0.3}]
	hills = [[ruins.x, ruins.y, 2.4, 6.5], [18, -5, 1.4, 5.5], [-3, -15, 0.9, 5.0]]
	dirt_spots = [[ruins.x, ruins.y, 4.0], [34, -12, 5.0]]
	entries = {&"west": [Vector3(-22.5, 0, 17.5), 1.0], &"start": [Vector3(-22.5, 0, 17.5), 1.0], &"waystone": [Vector3(39, 0, -11), -1.0],
		&"ward": [Vector3(-9.5, 0, 11.5), 1.0]}
	exits = [{"rect": Rect2(-27, 13, 2.2, 10), "to": &"hearthmere", "entry": &"east"}]
	respawn_entry = &"west"
	spawns = [[&"hound", 9.0, -4.0], [&"hound", 13.0, 1.0], [&"raider", 18.5, -6.8], [&"hexer", 21.5, -3.5], [&"knot", -14.0, 4.5]]
	if not GameState.flag(&"troll_defeated"):
		spawns.append([&"troll", 33.5, -12.2])


## The chasm between the cliff edge and the rock pillar.
func is_hazard(p: Vector3) -> bool:
	return p.x > CLIFF_GAP.x - 0.6 and p.x < CLIFF_GAP.y + 0.6 and p.z < _cliff_z(p.x) - 0.2 \
		and Vector2(p.x, p.z).distance_to(LEDGE) > 1.5


func _cliff_z(x: float) -> float:
	return -16.0 + 1.8 * sin(x * 0.17) + 0.8 * sin(x * 0.41 + 1.0)


## Southern rock ridge that walls the gorge east of the shelf.
func _ridge_z(x: float) -> float:
	return -8.4 - clampf((x - 21.0) * 0.2, 0.0, 1.6)


func _shape(x: float, z: float, h: float) -> float:
	# a steep-sided rock shelf (natural high ground) east of the bridge
	var shelf := smoothstep(0.9, 0.0, maxf(absf(x - 21.5) - 2.2, 0.0)) * smoothstep(0.9, 0.0, maxf(absf(z + 3.5) - 1.8, 0.0))
	h += shelf * 1.6
	# the gorge's southern rock wall
	var rz := _ridge_z(x)
	# low but sheer: taller hides the road from the camera, gentler lets walkers round the trunk
	h += 1.6 * smoothstep(rz, rz + 0.6, z) * smoothstep(21.0, 21.8, x)
	# the cliff and the valley below it
	var zc := _cliff_z(x)
	if z < zc:
		var t := clampf((zc - z) / 2.2, 0.0, 1.0)
		var valley := -24.0 + noise.get_noise_2d(x * 0.5, z * 0.5) * 4.0 - (zc - z) * 0.05 + 6.0 * gauss(x + 16, z + 40, 9.0)
		h = lerpf(h, valley, smoothstep(0.0, 1.0, t))
	# a lone rock pillar just off the cliff, level with the plateau
	var dl := Vector2(x, z).distance_to(LEDGE)
	h = lerpf(h, 0.3, smoothstep(2.0, 1.4, dl))
	return h


func _build() -> void:
	bridge(Vector2(0.98, 0.88), Vector2(6.62, -1.68), 0.28)
	_ruins()
	near_lanterns = [lantern_post(-9.5, 8.4, -1.0, false), lantern_post(-1.5, 4.2, 1.0, false)]
	lantern_post(8.6, 0.9)
	lantern_post(16.4, -3.2)
	lantern_post(36.5, -9.6, -1.0)
	fence(Vector2(7.6, -3.6), Vector2(18.5, -9.5), 7)
	var bpnt := _ground(11.2, -6.6)
	box(Vector3(0.22, 3.6, 0.22), bpnt + Vector3(0, 1.8, 0), "wood.png")
	box(Vector3(1.0, 0.14, 0.14), bpnt + Vector3(0.4, 3.45, 0), "wood.png", Vector3.ZERO, false)
	bill(load(D + "banner.png"), bpnt + Vector3(0.75, 1.55, 0.05))
	bill(load(D + "signpost.png"), _ground(-20.5, 15.2))
	_road_ward()
	_trunk()
	_fawn()
	_ledge()
	_gate()
	_folk()
	var keep := func(p: Vector2) -> bool:
		return path_dist(p) > 3.2 and dist_poly(p, streams[0].pts) > 2.7 and p.distance_to(ruins) > 5.5 \
			and p.y > _cliff_z(p.x) + 1.5 and not (p.x > 19.0 and p.y < _ridge_z(p.x) + 8.0) and p.distance_to(Vector2(13.5, 11.5)) > 3.0
	var keep_open := func(p: Vector2) -> bool:
		return keep.call(p) and not (absf(p.x) < 22.0 and p.y > -12.0 and p.y < 16.0 and rng.randf() < 0.75)
	trees(Rect2(-40, -15, 95, 45), 90, keep_open)
	# the gorge's rim, set back so it never hides the fight below
	trees(Rect2(22, -2, 24, 10), 12, func(p: Vector2) -> bool: return p.y > _ridge_z(p.x) + 8.0)
	# the far side of the gorge, beyond the cliff wall
	trees(Rect2(22, -24, 26, 7), 14, func(p: Vector2) -> bool: return p.y < _cliff_z(p.x) - 1.5, ["pine_a.png", "pine_b.png"])
	scenery(Rect2(-32, -14, 78, 40), 300, func(p: Vector2) -> bool:
		return p.y > _cliff_z(p.x) + 0.8 and dist_poly(p, roads[0]) > 1.7 and dist_poly(p, streams[0].pts) > 1.8)
	_valley()
	_cliff_walls()


func _ruins() -> void:
	var base := terrain.height_at(ruins.x, ruins.y - 0.8)
	box(Vector3(0.9, 3.8, 0.9), Vector3(ruins.x - 1.7, base + 1.7, ruins.y - 0.8), "bricks.png")
	box(Vector3(0.9, 3.4, 0.9), Vector3(ruins.x + 1.7, base + 1.5, ruins.y - 0.8), "bricks.png")
	box(Vector3(4.4, 0.8, 1.0), Vector3(ruins.x, base + 3.55, ruins.y - 0.8), "bricks.png", Vector3(0, 0, deg_to_rad(-4)), false)
	box(Vector3(1.2, 1.4, 0.2), Vector3(ruins.x, base + 2.4, ruins.y - 0.8), "rune_bricks.png", Vector3.ZERO, false, Color(1.0, 0.95, 1.1))
	for s: Array in [[Vector2(-21, -0.2), Vector3(0.8, 2.4, 0.5), 10.0], [Vector2(-12.8, 0.6), Vector3(0.8, 2.0, 0.5), -14.0],
			[Vector2(-19.5, -6.0), Vector3(3.0, 1.2, 0.7), 5.0], [Vector2(-13.8, -6.4), Vector3(2.2, 0.8, 0.7), -8.0]]:
		var p: Vector2 = s[0]
		var sz: Vector3 = s[1]
		box(sz, _ground(p.x, p.y) + Vector3(0, sz.y * 0.5 - 0.1, 0), "rune_bricks.png" if sz.y > 1.5 else "bricks.png", Vector3(0, deg_to_rad(s[2]), deg_to_rad(s[2] * 0.3)))
	brazier(-15.2, -0.6)
	chest(-19.2, -4.6, &"chest_ruins", [[&"ember_seed"]], 15, 0.2)


func _valley() -> void:
	for k in 160:
		var x := rng.randf_range(-48, 60)
		var z := rng.randf_range(-86, -20)
		if z > _cliff_z(x) - 3.0 or Vector2(x + 16, z + 40).length() < 8.0 or Vector2(x - 22, z + 42).length() < 6.0 or Vector2(x, z).distance_to(LEDGE) < 3.0:
			continue
		bill(load(D + ("pine_a.png" if k % 3 else "pine_b.png")), Vector3(x, _height(x, z), z), rng.randf_range(0.9, 1.3))
	var castle := bill(load(D + "castle.png"), Vector3(-16, _height(-16, -40) - 1.0, -40), 2.0)
	castle.mat.set_shader_parameter(&"emit", 0.15)
	var vil := bill(load(D + "village_far.png"), Vector3(22, _height(22, -42) - 0.5, -42), 1.6)
	vil.mat.set_shader_parameter(&"emit", 0.2)
	# the stream spills over the cliff: foam at the lip, mist from below
	var ex := 0.35
	var ez := _cliff_z(ex) + 0.5
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(func() -> void:
		FX3.burst(Vector3(ex + randf_range(-1.0, 1.0), -0.85, ez), 1, [Color("e8f4ff", 0.8), Color("a8c8e0", 0.6), Color("6a8aa8", 0.4)],
			Vector2(0.5, 1.5), Vector2(0.3, 0.6), {"dir": Vector3(0, 0.3, -1), "spread": 0.6, "gravity": 3.0})
		FX3.burst(Vector3(ex + randf_range(-2.5, 2.5), -0.95 - randf_range(1.0, 4.0), ez - randf_range(1.0, 3.0)), 1,
			[Color("c8d8f0", 0.35), Color("a0b0d0", 0.25), Color("8090b0", 0.15)], Vector2(0.2, 0.6), Vector2(1.2, 2.2), {"dir": Vector3.UP, "spread": 1.0, "size": 2.0}))
	add_child(t)


## Invisible walls along the cliff edge (with a gap at the ledge), and round
## the chasm so a levitating wizard can't drift out over the valley.
func _cliff_walls() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	for x in range(-30, 47, 2):
		if x > CLIFF_GAP.x - 1.0 and x < CLIFF_GAP.y + 1.0:
			continue
		_wall(body, Vector3(x, _height(x, _cliff_z(x) + 1.0) + 2.0, _cliff_z(x) + 0.9), Vector3(2.2, 6, 0.6))
	for x in [CLIFF_GAP.x - 0.6, CLIFF_GAP.y + 0.6]:
		_wall(body, Vector3(x, 0, -21.5), Vector3(0.6, 40, 9))
	_wall(body, Vector3(-3, 0, -24.3), Vector3(6, 40, 0.6))


# ------------------------------------------------------------------ roadside ward
func _road_ward() -> void:
	road_ward = ward_stone(-10.8, 9.6, false)
	var it := Interactable.make(road_ward.pos - Vector3(0, 1.2, 0), "Relight the roadside ward", 2.0, 1.9)
	add_child(it)
	it.activated.connect(func(p: Player) -> void:
		it.enabled = false
		await channel(p, road_ward.pos, [Color("ffffff"), Color("d8f8ff"), Color("9ae8ff")], 1.6)
		GameState.set_flag(&"road_ward_lit")
		ward_flare(road_ward)
		_apply_ward(true)
		# the light drives off whatever lurks nearby
		for e: Node3D in SpellEffect.in_circle(road_ward.pos, 9.0):
			var d := Damage.make(1.0, p, &"storm", SpellEffect.push(road_ward.pos, e.global_position, 10.0, 4.0))
			d.is_proc = true
			e.take_hit(d)
		set_checkpoint(&"ward")
		GameState.advance(Quests.MAIN, 2)
		await Dialogue.i.talk([["", "The ward drinks the light from your staff and blazes. The dark along the road draws back."],
			["", "Its glow will call you back here if you fall."]]))
	road_ward["it"] = it


func _apply_ward(lit: bool) -> void:
	set_ward(road_ward, lit)
	for l: Dictionary in near_lanterns:
		set_lantern(l, lit)
	if road_ward.has("it"):
		(road_ward.it as Interactable).enabled = not lit


# ------------------------------------------------------------------ fallen trunk
func _trunk() -> void:
	trunk = Node3D.new()
	add_child(trunk)
	var g := _ground(24.5, -12.0)
	trunk.global_position = g + Vector3(0, 0.55, 0)
	var log_mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 1.0, 9.0)
	log_mesh.mesh = bm
	var mat := ShaderMaterial.new()
	mat.shader = PROP_SHADER
	mat.set_shader_parameter(&"tex", load(D + "wood.png"))
	mat.set_shader_parameter(&"tint", Color(0.7, 0.6, 0.55))
	log_mesh.material_override = mat
	trunk.add_child(log_mesh)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = bm.size + Vector3(0.2, 2.0, 0)
	cs.shape = sh
	body.add_child(cs)
	trunk.add_child(body)
	trunk.set_meta(&"body", body)
	for k in 4:
		var br := PixelBillboard.still(load(D + "dead_tree.png"))
		br.scale = Vector3.ONE * 0.45
		trunk.add_child(br)
		br.position = Vector3(randf_range(-0.3, 0.3), 0.3, -3.5 + k * 2.3)
	var it := Interactable.make(g + Vector3(-1.4, 0, 0), "Lift the fallen trunk", 2.4, 2.2)
	add_child(it)
	trunk.set_meta(&"it", it)
	it.activated.connect(func(p: Player) -> void:
		it.enabled = false
		var ramp := Pal.school(StringName(p.wiz.school))
		var lift := func(t: float) -> void:
			trunk.global_position = g + Vector3(0, 0.55 + t * 1.8, 0)
			trunk.rotation.y = t * 0.2
			if randf() < 0.6:
				FX3.burst(trunk.global_position + Vector3(randf_range(-0.5, 0.5), -0.6, randf_range(-4, 4)), 1, ramp, Vector2(0.2, 0.8), Vector2(0.4, 0.8), {"gravity": -1.0})
		var tw := create_tween()
		tw.tween_method(lift, 0.0, 1.0, 1.6).set_trans(Tween.TRANS_SINE)
		Sfx.play("storm_hum", -2.0)
		await channel(p, trunk.global_position, ramp, 1.6)
		GameState.set_flag(&"trunk_lifted")
		var tw2 := create_tween()
		tw2.tween_property(trunk, "global_position", _ground(26.0, -7.4) + Vector3(0, 0.9, 0), 0.7).set_trans(Tween.TRANS_QUAD)
		tw2.parallel().tween_property(trunk, "rotation:y", PI / 2, 0.7)
		await tw2.finished
		FX3.burst(trunk.global_position, 30, Pal.DUST, Vector2(1.0, 4.0), Vector2(0.4, 0.8), {"gravity": 5.0, "jitter": 2.0})
		GameCamera3D.shake_all(3.0)
		Sfx.play("sentinel_slam", -4.0)
		GameState.advance(Quests.MAIN, 3))


func _apply_trunk(moved: bool) -> void:
	if moved:
		trunk.global_position = _ground(26.0, -7.4) + Vector3(0, 0.9, 0)
		trunk.rotation.y = PI / 2
	(trunk.get_meta(&"it") as Interactable).enabled = not moved


# ------------------------------------------------------------------ frightened fawn
func _fawn() -> void:
	fawn = Npc.new()
	fawn.sheet = "fawn"
	fawn.display = "Frightened fawn"
	fawn.prompt = "Calm the frightened fawn"
	fawn.radius = 2.4
	fawn.prompt_height = 1.4
	add_child(fawn)
	fawn.global_position = _ground(13.5, 11.5)
	fawn.sprite.play(&"panic")
	var thorns: Array[PixelBillboard] = []
	for k in 7:
		var a := k * TAU / 7.0
		var t := bill(load(D + "thorns.png"), _ground(13.5 + cos(a) * 1.1, 11.5 + sin(a) * 0.8))
		thorns.append(t)
	fawn.set_meta(&"thorns", thorns)
	fawn.on_talk = func() -> void:
		fawn.enabled = false
		GameState.start_quest(&"fawn")
		await channel(player, fawn.global_position + Vector3(0, 0.6, 0), Pal.HEAL, 2.0)
		for t: PixelBillboard in thorns:
			var tw := t.create_tween()
			tw.tween_property(t, "position:y", t.position.y - 1.0, 0.6)
		fawn.sprite.play(&"calm")
		FX3.ring(fawn.global_position + Vector3(0, 0.05, 0), 0.2, 2.5, 0.6, Pal.HEAL, 1.0)
		FX3.burst(fawn.global_position + Vector3(0, 1.0, 0), 30, Pal.HEAL, Vector2(0.5, 2.0), Vector2(0.6, 1.2), {"gravity": -1.0})
		await get_tree().create_timer(0.8).timeout
		await Dialogue.i.talk([["", "The fawn stops trembling. It steps close and presses its glowing brow against your staff."],
			["", "Warmth runs up your arms, and your feet grow light as thistledown."]])
		GameState.unlock(&"levitate")
		GameState.advance(&"fawn", -1)
		GameState.set_flag(&"fawn_calmed")
		FX3.flash(player.center(), 0.8, 0.4, Color(0.8, 1.0, 0.85), 5.0)
		Sfx.play("perfect_dodge")
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.banner("Levitate: hold %s" % Settings.key_label("jump"))
		fawn.walk_to = _ground(20.0, 16.0)
		await get_tree().create_timer(3.0).timeout
		var tw2 := fawn.create_tween()
		tw2.tween_method(fawn.sprite.set_fade, 0.0, 1.0, 0.8)
		tw2.tween_callback(func() -> void: fawn.visible = false)


# ------------------------------------------------------------------ levitation ledge
func _ledge() -> void:
	var g := _ground(LEDGE.x, LEDGE.y)
	box(Vector3(0.7, 0.5, 0.5), g + Vector3(0.3, 0.2, 0), "wood.png", Vector3(0, 0.4, 0), true, Color(0.8, 0.7, 0.6))
	var glint := bill(load(D + "ward_lit.png"), g + Vector3(0.3, 0.7, 0), 0.5)
	glint.mat.set_shader_parameter(&"emit", 1.0)
	var it := Interactable.make(g, "Open the weathered satchel", 1.6, 1.2)
	add_child(it)
	it.set_meta(&"glint", glint)
	it.activated.connect(func(p: Player) -> void:
		it.enabled = false
		glint.visible = false
		GameState.once(&"ledge_satchel", func() -> void:
			give(&"gale_feather")
			give_point())
		FX3.burst(g + Vector3(0, 0.6, 0), 24, Pal.MANA, Vector2(0.5, 2.5), Vector2(0.5, 1.0), {"gravity": -1.0})
		Sfx.play("mote", 0.0)
		var text := "Tucked inside: a traveller's spell-notes and a feather that never quite settles."
		await Dialogue.i.talk([["", text]]))
	set_meta(&"ledge_it", it)


# ------------------------------------------------------------------ gate, troll, travellers
func _gate() -> void:
	for z: float in [-15.2, -9.4]:
		var g := _ground(31.0, z)
		box(Vector3(1.0, 3.6, 1.0), g + Vector3(0, 1.6, 0), "bricks.png")
		box(Vector3(1.3, 0.4, 1.3), g + Vector3(0, 3.5, 0), "bricks.png", Vector3.ZERO, false)
	# the gate's broken planks lie where the troll tore them off
	for k in 5:
		var p := Vector2(29.5 + randf_range(-1.5, 2.5), -12.3 + randf_range(-2.5, 2.5))
		box(Vector3(1.6, 0.12, 0.35), _ground(p.x, p.y) + Vector3(0, 0.06, 0), "wood.png", Vector3(0, randf() * PI, 0), false, Color(0.8, 0.7, 0.6))
	checkpoint_stone(21.3, -10.9, &"gorge")
	gate_stone = waystone(41.0, -12.4, "Travel to the Old Ward")
	gate_stone.activated.connect(func(_p: Player) -> void:
		if GameState.quest_step(Quests.MAIN) >= 4 or GameState.quest_done(Quests.MAIN):
			exit_requested.emit(&"old_ward", &"waystone")
		else:
			await Dialogue.i.talk([["", "The waystone hums, but the missing travellers come first."]]))


func _tamsin() -> void:
	tamsin = Npc.new()
	tamsin.sheet = "tamsin"
	tamsin.display = "Tamsin"
	add_child(tamsin)
	tamsin.global_position = _ground(-19.5, 2.2)
	tamsin.sprite.play(&"guard")
	for k in 6:
		var a := k * TAU / 6.0
		tamsin_thorns.append(bill(load(D + "roots.png"), _ground(-19.5 + cos(a) * 0.8, 2.2 + sin(a) * 0.6), 1.2))
	tamsin.on_talk = func() -> void:
		if not GameState.flag(&"tamsin_freed"):
			await Dialogue.i.talk([["Tamsin", "Wizard! These roots won't give. It's that knot-thing by the stones: it's got its claws in the ground under me."]])
			return
		await Dialogue.i.talk([
			["Tamsin", "Hah! Free. Thank you. Tamsin Holt, shieldbearer of the Gate Watch... what's left of it."],
			["Tamsin", "That troll smashed our gate and scattered us. I've been fighting roots for two days."],
			["Tamsin", "You're clearly headed somewhere dangerous. My shield's yours, if you'll have it."],
		])
		var k: int = await Dialogue.i.choose("Tamsin", "Shall I come along?", ["Walk with me", "Wait at my sanctuary for now"])
		GameState.companion = {"recruited": true, "following": k == 0}
		GameState.once(&"tamsin_recruited")
		tamsin.visible = false
		tamsin.enabled = false
		get_tree().root.get_node("Main").sync_companion()
		SaveSystem.autosave()


func _free_tamsin() -> void:
	if GameState.flag(&"tamsin_freed"):
		return
	GameState.set_flag(&"tamsin_freed")
	for t in tamsin_thorns:
		var tw := t.create_tween()
		tw.tween_property(t, "position:y", t.position.y - 1.2, 0.6)
	tamsin.sprite.play(&"rise", true)
	FX3.burst(tamsin.global_position + Vector3(0, 0.5, 0), 20, Pal.DUST, Vector2(1.0, 3.0), Vector2(0.4, 0.7), {"gravity": 5.0})
	var hud := get_tree().get_first_node_in_group(&"hud") as HUD
	if hud:
		hud.toast("The roots around the shieldbearer wither")


func _folk() -> void:
	_tamsin()
	isolde = Npc.new()
	isolde.sheet = "isolde"
	isolde.display = "Isolde"
	add_child(isolde)
	isolde.global_position = _ground(38.5, -14.6)
	isolde.on_talk = _talk_isolde
	traveler = Npc.new()
	traveler.sheet = "traveler_a"
	traveler.display = "Oswin"
	add_child(traveler)
	traveler.global_position = _ground(39.5, -10.2)
	traveler.on_talk = func() -> void:
		if GameState.flag(&"troll_defeated"):
			await Dialogue.i.talk([["Oswin", "It had us pinned behind these stones for two nights. I'm going home to Hearthmere, and I'm not stopping till I see the square."]])
		else:
			await Dialogue.i.talk([["Oswin", "Quiet! It hears everything!"]])


func _talk_isolde() -> void:
	if not GameState.flag(&"troll_defeated"):
		await Dialogue.i.talk([["Isolde", "{name}? Oh, thank the stars. Careful, the brute is still out there!"]])
		return
	if GameState.flag(&"isolde_home", "") == "":
		await Dialogue.i.talk([
			["Isolde", "{name}! I knew Maren would send for you. That beast came through the gate the night the wardlight died."],
			["Isolde", "We were gathering nightbloom by the Old Ward when the roots woke. The guardian there... it isn't itself. The ward's light is being choked."],
			["Isolde", "The waystone will take you there. But first, I can't go back to my old garden. Where should I go?"],
		])
		var k: int = await Dialogue.i.choose("Isolde", "Where will you settle?", ["Stay at my sanctuary (tonics by my door)", "Help rebuild Hearthmere (a garden stall in the square)"])
		GameState.set_flag(&"isolde_home", "sanctuary" if k == 0 else "village")
		GameState.set_flag(&"travelers_rescued")
		GameState.once(&"isolde_rescued")
		GameState.start_quest(&"isolde")
		GameState.advance(&"isolde", -1)
		GameState.advance(Quests.MAIN, 4)
		await Dialogue.i.talk([["Isolde", "Then that's settled. Go, {name}. The ward won't wait for us."] if k == 0 else
			["Isolde", "Hearthmere it is. Maren will put me to work before I've set my basket down. Go, {name}."]])
		_folk_leave()
	else:
		await Dialogue.i.talk([["Isolde", "The waystone, {name}. The Old Ward."]])


func _folk_leave() -> void:
	for n: Npc in [isolde, traveler]:
		n.enabled = false
		n.walk_to = _ground(28.0, -11.5)
		var tw := n.create_tween()
		tw.tween_interval(2.5)
		tw.tween_method(n.sprite.set_fade, 0.0, 1.0, 0.6)
		tw.tween_callback(func() -> void: n.visible = false)


# ------------------------------------------------------------------ state
func spawn(kind: StringName, x: float, z: float) -> Enemy:
	var e := super.spawn(kind, x, z)
	if kind == &"knot" and Vector2(x, z).distance_to(ruins) < 12.0:
		e.died.connect(func(_e: Enemy) -> void: _free_tamsin())
	if kind == &"troll":
		troll = e
		e.died.connect(func(_e: Enemy) -> void:
			GameState.set_flag(&"troll_defeated")
			var at: Vector3 = _e.center()
			GameState.once(&"troll_reward", func() -> void:
				player.health.heal(player.health.max_hp)
				player.mana.refill()
				var staff: StringName = {"fire": &"cinderbrand", "hex": &"gravewood", "storm": &"stormcoil"}[player.wiz.school]
				give(staff)
				give(&"ward_bell")
				give_decor(&"hut", "Gatewood hut (from the broken gate's timbers)")
				FX3.burst(at, 30, [Color("fff0c0"), Color("f0c870"), Color("a07840")], Vector2(1.0, 4.0), Vector2(0.5, 1.0), {"gravity": 3.0})
				SaveSystem.autosave())
			var hud := get_tree().get_first_node_in_group(&"hud") as HUD
			if hud:
				hud.banner("The Gatebreaker falls"))
	return e


func apply_state() -> void:
	_apply_ward(GameState.flag(&"road_ward_lit"))
	_apply_trunk(GameState.flag(&"trunk_lifted"))
	if GameState.flag(&"fawn_calmed"):
		fawn.visible = false
		fawn.enabled = false
		for t: PixelBillboard in fawn.get_meta(&"thorns"):
			t.visible = false
	if GameState.events.has(&"ledge_satchel"):
		var it: Interactable = get_meta(&"ledge_it")
		it.enabled = false
		(it.get_meta(&"glint") as Node3D).visible = false
	if GameState.flag(&"travelers_rescued"):
		isolde.visible = false
		isolde.enabled = false
		traveler.visible = false
		traveler.enabled = false
	if GameState.flag(&"road_ward_lit"):
		respawn_entry = &"ward"
	if GameState.companion.recruited:
		tamsin.visible = false
		tamsin.enabled = false
	elif GameState.flag(&"tamsin_freed"):
		for t in tamsin_thorns:
			t.visible = false
		tamsin.sprite.play(&"idle")
