extends ShrineArea
## The Mire: a winding path through sickly green fog, between mud pools where
## Lurkers hunt. South of the path lies a deep bog with a hummock in the
## middle, where Pip, a Reedfolk boy, is stranded (the lost child). The old
## stepping stones sank when the mud went bad: raising them out of the bog is
## this area's contextual magic, and Pip runs home across them. The shrine
## stands at the east end among dead trees.

const BOG := Vector2(2.0, 6.8)
const STONES := [3.6, 4.3, 5.0, 5.7]     # z of each stepping stone at x = BOG.x
const MUD := Color(0.62, 0.62, 0.36)
const SUNK_Y := -1.6     # stone centres: tops under the mud...
const RAISED_Y := -0.78  # ...and just above it

var stones: Array[MeshInstance3D] = []
var stones_it: Interactable
var pip: Npc


func _area_layout() -> void:
	id = &"mire"
	display_name = "The Mire"
	env_preset = &"mire"
	seed_value = 257
	shrine_flag = &"shrine_mire"
	relic = &"bogheart"
	paths = [[Vector2(-30, 0.5), Vector2(-15, -1.0), Vector2(-9, 1.2), Vector2(-3, 0.0), Vector2(4, -1.2), Vector2(10, 0.5), Vector2(16, -0.5), Vector2(21, -2.5)]]
	streams = [
		{"pts": [Vector2(-17, -6), Vector2(-10, -7.5)], "width": 2.0, "depth": 0.7, "water_y": -0.45, "cap": true, "flow": Vector2(0.02, 0.01), "tint": MUD},
		{"pts": [Vector2(8, -6.5), Vector2(15, -7.0)], "width": 2.2, "depth": 0.7, "water_y": -0.45, "cap": true, "flow": Vector2(-0.02, 0.01), "tint": MUD},
		{"pts": [Vector2(-14, 6.5), Vector2(-9, 7.5)], "width": 1.6, "depth": 0.6, "water_y": -0.4, "cap": true, "flow": Vector2(0.01, 0.02), "tint": MUD},
		# the deep bog around Pip's hummock
		{"pts": [BOG + Vector2(-3, 0), BOG + Vector2(3, 0)], "width": 3.2, "depth": 1.3, "water_y": -0.4, "cap": true, "flow": Vector2(0.01, -0.01), "tint": MUD},
	]
	hills = [[BOG.x, BOG.y, 1.7, 1.3], [-6, -9.5, 1.2, 3.8], [4, -10, 1.5, 4.0], [18, -9.5, 1.1, 3.5], [-20, -8, 1.0, 3.5], [14, 7.5, 0.5, 3.0]]
	spawns = [[&"lurker", -9.0, 2.8], [&"hound", -5.0, -1.5], [&"husk", 5.0, -2.5], [&"lurker", 7.0, 2.6], [&"raider", 10.0, 1.0], [&"moth", 13.0, -4.0]]
	guards = [[&"raider", 20.0, -0.5, {"hollowed": true}], [&"knot", 23.5, -4.5, {"hollowed": true}], [&"lurker", 17.5, -3.5], [&"lurker", 23.0, 0.5]]
	arrive_lines = [["Kess", "The Mire. Keep to the firmer ground, {name}. Things move under the mud here."],
		["Kess", "Wait. Hear that? Someone's calling out. South of the path, past the bog."]]
	lit_lines = [["", "Green-white light pours across the Mire. The fog thins, and somewhere out in the reeds a frog begins to sing."]]


## The bog is too deep to wade, except on the raised stones or the hummock.
func is_hazard(p: Vector3) -> bool:
	if absf(p.x - BOG.x) > 7.5 or absf(p.z - BOG.y) > 4.5:
		return false
	if GameState.flag(&"mire_stones") and Rect2(BOG.x - 0.7, STONES[0] - 0.6, 1.4, STONES[3] - STONES[0] + 1.2).has_point(Vector2(p.x, p.z)):
		return false
	return terrain.height_at(p.x, p.z) < -0.55


func _area_build() -> void:
	_stones()
	_pip()
	checkpoint_stone(8.5, -3.0, &"mid")
	# dead trees on the northern mounds, drowned stumps and logs about the pools
	trees(Rect2(-40, -30, 80, 20), 44, func(p: Vector2) -> bool: return p.y < -9.0, ["dead_tree.png", "dead_tree.png", "pine_b.png"])
	trees(Rect2(-40, 10, 80, 14), 14, func(p: Vector2) -> bool: return p.y > 11.0, ["dead_tree.png"])
	for s: Dictionary in streams:
		var pts: Array = s.pts
		for k in 22:
			var a: Vector2 = (pts[0] as Vector2).lerp(pts[pts.size() - 1], rng.randf())
			var side := (float(s.width) + rng.randf_range(-0.2, 1.2)) * (1.0 if rng.randf() < 0.5 else -1.0)
			var p := a + Vector2(0, side)
			if path_dist(p) < 1.6 or absf(p.x - BOG.x) < 1.2:
				continue
			var r: Array = props["cattails" if rng.randf() < 0.45 else "reeds"]
			bill(tex, _ground(p.x, p.y), rng.randf_range(0.9, 1.2), Rect2(r[0], r[1], r[2], r[3])).set_tint(Color(0.8, 0.82, 0.7))
	var lg: Array = props["log"]
	for l: Array in [[-12.0, -3.0], [12.5, 3.0], [-2.0, -4.0], [16.0, 2.5]]:
		bill(tex, _ground(l[0], l[1]), 1.0, Rect2(lg[0], lg[1], lg[2], lg[3]))
	# a sunk cart by the path
	var cg := _ground(-15.5, 3.2)
	box(Vector3(1.8, 0.5, 1.0), cg + Vector3(0, 0.05, 0), "wood.png", Vector3(0.2, 0.4, 0.25), true, Color(0.6, 0.62, 0.45))
	box(Vector3(0.12, 0.9, 0.9), cg + Vector3(0.9, 0.2, 0.3), "wood.png", Vector3(0.1, 0.4, 1.2), false, Color(0.5, 0.52, 0.4))
	for lp: Array in [[-18.0, -1.5, 1.0], [0.5, -2.6, -1.0], [14.5, -2.3, 1.0]]:
		var l := lantern_post(lp[0], lp[1], lp[2], true)
		(l.light as OmniLight3D).light_color = Color(0.7, 1.0, 0.5)
		(l.lantern as PixelBillboard).set_tint(Color(0.8, 1.0, 0.7))
	scenery(Rect2(-28, -12, 56, 22), 150, func(p: Vector2) -> bool: return path_dist(p) > 1.5 and p.distance_to(BOG) > 5.0 and p.distance_to(shrine_at) > 3.8,
		["tuft_a", "tuft_b", "reeds", "cattails", "shrooms", "shrooms_red", "roots", "stump", "rock_s"])
	# bubbles on the mud, green motes in the fog
	var t := Timer.new()
	t.wait_time = 0.2
	t.autostart = true
	t.timeout.connect(func() -> void:
		var s: Dictionary = streams[randi() % streams.size()]
		var pts: Array = s.pts
		var p: Vector2 = (pts[0] as Vector2).lerp(pts[pts.size() - 1], randf()) + Vector2(0, randf_range(-1.0, 1.0))
		FX3.burst(Vector3(p.x, float(s.water_y) + 0.05, p.y), 2, [Color("c8d890"), Color("8a9a50"), Color("5a6a30")], Vector2(0.3, 1.2), Vector2(0.2, 0.4), {"dir": Vector3.UP, "spread": 0.8, "gravity": 5.0})
		if player:
			var at := player.global_position + Vector3(randf_range(-12, 12), randf_range(0.3, 2.0), randf_range(-8, 5))
			FX3.burst(at, 1, [Color(0.75, 0.9, 0.45, 0.3), Color(0.55, 0.7, 0.3, 0.2)], Vector2(0.1, 0.3), Vector2(2.0, 3.5), {"size": 3.0}))
	add_child(t)


## The old stepping stones, sunk in the bog until the wizard raises them.
func _stones() -> void:
	for z: float in STONES:
		var s := box(Vector3(0.95, 1.4, 0.6), Vector3(BOG.x + rng.randf_range(-0.1, 0.1), SUNK_Y, z), "rock.png", Vector3(0, rng.randf_range(-0.2, 0.2), 0), true, Color(0.7, 0.72, 0.6))
		stones.append(s)
	var edge := _ground(BOG.x, 2.4)
	var marker := bill(load(D + "roots.png"), edge + Vector3(0.9, 0, 0), 0.8)
	marker.set_tint(Color(0.8, 0.9, 0.7))
	stones_it = Interactable.make(edge, "Raise the old stepping stones", 2.0, 1.4)
	add_child(stones_it)
	stones_it.activated.connect(func(p: Player) -> void:
		stones_it.enabled = false
		var ramp := Pal.school(StringName(p.wiz.school))
		for k in stones.size():
			var s: MeshInstance3D = stones[k]
			var tw := s.create_tween()
			tw.tween_interval(0.3 + k * 0.35)
			tw.tween_property(s, "position:y", RAISED_Y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			SpellEffect.later(0.3 + k * 0.35, func() -> void:
				FX3.burst(s.global_position + Vector3(0, 0.8, 0), 12, [Color("c8d890"), Color("8a9a50"), Color("5a6a30")], Vector2(1.0, 3.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 1.0, "gravity": 7.0})
				Sfx.play("roots", -6.0, 0.2))
		await channel(p, _ground(BOG.x, BOG.y), ramp, 1.8)
		GameState.set_flag(&"mire_stones")
		await _pip_home())


func _pip() -> void:
	pip = Npc.new()
	pip.sheet = "reed_child"
	pip.display = "Pip"
	pip.radius = 2.6
	add_child(pip)
	pip.global_position = _ground(BOG.x + 0.2, BOG.y + 0.2)
	pip.on_talk = func() -> void:
		if not GameState.quest_active(&"lost_child") and not GameState.quest_done(&"lost_child"):
			GameState.start_quest(&"lost_child")
		await Dialogue.i.talk([["Pip", "Wizard? You flew! I can't fly. I can't get back!"],
			["Pip", "There were stepping stones here, but they sank when the mud went bad. Can you make them come up?"]])


## Pip crosses the raised stones and runs for the boat home.
func _pip_home() -> void:
	if not GameState.quest_active(&"lost_child"):
		GameState.start_quest(&"lost_child")
	GameState.advance(&"lost_child", 1)
	GameState.set_flag(&"pip_found")
	SaveSystem.autosave()
	pip.enabled = false
	await Dialogue.i.talk([["Pip", "The stones! They came up!"],
		["Pip", "I only wanted to catch a glow-frog for Mum. I'm going home. Tell her I'm sorry, and that I'm on the boat!"]])
	pip.walk_to = _ground(BOG.x, 2.2)
	await get_tree().create_timer(2.2).timeout
	pip.walk_to = _ground(landing.x + 2.0, landing.y)
	await get_tree().create_timer(2.5).timeout
	var tw := pip.create_tween()
	tw.tween_method(pip.sprite.set_fade, 0.0, 1.0, 0.8)
	tw.tween_callback(func() -> void: pip.visible = false)


func apply_state() -> void:
	super.apply_state()
	var raised: bool = GameState.flag(&"mire_stones")
	stones_it.enabled = not raised
	if raised:
		for s in stones:
			s.position.y = RAISED_Y
	var found: bool = GameState.flag(&"pip_found")
	pip.visible = not found
	pip.enabled = not found
