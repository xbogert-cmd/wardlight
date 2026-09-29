extends ShrineArea
## The Stilled Grove: a pale, grey wood where the Hollowing has stopped
## everything mid-motion. A deer, two Reedfolk, a hound and a traveller stand
## frozen along the path like statues; even the pond doesn't ripple. A wall of
## stilled roots closes the way to the shrine glade: thawing it is this
## area's contextual magic. When the shrine burns, colour floods back and the
## stilled shapes wake and leave.

const WALL_X := 12.5
const STILL := Color(0.72, 0.75, 0.8)

var stilled: Array[PixelBillboard] = []
var roots: Array[PixelBillboard] = []
var root_body: StaticBody3D
var roots_it: Interactable
var env: Environment


func _area_layout() -> void:
	id = &"stilled_grove"
	display_name = "The Stilled Grove"
	env_preset = &"grove"
	seed_value = 263
	shrine_flag = &"shrine_grove"
	relic = &"stillwater"
	paths = [[Vector2(-30, 0.5), Vector2(-15, -0.4), Vector2(-8, 1.0), Vector2(0, 0.0), Vector2(7, -0.8), Vector2(12, 0.0), Vector2(16, -0.6), Vector2(21, -2.5)]]
	streams = [{"pts": [Vector2(-2, 5.5), Vector2(3, 6.0)], "width": 1.6, "depth": 0.6, "water_y": -0.35, "cap": true, "flow": Vector2.ZERO,
		"tint": Color(0.86, 0.88, 0.92)}]
	hills = [[-14, -8, 1.2, 3.5], [-6, -8.5, 1.0, 3.0], [6, -9, 1.4, 4.0], [16, -9.5, 1.2, 4.0], [-10, 6.5, 0.5, 3.0], [8, 7.0, 0.5, 3.0]]
	spawns = [[&"husk", -14.0, 1.5], [&"hound", -10.0, -1.5], [&"moth", -3.0, -4.0], [&"knot", 2.0, 2.8], [&"raider", 5.0, 1.2], [&"husk", 7.5, -2.0]]
	guards = [[&"hound", 19.5, 0.5, {"hollowed": true}], [&"hound", 22.0, -0.5, {"hollowed": true}], [&"hexer", 23.0, -5.0, {"hollowed": true}], [&"moth", 17.5, -5.5]]
	arrive_lines = [["Kess", "It's so quiet. No wind, no birds, nothing."],
		["Kess", "Look at that deer, {name}. It isn't stone. It's... stopped."]]
	lit_lines = [["", "Colour floods back into the grove. The deer blinks, shakes itself and bolts into the trees."],
		["", "The Reedfolk stumble, gasp, and stare at their own hands. One of them laughs, and then cannot stop."]]


func _area_build() -> void:
	for we in get_children():
		if we is WorldEnvironment:
			env = (we as WorldEnvironment).environment
	_statues()
	_root_wall()
	chest(-6.0, -7.8, &"chest_grove", [[&"reedwhistle"]], 20, -0.2)
	checkpoint_stone(7.5, -2.9, &"mid")
	trees(Rect2(-40, -30, 80, 20), 46, func(p: Vector2) -> bool: return p.y < -9.0, ["oak.png", "pine_a.png", "pine_b.png", "oak.png"])
	trees(Rect2(-40, 10, 80, 14), 18, func(p: Vector2) -> bool: return p.y > 10.5, ["oak.png", "pine_a.png"])
	scenery(Rect2(-28, -12, 56, 22), 170, func(p: Vector2) -> bool: return path_dist(p) > 1.5 and absf(p.x - WALL_X) > 1.2 and p.distance_to(shrine_at) > 3.8,
		["tuft_a", "tuft_b", "tuft_c", "flowers", "fern", "bush_s", "rock_s", "rock_l", "shrooms"])
	for lp: Array in [[-17.0, -1.6, 1.0], [2.0, -2.2, -1.0]]:
		var l := lantern_post(lp[0], lp[1], lp[2], true)
		(l.light as OmniLight3D).light_color = Color(0.85, 0.9, 1.0)


func _frame(sheet: String, f: int) -> Rect2:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/%s.json" % sheet))
	var cw := int(meta.cell[0])
	var ch := int(meta.cell[1])
	var hf := int(meta.hframes)
	return Rect2((f % hf) * cw, (f / hf) * ch, cw, ch)


## Villagers and creatures stopped mid-motion, grey as the grove. All stand
## level with or north of the path (the people are taller than the camera rule).
func _statues() -> void:
	for s: Array in [["npc_fawn", 12, -12.0, -2.4], ["npc_reedfolk_a", 10, -4.0, -2.6], ["hound", 1, 3.0, 2.3],
			["npc_reedfolk_b", 5, 9.0, -2.9], ["npc_traveler_b", 11, 15.5, -3.6]]:
		var b := bill(load("res://assets/generated/%s.png" % s[0]), _ground(s[2], s[3]), 1.0, _frame(s[0], s[1]))
		b.set_tint(STILL)
		stilled.append(b)


## A wall of stilled roots across the whole glade, sealed by an unseen wall
## until thawed.
func _root_wall() -> void:
	for k in 40:
		var z := -11.5 + k * 0.55 + rng.randf_range(-0.15, 0.15)
		for row in 2:
			var x := WALL_X + (row - 0.5) * 0.6 + rng.randf_range(-0.15, 0.15)
			var r := bill(load(D + ("roots.png" if (k + row) % 3 else "thorns.png")), _ground(x, z), rng.randf_range(0.9, 1.3))
			r.set_tint(Color(0.82, 0.88, 1.0))
			roots.append(r)
	root_body = StaticBody3D.new()
	add_child(root_body)
	_wall(root_body, Vector3(WALL_X, 0, -1.0), Vector3(0.8, 40, 22))
	roots_it = Interactable.make(_ground(WALL_X - 1.6, 0.0), "Thaw the stilled roots", 2.2, 1.6)
	add_child(roots_it)
	roots_it.activated.connect(func(p: Player) -> void:
		roots_it.enabled = false
		var ramp := Pal.school(StringName(p.wiz.school))
		for r in roots:
			if randf() < 0.3:
				SpellEffect.later(randf() * 1.6, func() -> void:
					FX3.burst(r.global_position + Vector3(0, 0.5, 0), 3, ramp, Vector2(0.3, 1.5), Vector2(0.3, 0.6), {"gravity": -1.0}))
		await channel(p, _ground(WALL_X, 0.0) + Vector3(0, 0.6, 0), ramp, 2.0)
		GameState.set_flag(&"grove_thawed")
		Sfx.play("roots", 0.0)
		GameCamera3D.shake_all(2.0)
		_open_wall(true)
		await get_tree().create_timer(1.2).timeout
		await Dialogue.i.talk([["", "Warmth runs from your staff into the roots. They creak, soften, and sink back into the earth."]]))


func _open_wall(animate: bool) -> void:
	root_body.collision_layer = 0
	roots_it.enabled = false
	for r in roots:
		if animate:
			var tw := r.create_tween()
			tw.tween_interval(randf() * 0.6)
			tw.tween_property(r, "position:y", r.position.y - 1.4, 1.0).set_trans(Tween.TRANS_QUAD)
			tw.tween_callback(func() -> void: r.visible = false)
		else:
			r.visible = false


func _on_lit() -> void:
	var tw := create_tween()
	tw.tween_property(env, "adjustment_saturation", 1.0, 2.5)
	for b in stilled:
		FX3.burst(b.global_position + Vector3(0, 0.8, 0), 18, [Color("ffffff"), Color("f0e8c8"), Color("c8e8b0")], Vector2(0.5, 2.5), Vector2(0.5, 1.0), {"gravity": -1.0})
		var t2 := b.create_tween()
		t2.tween_method(b.set_tint, STILL, Color.WHITE, 1.5)
		t2.tween_interval(1.5)
		t2.tween_method(b.set_fade, 0.0, 1.0, 1.0)
		t2.tween_callback(func() -> void: b.visible = false)


func apply_state() -> void:
	super.apply_state()
	if GameState.flag(&"grove_thawed"):
		_open_wall(false)
	var lit: bool = GameState.flag(shrine_flag)
	env.adjustment_saturation = 1.0 if lit else 0.35
	for b in stilled:
		b.visible = not lit
