extends Region
## The Fenway: a marsh road under teal fog, from its waystone (west) to
## Reedhollow on the lake (east). Shallow pools and reeds along the road,
## dead trees on the northern mounds. Chapter 2's first fights: familiar
## enemies, a quarter stronger than Chapter 1's.

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
	hills = [[-20, -14, 1.4, 5.0], [0, -13, 1.6, 6.0], [20, -14, 1.3, 5.0], [-8, 14, 0.8, 5.0], [16, 13, 0.8, 5.0]]
	dirt_spots = [[2, -3.2, 2.0], [-24, 1.0, 2.5]]
	entries = {&"waystone": [Vector3(-24.5, 0, 1.8), 1.0], &"start": [Vector3(-24.5, 0, 1.8), 1.0], &"east": [Vector3(27.0, 0, -1.2), -1.0]}
	exits = [{"rect": Rect2(29.0, -7, 2.5, 12), "to": &"reedhollow", "entry": &"west"}]
	respawn_entry = &"waystone"
	spawns = [[&"hound", -8.0, -1.0], [&"hound", -5.0, 1.8], [&"raider", 12.0, 0.8], [&"hexer", 16.5, -3.2], [&"knot", 21.0, 3.2]]


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


func enter(p: Player, entry: StringName) -> void:
	super.enter(p, entry)
	if GameState.quest_step(Quests.HOLLOWING) == 1:
		GameState.advance(Quests.HOLLOWING, 2)
		await get_tree().create_timer(1.0).timeout
		if GameState.in_party(&"kess"):
			await Dialogue.i.talk([["Kess", "The Fenway. Reedhollow's at the far end, where the lake opens up."],
				["Kess", "Watch the reeds, {name}. Things have been hiding in them since the light started failing."]])
