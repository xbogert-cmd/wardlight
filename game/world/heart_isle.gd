extends Region
## The Heart Isle: an island in the deep middle of the lake, sealed until
## all three shrines burn. A short climb from the landing (Hollowing things
## on the way, a rune stone before the clearing) to the round clearing where
## the Deepwillow stands at the north edge. The clearing seals once the
## wizard is inside and the fight begins; when the tree is spent, the
## wizard cleanses it (contextual magic) and Chapter 2 ends.

const TREE := Vector2(2.0, -12.0)
const ARENA := Vector2(2.0, -7.0)
const ARENA_R := 8.5
const ISLE := Vector2(0.0, -4.0)
const ISLE_R := Vector2(21.0, 12.5)
const CLEANSE := [Color("ffffff"), Color("f0ffd0"), Color("a8e890"), Color("4a8a5a")]

var tree: Deepwillow
var healed_tree: PixelBillboard
var arena_wall: StaticBody3D
var cleanse_it: Interactable


func _layout() -> void:
	id = &"heart_isle"
	display_name = "The Heart Isle"
	music = "lake"
	boss_music = "deepwillow"
	env_preset = &"lake"
	seed_value = 283
	origin = Vector2(-40, -40)
	grid = Vector2i(80, 80)
	bounds = Rect2(-26, -20, 52, 30)
	enemy_scale = 1.25
	paths = [[Vector2(-30, 3.0), Vector2(-16, 3.0), Vector2(-10, 2.2), Vector2(-4, 2.4), Vector2(2, 1.6)]]
	streams = [{"pts": [Vector2(-60, -4), Vector2(60, -4)], "width": 34.0, "depth": 0.0, "water_y": -0.45, "flow": Vector2(0.04, -0.02)}]
	hills = [[-8, -10, 1.2, 4.0], [14, -4, 1.0, 4.0], [-14, -3, 0.8, 3.0]]
	pads = [[ARENA.x, ARENA.y, ARENA_R + 0.5, 0.25]]
	dirt_spots = [[ARENA.x, ARENA.y, ARENA_R + 1.0]]
	landing_layout(Vector2(-17.0, 3.0))
	if not GameState.flag(&"deepwillow_healed"):
		spawns = [[&"husk", -10.0, 3.2], [&"hound", -8.0, 0.8, {"hollowed": true}], [&"lurker", -5.0, 3.8], [&"moth", -3.0, -1.5],
			[&"deepwillow", TREE.x, TREE.y]]


static func isle(x: float, z: float) -> float:
	return pow((x - ISLE.x) / ISLE_R.x, 2.0) + pow((z - ISLE.y) / ISLE_R.y, 2.0)


func _shape(x: float, z: float, h: float) -> float:
	return lerpf(h, -1.6, smoothstep(0.82, 1.08, isle(x, z)))


## Deep water all round the isle (the landing pier stands in it).
func is_hazard(p: Vector3) -> bool:
	if isle(p.x, p.z) < 1.0:
		return false
	return not Rect2(-22.5, 1.9, 6.0, 2.2).has_point(Vector2(p.x, p.z))


func _build() -> void:
	landing_build(Vector2(-17.0, 3.0))
	checkpoint_stone(-3.0, 3.6, &"clearing")
	# a ring of low standing stones round the clearing, open to the south-west
	for k in 22:
		var a := k * TAU / 22.0
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.3:
			continue
		var p := ARENA + Vector2(cos(a), sin(a)) * (ARENA_R + 0.6)
		var h := rng.randf_range(0.5, 0.95)
		box(Vector3(1.4, h, 0.5), _ground(p.x, p.y) + Vector3(0, h * 0.5 - 0.1, 0), "rune_bricks.png", Vector3(0, -a + PI / 2, 0), true, Color(0.8, 0.95, 0.9))
	arena_wall = StaticBody3D.new()
	add_child(arena_wall)
	_wall(arena_wall, Vector3(ARENA.x, 0, ARENA.y + ARENA_R + 1.0), Vector3(5.0, 40, 0.6))
	arena_wall.collision_layer = 0
	cleanse_it = Interactable.make(_ground(TREE.x, TREE.y + 2.4), "Cleanse the Deepwillow", 2.6, 2.4)
	add_child(cleanse_it)
	cleanse_it.enabled = false
	cleanse_it.activated.connect(_cleanse)
	healed_tree = PixelBillboard.new()
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/deepwillow.json"))
	healed_tree.setup(load("res://assets/generated/deepwillow.png"), Vector2i(int(meta.cell[0]), int(meta.cell[1])), int(meta.hframes), meta.anims, Vector2(84, 152))
	add_child(healed_tree)
	healed_tree.global_position = _ground(TREE.x, TREE.y)
	healed_tree.play(&"healed")
	healed_tree.scale = Vector3.ONE * Deepwillow.SCALE
	var tex: Texture2D = load("res://assets/generated/props_woods.png")
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
	for k in 80:   # reeds round the shore
		var a := rng.randf() * TAU
		var e := rng.randf_range(0.9, 1.0)
		var x := ISLE.x + cos(a) * ISLE_R.x * sqrt(e)
		var z := ISLE.y + sin(a) * ISLE_R.y * sqrt(e)
		if path_dist(Vector2(x, z)) < 1.5 or z > 5.5:
			continue
		var r: Array = props["cattails" if rng.randf() < 0.3 else "reeds"]
		bill(tex, _ground(x, z), rng.randf_range(0.9, 1.2), Rect2(r[0], r[1], r[2], r[3]))
	trees(Rect2(-24, -20, 48, 6), 14, func(p: Vector2) -> bool: return isle(p.x, p.y) < 0.8 and absf(p.x - TREE.x) > 7.0, ["pine_b.png", "oak.png"])
	trees(Rect2(-60, -46, 120, 8), 40, func(_p: Vector2) -> bool: return true, ["pine_a.png", "pine_b.png"])
	scenery(Rect2(-22, -16, 44, 24), 110, func(p: Vector2) -> bool: return isle(p.x, p.y) < 0.85 and path_dist(p) > 1.5 and p.distance_to(ARENA) > ARENA_R + 1.2,
		["tuft_a", "tuft_b", "fern", "flowers", "rock_s", "roots", "shrooms"])
	for k in 20:   # hollow roots across the clearing floor (wither when healed)
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * ARENA_R * 0.9
		var rt := bill(load(D + "roots.png"), _ground(ARENA.x + cos(a) * r, ARENA.y + sin(a) * r), rng.randf_range(0.8, 1.2))
		rt.set_tint(Color(0.8, 0.7, 1.0))
		rt.add_to_group(&"hollow_roots")


func spawn(kind: StringName, x: float, z: float, opts := {}) -> Enemy:
	var e := super.spawn(kind, x, z, opts)
	if kind == &"deepwillow":
		tree = e as Deepwillow
		tree.arena_center = _ground(ARENA.x, ARENA.y)
		tree.spent.connect(_on_spent)
		tree.layer_changed.connect(func(n: int) -> void:
			var hud := get_tree().get_first_node_in_group(&"hud") as HUD
			if hud:
				hud.banner("The bark splits open" if n == 2 else "The hollow core tears free"))
	return e


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if tree and is_instance_valid(tree):
		var inside := player and player.is_alive() \
			and Vector2(player.global_position.x, player.global_position.z).distance_to(ARENA) < ARENA_R
		arena_wall.collision_layer = INVISIBLE if tree.engaged and inside else 0
		if tree.engaged and GameState.once(&"deepwillow_intro"):
			var lines := [["", "The great willow stirs. Its fronds lift like hair in water, and a grey voice fills your head, not quite words."],
				["", "Behind the bark, four knots begin to glow."]]
			if GameState.in_party(&"kess"):
				lines.append(["Kess", "Those knots, {name}! Where the light's coming through, hit it there!"])
			Dialogue.i.talk(lines)


func _on_respawn() -> void:
	arena_wall.collision_layer = 0


func _on_spent() -> void:
	arena_wall.collision_layer = 0
	cleanse_it.enabled = true
	await get_tree().create_timer(0.8).timeout
	await Dialogue.i.talk([["", "The Deepwillow sags, emptied. At the heart of the split bark the hollow core still pulses, weaker now."],
		["", "It can be cleansed. Go to it."]])


## Contextual magic: pour the wizard's light into the hollow core.
func _cleanse(p: Player) -> void:
	cleanse_it.enabled = false
	var core := _ground(TREE.x, TREE.y) + Vector3(0, 3.0, 0.4)
	Sfx.play("ward_light", 0.0)
	for k in 6:
		SpellEffect.later(0.4 * k, func() -> void:
			FX3.ring(_ground(TREE.x, TREE.y) + Vector3(0, 0.1, 0), 0.5, 4.0 + k * 1.5, 0.8, CLEANSE, 2.0))
	await channel(p, core, CLEANSE, 3.0)
	GameState.set_flag(&"deepwillow_healed")
	GameState.set_flag(&"reedfolk_allies")
	FX3.flash(core, 3.0, 0.5, Color(0.9, 1.0, 0.8), 10.0)
	FX3.burst(core, 80, CLEANSE, Vector2(2.0, 8.0), Vector2(0.6, 1.4), {"gravity": -1.0})
	GameCamera3D.shake_all(4.0)
	if is_instance_valid(tree):
		tree.queue_free()
	healed_tree.visible = true
	for r in get_tree().get_nodes_in_group(&"hollow_roots"):
		var tw := (r as Node3D).create_tween()
		tw.tween_property(r, "position:y", (r as Node3D).position.y - 1.5, 1.2).set_delay(randf() * 0.8)
	await get_tree().create_timer(1.6).timeout
	var lines := [["", "Violet light gutters out of the trunk. Green runs up the fronds like sap in spring, and the whole isle sighs."],
		["The Deepwillow", "...Little light. You have woken me. I was dreaming a grey dream, and I could not find its edge."],
		["The Deepwillow", "The masked one came up through my roots and planted its seeds in my heart. But it was not the mask that spoke."],
		["The Deepwillow", "Something far to the east, older than this lake, reached through it. It hungers for the roots of the world. Mine were only the first it found."],
		["The Deepwillow", "Take three workings of the deep water, in thanks. And tell the Reedfolk their lake is theirs again."]]
	if GameState.in_party(&"kess"):
		lines.append(["Kess", "...East. Where Orla saw her grey land."])
	await Dialogue.i.talk(lines)
	GameState.once(&"deepwillow_gifts", func() -> void:
		for sid: StringName in WizardState.LAKE.values():
			p.wiz.unlocked[sid] = true
		give_decor(&"reed_boat", "Reed boat")
		give_decor(&"lake_lantern", "Lake lamp")
		give_point(3)
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.banner("New spells: Boiling Spring, Chain Current, Drowning Grasp"))
	GameState.advance(Quests.HOLLOWING, -1)
	SaveSystem.autosave()
	await get_tree().create_timer(2.0).timeout
	await Dialogue.i.talk([["", "The new workings settle into your spellbook, cool and deep. (Open it with Tab to swap one in.)"],
		["", "The Reedfolk will remember this night. So will the lake."]])
	var hud2 := get_tree().get_first_node_in_group(&"hud") as HUD
	if hud2:
		hud2.banner("Chapter 2 complete: The Hollowing")


func apply_state() -> void:
	var healed: bool = GameState.flag(&"deepwillow_healed")
	healed_tree.visible = healed
	if healed:
		for r in get_tree().get_nodes_in_group(&"hollow_roots"):
			(r as Node3D).visible = false
