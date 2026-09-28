extends RefCounted
## Boss sprite sheets (side view, facing right), enemy sheet format.

const Sheets = preload("res://tools/art/enemies_art.gd")

enum B { NONE, SKIN, SKIN2, PLANK, IRON, BEAM, EYE, MOSS, ROCK, BARK, ROOT, RUNE, GLOW, CORE, LEAF }


static func _c(s: String) -> Color:
	return Color.html(s)


static func _ramp(hex: String) -> Array[Color]:
	var b := _c(hex)
	return [b.lightened(0.2), b, b.darkened(0.35)]


# ---------------------------------------------------------------- Gatebreaker troll
## A hulking troll wearing planks of a broken gate as armour, swinging the
## gate's crossbeam. Cell 88×80, feet at (40, 78).
static func troll() -> Dictionary:
	var defs := [["idle", 4, 4.0, true], ["walk", 6, 7.0, true], ["sweep_windup", 3, 5.0, false], ["sweep", 2, 12.0, false],
		["slam_windup", 3, 4.5, false], ["slam", 2, 12.0, false], ["throw_windup", 3, 5.0, false], ["throw", 2, 12.0, false],
		["recover", 2, 3.0, true], ["stagger", 2, 4.0, true], ["hurt", 1, 10.0, false], ["death", 5, 6.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "beam": 110.0})
	for i in 6:
		f.append({"bob": [0, 1, 2, 1, 0, 1][i], "step": [3, 1, -2, -3, -1, 2][i], "beam": 105.0 + [0, 4, 8, 4, 0, -4][i]})
	for i in 3:
		f.append({"lean": -2 - i, "beam": 150.0 + i * 25.0, "bob": 1, "eye": true})
	for i in 2:
		f.append({"lean": 4 + i, "beam": 20.0 - i * 40.0, "step": 3})
	for i in 3:
		f.append({"lean": -1 - i, "beam": -80.0 - i * 20.0, "arms_up": true, "eye": true, "bob": -i})
	for i in 2:
		f.append({"lean": 5, "beam": 60.0 + i * 20.0, "bob": 4 + i * 2, "step": 2})
	for i in 3:
		f.append({"lean": -2 - i, "beam": 120.0, "rock": Vector2(-6 - i * 2, -8 - i * 6), "eye": true})
	for i in 2:
		f.append({"lean": 4, "beam": 120.0, "rock": Vector2(30 + i * 16, 10 - i * 6), "throw_arm": true})
	for i in 2:
		f.append({"lean": 3, "bob": 5, "beam": 75.0, "tired": true})
	for i in 2:
		f.append({"lean": -4, "bob": 3 + i, "beam": 140.0, "tired": true, "eye": true})
	f.append({"lean": -5, "beam": 130.0, "bob": 2})
	for i in 5:
		f.append({"fall": i})
	return Sheets.sheet(f, Vector2i(88, 80), _draw_troll, defs)


static func _draw_troll(c: PixelCanvas, o: Dictionary) -> void:
	var skin := _ramp("6a7a5a")
	var plank := _ramp("7a5a3a")
	var iron := _ramp("5a5a66")
	var beam := _ramp("6a4a2e")
	var moss := _ramp("5a7a3a")
	var rock := _ramp("7a7470")
	if o.has("fall"):
		var fall: int = o.fall
		var tilt := fall * 5.0
		c.ellipse(40 + tilt * 0.4, 66 + fall * 2, 26, 12 - fall, skin[1], B.SKIN)
		c.poly(PackedVector2Array([Vector2(20 + tilt * 0.3, 62 + fall * 2), Vector2(58 + tilt * 0.3, 60 + fall * 2), Vector2(56 + tilt * 0.3, 72), Vector2(22 + tilt * 0.3, 74)]), plank[1], B.PLANK)
		c.stroke(Vector2(60, 76), Vector2(86, 72), 5, beam[1], B.BEAM)
		for pair: Array in [[B.SKIN, skin], [B.PLANK, plank], [B.BEAM, beam]]:
			c.shade(pair[0], pair[1][0], pair[1][2], 2)
		c.outline(_c("0c0a10"), 0.85)
		return
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var st: float = o.get("step", 0)
	var u := Vector2(lean, bob)
	# legs: short, thick
	c.stroke(Vector2(32, 58) + u * 0.4, Vector2(30 - st, 77), 9, skin[2], B.SKIN)
	c.stroke(Vector2(46, 58) + u * 0.4, Vector2(48 + st, 77), 10, skin[1], B.SKIN)
	c.rect(int(24 - st), 74, 12, 4, skin[2], B.SKIN2)
	c.rect(int(43 + st), 74, 13, 4, skin[1], B.SKIN2)
	# back arm
	var bsh := Vector2(30, 28) + u
	c.stroke(bsh, bsh + Vector2(-6, 22 if not o.has("arms_up") else -6), 8, skin[2], B.SKIN)
	# hunched body with gate-plank armour and iron bands
	c.ellipse(40 + lean, 40 + bob, 24, 21, skin[1], B.SKIN)
	c.poly(PackedVector2Array([Vector2(24, 38) + u, Vector2(52, 35) + u, Vector2(55, 57) + u * 0.5, Vector2(26, 60) + u * 0.5]), plank[1], B.PLANK)
	for k in 3:
		var x := 30 + k * 8 + lean
		c.line(int(x), int(37 + bob), int(x + 1), int(58 + bob * 0.5), plank[2], B.PLANK)
	c.rect(int(24 + lean), int(43 + bob), 30, 3, iron[1], B.IRON)
	c.rect(int(25 + lean), int(52 + bob), 30, 3, iron[1], B.IRON)
	for k in 3:
		c.put(int(26 + k * 12 + lean), int(41 + bob), iron[0], B.IRON)
	# moss on the shoulders
	c.ellipse(34 + lean, 24 + bob, 10, 4, moss[1], B.MOSS)
	# head: jutting forward from the hump, heavy brow, tusks
	var head := Vector2(64, 26) + u
	var face := _ramp("8a9a70")
	c.ellipse(head.x, head.y, 10, 9, face[1], B.SKIN2)
	c.poly(PackedVector2Array([head + Vector2(-9, -3), head + Vector2(-4, -10), head + Vector2(6, -9), head + Vector2(10, -4), head + Vector2(2, -4)]), skin[2], B.SKIN)
	c.rect(int(head.x) + 1, int(head.y) - 4, 9, 2, skin[2], B.SKIN)
	var ec := _c("ffd040") if o.get("eye", false) else _c("f0e8c0")
	c.rect(int(head.x) + 4, int(head.y) - 2, 2, 2, ec, B.EYE)
	c.put(int(head.x) + 5, int(head.y) - 1, _c("201810"), B.EYE)
	c.rect(int(head.x) + 2, int(head.y) + 4, 8, 1, _c("2a1a14"), B.EYE)
	for tx in [3, 8]:
		c.poly(PackedVector2Array([head + Vector2(tx, 5), head + Vector2(tx + 2, 5), head + Vector2(tx + 1, 0)]), _c("f0e8d0"), B.EYE)
	# big shoulder over the armour
	c.ellipse(50 + lean, 28 + bob, 9, 8, skin[1], B.SKIN)
	# front arm swinging the gate crossbeam
	var sh := Vector2(50, 30) + u
	var ang := deg_to_rad(o.get("beam", 110.0))
	var hand := sh + Vector2.from_angle(ang * 0.5 + 0.6) * 16.0
	if o.has("arms_up"):
		hand = sh + Vector2(-4, -18)
	c.stroke(sh, hand, 9, skin[1], B.SKIN)
	var tip := hand + Vector2.from_angle(ang) * 36.0
	c.stroke(hand, tip, 6, beam[1], B.BEAM)
	c.rect(int(tip.x) - 4, int(tip.y) - 4, 8, 8, iron[1], B.IRON)
	c.rect(int(hand.x) - 3, int(hand.y) - 3, 6, 6, skin[0], B.SKIN)
	if o.has("rock"):
		var r: Vector2 = o.rock
		c.ellipse(sh.x + r.x, sh.y + r.y, 7, 6, rock[1], B.ROCK)
	for pair: Array in [[B.SKIN, skin], [B.SKIN2, _ramp("8a9a70")], [B.PLANK, plank], [B.IRON, iron], [B.BEAM, beam], [B.MOSS, moss], [B.ROCK, rock]]:
		c.shade(pair[0], pair[1][0], pair[1][2], 2)
	c.outline(_c("0c0a10"), 0.85)


# ---------------------------------------------------------------- Corrupted guardian
## The old forest guardian, grown around the ward: a towering antlered body
## of bark and carved ward-stones, invaded by dark roots. `phase` 2 cracks the
## ward-stones open (violet corruption shows) and roots writhe more.
## Cell 128×120, feet at (60, 118).
static func guardian() -> Dictionary:
	var defs := [["idle", 4, 4.0, true], ["sweep_windup", 3, 5.0, false], ["sweep", 2, 12.0, false],
		["roots_windup", 3, 4.0, false], ["roots", 2, 8.0, false], ["seed_windup", 3, 5.0, false], ["seed", 2, 10.0, false],
		["recover", 2, 3.0, true], ["transform", 6, 5.0, false], ["idle2", 4, 5.0, true], ["hurt", 1, 10.0, false], ["death", 6, 5.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "limb": 70.0})
	for i in 3:
		f.append({"lean": -2 - i, "limb": 150.0 + i * 20.0, "eye": true})
	for i in 2:
		f.append({"lean": 4, "limb": 10.0 - i * 40.0})
	for i in 3:
		f.append({"lean": -1, "limb": 90.0, "arms_down": i, "eye": true, "bob": i})
	for i in 2:
		f.append({"lean": 2, "limb": 85.0, "arms_down": 3, "bob": 3})
	for i in 3:
		f.append({"lean": -3, "limb": 60.0, "pod": i, "eye": true})
	for i in 2:
		f.append({"lean": 4, "limb": 40.0, "pod_open": true})
	for i in 2:
		f.append({"lean": 2, "bob": 3, "limb": 80.0})
	for i in 6:
		f.append({"lean": [0, -2, 2, -3, 3, 0][i], "bob": [0, 1, 0, 2, 1, 0][i], "limb": 70.0, "cracks": i, "eye": true})
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "limb": 75.0, "phase": 2})
	f.append({"lean": -4, "limb": 90.0, "eye": true})
	for i in 6:
		f.append({"die": i})
	return Sheets.sheet(f, Vector2i(128, 120), _draw_guardian, defs)


static func _draw_guardian(c: PixelCanvas, o: Dictionary) -> void:
	var bark := _ramp("5a4a3a")
	var stone := _ramp("7a7a88")
	var root := _ramp("2a1a2a")
	var rune := _ramp("8ad8f0")
	var rot := _ramp("9a4ae0")
	var moss := _ramp("4a6a34")
	var dying: int = o.get("die", -1)
	var ph2: bool = o.get("phase", 1) == 2 or o.get("cracks", 0) >= 3
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var u := Vector2(lean, bob)
	var sink := 0.0
	if dying >= 0:
		sink = dying * 6.0
		u = Vector2(0, sink)
	# root feet spreading into the ground
	for k in 5:
		var x := 36 + k * 12
		c.stroke(Vector2(x, 96) + u * 0.3, Vector2(x + (k - 2) * 7, 118), 6 - absi(k - 2), root[1] if k % 2 else bark[2], B.ROOT if k % 2 else B.BARK)
	# trunk body
	c.poly(PackedVector2Array([Vector2(40, 50) + u, Vector2(78, 46) + u, Vector2(84, 100) + u * 0.4, Vector2(36, 102) + u * 0.4]), bark[1], B.BARK)
	for k in 5:
		c.line(int(44 + k * 8 + lean), int(52 + bob), int(42 + k * 9 + lean * 0.4), int(100 + bob * 0.4), bark[2], B.BARK)
	# carved ward-stones set into the chest
	for st: Vector2 in [Vector2(50, 62), Vector2(66, 60), Vector2(58, 78)]:
		var p := st + u
		c.rect(int(p.x) - 5, int(p.y) - 5, 10, 10, stone[1], B.RUNE)
		var glowc := rot[0] if ph2 else rune[0]
		if dying >= 3:
			glowc = rune[0]
		c.put(int(p.x), int(p.y) - 2, glowc, B.GLOW)
		c.put(int(p.x) - 2, int(p.y), glowc, B.GLOW)
		c.put(int(p.x) + 2, int(p.y), glowc, B.GLOW)
		c.put(int(p.x), int(p.y) + 2, glowc, B.GLOW)
		if ph2 and dying < 0:
			c.line(int(p.x) - 4, int(p.y) - 4, int(p.x) + 1, int(p.y) + 3, rot[1], B.CORE)
	# invading roots crawling over the body
	var writhe := 3.0 if ph2 else 1.5
	for k in 4:
		var a := Vector2(42 + k * 11, 100) + u * 0.4
		var b := Vector2(46 + k * 9 + sin(k * 1.7 + bob) * writhe, 52 + k * 3) + u
		c.stroke(a, b, 2, root[1], B.ROOT)
	# head with antlers of branch and a mask-like ward face
	var head := Vector2(62, 38) + u
	c.ellipse(head.x, head.y, 11, 10, bark[1], B.BARK)
	c.rect(int(head.x) - 6, int(head.y) - 4, 13, 9, stone[1], B.RUNE)
	var eye := rot[0] if ph2 else rune[0]
	if o.get("eye", false):
		eye = _c("ffffff")
	c.rect(int(head.x) - 4, int(head.y) - 1, 3, 2, eye, B.GLOW)
	c.rect(int(head.x) + 2, int(head.y) - 1, 3, 2, eye, B.GLOW)
	for s: float in [-1.0, 1.0]:
		var base := head + Vector2(4 * s, -8)
		var t1 := base + Vector2(10 * s, -14)
		c.stroke(base, t1, 3, bark[0], B.BARK)
		c.stroke(t1, t1 + Vector2(8 * s, -4), 2, bark[0], B.BARK)
		c.stroke(base + Vector2(5 * s, -7), base + Vector2(2 * s, -18), 2, bark[0], B.BARK)
		c.put(int(t1.x + 8 * s), int(t1.y - 4), moss[0], B.LEAF)
	c.ellipse(52 + lean, 46 + bob, 10, 4, moss[1], B.MOSS)
	# limbs: the back one hangs, the front one sweeps
	var bsh := Vector2(44, 54) + u
	c.stroke(bsh, bsh + Vector2(-8, 30), 7, bark[2], B.BARK)
	var sh := Vector2(76, 54) + u
	var ang := deg_to_rad(o.get("limb", 70.0))
	var elbow := sh + Vector2.from_angle(ang * 0.6 + 0.3) * 20.0
	if o.has("arms_down"):
		elbow = sh + Vector2(6, 16 + o.arms_down * 4)
	var hand := elbow + Vector2.from_angle(ang) * 26.0
	if o.has("arms_down"):
		hand = elbow + Vector2(4, 12)
	c.stroke(sh, elbow, 8, bark[1], B.BARK)
	c.stroke(elbow, hand, 6, bark[1], B.BARK)
	for k in 3:
		c.stroke(hand, hand + Vector2.from_angle(ang + (k - 1) * 0.5) * 9.0, 2, bark[0], B.BARK)
	# seed pod swelling on the shoulder
	if o.has("pod") or o.has("pod_open"):
		var pr: float = 4.0 + o.get("pod", 3) * 2.0
		c.ellipse(70 + lean, 44 + bob, pr, pr, rot[2], B.CORE)
		if o.has("pod_open"):
			c.ellipse(70 + lean, 44 + bob, pr * 0.6, pr * 0.6, rot[0], B.GLOW)
	for pair: Array in [[B.BARK, bark], [B.RUNE, stone], [B.ROOT, root], [B.MOSS, moss], [B.CORE, rot]]:
		c.shade(pair[0], pair[1][0], pair[1][2], 2)
	c.outline(_c("08060c"), 0.85)
