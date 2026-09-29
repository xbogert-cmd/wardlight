extends ShrineArea
## The Sunken Chapel: a ruined lakeside chapel under slate moonlight. The
## path runs east up the old nave (tall walls and columns on its north side
## only, broken stubs to the south) to the shrine in the apse. The lake has
## flooded the middle of the nave: deep water, crossed by levitating, or
## drained by ringing the chapel bell on the west bank (the contextual
## magic). A side chapel on the northern mound keeps a chest.

const FLOOD_X := 4.0
const SLATE := Color(0.78, 0.8, 0.95)

var flood: Dictionary
var bell: MeshInstance3D
var bell_it: Interactable


func _area_layout() -> void:
	id = &"sunken_chapel"
	display_name = "The Sunken Chapel"
	env_preset = &"chapel"
	seed_value = 241
	shrine_flag = &"shrine_chapel"
	relic = &"vesper_candle"
	paths = [[Vector2(-30, 0.5), Vector2(-14, 1.0), Vector2(-8, 0.2), Vector2(0, -0.3), Vector2(8, 0.2), Vector2(15, -0.8), Vector2(21, -2.5)]]
	roads = [[Vector2(-5, -0.1), Vector2(14, -0.6)]]
	flood = {"pts": [Vector2(FLOOD_X, -16), Vector2(FLOOD_X, 14)], "width": 2.4, "depth": 1.0, "water_y": -0.15,
		"flow": Vector2(0.0, 0.04), "tint": Color(0.82, 0.78, 1.0)}
	streams = [flood]
	hills = [[-10, -8.5, 0.9, 3.2], [-2, -10, 1.2, 4.0], [12, -10, 1.3, 4.0], [-18, -8, 1.0, 3.5], [-12, 7.5, 0.4, 3.0], [16, 7, 0.5, 3.0]]
	dirt_spots = [[1.0, -2.6, 2.0]]
	spawns = [[&"hound", -14.0, 1.5], [&"hound", -12.0, -1.0], [&"husk", -6.5, 1.5], [&"moth", 9.5, -3.5], [&"hexer", 12.5, 2.0], [&"husk", 14.0, 0.5]]
	guards = [[&"sentinel", 19.5, -0.5, {"hollowed": true}], [&"hexer", 23.0, -4.5, {"hollowed": true}], [&"moth", 17.0, -5.0]]
	arrive_lines = [["Kess", "The Sunken Chapel. The Reedfolk rang its bell to call the boats home through the fog."],
		["Kess", "The nave's flooded now. If that old bell still rings... I'd like to hear it again."]]
	lit_lines = [["", "Violet light runs up the old columns. For a moment the chapel stands whole, a candle burning in every niche."]]


## The flooded nave is deep water until the bell drains it.
func is_hazard(p: Vector3) -> bool:
	if GameState.flag(&"chapel_drained") or absf(p.x - FLOOD_X) > 3.0:
		return false
	return terrain.height_at(p.x, p.z) < -0.5


func _area_build() -> void:
	_nave()
	_bell()
	_apse()
	chest(-10.0, -8.2, &"chest_chapel", [[&"lakeweave"]], 20, 0.2)
	checkpoint_stone(9.0, -2.9, &"nave")
	# graves in the old churchyard (all low)
	for k in 9:
		var p := Vector2(rng.randf_range(-17, -8), rng.randf_range(4.5, 8.5))
		if path_dist(p) < 2.0:
			continue
		var h := rng.randf_range(0.4, 0.75)
		box(Vector3(0.5, h, 0.18), _ground(p.x, p.y) + Vector3(0, h * 0.5 - 0.05, 0), "rune_bricks.png", Vector3(0, rng.randf_range(-0.2, 0.2), rng.randf_range(-0.15, 0.15)), true, SLATE)
	trees(Rect2(-40, -30, 80, 19), 40, func(p: Vector2) -> bool: return p.y < -9.5 and absf(p.x - FLOOD_X) > 3.5, ["dead_tree.png", "pine_b.png", "dead_tree.png"])
	trees(Rect2(-40, 9, 80, 16), 16, func(p: Vector2) -> bool: return p.y > 10.0 and absf(p.x - FLOOD_X) > 3.5, ["dead_tree.png", "pine_b.png"])
	scenery(Rect2(-28, -12, 56, 22), 130, func(p: Vector2) -> bool: return path_dist(p) > 1.5 and absf(p.x - FLOOD_X) > 3.2 and p.distance_to(shrine_at) > 3.8,
		["tuft_a", "tuft_c", "roots", "rock_s", "rock_l", "shrooms", "fern", "stump"])
	var r: Array = props["reeds"]
	for k in 30:   # reeds where the flood meets the nave floor
		var z := rng.randf_range(-12, 10)
		var x := FLOOD_X + (3.2 + rng.randf_range(-0.3, 0.6)) * (1.0 if k % 2 else -1.0)
		if absf(z) < 1.8:
			continue
		bill(tex, _ground(x, z), rng.randf_range(0.9, 1.15), Rect2(r[0], r[1], r[2], r[3]))
	# moonlit motes over the water
	var t := Timer.new()
	t.wait_time = 0.3
	t.autostart = true
	t.timeout.connect(func() -> void:
		FX3.burst(Vector3(FLOOD_X + randf_range(-2.0, 2.0), -0.1, randf_range(-8, 8)), 1, [Color(0.85, 0.8, 1.0, 0.4), Color(0.6, 0.55, 0.9, 0.3)],
			Vector2(0.1, 0.3), Vector2(2.0, 3.5), {"dir": Vector3.UP, "spread": 0.5, "gravity": -0.1, "size": 2.0}))
	add_child(t)


## The nave: tall walls and columns north of the aisle, only broken stubs
## and toppled pews to the south (the camera looks north over them).
func _nave() -> void:
	for x: float in [-5.0, -2.0, 7.5, 10.5, 13.5]:
		var h := rng.randf_range(2.4, 3.4)
		box(Vector3(2.9, h, 0.6), _ground(x, -6.6) + Vector3(0, h * 0.5 - 0.2, 0), "bricks.png", Vector3(0, rng.randf_range(-0.04, 0.04), 0), true, SLATE)
	for x: float in [-4.0, -0.4, 8.6, 12.2]:
		var h := rng.randf_range(2.8, 3.4)
		var g := _ground(x, -4.6)
		box(Vector3(0.7, h, 0.7), g + Vector3(0, h * 0.5 - 0.2, 0), "rune_bricks.png", Vector3.ZERO, true, SLATE)
		box(Vector3(1.0, 0.3, 1.0), g + Vector3(0, h - 0.2, 0), "bricks.png", Vector3.ZERO, false, SLATE)
		light(g + Vector3(0, h + 0.3, 0.5), Color(0.72, 0.55, 1.0), 1.4, 5.0)
		# its fallen partner across the aisle
		var s := _ground(x, 3.9)
		box(Vector3(0.7, rng.randf_range(0.4, 0.8), 0.7), s + Vector3(0, 0.2, 0), "rune_bricks.png", Vector3(0, rng.randf(), 0), true, SLATE)
	for x: float in [-3.0, 9.8, 12.8]:
		box(Vector3(2.4, rng.randf_range(0.4, 0.8), 0.5), _ground(x, 5.4) + Vector3(0, 0.2, 0), "bricks.png", Vector3(0, rng.randf_range(-0.1, 0.1), 0), true, SLATE)
	for pw: Array in [[-3.4, -2.3, 0.0], [-1.2, -2.4, 0.1], [-3.2, 2.3, 0.0], [-0.8, 2.6, 1.2], [8.8, -2.4, 0.0], [11.2, -2.2, -0.1], [9.2, 2.3, 0.0], [12.0, 2.8, -1.1]]:
		box(Vector3(1.8, 0.45, 0.4), _ground(pw[0], pw[1]) + Vector3(0, 0.2, 0), "wood.png", Vector3(0, pw[2], 0), true, Color(0.62, 0.55, 0.6))


## The chapel bell on the west bank of the flood. Ringing it (contextual
## magic) sends the water back down the crypt drains.
func _bell() -> void:
	var g := _ground(1.0, -3.1)
	for dx: float in [-0.8, 0.8]:
		box(Vector3(0.2, 2.3, 0.2), g + Vector3(dx, 1.1, 0), "wood.png", Vector3.ZERO, true, Color(0.7, 0.62, 0.62))
	box(Vector3(1.9, 0.18, 0.2), g + Vector3(0, 2.25, 0), "wood.png", Vector3.ZERO, false, Color(0.7, 0.62, 0.62))
	bell = box(Vector3(0.62, 0.7, 0.62), g + Vector3(0, 1.75, 0), "bricks.png", Vector3.ZERO, false, Color(0.95, 0.72, 0.42))
	bell_it = Interactable.make(g + Vector3(0, 0, 1.0), "Ring the chapel bell", 2.0, 2.4)
	add_child(bell_it)
	bell_it.activated.connect(func(p: Player) -> void:
		bell_it.enabled = false
		var ramp := Pal.school(StringName(p.wiz.school))
		await channel(p, bell.global_position, ramp, 1.2)
		for k in 3:
			SpellEffect.later(0.7 * k, func() -> void:
				var tw := bell.create_tween()
				tw.tween_property(bell, "rotation:z", 0.45, 0.18).set_trans(Tween.TRANS_SINE)
				tw.tween_property(bell, "rotation:z", -0.35, 0.3).set_trans(Tween.TRANS_SINE)
				tw.tween_property(bell, "rotation:z", 0.0, 0.2)
				Sfx.play("hex_block", 2.0 - k * 3.0, 0.1)
				FX3.ring(bell.global_position, 0.2, 5.0 + k * 3.0, 1.0, [Color("fff4c8"), Color("f0d890"), Color("a08850")], 2.0, false))
		await get_tree().create_timer(1.0).timeout
		GameState.set_flag(&"chapel_drained")
		GameCamera3D.shake_all(1.5)
		Sfx.play("roots", -2.0)
		var water: MeshInstance3D = flood.mesh
		var tw2 := water.create_tween()
		tw2.tween_property(water, "position:y", -0.8, 2.6).set_trans(Tween.TRANS_SINE)
		for k in 20:
			SpellEffect.later(randf() * 2.4, func() -> void:
				FX3.burst(Vector3(FLOOD_X + randf_range(-2, 2), -0.4, randf_range(-6, 6)), 3, [Color(0.85, 0.8, 1.0), Color(0.55, 0.5, 0.85)],
					Vector2(0.5, 2.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 0.6, "gravity": 4.0}))
		await tw2.finished
		await Dialogue.i.talk([["", "The bell's voice rolls out under the water. The flood shivers, then sinks away down the old crypt drains."],
			["", "The drowned aisle lies open, slick and glittering."]]))


## The apse: a half-ring of tall wall behind (north of) the shrine only.
func _apse() -> void:
	for k in 7:
		var a := PI + k * PI / 6.0
		var p := shrine_at + Vector2(cos(a), sin(a)) * 5.6
		if p.y > shrine_at.y - 1.0:
			continue
		var h := rng.randf_range(2.2, 3.2)
		box(Vector3(2.8, h, 0.6), _ground(p.x, p.y) + Vector3(0, h * 0.5 - 0.2, 0), "bricks.png", Vector3(0, -a - PI / 2, 0), true, SLATE)
	for x: float in [16.5, 25.5]:
		light(_ground(x, -4.0) + Vector3(0, 2.0, 0), Color(0.72, 0.55, 1.0), 1.8, 6.0)


func apply_state() -> void:
	super.apply_state()
	var drained: bool = GameState.flag(&"chapel_drained")
	bell_it.enabled = not drained
	if drained:
		(flood.mesh as MeshInstance3D).position.y = -0.8
