extends Region
## Reedhollow: the Reedfolk's village on the lake, Chapter 2's hub. A shore
## promenade runs west to east; the lake lies north, with stilt houses and
## the boat dock standing out over the water on piers (the camera looks
## north, so nothing tall stands between it and the walkways). Deep water
## beyond the shore is a hazard like a chasm: walkers are put back ashore,
## levitation crosses short gaps. The village recovers as the lake shrines
## are relit: more lanterns and people (one shrine and up), the fishing
## walkway mended (two), Corrin the trader's stall (three). Wenna's son Pip
## is the lost child in the Mire; once found he waits here with her.

const PROPS := "res://assets/generated/props_woods.png"
## Boat stops: [region id, label, when it's offered]. A stop appears once its
## region exists (steps 5-8 add them) and its condition holds.
const STOPS := [
	[&"sunken_chapel", "The Sunken Chapel", &"shrines"],
	[&"mire", "The Mire", &"shrines"],
	[&"stilled_grove", "The Stilled Grove", &"shrines"],
	[&"far_watch", "The far watchtower", &"far_watch"],
	[&"heart_isle", "The Heart Isle", &"heart"],
]

const DECK_Y := 0.15           # pier and stilt decks: flush with the shore (land is at 0)
var piers: Array[Rect2] = []   # walkable decks over deep water (x, z)
var lanterns: Array = []
var folk_later: Array[Npc] = []  # appear as the shrines are relit
var elder: Npc
var wenna: Npc
var pip: Npc
var bren: Npc                    # fishes off the mended walkway (two shrines)
var trader: Npc                  # the Reedfolk trader (three shrines)
var orla: Npc                    # the mapmaker (after the Herald): the far-watch teaser
var walk_broken: Node3D
var walk_mended: Node3D
var walk_rect := Rect2()
var platform_lamp: Dictionary

var folk: Array[Npc] = []        # Teodor and Mira
var herald: Herald
var arena_wall: StaticBody3D
var attack_fx: Array[Node] = []  # fires, lights and shadow pools while the village is attacked

const PLATFORM := Vector2(-6.5, -8.6)
## The square the Herald fights on (sealed while it fights, once the wizard is inside).
const ARENA := Rect2(-9.0, -2.4, 18.0, 13.4)
const POOLS := [Vector2(-6.0, 1.2), Vector2(6.0, 1.2), Vector2(-5.5, 8.5), Vector2(5.5, 8.5), Vector2(0.0, 9.6), Vector2(0.0, 0.2)]
const SHOP := [[&"moonstone", 35], [&"gale_feather", 35], [&"stormglass", 35], [&"ward_bell", 50], [&"reedwhistle", 90], [&"lakeweave", 90]]


func _layout() -> void:
	id = &"reedhollow"
	display_name = "Reedhollow"
	music = "lake"
	env_preset = &"lake"
	seed_value = 233
	origin = Vector2(-40, -40)
	grid = Vector2i(80, 80)
	bounds = Rect2(-26, -14, 52, 26)
	paths = [[Vector2(-28, 1.0), Vector2(-16, 0.4), Vector2(-6, 1.2), Vector2(4, 0.8), Vector2(14, 1.3), Vector2(28, 0.8)],
		[Vector2(-12, 0.5), Vector2(-12, -2.5)], [Vector2(-1, 1.1), Vector2(-1, -2.5)], [Vector2(10, 1.1), Vector2(10, -2.5)],
		[Vector2(19, 1.2), Vector2(19, -2.5)]]
	# the lake: one wide sheet of water (the shore is carved in _shape)
	streams = [{"pts": [Vector2(-46, -20), Vector2(46, -20)], "width": 18.5, "depth": 0.0, "water_y": -0.45, "flow": Vector2(0.06, -0.03)}]
	hills = [[-18, 14, 1.2, 6.0], [16, 14, 1.0, 6.0]]
	pads = [[0, 5.5, 4.5, 0.3]]
	dirt_spots = [[0, 5.5, 3.5]]
	entries = {&"west": [Vector3(-23.5, 0, 1.0), 1.0], &"start": [Vector3(-23.5, 0, 1.0), 1.0], &"dock": [Vector3(19.0, 0, -1.2), -1.0],
		&"square": [Vector3(-3.0, 0, 4.5), 1.0]}
	exits = [{"rect": Rect2(-27.0, -4, 2.5, 12), "to": &"fenway", "entry": &"east"}]
	respawn_entry = &"square"
	if under_attack():
		# the Herald's attack (after the second shrine): Chapter 2 strength, the
		# Herald waiting on the square, husks and hollowed hounds on the promenade
		enemy_scale = 1.25
		boss_music = "herald"
		respawn_entry = &"dock"
		spawns = [[&"husk", 15.0, 2.5], [&"hound", 12.5, 1.0, {"hollowed": true}], [&"hound", 13.5, -0.5, {"hollowed": true}],
			[&"husk", -13.0, 1.0], [&"husk", -16.0, 2.5], [&"moth", -11.0, -1.0], [&"herald", ARENA.get_center().x, 4.0]]


## After the second shrine the Herald comes for the village, until driven off.
static func under_attack() -> bool:
	return GameState.quest_step(Quests.HOLLOWING) == 4 and not GameState.flag(&"herald_fled")


static func shore_z(x: float) -> float:
	return -3.5 + 0.8 * sin(x * 0.23)


func _shape(x: float, z: float, h: float) -> float:
	var t := smoothstep(shore_z(x) + 1.2, shore_z(x) - 1.8, z)
	return lerpf(h, -1.6, t)


## Deep water: past the shore and not on a pier or stilt deck.
func is_hazard(p: Vector3) -> bool:
	if p.z > shore_z(p.x) - 1.0:
		return false
	for r in piers:
		if r.has_point(Vector2(p.x, p.z)):
			return false
	return not (Quests.shrines_lit() >= 2 and walk_rect.has_point(Vector2(p.x, p.z)))


func _build() -> void:
	# stilt houses out on the water, each with a pier from the shore
	for sh: Array in [[-12.0, -11.0, 4.6, Color(0.92, 0.95, 1.0)], [-1.0, -10.5, 5.2, Color(1.0, 0.94, 0.86)], [10.0, -11.0, 4.4, Color(0.9, 0.97, 0.95)]]:
		_stilt_house(sh[0], sh[1], sh[2], sh[3])
	_dock(19.0)
	_walkway()
	# the lake light: Reedhollow's ward, fed by the Deepwillow (dim until the shrines burn)
	ward_stone(4.0, -1.8, false, false)
	for lx: float in [-19.0, -7.0, 5.5, 14.5, 23.0]:
		lanterns.append(lantern_post(lx, -1.9, 1.0, false))
	# low things only on the land south of the promenade (camera rule)
	for rack: Array in [[-17.0, 5.0], [8.0, 7.5]]:
		_net_rack(rack[0], rack[1])
	for c: Array in [[-5.5, 7.0, "barrel.png"], [-4.8, 7.4, "crate.png"], [13.5, 5.5, "crate.png"], [21.0, 4.5, "barrel.png"]]:
		bill(load(D + c[2]), _ground(c[0], c[1]))
	for k in 3:   # upturned boats on the grass
		var g := _ground(-21.0 + k * 19.0, 8.5 + k % 2)
		box(Vector3(2.2, 0.35, 0.8), g + Vector3(0, 0.15, 0), "wood.png", Vector3(0, 0.3 * (k - 1), 0), true, Color(0.62, 0.5, 0.4))
	brazier(0.0, 6.5)
	_people()
	var tex: Texture2D = load(PROPS)
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
	for k in 70:   # reeds along the shoreline
		var x := rng.randf_range(-26, 26)
		var z := shore_z(x) + rng.randf_range(-0.9, 0.9)
		if path_dist(Vector2(x, z)) < 1.4 or _on_pier(Vector2(x, z), 1.0):
			continue
		var r: Array = props["cattails" if rng.randf() < 0.3 else "reeds"]
		bill(tex, _ground(x, z), rng.randf_range(0.9, 1.25), Rect2(r[0], r[1], r[2], r[3]))
	# the far shore: a dark treeline across the water
	trees(Rect2(-46, -44, 92, 6), 40, func(p: Vector2) -> bool: return p.y < -38.5, ["pine_a.png", "pine_b.png", "oak.png"])
	trees(Rect2(-40, 14, 80, 12), 20, func(p: Vector2) -> bool: return p.y > 15.0)
	scenery(Rect2(-26, -2, 52, 14), 110, func(p: Vector2) -> bool: return path_dist(p) > 1.5 and p.distance_to(Vector2(0, 5.5)) > 3.5,
		["tuft_a", "tuft_b", "tuft_c", "flowers", "reeds", "rock_s", "fern"])
	bill(load(D + "signpost.png"), _ground(-21.5, 3.0))
	arena_wall = StaticBody3D.new()
	add_child(arena_wall)
	for w: Array in [[Vector3(ARENA.position.x, 0, ARENA.get_center().y), Vector3(0.6, 40, ARENA.size.y)],
			[Vector3(ARENA.end.x, 0, ARENA.get_center().y), Vector3(0.6, 40, ARENA.size.y)],
			[Vector3(ARENA.get_center().x, 0, ARENA.position.y), Vector3(ARENA.size.x, 40, 0.6)],
			[Vector3(ARENA.get_center().x, 0, ARENA.end.y), Vector3(ARENA.size.x, 40, 0.6)]]:
		_wall(arena_wall, w[0], w[1])
	arena_wall.collision_layer = 0
	if under_attack():
		_attack_fx()


## The village burning: fires on the stilt roofs and net racks, shadow pools
## on the square (the Herald's blink points).
func _attack_fx() -> void:
	var fires := [Vector3(-12, 3.4, -10.5), Vector3(10, 3.3, -10.5), _ground(-17, 5) + Vector3(0, 1.2, 0), _ground(8, 7.5) + Vector3(0, 1.2, 0)]
	for f: Vector3 in fires:
		attack_fx.append(light(f + Vector3(0, 0.4, 0.6), Color(1.0, 0.45, 0.15), 3.0, 7.0))
	var flame := [Color("fff0a0"), Color("ffb040"), Color("e05a20"), Color("5a2a20")]
	var smoke := [Color(0.25, 0.2, 0.22, 0.5), Color(0.15, 0.12, 0.14, 0.4)]
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(func() -> void:
		var f: Vector3 = fires[randi() % fires.size()]
		FX3.burst(f + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.4, 0.4)), 2, flame, Vector2(0.5, 1.8), Vector2(0.3, 0.7), {"dir": Vector3.UP, "spread": 0.6, "gravity": -2.0})
		if randf() < 0.3:
			FX3.burst(f + Vector3(0, 0.8, 0), 1, smoke, Vector2(0.3, 1.0), Vector2(1.5, 2.5), {"dir": Vector3.UP, "spread": 0.4, "gravity": -0.5, "size": 3.0}))
	add_child(t)
	for q: Vector2 in POOLS:
		var g := _ground(q.x, q.y) + Vector3(0, 0.03, 0)
		attack_fx.append(FX3.decal(FX3.GLOW_L, g, 1e9, Color(0.1, 0.04, 0.16, 0.85), 1.4, 1.4, 0.0, true, 0.0, true))
		attack_fx.append(FX3.decal(FX3.RUNE_M, g + Vector3(0, 0.01, 0), 1e9, Color(0.6, 0.3, 0.9, 0.35), 1.0, 1.0, 0.3))
	attack_fx.append(t)


func spawn(kind: StringName, x: float, z: float, opts := {}) -> Enemy:
	var e := super.spawn(kind, x, z, opts)
	if kind == &"herald":
		herald = e as Herald
		for q: Vector2 in POOLS:
			herald.pools.append(_ground(q.x, q.y))
		herald.fled.connect(_herald_fled)
	return e


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if herald and is_instance_valid(herald):
		var sealed := herald.engaged and not herald.fleeing and player and player.is_alive() \
			and ARENA.has_point(Vector2(player.global_position.x, player.global_position.z))
		arena_wall.collision_layer = INVISIBLE if sealed else 0
		if herald.engaged and GameState.once(&"herald_intro"):
			var lines := [["The Herald", "Little lamp-lighter. You have been busy in my garden."],
				["The Herald", "The Deepwillow dreams so sweetly now. Why wake it? Waking only hurts."]]
			if GameState.in_party(&"kess"):
				lines.append(["Kess", "Get away from our village!"])
			lines.append(["The Herald", "Come, then. Let me see what grows in you."])
			Dialogue.i.talk(lines)
		if sealed and Engine.get_physics_frames() % 3 == 0:
			var e := ARENA.position + Vector2(randf() * ARENA.size.x, 0) if randf() < 0.5 else ARENA.position + Vector2(0, randf() * ARENA.size.y)
			if randf() < 0.5:
				e = ARENA.end - (e - ARENA.position)
			FX3.burst(_ground(e.x, e.y) + Vector3(0, 0.3, 0), 1, Herald.VIOLET, Vector2(0.3, 1.2), Vector2(0.5, 0.9), {"dir": Vector3.UP, "spread": 0.5, "gravity": -1.0})


func _on_respawn() -> void:
	arena_wall.collision_layer = 0


## At 30% the Herald breaks off, speaks and flees; its creatures scatter and
## the village comes back out.
func _herald_fled() -> void:
	GameState.set_flag(&"herald_fled")
	arena_wall.collision_layer = 0
	await get_tree().create_timer(0.6).timeout
	var lines := [["The Herald", "Enough. You burn brighter than I was told, little lamp-lighter."],
		["The Herald", "No matter. A garden is patient, and so is the one I tend it for."],
		["The Herald", "Light your last shrine. Wake the old tree. Ask it what it remembers."]]
	if GameState.in_party(&"kess"):
		lines.append(["Kess", "Coward! Come back here!"])
	await Dialogue.i.talk(lines)
	if is_instance_valid(herald):
		await herald.depart()
	for e in get_tree().get_nodes_in_group(&"enemy"):
		FX3.burst((e as Enemy).center(), 12, Pal.SMOKE, Vector2(0.4, 1.6), Vector2(0.4, 0.8), {"gravity": -1.2})
		e.queue_free()
	for n in attack_fx:
		if is_instance_valid(n):
			n.queue_free()
	attack_fx.clear()
	GameState.advance(Quests.HOLLOWING, 6 if Quests.shrines_lit() >= 3 else 5)
	GameState.once(&"herald_driven_off", func() -> void:
		GameState.inv.earn(60)
		reward(["+60 coins"])
		give_point(2))
	respawn_entry = &"square"
	apply_state()
	SaveSystem.autosave()
	await get_tree().create_timer(1.0).timeout
	await Dialogue.i.talk([["Elder Rhosyn", "It's gone. You drove it off, {name}. Reedhollow still stands."],
		["Elder Rhosyn", "It called itself a Herald. A herald speaks for someone greater. That frightens me more than the fire did."],
		["Elder Rhosyn", "Light the last shrine. The Deepwillow must wake, and soon."]])


## Where a pier from the water meets flat land at `x`: a little way past the
## top of the bank, so its end rests on the ground instead of the slope.
func _land_z(x: float) -> float:
	var z := shore_z(x)
	while z < shore_z(x) + 5.0 and terrain.height_at(x, z) < -0.02:
		z += 0.1
	return z + 0.7


func _on_pier(p: Vector2, grow := 0.0) -> bool:
	for r in piers:
		if r.grow(grow).has_point(p):
			return true
	return false


## A house on a stilted deck over the water, reached by a pier from the shore.
func _stilt_house(x: float, z: float, w: float, tint: Color) -> void:
	var d := 3.6
	var deck_y := DECK_Y
	var deck := Rect2(x - w * 0.5 - 0.7, z - d * 0.5 - 0.4, w + 1.4, d + 1.9)
	box(Vector3(deck.size.x, 0.3, deck.size.y), Vector3(deck.get_center().x, deck_y - 0.15, deck.get_center().y), "wood.png")
	for cx: float in [deck.position.x + 0.3, deck.end.x - 0.3]:
		for cz: float in [deck.position.y + 0.3, deck.end.y - 0.3]:
			box(Vector3(0.24, 2.4, 0.24), Vector3(cx, deck_y - 1.35, cz), "wood.png", Vector3.ZERO, false, Color(0.6, 0.5, 0.42))
	piers.append(deck)
	var h := house(x, z, w, d, 2.3, {"roof": "thatch.png", "base_y": deck_y, "tint": tint, "light": true})
	var sz := _land_z(x)
	var pier_len := sz - deck.end.y
	bridge(Vector2(x, sz), Vector2(x, deck.end.y - 0.1), deck_y, 1.8)
	piers.append(Rect2(x - 1.1, deck.end.y - 0.2, 2.2, pier_len + 0.4))


## The boat dock: a long pier with two boats moored alongside.
func _dock(x: float) -> void:
	var sz := _land_z(x)
	var end_z := -11.0
	var deck_y := DECK_Y
	bridge(Vector2(x, sz), Vector2(x, end_z), deck_y, 2.2)
	piers.append(Rect2(x - 1.3, end_z - 0.3, 2.6, sz + 0.3 - end_z))
	box(Vector3(3.6, 0.3, 2.4), Vector3(x, deck_y - 0.15, end_z - 1.0), "wood.png")
	piers.append(Rect2(x - 1.9, end_z - 2.3, 3.8, 2.6))
	for bz: Array in [[x - 2.2, -7.5, 0.1], [x + 2.2, -8.8, -0.12]]:
		var bp := Vector3(bz[0], -0.35, bz[1])
		box(Vector3(0.95, 0.4, 3.0), bp, "wood.png", Vector3(0, bz[2], 0), false, Color(0.55, 0.42, 0.32))
		box(Vector3(0.7, 0.1, 2.6), bp + Vector3(0, 0.2, 0), "wood.png", Vector3(0, bz[2], 0), false, Color(0.4, 0.3, 0.24))
		var lamp := bill(load(D + "lantern.png"), bp + Vector3(0, 0.9, 1.2), 0.8)
		lamp.mat.set_shader_parameter(&"emit", 1.0)
		light(bp + Vector3(0, 1.0, 1.4), Color(1.0, 0.6, 0.3), 1.6, 4.0)
	var it := Interactable.make(Vector3(x, deck_y, end_z - 0.6), "Take a boat", 2.0, 1.6)
	add_child(it)
	it.activated.connect(func(_p: Player) -> void: await _boats())


## A fishing platform between the stilt houses. Its walkway lies broken
## (a stub and loose planks) until two shrines burn, then it is mended.
func _walkway() -> void:
	var deck := Rect2(PLATFORM.x - 1.4, PLATFORM.y - 1.4, 2.8, 2.8)
	box(Vector3(deck.size.x, 0.3, deck.size.y), Vector3(PLATFORM.x, DECK_Y - 0.15, PLATFORM.y), "wood.png")
	for c: Vector2 in [deck.position, Vector2(deck.end.x, deck.position.y), Vector2(deck.position.x, deck.end.y), deck.end]:
		box(Vector3(0.22, 2.2, 0.22), Vector3(c.x - signf(c.x - PLATFORM.x) * 0.3, DECK_Y - 1.25, c.y - signf(c.y - PLATFORM.y) * 0.3), "wood.png", Vector3.ZERO, false, Color(0.6, 0.5, 0.42))
	piers.append(deck)
	platform_lamp = lantern_post(PLATFORM.x + 1.0, PLATFORM.y - 1.0, -1.0, false)
	var sz := _land_z(PLATFORM.x)
	walk_rect = Rect2(PLATFORM.x - 1.0, deck.end.y - 0.2, 2.0, sz - deck.end.y + 0.4)
	walk_broken = _collect(func() -> void:
		bridge(Vector2(PLATFORM.x, sz), Vector2(PLATFORM.x, sz - 2.2), DECK_Y, 1.6)
		for k in 3:   # loose planks drifting in the gap
			box(Vector3(1.3, 0.08, 0.3), Vector3(PLATFORM.x + randf_range(-0.8, 0.8), -0.42, sz - 3.0 - k * 1.0), "wood.png", Vector3(0, randf_range(-0.6, 0.6), 0), false, Color(0.55, 0.45, 0.38)))
	walk_mended = _collect(func() -> void:
		bridge(Vector2(PLATFORM.x, sz), Vector2(PLATFORM.x, deck.end.y - 0.1), DECK_Y, 1.6))


## Group the nodes `build` adds, so they can be shown or hidden (and their
## collision switched off) together.
func _collect(build: Callable) -> Node3D:
	var n := get_child_count()
	build.call()
	var made := get_children().slice(n)
	var g := Node3D.new()
	add_child(g)
	for c: Node in made:
		c.reparent(g)
	return g


static func _show(g: Node3D, on: bool) -> void:
	g.visible = on
	g.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _net_rack(x: float, z: float) -> void:
	var g := _ground(x, z)
	for dx: float in [-0.9, 0.9]:
		box(Vector3(0.12, 1.4, 0.12), g + Vector3(dx, 0.7, 0), "wood.png", Vector3.ZERO, false)
	box(Vector3(2.0, 0.1, 0.1), g + Vector3(0, 1.38, 0), "wood.png", Vector3.ZERO, false)
	box(Vector3(1.7, 1.0, 0.04), g + Vector3(0, 0.85, 0), "thatch.png", Vector3.ZERO, false, Color(0.55, 0.6, 0.5, 0.8))


func _people() -> void:
	elder = Npc.new()
	elder.sheet = "reed_elder"
	elder.display = "Elder Rhosyn"
	add_child(elder)
	elder.global_position = _ground(-1.5, 4.6)
	elder.on_talk = _talk_elder
	for f: Array in [["reedfolk_a", "Teodor", -8.0, 3.2, "The lake's gone quiet, wizard. Not even the frogs sing."],
			["reedfolk_b", "Mira", 7.0, 3.8, "My grandmother said the Deepwillow dreams for all of us. If it's sick..."]]:
		var n := Npc.new()
		n.sheet = f[0]
		n.display = f[1]
		add_child(n)
		n.global_position = _ground(f[2], f[3])
		n.on_talk = func() -> void: await Dialogue.i.talk([[f[1], f[4]]])
		folk.append(n)
	for f: Array in [["reedfolk_a", "Hollis", 15.0, 4.0, "Lanterns on the water again! Like old times."],
			["reedfolk_b", "Ysolt", -13.0, 3.6, "We came back from the far shore when we saw the shrine light. Thank you."]]:
		var n := Npc.new()
		n.sheet = f[0]
		n.display = f[1]
		add_child(n)
		n.global_position = _ground(f[2], f[3])
		n.on_talk = func() -> void: await Dialogue.i.talk([[f[1], f[4]]])
		folk_later.append(n)
	wenna = _npc("wenna", "Wenna", 3.4, 3.2)
	wenna.on_talk = _talk_wenna
	pip = _npc("reed_child", "Pip", 4.5, 3.6)
	pip.on_talk = func() -> void:
		await Dialogue.i.talk([["Pip", "Mum says I'm not allowed near a frog ever again. Not even a small one."],
			["Pip", "Thanks for the stones, wizard. When I'm big I'm going to learn magic too."]])
	bren = _npc("elder_man", "Old Bren", PLATFORM.x - 0.4, PLATFORM.y + 0.2)
	bren.global_position.y = DECK_Y
	bren.on_talk = func() -> void:
		await Dialogue.i.talk([["Old Bren", "They mended my walkway, and the fish came back underneath it. My old bones are glad of both."]])
	orla = _npc("orla", "Orla the mapmaker", -18.5, 4.0)
	orla.on_talk = _talk_orla
	trader = _npc("trader", "Corrin the trader", 12.2, 5.4)
	trader.on_talk = _talk_trader
	var sg := _ground(12.2, 6.4)
	box(Vector3(1.8, 0.8, 0.6), sg + Vector3(0, 0.35, 0), "wood.png", Vector3.ZERO, true, Color(0.75, 0.62, 0.5))
	box(Vector3(2.0, 0.08, 0.8), sg + Vector3(0, 0.8, 0), "thatch.png", Vector3.ZERO, false, Color(0.7, 0.75, 0.55))


func _npc(sheet: String, display: String, x: float, z: float) -> Npc:
	var n := Npc.new()
	n.sheet = sheet
	n.display = display
	add_child(n)
	n.global_position = _ground(x, z)
	return n


func _talk_wenna() -> void:
	if GameState.flag(&"pip_found"):
		if GameState.quest_active(&"lost_child"):
			await Dialogue.i.talk([["Wenna", "Pip! Oh, you muddy, foolish, wonderful boy."],
				["Wenna", "Wizard, I have nothing grand to give. Take this, all we'd put by, and our thanks every day we have."]])
			GameState.advance(&"lost_child", -1)
			GameState.once(&"wenna_thanks", func() -> void:
				GameState.inv.earn(40)
				reward(["+40 coins"])
				give_point())
			SaveSystem.autosave()
		else:
			await Dialogue.i.talk([["Wenna", "He's not leaving my sight again. Not until he's thirty."]])
		return
	if not GameState.quest_active(&"lost_child"):
		GameState.start_quest(&"lost_child")
		await Dialogue.i.talk([["Wenna", "Wizard! My boy Pip took a punt into the Mire after glow-frogs, and the punt drifted back empty."],
			["Wenna", "Please. If the boats take you to the Mire, look for him. He's small, and he never listens."]])
		return
	await Dialogue.i.talk([["Wenna", "Any sign of Pip? The Mire's no place for a child. It's hardly a place for anyone now."]])


func _talk_orla() -> void:
	if GameState.quest_done(&"far_watch"):
		await Dialogue.i.talk([["Orla", "I've drawn it in, at the very edge of the map: grey land, and a question mark. I hate question marks."]])
		return
	if GameState.quest_step(&"far_watch") == 1:
		await Dialogue.i.talk([["Orla", "My spyglass! You went all the way up. So... did you look east?"],
			["Orla", "Grey land. Something walking. I saw it too, the night the Herald came. I thought I'd dreamed it."],
			["Orla", "Keep the reward, and keep your eyes open. Whatever is out there, it isn't finished with us."]])
		GameState.advance(&"far_watch", -1)
		GameState.once(&"orla_thanks", func() -> void:
			GameState.inv.earn(50)
			reward(["+50 coins"])
			give(&"gale_feather", 2)
			give_point())
		SaveSystem.autosave()
		return
	if not GameState.quest_active(&"far_watch"):
		GameState.start_quest(&"far_watch")
		await Dialogue.i.talk([["Orla", "You're the wizard who sent that masked thing running? I'm Orla. I map the lake, and the lands past it."],
			["Orla", "I left my spyglass at the old far watchtower when the Herald's creatures came through. I ran, I'm not ashamed to say."],
			["Orla", "Would you fetch it? The boatmen know the way. And while you're up there... look east. Tell me I'm not mad."]])
		return
	await Dialogue.i.talk([["Orla", "The far watchtower, across the lake. The boatmen will take you."]])


func _talk_trader() -> void:
	var opts: Array = []
	for s: Array in SHOP:
		opts.append("%s  (%d coins)" % [Items.def(s[0]).name, s[1]])
	opts.append("Nothing today")
	var k: int = await Dialogue.i.choose("Corrin", "With the shrines burning, the boats run again, and so does trade. (You have %d coins.)" % GameState.inv.coins, opts)
	if k >= SHOP.size():
		return
	var item: Array = SHOP[k]
	if not GameState.inv.spend(item[1]):
		await Dialogue.i.talk([["Corrin", "Come back when your purse is heavier, friend."]])
		return
	give(item[0])
	Sfx.play("mote", 0.0)
	SaveSystem.autosave()


func _talk_elder() -> void:
	if GameState.quest_step(Quests.HOLLOWING) == 2:
		await Dialogue.i.talk([
			["Elder Rhosyn", "Kess! You found them. And this is the wizard of Hearthmere, stars be thanked."],
			["Elder Rhosyn", "Under our lake sleeps the Deepwillow, {name}. Its roots feed every ward-light from here to your village."],
			["Elder Rhosyn", "A masked thing came up out of the water. Since then the Heart Isle is sealed and the Deepwillow will not wake."],
			["Elder Rhosyn", "Three shrines stand around the lake. Relight them, and the seal on the Heart Isle should open."],
			["Kess", "I'm coming with you. It's my lake too."],
			["Elder Rhosyn", "Our boats are yours. Take one from the dock whenever you're ready."],
		])
		GameState.advance(Quests.HOLLOWING, 3)
		GameState.set_flag(&"kess_joined")
		SaveSystem.autosave()
		return
	var lines := ["The shrines, {name}. The Sunken Chapel, the Mire and the Stilled Grove. Any order will do.",
		"One shrine burns again. I can feel the lake breathing easier.",
		"Two shrines! The Heart Isle's seal is thinning. One more.",
		"All three shrines burn. The Heart Isle is open to you."]
	await Dialogue.i.talk([["Elder Rhosyn", lines[mini(Quests.shrines_lit(), 3)]]])


## Boat stops that exist and are open right now.
func open_stops() -> Array:
	var main := get_tree().root.get_node_or_null("Main")
	var out: Array = []
	for s: Array in STOPS:
		if main == null or not (main.REGIONS as Dictionary).has(s[0]):
			continue
		var ok := false
		match s[2]:
			&"shrines":
				ok = GameState.quest_step(Quests.HOLLOWING) >= 3 or GameState.quest_done(Quests.HOLLOWING)
			&"far_watch":
				ok = GameState.quest_active(&"far_watch") or GameState.quest_done(&"far_watch")
			&"heart":
				ok = Quests.shrines_lit() >= 3
		if ok:
			out.append(s)
	return out


func _boats() -> void:
	if under_attack():
		await Dialogue.i.talk([["", "The boatmen have fled into the houses. No one is sailing while the village burns."]])
		return
	var stops := open_stops()
	if stops.is_empty():
		await Dialogue.i.talk([["Boatman", "Nowhere I can take you yet, {name}. Talk to the elder first."]])
		return
	var names: Array = stops.map(func(s: Array) -> String: return s[1])
	names.append("Stay here")
	var k: int = await Dialogue.i.choose("Boatman", "Where to? The lake's calm tonight.", names)
	if k < stops.size():
		exit_requested.emit(stops[k][0], &"dock")


func apply_state() -> void:
	for k in lanterns.size():
		set_lantern(lanterns[k], k < 1 + Quests.shrines_lit() * 2)
	for k in folk_later.size():
		var here: bool = Quests.shrines_lit() > k
		folk_later[k].visible = here
		folk_later[k].enabled = here
	var lit := Quests.shrines_lit()
	_show(walk_broken, lit < 2)
	_show(walk_mended, lit >= 2)
	set_lantern(platform_lamp, lit >= 2)
	var found: bool = GameState.flag(&"pip_found")
	for n: Array in [[pip, found], [bren, lit >= 2], [trader, lit >= 3], [orla, GameState.flag(&"herald_fled")]]:
		(n[0] as Npc).visible = n[1]
		(n[0] as Npc).enabled = n[1]
	if under_attack():   # everyone hides indoors, every lantern is out
		for n: Npc in [elder, wenna, pip, bren, trader, orla] + folk + folk_later:
			n.visible = false
			n.enabled = false
		for l: Dictionary in lanterns:
			set_lantern(l, false)


func enter(p: Player, entry: StringName) -> void:
	super.enter(p, entry)
	if under_attack():
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.banner("Reedhollow is under attack!")
