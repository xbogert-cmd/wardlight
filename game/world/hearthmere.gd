extends Region
## Hearthmere: the village below the sanctuary. Houses round a square with
## the village wardlight at its heart, dark when the story begins. After the
## Old Ward is cleansed the wardlight and lanterns return, rescued travellers
## are in the square, the roots are gone from the east road, and everyone's
## lines change. Isolde keeps a garden stall here if she chose the village.
## Chapter 2 opens here: once Chapter 1 is done, wounded Kess reaches the
## square, and afterwards a waystone by the west road leads to the Fenway.

var wardlight: Dictionary
var lanterns: Array = []
var houses: Array = []
var road_roots: Array[Node3D] = []
var garland: Array[Node3D] = []
var maren: Npc
var villagers: Array[Npc] = []
var returnees: Array[Npc] = []
var isolde: Npc
var stall: Array[Node3D] = []
var kess: Npc
var way: Interactable


func _layout() -> void:
	id = &"hearthmere"
	display_name = "Hearthmere"
	music = "home"
	env_preset = &"dusk"
	seed_value = 91
	origin = Vector2(-40, -40)
	grid = Vector2i(80, 80)
	bounds = Rect2(-24, -16, 48, 30)
	roads = [[Vector2(-26, 2), Vector2(-12, 1.5), Vector2(-3, 1), Vector2(6, 0), Vector2(15, -0.5), Vector2(26, -1)],
		[Vector2(-4, 1), Vector2(-4, -7)], [Vector2(5, 0), Vector2(5, -7.5)]]
	hills = [[-16, 14, 3.0, 7.0], [14, 14, 2.6, 6.5], [0, -22, 3.5, 10.0], [-22, -10, 2.5, 7.0], [22, -12, 2.5, 7.0]]
	pads = [[0, 0, 9.0, 0.3], [-12, -9, 3.5, 0.3], [-4, -10.5, 3.8, 0.35], [5, -10, 3.5, 0.3], [13, -8.5, 3.5, 0.25],
		[-11, 8.5, 3.5, 0.25], [10, 9, 3.8, 0.25]]
	dirt_spots = [[0, 0, 6.0], [12.5, -4.8, 2.5]]
	entries = {&"west": [Vector3(-21.5, 0, 2.0), 1.0], &"start": [Vector3(-21.5, 0, 2.0), 1.0], &"east": [Vector3(21.5, 0, -1.0), -1.0],
		&"square": [Vector3(-2.5, 0, 3.0), 1.0], &"waystone": [Vector3(-16.0, 0, -1.4), 1.0]}
	exits = [{"rect": Rect2(-25, -3, 2.5, 10), "to": &"sanctuary", "entry": &"east"},
		{"rect": Rect2(22.5, -6, 2.5, 10), "to": &"briarwood", "entry": &"west"}]
	respawn_entry = &"square"


func _build() -> void:
	houses.append(house(-12, -9, 5.0, 4.0, 2.5, {"chimney": true, "tint": Color(1.0, 0.92, 0.85)}))
	houses.append(house(-4, -10.5, 6.0, 4.4, 2.8, {"windows": [-2.0, 2.0], "door_x": 0.0, "tint": Color(0.92, 0.95, 1.0), "lit": false}))
	houses.append(house(5, -10, 5.0, 4.0, 2.6, {"roof": "thatch.png", "tint": Color(1.0, 0.95, 0.8), "lit": false}))
	houses.append(house(13, -8.5, 5.0, 4.0, 2.4, {"chimney": true, "tint": Color(0.95, 0.88, 0.85)}))
	houses.append(house(-11, 8.5, 5.0, 3.8, 2.4, {"roof": "thatch.png", "lit": false}))
	houses.append(house(10, 9, 6.0, 4.0, 2.6, {"windows": [-2.0, 0.5], "door_x": 2.0, "tint": Color(0.9, 0.92, 1.0)}))
	wardlight = ward_stone(0.0, -1.5, false, true)
	for lp: Array in [[-8.5, 4.0, 1.0], [8.0, 3.2, -1.0], [-8.0, -4.5, 1.0], [8.5, -4.8, -1.0], [18.0, 1.8, -1.0], [-17.0, 4.2, 1.0]]:
		lanterns.append(lantern_post(lp[0], lp[1], lp[2], false))
	# the well
	var wg := _ground(4.5, 3.6)
	for k in 8:
		var a := k * TAU / 8.0
		box(Vector3(0.5, 0.7, 0.3), wg + Vector3(cos(a) * 0.75, 0.3, sin(a) * 0.75), "bricks.png", Vector3(0, -a, 0), k == 0)
	box(Vector3(0.15, 1.8, 0.15), wg + Vector3(-0.8, 0.9, 0), "wood.png", Vector3.ZERO, false)
	box(Vector3(0.15, 1.8, 0.15), wg + Vector3(0.8, 0.9, 0), "wood.png", Vector3.ZERO, false)
	box(Vector3(2.0, 0.2, 0.2), wg + Vector3(0, 1.8, 0), "wood.png", Vector3.ZERO, false)
	# the smithy corner and market clutter
	brazier(12.5, -4.5)
	for c: Array in [[-7.0, -6.0, "crate.png"], [-6.2, -6.4, "barrel.png"], [9.5, -6.2, "barrel.png"], [15.0, -5.0, "crate.png"],
			[-13.5, -5.5, "crate.png"], [-12.8, 5.5, "barrel.png"], [7.0, 6.2, "crate.png"]]:
		bill(load(D + c[2]), _ground(c[0], c[1]))
	bill(load(D + "signpost.png"), _ground(-19.5, 0.0))
	bill(load(D + "signpost.png"), _ground(19.5, -2.5))
	# roots breaking through the east road (gone once the ward is restored)
	for k in 7:
		var p := Vector2(14.0 + k * 1.4, -0.6 + randf_range(-1.0, 1.0))
		var r := bill(load(D + ("thorns.png" if k % 2 else "roots.png")), _ground(p.x, p.y), randf_range(0.8, 1.1))
		road_roots.append(r)
	# a garland arch over the east road (appears with the restoration)
	for z: float in [-3.0, 1.2]:
		var g := _ground(20.5, z)
		garland.append(box(Vector3(0.2, 3.2, 0.2), g + Vector3(0, 1.6, 0), "wood.png", Vector3.ZERO, true))
	var gm := box(Vector3(0.2, 0.2, 4.4), _ground(20.5, -0.9) + Vector3(0, 3.1, 0), "wood.png", Vector3.ZERO, false)
	garland.append(gm)
	var ban := bill(load(D + "banner.png"), _ground(20.5, -0.9) + Vector3(0, 1.4, 0.05), 0.9)
	garland.append(ban)
	_stall()
	_people()
	var keep := func(p: Vector2) -> bool:
		return path_dist(p) > 2.5 and p.length() > 10.5 and not _near_house(p)
	trees(Rect2(-36, -30, 72, 52), 90, func(p: Vector2) -> bool: return keep.call(p) and (not bounds.grow(-2.5).has_point(p) or rng.randf() < 0.15))
	scenery(Rect2(-24, -16, 48, 30), 140, func(p: Vector2) -> bool: return path_dist(p) > 1.6 and p.length() > 7.0 and not _near_house(p),
		["tuft_a", "tuft_b", "tuft_c", "flowers", "bush_s", "fern", "rock_s", "flowers"])


func _near_house(p: Vector2) -> bool:
	for pd: Array in pads:
		if pd[2] < 5.0 and p.distance_to(Vector2(pd[0], pd[1])) < pd[2] + 0.5:
			return true
	return false


func _stall() -> void:
	var g := _ground(-7.5, 3.8)
	stall.append(box(Vector3(2.4, 0.9, 1.0), g + Vector3(0, 0.45, 0), "wood.png", Vector3.ZERO, true, Color(0.85, 0.75, 0.6)))
	for x: float in [-1.1, 1.1]:
		stall.append(box(Vector3(0.12, 2.2, 0.12), g + Vector3(x, 1.1, -0.4), "wood.png", Vector3.ZERO, false))
	stall.append(box(Vector3(2.6, 0.1, 1.4), g + Vector3(0, 2.2, 0), "thatch.png", Vector3(0.15, 0, 0), false))
	for k in 4:
		var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
		var r: Array = props["flowers" if k % 2 else "fern"]
		stall.append(bill(load("res://assets/generated/props_woods.png"), g + Vector3(-0.9 + k * 0.6, 0.9, 0), 1.0, Rect2(r[0], r[1], r[2], r[3])))
	isolde = Npc.new()
	isolde.sheet = "isolde"
	isolde.display = "Isolde"
	add_child(isolde)
	isolde.global_position = _ground(-7.5, 4.9)
	isolde.on_talk = func() -> void:
		var k: int = await Dialogue.i.choose("Isolde", "Nightbloom tonic, {name}? First one's free for the wizard who carried us home.", ["A tonic, please", "Not now"])
		if k == 0:
			player.health.heal(player.health.max_hp)
			player.mana.refill()
			FX3.burst(player.center(), 20, Pal.HEAL, Vector2(0.5, 2.0), Vector2(0.4, 0.8), {"gravity": -1.0})
			await Dialogue.i.talk([["Isolde", "Maren's already got me mending half the village. I don't mind."]])
	stall.append(isolde)


func _npc(sheet: String, name: String, x: float, z: float, lines: Callable) -> Npc:
	var n := Npc.new()
	n.sheet = sheet
	n.display = name
	add_child(n)
	n.global_position = _ground(x, z)
	n.on_talk = func() -> void: await Dialogue.i.talk(lines.call())
	return n


func _people() -> void:
	maren = Npc.new()
	maren.sheet = "maren"
	maren.display = "Elder Maren"
	add_child(maren)
	maren.global_position = _ground(-2.0, 1.6)
	maren.on_talk = _talk_maren
	kess = Npc.new()
	kess.sheet = "kess"
	kess.display = "Kess"
	add_child(kess)
	kess.global_position = _ground(0.3, 2.6)
	kess.on_talk = _opening
	var restored := func() -> bool: return GameState.flag(&"ward_restored")
	var smith := _npc("smith", "Brannoc the smith", 11.5, -3.2, func() -> Array:
		return [["Brannoc", "Can't work the forge with that wardlight dark. Feels like the whole wood is leaning in on us."]])
	smith.on_talk = _talk_smith
	villagers.append(smith)
	villagers.append(_npc("farmer", "Hild", -9.5, -4.0, func() -> Array:
		return ([["Hild", "The lanterns are back! My little ones slept the whole night through."]] if restored.call() else [["Hild", "Oswin went down the Briarwood road three days ago for salt. He's never been gone this long, {name}."]])))
	var tobin := _npc("elder_man", "Old Tobin", -5.5, 5.8, func() -> Array:
		return [["Old Tobin", "Seventy winters, and the wardlight never slept once. Something's wrong out at the Old Ward, you mark me."]])
	tobin.on_talk = func() -> void:
		if not restored.call():
			await Dialogue.i.talk([["Old Tobin", "Seventy winters, and the wardlight never slept once. Something's wrong out at the Old Ward, you mark me."]])
		elif GameState.once(&"gift_bookshelf", func() -> void: give_decor(&"bookshelf", "Tobin's bookshelf")):
			await Dialogue.i.talk([["Old Tobin", "They'll sing about this at harvest, {name}. Not a legend yet, mind. But it's a start."],
				["Old Tobin", "My old books want a wizard's shelf. Take them, and the shelf with them."]])
		else:
			await Dialogue.i.talk([["Old Tobin", "Not a legend yet, mind. But it's a start."]])
	villagers.append(tobin)
	for t: Array in [["traveler_a", "Oswin", 2.8, 4.8], ["traveler_b", "Wenna", 3.8, 5.5]]:
		var n := _npc(t[0], t[1], t[2], t[3], func() -> Array:
			return [[t[1], "We'd be roots and bones by now if you hadn't come, {name}. Hearthmere owes you."]])
		n.on_talk = func() -> void:
			if GameState.once(&"gift_tent", func() -> void: give_decor(&"tent", "a travelling tent")):
				await Dialogue.i.talk([[t[1], "We'd be roots and bones by now if you hadn't come, {name}."],
					[t[1], "Take our old tent for your sanctuary. We're not going anywhere for a while."]])
			else:
				await Dialogue.i.talk([[t[1], "Hearthmere owes you, {name}. We all do."]])
		returnees.append(n)


const SHOP := [[&"stormglass", 35], [&"ember_seed", 35], [&"whisper_bone", 35], [&"moonstone", 35], [&"gale_feather", 35], [&"mistcloak", 80]]


func _talk_smith() -> void:
	if not GameState.flag(&"ward_restored"):
		await Dialogue.i.talk([["Brannoc", "Can't work the forge with that wardlight dark. Feels like the whole wood is leaning in on us."]])
		return
	var first := GameState.once(&"smith_open")
	var opts: Array = []
	for s: Array in SHOP:
		opts.append("%s  (%d coins)" % [Items.def(s[0]).name, s[1]])
	opts.append("Nothing today")
	var k: int = await Dialogue.i.choose("Brannoc", ("The forge is lit again, {name}! " if first else "") + "Trinkets from the road, cleaned and mended. Coin's coin. (You have %d.)" % GameState.inv.coins, opts)
	if k >= SHOP.size():
		return
	var item: Array = SHOP[k]
	if not GameState.inv.spend(item[1]):
		await Dialogue.i.talk([["Brannoc", "That's more coin than you've got, friend."]])
		return
	give(item[0])
	Sfx.play("mote", 0.0)
	SaveSystem.autosave()


func enter(p: Player, entry: StringName) -> void:
	super.enter(p, entry)
	if Quests.hollowing_ready():
		GameState.start_quest(Quests.HOLLOWING)
		apply_state()
		SaveSystem.autosave()
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.banner("Voices in the square: Elder Maren is calling for you")


## Chapter 2's opening: Kess, wounded, with a shard of a hollow mask.
func _opening() -> void:
	if GameState.quest_step(Quests.HOLLOWING) != 0:
		await Dialogue.i.talk([["Kess", "Ready when you are. The waystone by the west road."]])
		return
	await Dialogue.i.talk([
		["Kess", "You're the wizard? The one who woke the Old Ward?"],
		["Elder Maren", "{name}, this is Kess. She came out of the east marsh an hour ago, bleeding."],
		["Kess", "Reedhollow sent me. Our lake's light is failing, the way yours did. Only worse."],
		["Kess", "Something came up out of the water wearing a face. It left this behind."],
		["", "Kess holds out a shard of pale wood, carved like a mask and hollow behind the eyes."],
		["Elder Maren", "The Hollowed Warden at the Old Ward wore a mask like that."],
		["Elder Maren", "So it was never one sick ward. Something is doing this. The wider world has come knocking, {name}."],
		["Kess", "The Fenway road starts at a waystone. I can still walk. I'll show you the way."],
		["Elder Maren", "The old waystone by the west road has woken. Go carefully, both of you."],
	])
	GameState.recruit(&"kess", true)
	GameState.advance(Quests.HOLLOWING, 1)
	apply_state()
	get_tree().root.get_node("Main").sync_party()
	SaveSystem.autosave()


## The waystone by the west road wakes with Chapter 2 (built once, on demand).
func _ensure_waystone() -> void:
	if way:
		return
	way = waystone(-17.5, -4.2, "Waystone: travel")
	way.activated.connect(func(_p: Player) -> void:
		var k: int = await Dialogue.i.choose("", "The waystone hums with the road's memory.", ["The Fenway", "Stay"])
		if k == 0:
			exit_requested.emit(&"fenway", &"waystone"))


func _talk_maren() -> void:
	if GameState.quest_step(Quests.HOLLOWING) == 0:
		await _opening()
		return
	if GameState.quest_active(Quests.HOLLOWING):
		await Dialogue.i.talk([["Elder Maren", "Reedhollow needs you, {name}. The waystone by the west road will take you to the Fenway."]])
		return
	var step := GameState.quest_step(Quests.MAIN)
	if GameState.flag(&"ward_restored") and not GameState.quest_done(Quests.MAIN):
		await Dialogue.i.talk([
			["Elder Maren", "{name}. We saw it from the square: the light came racing up the road like a tide, and the wardlight woke."],
			["Elder Maren", "You brought our people home and gave us back the night. Hearthmere won't forget it."],
			["Elder Maren", "Word will travel, you know. Further than our little road. Take this; it was my mother's."],
		])
		GameState.once(&"maren_reward", func() -> void:
			GameState.set_flag(&"hp_bonus", 20.0)
			player.apply_bonuses()
			player.health.heal(player.health.max_hp)
			give_point())
		GameState.advance(Quests.MAIN, -1)
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.banner("Maren's ward-charm: +20 health")
		return
	if GameState.quest_done(Quests.MAIN):
		await Dialogue.i.talk([["Elder Maren", "Rest while you can, {name}. The wider world will come knocking soon enough."]])
		return
	if step <= 0:
		GameState.start_quest(Quests.MAIN)
		await Dialogue.i.talk([
			["Elder Maren", "{name}. Thank the stars Pell found you."],
			["Elder Maren", "Our wardlight draws its light from the Old Ward beyond Briarwood. Three nights ago it went dark, and the roots began to come."],
			["Elder Maren", "Travellers are missing on the road: Oswin, Wenna, and Isolde the herbalist among them."],
			["Elder Maren", "There's a roadside ward on the Briarwood road. Relight it and the road will be safer. Then find our people."],
		])
		GameState.advance(Quests.MAIN, 1)
		return
	var hints := {1: "The roadside ward stands where the Briarwood road leaves the trees. Relight it.",
		2: "A trunk across the road, you say? Nothing a wizard can't lift.",
		3: "Beyond the broken gate... be careful. Something tore that gate apart.",
		4: "Isolde's safe? Stars be thanked. Now the Old Ward. The waystone by the gate will take you.",
		5: "The Old Ward's guardian kept it for a thousand years. If it's turned, it will fight like the forest itself."}
	await Dialogue.i.talk([["Elder Maren", hints.get(step, "Go carefully, {name}.")]])


func apply_state() -> void:
	var met: bool = GameState.quest_step(Quests.HOLLOWING) == 0
	kess.visible = met
	kess.enabled = met
	if GameState.quest_step(Quests.HOLLOWING) >= 1 or GameState.quest_done(Quests.HOLLOWING):
		_ensure_waystone()
	var restored: bool = GameState.flag(&"ward_restored")
	set_ward(wardlight, restored)
	for l: Dictionary in lanterns:
		set_lantern(l, restored)
	for h: Dictionary in houses:
		if restored:
			set_windows(h, true)
	for r in road_roots:
		r.visible = not restored
	for g in garland:
		g.visible = restored
		for c in g.get_children():
			if c is StaticBody3D:
				(c as StaticBody3D).collision_layer = 1 if restored else 0
	var back: bool = GameState.flag(&"travelers_rescued")
	for n in returnees:
		n.visible = back
		n.enabled = back
	var here: bool = GameState.flag(&"isolde_home", "") == "village"
	for s in stall:
		s.visible = here
		if s is Interactable:
			(s as Interactable).enabled = here
		for c in s.get_children():
			if c is StaticBody3D:
				(c as StaticBody3D).collision_layer = 1 if here else 0
