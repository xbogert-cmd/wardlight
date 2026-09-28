extends RefCounted
## Enemy sprite sheets. Each builder returns {image, anims, cell, origin}.

enum R { NONE, FUR, FUR_FAR, BELLY, MANE, EYE, MOUTH, THORN, TOOTH, CLAW }


static func sheet(frames: Array, cell: Vector2i, draw: Callable, defs: Array) -> Dictionary:
	var cols := 8
	var rows := ceili(frames.size() / float(cols))
	var img := Image.create_empty(cols * cell.x, rows * cell.y, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var c := PixelCanvas.new(cell.x, cell.y)
		draw.call(c, frames[i])
		c.blit_into(img, (i % cols) * cell.x, (i / cols) * cell.y)
	var anims := {}
	var at := 0
	for d in defs:
		var idx := []
		for k in d[1]:
			idx.append(at)
			at += 1
		anims[d[0]] = {"frames": idx, "fps": d[2], "loop": d[3]}
	return {"image": img, "anims": anims, "cell": cell, "hframes": cols, "vframes": rows}


# ---------------------------------------------------------------- Gloamhound
const HOUND := {
	"fur": ["4c5472", "343a54", "22263a"], "far": ["2c3048", "22263a", "171a2a"],
	"belly": ["8a90ae", "666c8c", "464a66"], "mane": ["5a4a78", "3e3258", "2a2140"],
	"eye": "e4ff6a", "mouth": "8a1e34", "thorn": ["8ab85a", "5a8a3e", "3a5a2c"],
}


static func hound() -> Dictionary:
	var defs := [
		["idle", 4, 6.0, true], ["run", 6, 14.0, true], ["windup", 2, 8.0, true],
		["leap", 2, 10.0, true], ["land", 2, 8.0, false], ["hurt", 1, 10.0, false], ["death", 3, 8.0, false],
	]
	var f := []
	for i in 4:
		f.append({"by": [0, 0, 1, 1][i], "tail": [-20, -24, -28, -24][i], "hy": [0, 0, 1, 1][i]})
	var gal := [
		{"fn": Vector2(6, -2), "ff": Vector2(3, 0), "bn": Vector2(-6, 0), "bf": Vector2(-3, -2), "by": 0, "stretch": 2},
		{"fn": Vector2(8, -4), "ff": Vector2(6, -3), "bn": Vector2(-8, -2), "bf": Vector2(-6, -1), "by": -2, "stretch": 3},
		{"fn": Vector2(4, 0), "ff": Vector2(6, -2), "bn": Vector2(-3, -3), "bf": Vector2(-6, -1), "by": -1, "stretch": 1},
		{"fn": Vector2(-2, 0), "ff": Vector2(1, 0), "bn": Vector2(3, -2), "bf": Vector2(1, -3), "by": 1, "stretch": -1},
		{"fn": Vector2(-5, -1), "ff": Vector2(-3, 0), "bn": Vector2(6, -3), "bf": Vector2(4, -2), "by": 1, "stretch": -2},
		{"fn": Vector2(0, -3), "ff": Vector2(-2, -1), "bn": Vector2(2, 0), "bf": Vector2(4, 0), "by": 0, "stretch": 0},
	]
	for g in gal:
		g["tail"] = -5
		g["mouth"] = 1
		f.append(g)
	for i in 2:  # windup: haunches up, head low, jaws open — the tell
		f.append({"by": 3, "tilt": 4, "hy": 2, "hx": 1, "tail": 30 + i * 8, "mouth": 1, "fn": Vector2(4, 0), "ff": Vector2(2, 0),
			"bn": Vector2(-2, 0), "bf": Vector2(0, 0), "stretch": -2, "glow": true, "shiver": i})
	for i in 2:
		f.append({"by": -5, "tilt": -2, "tail": -10, "mouth": 1, "fn": Vector2(9, -7), "ff": Vector2(7, -6),
			"bn": Vector2(-9, -3), "bf": Vector2(-7, -4), "stretch": 4, "hx": 2})
	f.append({"by": 3, "tilt": 5, "hy": 4, "hx": 2, "tail": 10, "fn": Vector2(8, 0), "ff": Vector2(5, 0), "bn": Vector2(-3, -1), "bf": Vector2(-1, 0), "stretch": 1})
	f.append({"by": 2, "tilt": 3, "hy": 3, "hx": 1, "tail": -5, "fn": Vector2(5, 0), "ff": Vector2(3, 0), "bn": Vector2(-2, 0), "bf": Vector2(0, 0), "stretch": 0})
	f.append({"by": 1, "tilt": -3, "hy": -2, "hx": -2, "tail": 20, "mouth": 1, "fn": Vector2(-2, 0), "ff": Vector2(-3, 0), "bn": Vector2(2, 0), "bf": Vector2(1, 0), "stretch": -2})
	f.append({"by": 4, "tilt": 3, "hy": 3, "tail": 30, "fn": Vector2(4, 0), "ff": Vector2(2, 0), "stretch": -1})
	f.append({"lying": 1})
	f.append({"lying": 2})
	return sheet(f, Vector2i(56, 40), _draw_hound, defs)


static func _draw_hound(c: PixelCanvas, o: Dictionary) -> void:
	var fur := _cols(HOUND.fur)
	var far := _cols(HOUND.far)
	var belly := _cols(HOUND.belly)
	var mane := _cols(HOUND.mane)
	var thorn := _cols(HOUND.thorn)
	if o.has("lying"):
		var k: int = o.lying
		c.ellipse(26, 33.5 + k * 0.5, 14, 4.5, fur[1], R.FUR)
		c.ellipse(42, 33 + k, 5, 3.5, fur[1], R.FUR)
		c.poly(PackedVector2Array([Vector2(45, 32 + k), Vector2(51, 34 + k), Vector2(45, 35 + k)]), fur[1], R.FUR)
		c.stroke(Vector2(12, 34), Vector2(4, 36), 3, fur[1], R.FUR)
		c.stroke(Vector2(30, 36), Vector2(38, 38), 2, far[1], R.FUR_FAR)
		c.stroke(Vector2(18, 36), Vector2(24, 38), 2, far[1], R.FUR_FAR)
		for tp: Vector2 in [Vector2(20, 28), Vector2(26, 27.5), Vector2(32, 28)]:
			c.poly(PackedVector2Array([tp, tp + Vector2(2, -4), tp + Vector2(3, 0)]), thorn[1], R.THORN)
		c.shade(R.FUR, fur[0], fur[2], 1)
		c.shade(R.THORN, thorn[0], thorn[2], 1)
		c.outline(Color.html("0e0a16"))
		return
	var by: float = o.get("by", 0)
	var tilt: float = o.get("tilt", 0)
	var st: float = o.get("stretch", 0)
	var sx: float = o.get("shiver", 0)
	var hx: float = o.get("hx", 0) + st * 0.5
	var hy: float = o.get("hy", 0)
	var shoulder := Vector2(34 + st * 0.5 + sx, 24 + by + tilt * 0.5)
	var hip := Vector2(18 - st * 0.5 + sx, 23 + by - tilt * 0.5)
	var fpaw := Vector2(36, 37)
	var bpaw := Vector2(17, 37)

	# far legs
	_leg(c, shoulder + Vector2(-2, 0), fpaw + o.get("ff", Vector2.ZERO) + Vector2(-2, 0), 1, far[1], R.FUR_FAR, true)
	_leg(c, hip + Vector2(2, 0), bpaw + o.get("bf", Vector2.ZERO) + Vector2(2, 0), -1, far[1], R.FUR_FAR, false)
	# tail
	var ta := deg_to_rad(180.0 + o.get("tail", -15))
	var tb := hip + Vector2(-3, -2)
	var tt := tb + Vector2(cos(ta), sin(ta)) * 11
	c.stroke(tb, tt, 3, fur[1], R.FUR)
	c.ellipse(tt.x, tt.y, 2.5, 2, fur[1], R.FUR)
	# torso + chest
	c.poly(PackedVector2Array([hip + Vector2(-5, -2), hip + Vector2(0, -6), shoulder + Vector2(-2, -7), shoulder + Vector2(5, -3),
		shoulder + Vector2(4, 5), shoulder + Vector2(-3, 4), hip + Vector2(3, 5), hip + Vector2(-4, 4)]), fur[1], R.FUR)
	c.poly(PackedVector2Array([shoulder + Vector2(-8, 3), shoulder + Vector2(4, 1), shoulder + Vector2(3, 5), hip + Vector2(4, 5)]), belly[1], R.BELLY)
	# thorny corruption along the spine
	for k in 3:
		var tp := hip.lerp(shoulder, 0.25 + k * 0.25) + Vector2(0, -6)
		c.poly(PackedVector2Array([tp + Vector2(-2, 1), tp + Vector2(1, -4 - k % 2), tp + Vector2(2, 1)]), thorn[1], R.THORN)
	# head
	var head := Vector2(42 + hx + sx, 16 + by + tilt + hy)
	c.poly(PackedVector2Array([shoulder + Vector2(-3, -6), head + Vector2(-3, -3), head + Vector2(0, 4), shoulder + Vector2(3, 2)]), mane[1], R.MANE)
	c.ellipse(head.x, head.y, 4.5, 4, fur[1], R.FUR)
	var mouth: int = o.get("mouth", 0)
	c.poly(PackedVector2Array([head + Vector2(2, -2), head + Vector2(9, 0), head + Vector2(9, 2), head + Vector2(2, 3)]), fur[1], R.FUR)
	if mouth:
		c.poly(PackedVector2Array([head + Vector2(3, 3), head + Vector2(9, 3), head + Vector2(7, 6), head + Vector2(3, 5)]), fur[2], R.FUR)
		c.line(roundi(head.x) + 4, roundi(head.y) + 3, roundi(head.x) + 8, roundi(head.y) + 3, Color.html(HOUND.mouth), R.MOUTH)
		c.put(roundi(head.x) + 5, roundi(head.y) + 4, Color.html("eae4d8"), R.TOOTH)
		c.put(roundi(head.x) + 8, roundi(head.y) + 2, Color.html("eae4d8"), R.TOOTH)
	# ears
	c.poly(PackedVector2Array([head + Vector2(-3, -2), head + Vector2(-4, -8), head + Vector2(0, -3)]), fur[1], R.FUR)
	c.poly(PackedVector2Array([head + Vector2(0, -3), head + Vector2(1, -8), head + Vector2(3, -2)]), mane[1], R.MANE)
	# near legs
	_leg(c, shoulder, fpaw + o.get("fn", Vector2.ZERO), 1, fur[1], R.FUR, true)
	_leg(c, hip, bpaw + o.get("bn", Vector2.ZERO), -1, fur[1], R.FUR, false)

	c.shade(R.FUR, fur[0], fur[2], 1)
	c.shade(R.FUR_FAR, far[0], far[2], 1)
	c.shade(R.BELLY, belly[0], belly[2], 1)
	c.shade(R.MANE, mane[0], mane[2], 1)
	c.shade(R.THORN, thorn[0], thorn[2], 1)
	var eye := Color.html(HOUND.eye)
	c.put(roundi(head.x) + 1, roundi(head.y) - 1, eye, R.EYE)
	c.put(roundi(head.x) + 2, roundi(head.y) - 1, eye, R.EYE)
	c.outline(Color.html("0e0a16"))
	if o.get("glow", false):
		for d: Vector2i in [Vector2i(0, -2), Vector2i(3, -1), Vector2i(-1, -1), Vector2i(1, 0)]:
			var q := Vector2i(roundi(head.x) + 1, roundi(head.y) - 1) + d
			if c.region_at(q.x, q.y) == R.NONE or c.region_at(q.x, q.y) == PixelCanvas.OUTLINE_REG:
				c.put(q.x, q.y, Color(eye, 0.9), R.EYE)


static func _leg(c: PixelCanvas, joint: Vector2, paw: Vector2, bend: int, col: Color, r: int, front: bool) -> void:
	var knee := joint.lerp(paw, 0.5) + Vector2(bend * (-1.5 if front else 2.5), 0)
	c.stroke(joint, knee, 3, col, r)
	c.stroke(knee, paw + Vector2(0, -1), 2, col, r)
	c.rect(roundi(paw.x) - 1, roundi(paw.y) - 1, 4, 2, col, r)


static func _cols(a: Array) -> Array[Color]:
	var out: Array[Color] = []
	for s: String in a:
		out.append(Color.html(s))
	return out
