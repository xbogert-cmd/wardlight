extends Region
## The Far Watch: an old watchtower on a high hill across the lake, under a
## dusk sky (Chapter 2's teaser; no fighting). The path climbs the hill's
## south face to the tower, where Orla the mapmaker left her spyglass. From
## the top: a grey, dead land in the east, and something vast moving in it.

const TOWER := Vector2(14.0, -7.0)

var climb: Interactable


func _layout() -> void:
	id = &"far_watch"
	display_name = "The Far Watch"
	music = "lake"
	env_preset = &"farwatch"
	seed_value = 271
	origin = Vector2(-40, -40)
	grid = Vector2i(80, 80)
	bounds = Rect2(-28, -14, 52, 24)
	paths = [[Vector2(-30, 0.5), Vector2(-12, 1.0), Vector2(-2, 0.0), Vector2(6, -1.5), Vector2(10.5, -3.2), Vector2(13.5, -4.6)]]
	hills = [[TOWER.x, TOWER.y, 4.2, 6.0], [-10, -10, 1.4, 4.0], [-2, 9, 0.6, 3.5], [20, 4, 0.8, 4.0]]
	dirt_spots = [[TOWER.x, TOWER.y + 2.0, 2.5]]
	landing_layout(Vector2(-21, 0.5))


func _build() -> void:
	landing_build(Vector2(-21, 0.5))
	var g := _ground(TOWER.x, TOWER.y)
	# the tower (north of the lookout, so it never stands between camera and path)
	box(Vector3(3.0, 6.5, 3.0), g + Vector3(0, 3.0, -0.6), "rune_bricks.png", Vector3(0, 0.1, 0), true, Color(1.0, 0.86, 0.8))
	box(Vector3(3.6, 0.5, 3.6), g + Vector3(0, 6.4, -0.6), "bricks.png", Vector3(0, 0.1, 0), false, Color(1.0, 0.86, 0.8))
	for k in 4:
		box(Vector3(0.6, 0.7, 0.6), g + Vector3(-1.4 + (k % 2) * 2.8, 6.9, -2.0 + (k / 2) * 2.8), "bricks.png", Vector3.ZERO, false, Color(1.0, 0.86, 0.8))
	box(Vector3(1.0, 1.8, 0.1), g + Vector3(0, 0.8, 0.95), "door.png", Vector3(0, 0.1, 0), false)
	light(g + Vector3(1.6, 1.6, 1.4), Color(1.0, 0.6, 0.3), 1.8, 5.0)
	climb = Interactable.make(g + Vector3(0, 0, 1.6), "Climb the watchtower", 2.2, 2.2)
	add_child(climb)
	climb.activated.connect(_climb)
	trees(Rect2(-40, -30, 80, 16), 30, func(p: Vector2) -> bool: return p.y < -10.0 and p.distance_to(TOWER) > 5.0, ["pine_a.png", "pine_b.png", "dead_tree.png"])
	trees(Rect2(-40, 11, 80, 12), 14, func(p: Vector2) -> bool: return p.y > 11.5, ["pine_b.png", "oak.png"])
	scenery(Rect2(-28, -14, 52, 24), 120, func(p: Vector2) -> bool: return path_dist(p) > 1.5 and p.distance_to(TOWER) > 3.5,
		["tuft_a", "tuft_b", "tuft_c", "rock_s", "rock_l", "fern", "flowers", "stump"])
	# old milestones along the climb
	for m: Array in [[-8.0, -1.6], [3.0, -3.0], [9.5, -5.2]]:
		box(Vector3(0.4, 0.8, 0.3), _ground(m[0], m[1]) + Vector3(0, 0.35, 0), "rune_bricks.png", Vector3(0, 0.3, 0.06))


func _climb(p: Player) -> void:
	climb.enabled = false
	var main := get_tree().root.get_node_or_null("Main")
	await Dialogue.i.talk([["", "You climb the winding stair. At the top, wrapped in oilcloth against the damp, lies Orla's brass spyglass."],
		["", "You raise it to the east, past where the lake ends."]])
	await Spyglass.look(main if main else self)
	await Dialogue.i.talk([["", "Beyond the lake the land is grey. No green, no lights, no birds: as if everything there had been emptied out."],
		["", "And something is walking in the haze. Something far too big, pale growths on its back, taking one slow step at a time."],
		["", "Then the haze closes, and there is only the dusk."]])
	if GameState.in_party(&"kess"):
		await Dialogue.i.talk([["Kess", "...Tell me you didn't see that too."]])
	GameState.set_flag(&"saw_the_east")
	GameState.advance(&"far_watch", 1)
	SaveSystem.autosave()
	climb.enabled = true
	climb.prompt = "Look east again"


func apply_state() -> void:
	if GameState.flag(&"saw_the_east"):
		climb.prompt = "Look east again"
