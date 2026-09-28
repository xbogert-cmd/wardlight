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


# ---------------------------------------------------------------- shared limbs
enum H { NONE, SKIN, CLOTH, LEATHER, METAL, WOOD, BLADE, EYE, GLOW, ROBE, BONE, VOID, CAPE, BARK, HEART, THORNS, BOOT }


static func _limb(c: PixelCanvas, a: Vector2, b: Vector2, w: int, col: Color, r: int) -> void:
	c.stroke(a, b, w, col, r)


static func _legs(c: PixelCanvas, hipf: Vector2, hipb: Vector2, ff: Vector2, bf: Vector2, col: Color, boot: Color, knee_bend: float = 1.5) -> void:
	for pair: Array in [[hipb, bf, col.darkened(0.25), boot.darkened(0.25)], [hipf, ff, col, boot]]:
		var hip: Vector2 = pair[0]
		var foot: Vector2 = pair[1]
		var knee := hip.lerp(foot, 0.5) + Vector2(knee_bend, 0)
		c.stroke(hip, knee, 3, pair[2], H.CLOTH)
		c.stroke(knee, foot + Vector2(0, -2), 3, pair[2], H.CLOTH)
		c.rect(roundi(foot.x) - 1, roundi(foot.y) - 2, 4, 3, pair[3], H.BOOT)


# ---------------------------------------------------------------- Briar Raider
const RAIDER := {
	"skin": ["b8b098", "948a74", "6a6252"], "cloth": ["5a6a44", "3e4c30", "283220"], "leather": ["8a6a4a", "65492f", "42301f"],
	"metal": ["a8acba", "747888", "4a4c5a"], "wood": ["9a7448", "71522f", "4a341e"], "blade": ["e8ecf0", "a8b0bc", "6a7080"],
	"boot": ["4a3a30", "34281f", "201812"], "thorn": ["8ab85a", "5a8a3e", "3a5a2c"],
}


static func raider() -> Dictionary:
	var defs := [["idle", 4, 6.0, true], ["walk", 6, 9.0, true], ["guard", 2, 6.0, true], ["bash_windup", 2, 8.0, false],
		["bash", 2, 12.0, false], ["slash_windup", 2, 8.0, false], ["slash", 2, 14.0, false], ["stagger", 2, 6.0, true],
		["hurt", 1, 10.0, false], ["death", 4, 8.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "shield": Vector2(29, 29), "blade": -60.0})
	var wk := [[3, -3, 0], [1, -1, -1], [-2, 2, 0], [-3, 3, 0], [-1, 1, -1], [2, -2, 0]]
	for w in wk:
		f.append({"ff": Vector2(w[0], 0), "bf": Vector2(w[1], 0), "bob": w[2], "shield": Vector2(29, 29 + w[2]), "blade": -50.0})
	for i in 2:
		f.append({"lean": 1, "bob": 1, "shield": Vector2(31, 26 + i), "blade": -80.0, "ff": Vector2(3, 0), "bf": Vector2(-3, 0)})
	f.append({"lean": -2, "shield": Vector2(24, 28), "blade": -70.0, "ff": Vector2(2, 0), "bf": Vector2(-4, 0), "eye": true})
	f.append({"lean": -3, "shield": Vector2(23, 27), "blade": -75.0, "ff": Vector2(2, 0), "bf": Vector2(-5, 0), "eye": true})
	f.append({"lean": 4, "shield": Vector2(35, 27), "blade": -40.0, "ff": Vector2(5, 0), "bf": Vector2(-3, 0)})
	f.append({"lean": 3, "shield": Vector2(34, 28), "blade": -40.0, "ff": Vector2(5, 0), "bf": Vector2(-3, 0)})
	f.append({"lean": -1, "shield": Vector2(27, 31), "blade": -150.0, "bob": 1, "ff": Vector2(2, 0), "bf": Vector2(-3, 0), "eye": true})
	f.append({"lean": -2, "shield": Vector2(27, 31), "blade": -165.0, "bob": 1, "ff": Vector2(2, 0), "bf": Vector2(-3, 0), "eye": true})
	f.append({"lean": 3, "shield": Vector2(28, 30), "blade": 20.0, "ff": Vector2(4, 0), "bf": Vector2(-3, 0)})
	f.append({"lean": 2, "shield": Vector2(28, 30), "blade": 40.0, "ff": Vector2(4, 0), "bf": Vector2(-3, 0)})
	f.append({"lean": -3, "bob": 1, "shield": Vector2(20, 22), "shield_ang": 1.0, "blade": -120.0, "ff": Vector2(1, 0), "bf": Vector2(-4, 0)})
	f.append({"lean": -2, "bob": 1, "shield": Vector2(21, 23), "shield_ang": 0.9, "blade": -115.0, "ff": Vector2(1, 0), "bf": Vector2(-4, 0)})
	f.append({"lean": -3, "shield": Vector2(25, 28), "blade": -100.0})
	f.append({"lean": -3, "bob": 2, "shield": Vector2(24, 30), "blade": -110.0})
	f.append({"lean": -1, "bob": 7, "shield": Vector2(26, 36), "blade": -170.0, "ff": Vector2(3, -2), "bf": Vector2(-4, -1)})
	f.append({"lying": 1})
	f.append({"lying": 2})
	return sheet(f, Vector2i(48, 48), _draw_raider, defs)


static func _draw_raider(c: PixelCanvas, o: Dictionary) -> void:
	var skin := _cols(RAIDER.skin)
	var cloth := _cols(RAIDER.cloth)
	var lea := _cols(RAIDER.leather)
	var metal := _cols(RAIDER.metal)
	var wood := _cols(RAIDER.wood)
	var blade := _cols(RAIDER.blade)
	var boot := _cols(RAIDER.boot)
	var thorn := _cols(RAIDER.thorn)
	if o.has("lying"):
		c.poly(PackedVector2Array([Vector2(8, 46), Vector2(12, 40), Vector2(34, 39), Vector2(38, 46)]), lea[1], H.LEATHER)
		c.ellipse(38, 42, 4, 3.5, metal[1], H.METAL)
		c.ellipse(16 - o.lying, 43, 8, 3, wood[1], H.WOOD)
		c.ring(16 - o.lying, 43, 8, 1, metal[1], H.METAL)
		c.stroke(Vector2(28, 46), Vector2(44, 44), 1, blade[1], H.BLADE)
		c.shade(H.LEATHER, lea[0], lea[2], 1)
		c.shade(H.WOOD, wood[0], wood[2], 1)
		c.outline(Color.html("0e0a16"))
		return
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var u := Vector2(lean, bob)
	var hipf := Vector2(24, 34) + u * 0.5
	var hipb := Vector2(20, 34) + u * 0.5
	_legs(c, hipf, hipb, Vector2(24, 46) + o.get("ff", Vector2.ZERO), Vector2(19, 46) + o.get("bf", Vector2.ZERO), cloth[1], boot[1])
	# back arm + blade (behind body)
	var bsh := Vector2(19, 24) + u
	var bang := deg_to_rad(o.get("blade", -60.0))
	var bhand := bsh + Vector2(-2, 7)
	if o.get("blade", -60.0) > -90.0:
		bhand = bsh + Vector2(5, 6)
	c.stroke(bsh, bhand, 3, lea[2], H.LEATHER)
	var tip := bhand + Vector2.from_angle(bang) * 13.0
	c.stroke(bhand, tip, 2, blade[1], H.BLADE)
	c.rect(roundi(bhand.x) - 1, roundi(bhand.y) - 1, 3, 3, lea[1], H.LEATHER)
	# torso: leather jerkin with thorn growths
	c.poly(PackedVector2Array([Vector2(17, 22) + u, Vector2(28, 22) + u, Vector2(29, 35) + u * 0.5, Vector2(16, 35) + u * 0.5]), lea[1], H.LEATHER)
	c.rect(roundi(16 + lean * 0.5), roundi(32 + bob * 0.5), 14, 2, lea[2], H.LEATHER)
	for tp: Vector2 in [Vector2(18, 23), Vector2(21, 21)]:
		c.poly(PackedVector2Array([tp + u, tp + u + Vector2(-2, -4), tp + u + Vector2(1, 0)]), thorn[1], H.THORNS)
	# head with iron helm
	var head := Vector2(23, 17) + u
	c.ellipse(head.x, head.y, 4.2, 4.5, skin[1], H.SKIN)
	c.poly(PackedVector2Array([head + Vector2(-5, 0), head + Vector2(-4, -5), head + Vector2(1, -6), head + Vector2(5, -3), head + Vector2(5, -1)]), metal[1], H.METAL)
	c.rect(roundi(head.x) + 2, roundi(head.y) - 1, 1, 4, metal[1], H.METAL)  # nose guard
	c.put(roundi(head.x) + 3, roundi(head.y), Color.html("f0e060") if o.get("eye", false) else Color.html("1a1418"), H.EYE)
	# front arm + round shield
	var sh := Vector2(26, 24) + u
	var sp: Vector2 = o.get("shield", Vector2(29, 29)) + Vector2(lean * 0.5, bob)
	c.stroke(sh, sp, 3, lea[1], H.LEATHER)
	var sa: float = o.get("shield_ang", 0.0)
	c.ellipse(sp.x + 2, sp.y, 5.0 + sa, 8.0 - sa * 2.0, wood[1], H.WOOD)
	c.ring(sp.x + 2, sp.y, 8.0 - sa * 2.0, 1.0, metal[1], H.METAL)
	c.ellipse(sp.x + 3, sp.y, 1.6, 1.6, metal[0], H.METAL)
	c.shade(H.CLOTH, cloth[0], cloth[2], 1)
	c.shade(H.LEATHER, lea[0], lea[2], 1)
	c.shade(H.SKIN, skin[0], skin[2], 1)
	c.shade(H.METAL, metal[0], metal[2], 1)
	c.shade(H.WOOD, wood[0], wood[2], 1)
	c.shade(H.BLADE, blade[0], blade[2], 1)
	c.shade(H.BOOT, boot[0], boot[2], 1)
	c.shade(H.THORNS, thorn[0], thorn[2], 1)
	# plank lines on the shield
	for dy in [-3, 2]:
		for dx in range(-3, 6):
			var q := Vector2i(roundi(sp.x + 2 + dx), roundi(sp.y + dy))
			if c.region_at(q.x, q.y) == H.WOOD:
				c.put(q.x, q.y, wood[2], H.WOOD)
	c.outline(Color.html("0e0a16"))


# ---------------------------------------------------------------- Hollow Hexer
const HEXER := {
	"robe": ["5a4474", "3c2c52", "241a36"], "bone": ["ece6d6", "c4bca8", "8a8274"], "glow": ["f4e8ff", "c88cff", "8a4ae0"],
	"trim": ["8a6ab0", "6a4a90", "4a3068"],
}


static func hexer() -> Dictionary:
	var defs := [["idle", 4, 5.0, true], ["move", 4, 8.0, true], ["windup", 3, 5.0, false], ["cast", 2, 10.0, false],
		["recover", 2, 4.0, true], ["hurt", 1, 10.0, false], ["death", 5, 8.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, -1, -1, 0][i], "hem": [0, 1, 0, -1][i], "hands": 0})
	for i in 4:
		f.append({"bob": [0, -1, 0, -1][i], "hem": [2, 3, 2, 3][i], "lean": 2, "hands": 0})
	for i in 3:
		f.append({"bob": -1 - i, "hands": 1 + i, "hem": i % 2, "glow": 1 + i})
	f.append({"bob": -2, "lean": 3, "hands": 4, "hem": 2, "glow": 3})
	f.append({"bob": -1, "lean": 2, "hands": 4, "hem": 1, "glow": 1})
	f.append({"bob": 3, "lean": 2, "slump": true, "hands": 5, "hem": 0})
	f.append({"bob": 4, "lean": 2, "slump": true, "hands": 5, "hem": 1})
	f.append({"bob": 1, "lean": -2, "hands": 0, "hem": -2})
	for i in 5:
		f.append({"crumble": i})
	return sheet(f, Vector2i(40, 56), _draw_hexer, defs)


static func _draw_hexer(c: PixelCanvas, o: Dictionary) -> void:
	var robe := _cols(HEXER.robe)
	var bone := _cols(HEXER.bone)
	var glow := _cols(HEXER.glow)
	var trim := _cols(HEXER.trim)
	var k: int = o.get("crumble", -1)
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	if k >= 0:
		bob = k * 4.0
	var u := Vector2(lean, bob)
	var hem: float = o.get("hem", 0)
	# robe: tall, tattered hem floating above the ground
	var hem_y := 50.0 + (k * 1.0 if k > 0 else 0.0)
	var body := PackedVector2Array([Vector2(15, 18) + u, Vector2(25, 18) + u, Vector2(29, 34) + u * 0.6, Vector2(31 - hem, hem_y),
		Vector2(28 - hem, hem_y - 3), Vector2(25 - hem, hem_y), Vector2(21 - hem, hem_y - 2), Vector2(17 - hem, hem_y), Vector2(13 - hem, hem_y - 3),
		Vector2(10 - hem, hem_y), Vector2(12, 34) + u * 0.6])
	if k < 4:
		c.poly(body, robe[1], H.ROBE)
		c.line(roundi(20 + lean), roundi(22 + bob), roundi(20 - hem), roundi(hem_y - 2), trim[1], H.ROBE)
	if k >= 2:
		for x in range(0, 40):
			for y in range(0, int(56 - (k - 1) * 8)):
				c.erase(x, y)
		c.poly(PackedVector2Array([Vector2(8, 55), Vector2(14, 49), Vector2(26, 48), Vector2(33, 55)]), robe[2], H.ROBE)
		c.ellipse(24, 51, 4, 3, bone[1], H.BONE)
		c.shade(H.ROBE, robe[0], robe[2], 1)
		c.shade(H.BONE, bone[0], bone[2], 1)
		c.outline(Color.html("0e0a16"))
		return
	# hood and antlered bone mask
	var head := Vector2(20, 12) + u
	c.ellipse(head.x, head.y + 1, 6, 7, robe[2], H.ROBE)
	c.ellipse(head.x + 1.5, head.y + 2, 3.2, 4.2, bone[1], H.BONE)
	c.rect(roundi(head.x) + 1, roundi(head.y) + 1, 1, 2, Color.html("140a1e"), H.EYE)
	c.rect(roundi(head.x) + 3, roundi(head.y) + 1, 1, 2, Color.html("140a1e"), H.EYE)
	for s in [-1.0, 1.0]:
		var base := head + Vector2(s * 3.0 - 1.0, -5)
		c.linev(base, base + Vector2(s * 3.0, -5), bone[1], H.BONE)
		c.linev(base + Vector2(s * 2.0, -3), base + Vector2(s * 5.0, -4), bone[1], H.BONE)
	# arms / hands
	var hands: int = o.get("hands", 0)
	var hp: Vector2 = [Vector2(26, 32), Vector2(27, 24), Vector2(27, 17), Vector2(26, 10), Vector2(32, 20), Vector2(26, 38)][hands] + Vector2(lean, bob)
	c.stroke(Vector2(23, 21) + u, hp, 3, robe[1], H.ROBE)
	c.rect(roundi(hp.x) - 1, roundi(hp.y) - 1, 3, 3, bone[1], H.BONE)
	c.shade(H.ROBE, robe[0], robe[2], 1)
	c.shade(H.BONE, bone[0], bone[2], 1)
	var g: int = o.get("glow", 0)
	if g > 0:
		c.ellipse(hp.x + 1, hp.y - 1, 1.0 + g * 0.8, 1.0 + g * 0.8, glow[1], H.GLOW)
		c.put(roundi(hp.x + 1), roundi(hp.y - 1), glow[0], H.GLOW)
	c.put(roundi(head.x) + 1, roundi(head.y) + 1, glow[1] if g > 0 else Color.html("6a3aa0"), H.EYE)
	c.put(roundi(head.x) + 3, roundi(head.y) + 1, glow[1] if g > 0 else Color.html("6a3aa0"), H.EYE)
	c.outline(Color.html("0e0a16"))


# ---------------------------------------------------------------- Briar Knot
const KNOT := {"bark": ["7a6048", "57432f", "3a2b1f"], "moss": ["7aa04a", "527a36", "34522a"], "heart": ["fff6b0", "d8ff60", "7ab83a"],
	"thorn": ["b0a080", "8a7a5a", "5a4a3a"]}


static func knot() -> Dictionary:
	var defs := [["idle", 4, 5.0, true], ["burrow", 4, 10.0, false], ["emerge", 4, 10.0, false], ["attack", 3, 8.0, false],
		["exposed", 2, 5.0, true], ["hurt", 1, 10.0, false], ["death", 4, 7.0, false]]
	var f := []
	for i in 4:
		f.append({"sway": [0, 1, 0, -1][i]})
	for i in 4:
		f.append({"sink": (i + 1) * 7})
	for i in 4:
		f.append({"sink": (3 - i) * 7})
	for i in 3:
		f.append({"arms": 1 + i, "heart": 1 + i})
	f.append({"open": 1, "heart": 3, "sway": 1})
	f.append({"open": 1, "heart": 2, "sway": 0})
	f.append({"sway": -2, "heart": 2})
	for i in 4:
		f.append({"wither": i})
	return sheet(f, Vector2i(48, 40), _draw_knot, defs)


static func _draw_knot(c: PixelCanvas, o: Dictionary) -> void:
	var bark := _cols(KNOT.bark)
	var moss := _cols(KNOT.moss)
	var heart := _cols(KNOT.heart)
	var thorn := _cols(KNOT.thorn)
	var sink: float = o.get("sink", 0)
	var sway: float = o.get("sway", 0)
	var wither: int = o.get("wither", -1)
	var arms: int = o.get("arms", 0)
	var y0 := sink + (wither * 3.0 if wither > 0 else 0.0)
	# root legs
	for rl: Array in [[Vector2(18, 30), Vector2(8, 38)], [Vector2(22, 32), Vector2(16, 38)], [Vector2(27, 32), Vector2(33, 38)], [Vector2(30, 30), Vector2(41, 38)]]:
		c.stroke(rl[0] + Vector2(0, y0), rl[1] + Vector2(0, minf(y0, 0)), 2, bark[1], H.BARK)
	# gnarled trunk
	var trunk := PackedVector2Array()
	for p: Vector2 in [Vector2(14, 32), Vector2(13 + sway, 18), Vector2(18 + sway, 10), Vector2(29 + sway, 10), Vector2(35 + sway, 17), Vector2(34, 32)]:
		trunk.append(p + Vector2(0, y0))
	c.poly(trunk, bark[1], H.BARK)
	# branch arms / crown of thorns
	var raise := arms * 4.0
	for br: Array in [[Vector2(16, 16), Vector2(6, 12 - raise)], [Vector2(32, 16), Vector2(42, 11 - raise)], [Vector2(22, 11), Vector2(19, 3 - raise * 0.5)], [Vector2(27, 11), Vector2(31, 2 - raise * 0.5)]]:
		var a: Vector2 = br[0] + Vector2(sway, y0)
		var b: Vector2 = br[1] + Vector2(sway * 2.0, y0)
		c.stroke(a, b, 2, bark[1], H.BARK)
		c.put(roundi(b.x), roundi(b.y) - 1, thorn[0], H.THORNS)
		c.put(roundi(a.lerp(b, 0.5).x) + 1, roundi(a.lerp(b, 0.5).y) - 1, thorn[1], H.THORNS)
	c.shade(H.BARK, bark[0], bark[2], 1)
	# mossy shoulders
	for x in range(14, 36, 2):
		for y in range(0, 40):
			if c.region_at(x + roundi(sway), y) == H.BARK:
				c.put(x + roundi(sway), y, moss[1], H.THORNS)
				if x % 4 == 0:
					c.put(x + roundi(sway), y + 1, moss[2], H.THORNS)
				break
	# glowing heart hollow
	var hh: int = o.get("heart", 1)
	if wither < 2:
		var hc := Vector2(24 + sway, 22 + y0)
		var open: float = o.get("open", 0) * 1.5
		c.ellipse(hc.x, hc.y, 3.5 + open, 4.5 + open, Color.html("1a1208"), H.EYE)
		c.ellipse(hc.x, hc.y + 0.5, 1.5 + hh * 0.5 + open * 0.5, 2.0 + hh * 0.5 + open * 0.5, heart[1], H.HEART)
		c.put(roundi(hc.x), roundi(hc.y), heart[0], H.HEART)
	# crop anything below the ground line (burrowing)
	for y in range(38, 40):
		for x in 48:
			c.erase(x, y)
	c.outline(Color.html("0e0a16"))


# ---------------------------------------------------------------- Hollow Sentinel
const SENTINEL := {"metal": ["9a9eb4", "6a6e84", "43465a"], "void": ["3a2458", "1a1028", "0c0814"], "eye": ["f0e0ff", "b080ff"],
	"cape": ["6a2430", "4a1a24", "2e1016"], "blade": ["dce2ea", "9aa2b0", "5a6070"], "rust": "8a5a3a"}


static func sentinel() -> Dictionary:
	var defs := [["idle", 4, 4.0, true], ["walk", 6, 6.0, true], ["slam_windup", 3, 4.0, false], ["slam", 2, 12.0, false],
		["stuck", 3, 4.0, false], ["sweep_windup", 2, 5.0, false], ["sweep", 2, 12.0, false], ["stagger", 3, 5.0, false],
		["hurt", 1, 10.0, false], ["death", 6, 7.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "sword": 70.0, "hand": Vector2(40, 38)})
	var wk := [[4, -4, 0], [2, -2, -1], [-2, 2, 0], [-4, 4, 0], [-2, 2, -1], [2, -2, 0]]
	for w in wk:
		f.append({"ff": Vector2(w[0], 0), "bf": Vector2(w[1], 0), "bob": w[2], "sword": 75.0, "hand": Vector2(40, 38 + w[2])})
	for i in 3:
		f.append({"lean": -1 - i, "sword": -100.0 - i * 15.0, "hand": Vector2(36 - i, 24 - i * 4), "eye": i + 1, "cape": i})
	f.append({"lean": 4, "bob": 2, "sword": 20.0, "hand": Vector2(44, 34), "eye": 3, "ff": Vector2(5, 0)})
	f.append({"lean": 5, "bob": 4, "sword": 70.0, "hand": Vector2(46, 44), "eye": 2, "ff": Vector2(6, 0)})
	for i in 3:
		f.append({"lean": 5, "bob": 4, "sword": 80.0, "hand": Vector2(46, 46), "eye": 0, "ff": Vector2(6, 0), "stuck": i})
	f.append({"lean": -3, "sword": 170.0, "hand": Vector2(26, 34), "eye": 2, "bf": Vector2(-3, 0)})
	f.append({"lean": -4, "sword": 175.0, "hand": Vector2(25, 34), "eye": 3, "bf": Vector2(-4, 0)})
	f.append({"lean": 4, "sword": 5.0, "hand": Vector2(46, 34), "eye": 3, "ff": Vector2(5, 0)})
	f.append({"lean": 3, "sword": 20.0, "hand": Vector2(45, 36), "eye": 1, "ff": Vector2(5, 0)})
	for i in 3:
		f.append({"kneel": i + 1, "sword": 95.0, "hand": Vector2(42, 44 + i), "eye": 0, "bob": 3 + i * 3})
	f.append({"lean": -2, "bob": 1, "sword": 60.0, "hand": Vector2(38, 38), "eye": 2})
	for i in 6:
		f.append({"collapse": i, "sword": 95.0, "hand": Vector2(42, 48), "bob": mini(i * 4, 16)})
	return sheet(f, Vector2i(72, 64), _draw_sentinel, defs)


static func _draw_sentinel(c: PixelCanvas, o: Dictionary) -> void:
	var metal := _cols(SENTINEL.metal)
	var void_c := _cols(SENTINEL.void)
	var cape := _cols(SENTINEL.cape)
	var blade := _cols(SENTINEL.blade)
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var col: int = o.get("collapse", -1)
	var u := Vector2(lean, bob)
	# tattered cape behind
	var cw: float = o.get("cape", 0)
	if col < 3:
		c.poly(PackedVector2Array([Vector2(24, 22) + u, Vector2(34, 22) + u, Vector2(28 - cw, 54), Vector2(22 - cw * 2.0, 58), Vector2(18 - cw * 2.0, 52),
			Vector2(14 - cw * 2.0, 56)]), cape[1], H.CAPE)
	# legs (armoured greaves)
	var kneel: int = o.get("kneel", 0)
	var ff: Vector2 = Vector2(37, 62) + o.get("ff", Vector2.ZERO)
	var bf: Vector2 = Vector2(26, 62) + o.get("bf", Vector2.ZERO)
	if kneel > 0 or col >= 0:
		ff = Vector2(40, 62)
		bf = Vector2(24, 62)
	var hip := Vector2(31, 42) + Vector2(lean * 0.5, bob)
	for pair: Array in [[hip + Vector2(-3, 0), bf, metal[2]], [hip + Vector2(3, 0), ff, metal[1]]]:
		var knee: Vector2 = (pair[0] as Vector2).lerp(pair[1], 0.5) + Vector2(2, -kneel * 1.5)
		c.stroke(pair[0], knee, 5, pair[2], H.METAL)
		c.stroke(knee, pair[1] + Vector2(0, -3), 4, pair[2], H.METAL)
		c.rect(roundi((pair[1] as Vector2).x) - 2, roundi((pair[1] as Vector2).y) - 3, 7, 4, pair[2], H.METAL)
	# torso: breastplate with a void crack
	if col < 5:
		c.poly(PackedVector2Array([Vector2(22, 20) + u, Vector2(40, 20) + u, Vector2(42, 32) + u, Vector2(38, 44) + u * 0.8, Vector2(25, 44) + u * 0.8,
			Vector2(21, 32) + u]), metal[1], H.METAL)
		c.poly(PackedVector2Array([Vector2(30, 24) + u, Vector2(34, 28) + u, Vector2(31, 33) + u, Vector2(33, 38) + u]), void_c[1], H.VOID)
		# pauldrons
		c.ellipse(23 + lean, 22 + bob, 5, 4, metal[1], H.METAL)
		c.ellipse(40 + lean, 22 + bob, 5, 4, metal[1], H.METAL)
		# helm: tall, visored, with a crest
		var head := Vector2(31, 13) + u
		c.poly(PackedVector2Array([head + Vector2(-6, 6), head + Vector2(-6, -4), head + Vector2(-2, -8), head + Vector2(5, -7), head + Vector2(7, -2), head + Vector2(6, 6)]), metal[1], H.METAL)
		c.rect(roundi(head.x) - 1, roundi(head.y) - 11, 3, 4, cape[1], H.CAPE)
		c.rect(roundi(head.x) - 4, roundi(head.y) - 1, 10, 2, void_c[2], H.VOID)
		var eye: int = o.get("eye", 1)
		var ec: Color = Color.html(SENTINEL.eye[0]) if eye >= 3 else Color.html(SENTINEL.eye[1])
		if eye > 0:
			c.rect(roundi(head.x) + 2, roundi(head.y) - 1, 2 + mini(eye, 2), 1, ec, H.EYE)
	# arm + greatsword
	var sh := Vector2(38, 24) + u
	var hand: Vector2 = o.get("hand", Vector2(40, 38)) + Vector2(lean * 0.5, 0)
	c.stroke(sh, hand, 4, metal[2], H.METAL)
	var ang := deg_to_rad(o.get("sword", 70.0))
	var tip := hand + Vector2.from_angle(ang) * 30.0
	var pommel := hand - Vector2.from_angle(ang) * 6.0
	c.stroke(pommel, hand, 2, Color.html("4a3a30"), H.CAPE)
	c.stroke(hand + Vector2.from_angle(ang) * 3.0, tip, 3, blade[1], H.BLADE)
	var guard := Vector2.from_angle(ang).orthogonal()
	c.stroke(hand + guard * 4.0, hand - guard * 4.0, 2, metal[0], H.METAL)
	c.rect(roundi(hand.x) - 1, roundi(hand.y) - 1, 4, 4, metal[1], H.METAL)
	c.shade(H.METAL, metal[0], metal[2], 1)
	c.shade(H.CAPE, cape[0], cape[2], 1)
	c.shade(H.BLADE, blade[0], blade[2], 1)
	c.shade(H.VOID, void_c[0], void_c[2], 1)
	# rust flecks
	for p: Vector2i in [Vector2i(25, 30), Vector2i(36, 40), Vector2i(28, 36)]:
		var q := p + Vector2i(roundi(lean), roundi(bob))
		if c.region_at(q.x, q.y) == H.METAL:
			c.put(q.x, q.y, Color.html(SENTINEL.rust), H.METAL)
	if o.get("stuck", -1) >= 0:
		FXDust.cracks(c, tip, int(o.stuck))
	if col >= 3:
		for y in range(0, 20 + (col - 3) * 8):
			for x in 72:
				if c.region_at(x, y) != H.BLADE:
					c.erase(x, y)
		for pc: Vector2 in [Vector2(20, 60), Vector2(30, 61), Vector2(44, 60)]:
			c.ellipse(pc.x, pc.y, 4, 2.5, metal[1], H.METAL)
		c.shade(H.METAL, metal[0], metal[2], 1)
	c.outline(Color.html("0a0612"))


class FXDust:
	static func cracks(c: PixelCanvas, at: Vector2, k: int) -> void:
		var col := Color.html("2a1e18")
		for s in [-1.0, 1.0]:
			c.line(roundi(at.x), 62, roundi(at.x + s * (4 + k * 2)), 60 - k % 2, col, H.NONE + 20)
