extends Region
## The Fenway: a marsh road under teal fog, from its waystone (west) to
## Reedhollow on the lake (east). Shallow pools and reeds along the road,
## dead trees on the northern mounds, a drowned reed hut, boulders, and a
## boardwalk out to a hummock with a chest. Chapter 2's first fights:
## familiar enemies, a quarter stronger than Chapter 1's.

const PROPS := "res://assets/generated/props_woods.png"

var stone: Interactable


func _layout() -> void:
	id = &"fenway"
	display_name = "The Fenway"
	music = "lake"
	env_preset = &"marsh"
	seed_value = 211
	origin = Vector2(-40, -40)
	grid = Vector2i(80, 80)
	bounds = Rect2(-30, -13, 60, 24)
	enemy_scale = 1.25
	paths = [[Vector2(-32, 2), Vector2(-22, 2.5), Vector2(-14, 0.5), Vector2(-6, -1.5), Vector2(2, -0.5), Vector2(10, 2),
		Vector2(18, 1), Vector2(26, -1), Vector2(32, -1.5)]]
	# shallow marsh pools (wadeable) either side of the road
	streams = [
		{"pts": [Vector2(-27, -7), Vector2(-19, -9), Vector2(-11, -7.5)], "width": 2.2, "depth": 0.8, "water_y": -0.5, "cap": true, "flow": Vector2(0.05, -0.08)},
		{"pts": [Vector2(-5, 6.5), Vector2(3, 7.5), Vector2(11, 6.5)], "width": 1.9, "depth": 0.8, "water_y": -0.5, "cap": true, "flow": Vector2(0.06, 0.05)},
		{"pts": [Vector2(13, -8), Vector2(21, -6.5), Vector2(29, -8.5)], "width": 2.4, "depth": 0.8, "water_y": -0.5, "cap": true, "flow": Vector2(-0.05, -0.06)},
		{"pts": [Vector2(-22, 8), Vector2(-15, 9)], "width": 1.5, "depth": 0.7, "water_y": -0.45, "cap": true, "flow": Vector2(0.04, 0.04)},
	]
	hills = [[-20, -14, 1.4, 5.0], [0, -13, 1.6, 6.0], [20, -14, 1.3, 5.0], [-8, 14, 0.8, 5.0], [16, 13, 0.8, 5.0],
		# walkable mounds north of the road, low hummocks south of it (camera rule)
		[-12, -9, 1.3, 3.6], [8, -9.5, 1.6, 4.0], [-2, -10, 1.0, 3.0], [23, 7.5, 0.6, 3.2], [-26, 7, 0.5, 3.0], [4, 11.5, 0.5, 2.6]]
	dirt_spots = [[2, -3.2, 2.0], [-24, 1.0, 2.5]]
	entries = {&"waystone": [Vector3(-24.5, 0, 1.8), 1.0], &"start": [Vector3(-24.5, 0, 1.8), 1.0], &"east": [Vector3(27.0, 0, -1.2), -1.0]}
	exits = [{"rect": Rect2(29.0, -7, 2.5, 12), "to": &"reedhollow", "entry": &"west"}]
	respawn_entry = &"waystone"
	# familiar enemies, and the first Husks (the Hollowing's emptied villagers)
	spawns = [[&"hound", -8.0, -1.0], [&"hound", -5.0, 1.8], [&"husk", 5.0, 2.6], [&"raider", 12.0, 0.8], [&"hexer", 16.5, -3.2],
		[&"knot", 21.0, 3.2], [&"husk", 24.0, -2.4], [&"husk", 25.5, 0.6]]


func _build() -> void:
	stone = waystone(-26.5, -3.5, "Waystone: travel")
	stone.activated.connect(func(_p: Player) -> void:
		var k: int = await Dialogue.i.choose("", "The waystone hums with the road's memory.", ["Hearthmere", "Briarwood Road", "Stay"])
		if k == 0:
			exit_requested.emit(&"hearthmere", &"waystone")
		elif k == 1:
			exit_requested.emit(&"briarwood", &"waystone"))
	checkpoint_stone(2.0, -3.4, &"mid")
	var tex: Texture2D = load(PROPS)
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
	# reeds and cattails crowd the pool edges (all low: nothing hides the road)
	for s: Dictionary in streams:
		var pts: Array = s.pts
		for k in 26:
			var a: Vector2 = pts[rng.randi_range(0, pts.size() - 2)]
			var b: Vector2 = pts[pts.find(a) + 1]
			var along := a.lerp(b, rng.randf())
			var side := (b - a).normalized().orthogonal() * (float(s.width) + rng.randf_range(-0.3, 1.2)) * (1.0 if rng.randf() < 0.5 else -1.0)
			var p := along + side
			if path_dist(p) < 1.6:
				continue
			var r: Array = props["cattails" if rng.randf() < 0.35 else "reeds"]
			bill(tex, _ground(p.x, p.y), rng.randf_range(0.9, 1.2), Rect2(r[0], r[1], r[2], r[3]))
	# dead trees and old stumps on the northern mounds only (camera rule)
	trees(Rect2(-36, -30, 72, 16), 34, func(p: Vector2) -> bool: return p.y < -9.0 and path_dist(p) > 3.0, ["dead_tree.png", "pine_b.png", "dead_tree.png"])
	trees(Rect2(-36, 13, 72, 14), 18, func(p: Vector2) -> bool: return p.y > 14.5, ["dead_tree.png", "pine_b.png"])
	scenery(Rect2(-30, -13, 60, 24), 150, func(p: Vector2) -> bool: return path_dist(p) > 1.5,
		["tuft_a", "tuft_b", "tuft_c", "reeds", "cattails", "fern", "rock_s", "stump", "roots", "shrooms"])
	bill(load(D + "signpost.png"), _ground(24.5, 2.8))
	_features(tex, props)


func _features(tex: Texture2D, props: Dictionary) -> void:
	# boulders on the northern mounds
	for b: Array in [[-13.5, -8.0, 1.2], [-11.0, -10.2, 0.8], [7.0, -8.2, 1.4], [9.6, -10.0, 1.0], [-2.5, -8.8, 0.7], [17.5, -10.5, 1.1], [-24.0, -9.5, 0.9]]:
		var g := _ground(b[0], b[1])
		var sz: float = b[2]
		box(Vector3(sz * 1.3, sz, sz), g + Vector3(0, sz * 0.4, 0), "rock.png", Vector3(0.1, rng.randf() * TAU, 0.08), true, Color(0.72, 0.8, 0.78))
		box(Vector3(sz * 0.7, sz * 0.6, sz * 0.8), g + Vector3(sz * 0.7, sz * 0.2, 0.3), "rock.png", Vector3(0, rng.randf() * TAU, 0.15), true, Color(0.66, 0.74, 0.72))
	# a drowned reed hut: low broken walls and a slumped roof
	var hg := _ground(-4.5, -6.5)
	for w: Array in [[Vector3(3.0, 0.9, 0.25), Vector3(0, 0.35, -1.2), 0.0], [Vector3(0.25, 1.2, 2.4), Vector3(-1.4, 0.5, 0), 0.05],
			[Vector3(0.25, 0.6, 1.6), Vector3(1.4, 0.2, -0.4), -0.1], [Vector3(1.2, 0.5, 0.25), Vector3(-0.8, 0.15, 1.2), 0.0]]:
		box(w[0], hg + w[1], "wood.png", Vector3(0, 0, w[2]), true, Color(0.55, 0.52, 0.45))
	box(Vector3(2.8, 0.12, 2.2), hg + Vector3(0.2, 0.9, -0.2), "thatch.png", Vector3(0.25, 0.2, -0.35), false, Color(0.6, 0.62, 0.5))
	var r: Array = props["reeds"]
	for k in 5:
		bill(tex, hg + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.0, 1.0)), 1.1, Rect2(r[0], r[1], r[2], r[3]))
	# fallen logs and old marker posts along the road
	var lg: Array = props["log"]
	for l: Array in [[-17.0, -3.2], [14.5, -2.4], [-9.0, 4.2], [20.0, 4.0]]:
		bill(tex, _ground(l[0], l[1]), 1.0, Rect2(lg[0], lg[1], lg[2], lg[3]))
	for lp: Array in [[-18.0, -0.8, 1.0, false], [-2.0, -3.2, 1.0, true], [15.0, -1.4, -1.0, false]]:
		lantern_post(lp[0], lp[1], lp[2], lp[3])
	# a boardwalk over the southern pool to a hummock with a chest
	bridge(Vector2(4.0, 3.6), Vector2(4.0, 9.8), 0.12, 1.4)
	chest(4.0, 10.6, &"fenway_chest", [[&"gale_feather", 1]], 30)
	# mist drifting off the pools
	var t := Timer.new()
	t.wait_time = 0.35
	t.autostart = true
	t.timeout.connect(func() -> void:
		var s: Dictionary = streams[randi() % streams.size()]
		var pts: Array = s.pts
		var p: Vector2 = (pts[0] as Vector2).lerp(pts[pts.size() - 1], randf())
		FX3.burst(Vector3(p.x, -0.3, p.y), 1, [Color(0.7, 0.85, 0.85, 0.35), Color(0.55, 0.72, 0.72, 0.3), Color(0.4, 0.55, 0.56, 0.25)],
			Vector2(0.1, 0.3), Vector2(2.5, 4.0), {"dir": Vector3(1, 0.3, 0), "spread": 0.6, "gravity": -0.05, "size": 3.0}))
	add_child(t)


func enter(p: Player, entry: StringName) -> void:
	super.enter(p, entry)
	if GameState.quest_step(Quests.HOLLOWING) == 1:
		GameState.advance(Quests.HOLLOWING, 2)
		await get_tree().create_timer(1.0).timeout
		if GameState.in_party(&"kess"):
			await Dialogue.i.talk([["Kess", "The Fenway. Reedhollow's at the far end, where the lake opens up."],
				["Kess", "Watch the reeds, {name}. Things have been hiding in them since the light started failing."]])
