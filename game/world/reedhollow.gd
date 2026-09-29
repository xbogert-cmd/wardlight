extends Region
## Reedhollow: the Reedfolk's village on the lake, Chapter 2's hub. A shore
## promenade runs west to east; the lake lies north, with stilt houses and
## the boat dock standing out over the water on piers (the camera looks
## north, so nothing tall stands between it and the walkways). Deep water
## beyond the shore is a hazard like a chasm: walkers are put back ashore,
## levitation crosses short gaps. The village recovers as the lake shrines
## are relit: more lanterns, more people.

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

var piers: Array[Rect2] = []   # walkable decks over deep water (x, z)
var lanterns: Array = []
var folk_later: Array[Npc] = []  # appear as the shrines are relit
var elder: Npc


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
	return true


func _build() -> void:
	# stilt houses out on the water, each with a pier from the shore
	for sh: Array in [[-12.0, -11.0, 4.6, Color(0.92, 0.95, 1.0)], [-1.0, -10.5, 5.2, Color(1.0, 0.94, 0.86)], [10.0, -11.0, 4.4, Color(0.9, 0.97, 0.95)]]:
		_stilt_house(sh[0], sh[1], sh[2], sh[3])
	_dock(19.0)
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


func _on_pier(p: Vector2, grow := 0.0) -> bool:
	for r in piers:
		if r.grow(grow).has_point(p):
			return true
	return false


## A house on a stilted deck over the water, reached by a pier from the shore.
func _stilt_house(x: float, z: float, w: float, tint: Color) -> void:
	var d := 3.6
	var deck_y := 0.35
	var deck := Rect2(x - w * 0.5 - 0.7, z - d * 0.5 - 0.4, w + 1.4, d + 1.9)
	box(Vector3(deck.size.x, 0.3, deck.size.y), Vector3(deck.get_center().x, deck_y - 0.15, deck.get_center().y), "wood.png")
	for cx: float in [deck.position.x + 0.3, deck.end.x - 0.3]:
		for cz: float in [deck.position.y + 0.3, deck.end.y - 0.3]:
			box(Vector3(0.24, 2.4, 0.24), Vector3(cx, deck_y - 1.35, cz), "wood.png", Vector3.ZERO, false, Color(0.6, 0.5, 0.42))
	piers.append(deck)
	var h := house(x, z, w, d, 2.3, {"roof": "thatch.png", "base_y": deck_y, "tint": tint, "light": true})
	var sz := shore_z(x)
	var pier_len := (sz + 0.6) - deck.end.y
	bridge(Vector2(x, sz + 0.6), Vector2(x, deck.end.y - 0.1), deck_y, 1.8)
	piers.append(Rect2(x - 1.1, deck.end.y - 0.2, 2.2, pier_len + 0.4))


## The boat dock: a long pier with two boats moored alongside.
func _dock(x: float) -> void:
	var sz := shore_z(x)
	var end_z := -11.0
	var deck_y := 0.35
	bridge(Vector2(x, sz + 0.6), Vector2(x, end_z), deck_y, 2.2)
	piers.append(Rect2(x - 1.3, end_z - 0.3, 2.6, sz + 0.9 - end_z))
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
	for f: Array in [["reedfolk_a", "Hollis", 15.0, 4.0, "Lanterns on the water again! Like old times."],
			["reedfolk_b", "Ysolt", -13.0, 3.6, "We came back from the far shore when we saw the shrine light. Thank you."]]:
		var n := Npc.new()
		n.sheet = f[0]
		n.display = f[1]
		add_child(n)
		n.global_position = _ground(f[2], f[3])
		n.on_talk = func() -> void: await Dialogue.i.talk([[f[1], f[4]]])
		folk_later.append(n)


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
	var lit := 1 + Quests.shrines_lit() * 2
	for k in lanterns.size():
		set_lantern(lanterns[k], k < lit)
	for k in folk_later.size():
		var here: bool = Quests.shrines_lit() > k
		folk_later[k].visible = here
		folk_later[k].enabled = here
