extends RefCounted
## Townsfolk and creature sprite sheets (side view, facing right). One
## parametric villager drawer covers the cast: build, hair, clothes, apron,
## beard, carried things. Sheets use the enemy format (idle / talk / walk).

const Sheets = preload("res://tools/art/enemies_art.gd")

enum P { NONE, SKIN, HAIR, TOP, BOTTOM, APRON, BOOT, ITEM, ITEM2, EYE, GLOW }

## Cast list: sheet name -> look.
const CAST := {
	"pell": {"skin": "d8a880", "hair": "7a4a2a", "hair_style": "cap", "cap": "5a6a8a", "top": "8a5a3a", "bottom": "4a4a5a",
		"height": 38, "build": 0, "item": "satchel"},
	"maren": {"skin": "e0b898", "hair": "c8c8d0", "hair_style": "bun", "top": "6a3a4a", "bottom": "4a2a36", "dress": true,
		"height": 42, "build": 0, "item": "cane", "shawl": "8a7a5a"},
	"isolde": {"skin": "c89070", "hair": "3a2a20", "hair_style": "hood", "hood": "4a6a3a", "top": "5a7a44", "bottom": "3a4a2a",
		"dress": true, "height": 44, "build": 0, "item": "basket"},
	"smith": {"skin": "b88060", "hair": "2a2020", "hair_style": "short", "top": "6a5a4a", "bottom": "3a3430", "apron": "4a3a30",
		"height": 44, "build": 2, "beard": "2a2020", "item": "hammer"},
	"farmer": {"skin": "e8c0a0", "hair": "c89048", "hair_style": "long", "top": "a86a48", "bottom": "5a4a3a", "dress": true,
		"height": 42, "build": 1, "apron": "d8d0b8"},
	"elder_man": {"skin": "d0a888", "hair": "e0e0e0", "hair_style": "bald", "top": "4a5a6a", "bottom": "3a3a44",
		"height": 40, "build": 1, "beard": "e0e0e0", "item": "cane"},
	"traveler_a": {"skin": "a87058", "hair": "1a1a20", "hair_style": "hood", "hood": "5a4a3a", "top": "6a5a44", "bottom": "3a3228",
		"height": 44, "build": 1, "item": "pack"},
	# Chapter 2: the Reedfolk of Reedhollow (reed greens, lake teals, woven hoods)
	"reed_elder": {"skin": "b08868", "hair": "d8d8c8", "hair_style": "hood", "hood": "3a5a4a", "top": "2e4e52", "bottom": "243a3e",
		"dress": true, "height": 40, "build": 0, "item": "cane", "shawl": "8a9a6a"},
	"reedfolk_a": {"skin": "c89878", "hair": "4a3020", "hair_style": "short", "top": "4a6a4a", "bottom": "2a3a3a", "apron": "8a7a5a",
		"height": 42, "build": 1, "item": "basket"},
	"reedfolk_b": {"skin": "9a6a50", "hair": "2a2420", "hair_style": "long", "top": "3a5a6a", "bottom": "2a3440", "dress": true,
		"height": 40, "build": 0},
	"reed_child": {"skin": "c89878", "hair": "6a4a28", "hair_style": "short", "top": "7a8a4a", "bottom": "3a4a3a",
		"height": 28, "build": 0},
	"wenna": {"skin": "b88a68", "hair": "9a4a28", "hair_style": "bun", "top": "5a6a7a", "bottom": "34404a", "dress": true,
		"height": 41, "build": 0, "shawl": "7a8a5a"},
	"trader": {"skin": "a87a58", "hair": "3a3028", "hair_style": "cap", "cap": "4a6a5a", "top": "6a5a3a", "bottom": "3a3a2a",
		"height": 43, "build": 1, "beard": "3a3028", "item": "pack"},
	"orla": {"skin": "d8a888", "hair": "c8c0b0", "hair_style": "long", "top": "6a4a3a", "bottom": "3a3040", "dress": false,
		"height": 42, "build": 0, "item": "satchel", "shawl": "a88a4a"},
	"traveler_b": {"skin": "e0b090", "hair": "8a3a20", "hair_style": "long", "top": "3a5a6a", "bottom": "2a3a44",
		"height": 42, "build": 0, "item": "pack"},
}


static func build(look: Dictionary) -> Dictionary:
	var defs := [["idle", 4, 4.0, true], ["talk", 4, 7.0, true], ["walk", 6, 9.0, true]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i]})
	for i in 4:
		f.append({"bob": [0, 1, 0, 1][i], "arm": [-30.0, -55.0, -40.0, -65.0][i], "mouth": i % 2 == 0})
	var wk := [[3, -3, 0], [1, -1, -1], [-2, 2, 0], [-3, 3, 0], [-1, 1, -1], [2, -2, 0]]
	for w in wk:
		f.append({"ff": w[0], "bf": w[1], "bob": w[2], "swing": w[0] * 0.15})
	return Sheets.sheet(f, Vector2i(32, 48), func(c: PixelCanvas, o: Dictionary) -> void: _draw(c, o, look), defs)


static func _c(s: String) -> Color:
	return Color.html(s)


static func _ramp(hex: String) -> Array[Color]:
	var b := _c(hex)
	return [b.lightened(0.22), b, b.darkened(0.32)]


static func _draw(c: PixelCanvas, o: Dictionary, lk: Dictionary) -> void:
	var skin := _ramp(lk.skin)
	var hair := _ramp(lk.hair)
	var top := _ramp(lk.top)
	var bot := _ramp(lk.bottom)
	var boot := _ramp("3a2a22")
	var h: int = lk.get("height", 42)
	var build: int = lk.get("build", 0)
	var bob: float = o.get("bob", 0)
	var foot := 46
	var hip := foot - int(h * 0.42)
	var neck := foot - int(h * 0.78)
	var cx := 15.0
	var half := 4.0 + build
	# legs (or skirt)
	var ff: float = o.get("ff", 0)
	var bf: float = o.get("bf", 0)
	if lk.get("dress", false):
		c.poly(PackedVector2Array([Vector2(cx - half, hip + bob), Vector2(cx + half, hip + bob), Vector2(cx + half + 2 + ff * 0.3, foot - 1),
			Vector2(cx - half - 2 + bf * 0.3, foot - 1)]), bot[1], P.BOTTOM)
		c.rect(int(cx - 3 + ff * 0.4), foot - 1, 3, 2, boot[1], P.BOOT)
		c.rect(int(cx + bf * 0.4), foot - 1, 3, 2, boot[2], P.BOOT)
	else:
		for leg: Array in [[bf, -1.5, bot[2]], [ff, 1.5, bot[1]]]:
			var top_p := Vector2(cx + leg[1], hip + bob)
			var foot_p := Vector2(cx + leg[1] + leg[0], foot - 1)
			c.stroke(top_p, foot_p, 3 + (1 if build > 1 else 0), leg[2], P.BOTTOM)
			c.rect(int(foot_p.x) - 1, foot - 1, 4, 2, boot[1], P.BOOT)
	# back arm
	var sh := Vector2(cx - 1, neck + 3 + bob)
	var swing: float = o.get("swing", 0.0)
	c.stroke(sh, sh + Vector2(-1 - swing * 4, 9), 2 + (1 if build > 1 else 0), top[2], P.TOP)
	# torso
	c.poly(PackedVector2Array([Vector2(cx - half, neck + 2 + bob), Vector2(cx + half, neck + 2 + bob), Vector2(cx + half + 1, hip + 1 + bob),
		Vector2(cx - half - 1, hip + 1 + bob)]), top[1], P.TOP)
	if lk.has("apron"):
		var ap := _ramp(lk.apron)
		c.rect(int(cx - half + 2), neck + 6 + int(bob), int(half * 2) - 2, hip - neck + 2, ap[1], P.APRON)
	if lk.has("shawl"):
		var sw := _ramp(lk.shawl)
		c.poly(PackedVector2Array([Vector2(cx - half - 1, neck + 2 + bob), Vector2(cx + half + 1, neck + 2 + bob), Vector2(cx, neck + 8 + bob)]), sw[1], P.APRON)
	# head
	var head := Vector2(cx + 1, neck - 3 + bob)
	c.ellipse(head.x, head.y, 3.6, 4.0, skin[1], P.SKIN)
	c.put(int(head.x) + 2, int(head.y) - 1, _c("1a1418"), P.EYE)
	if o.get("mouth", false):
		c.put(int(head.x) + 2, int(head.y) + 2, _c("5a2a2a"), P.EYE)
	match lk.get("hair_style", "short"):
		"short":
			c.poly(PackedVector2Array([head + Vector2(-4, 0), head + Vector2(-3, -4), head + Vector2(2, -5), head + Vector2(4, -2), head + Vector2(-1, -2)]), hair[1], P.HAIR)
		"long":
			c.poly(PackedVector2Array([head + Vector2(-4, 5), head + Vector2(-4, -3), head + Vector2(1, -5), head + Vector2(4, -2), head + Vector2(-1, -2), head + Vector2(-1, 5)]), hair[1], P.HAIR)
		"bun":
			c.poly(PackedVector2Array([head + Vector2(-4, 1), head + Vector2(-3, -4), head + Vector2(2, -5), head + Vector2(4, -2), head + Vector2(-1, -2)]), hair[1], P.HAIR)
			c.ellipse(head.x - 3, head.y - 4, 2, 2, hair[1], P.HAIR)
		"cap":
			var cap := _ramp(lk.get("cap", "5a5a6a"))
			c.poly(PackedVector2Array([head + Vector2(-4, -1), head + Vector2(-3, -5), head + Vector2(3, -5), head + Vector2(6, -2), head + Vector2(-4, -2)]), cap[1], P.ITEM2)
			c.rect(int(head.x) - 4, int(head.y) - 1, 2, 3, hair[1], P.HAIR)
		"hood":
			var hd := _ramp(lk.get("hood", "4a4a4a"))
			c.poly(PackedVector2Array([head + Vector2(-5, 5), head + Vector2(-5, -3), head + Vector2(-1, -6), head + Vector2(4, -4), head + Vector2(5, 0), head + Vector2(2, -2), head + Vector2(-2, 2), head + Vector2(-2, 6)]), hd[1], P.ITEM2)
		"bald":
			c.rect(int(head.x) - 4, int(head.y) - 1, 2, 3, hair[1], P.HAIR)
	if lk.has("beard"):
		var bd := _ramp(lk.beard)
		c.poly(PackedVector2Array([head + Vector2(-1, 1), head + Vector2(4, 1), head + Vector2(3, 6), head + Vector2(0, 5)]), bd[1], P.HAIR)
	# front arm (gestures while talking) + carried item
	var arm_ang := deg_to_rad(o.get("arm", 80.0 - swing * 60.0))
	var hand := sh + Vector2(2, 0) + Vector2.from_angle(arm_ang) * 9.0
	c.stroke(sh + Vector2(2, 0), hand, 2 + (1 if build > 1 else 0), top[0], P.TOP)
	c.rect(int(hand.x), int(hand.y), 2, 2, skin[1], P.SKIN)
	var it := _ramp("7a5a3a")
	match lk.get("item", ""):
		"cane":
			if not o.has("arm"):
				c.stroke(hand + Vector2(1, 0), Vector2(hand.x + 2, foot), 1, it[1], P.ITEM)
		"basket":
			c.ellipse(cx - half, hip - 1 + bob, 3.5, 2.5, _c("a08050"), P.ITEM)
			c.put(int(cx - half), int(hip - 3 + bob), _c("7ac050"), P.ITEM2)
			c.put(int(cx - half) + 1, int(hip - 4 + bob), _c("c8e070"), P.ITEM2)
		"satchel":
			c.rect(int(cx - half - 2), hip - 4 + int(bob), 4, 5, it[1], P.ITEM)
		"pack":
			c.rect(int(cx - half - 4), neck + 2 + int(bob), 5, 9, _c("6a5a44"), P.ITEM)
			c.rect(int(cx - half - 4), neck + 1 + int(bob), 5, 2, _c("8a3a2a"), P.ITEM2)
		"hammer":
			if not o.has("arm"):
				c.stroke(hand, hand + Vector2(0, 7), 1, it[1], P.ITEM)
				c.rect(int(hand.x) - 2, int(hand.y) + 6, 5, 3, _c("6a6a74"), P.ITEM2)
	for pair: Array in [[P.SKIN, skin], [P.HAIR, hair], [P.TOP, top], [P.BOTTOM, bot], [P.BOOT, boot]]:
		c.shade(pair[0], pair[1][0], pair[1][2], 1)
	c.outline(_c("0e0a14"), 0.85)


## The frightened woodland creature: a small moss-backed deer whose antlers
## hold a faint glow. Frames: idle, panic (tremble), calm (glowing), walk.
static func fawn() -> Dictionary:
	var defs := [["idle", 4, 4.0, true], ["panic", 4, 14.0, true], ["calm", 4, 5.0, true], ["walk", 4, 8.0, true]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 0][i]})
	for i in 4:
		f.append({"bob": [0, 1, 0, 1][i], "shake": [1, -1, 1, -1][i], "ears": true})
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "glow": true, "head": -2})
	for i in 4:
		f.append({"step": [2, 0, -2, 0][i], "bob": [0, 1, 0, 1][i]})
	return Sheets.sheet(f, Vector2i(40, 36), _draw_fawn, defs)


static func _draw_fawn(c: PixelCanvas, o: Dictionary) -> void:
	var fur := _ramp("8a6a4a")
	var moss := _ramp("5a8a44")
	var glow := _ramp("c8ffd8")
	var bob: float = o.get("bob", 0)
	var sx: float = o.get("shake", 0)
	var st: float = o.get("step", 0)
	var body := Vector2(18 + sx, 21 + bob)
	for leg: Array in [[-6, st], [-3, -st], [5, -st], [8, st]]:
		c.stroke(body + Vector2(leg[0], 3), Vector2(body.x + leg[0] + leg[1] * 0.5, 34), 2, fur[2] if leg[0] in [-3, 8] else fur[1], P.BOTTOM)
	c.ellipse(body.x, body.y, 10, 5, fur[1], P.TOP)
	c.ellipse(body.x - 1, body.y - 3, 7, 2.5, moss[1], P.APRON)
	var neck := body + Vector2(8, -3)
	var head := neck + Vector2(4, -7 + o.get("head", 0))
	c.stroke(neck, head, 3, fur[1], P.TOP)
	c.ellipse(head.x + 1, head.y, 3.5, 2.5, fur[1], P.SKIN)
	c.put(int(head.x) + 2, int(head.y) - 1, _c("1a1418"), P.EYE)
	var ag: Array[Color] = glow if o.get("glow", false) else _ramp("b8a888")
	c.stroke(head + Vector2(-1, -2), head + Vector2(-3, -8), 1, ag[1], P.GLOW)
	c.stroke(head + Vector2(-2, -5), head + Vector2(-5, -7), 1, ag[1], P.GLOW)
	c.stroke(head + Vector2(1, -2), head + Vector2(2, -7), 1, ag[1], P.GLOW)
	if o.get("ears", false):
		c.put(int(head.x) - 2, int(head.y) - 3, fur[0], P.SKIN)
	c.stroke(body + Vector2(-10, -1), body + Vector2(-12, -3), 2, fur[0], P.TOP)
	for pair: Array in [[P.TOP, fur], [P.BOTTOM, fur], [P.APRON, moss], [P.SKIN, fur]]:
		c.shade(pair[0], pair[1][0], pair[1][2], 1)
	c.outline(_c("0e0a14"), 0.85)


## Tamsin the shieldbearer (companion): kite shield with a sun sigil, short
## spear, teal cloak. Cell 48×48, feet at (22, 46).
static func shieldbearer() -> Dictionary:
	var defs := [["idle", 4, 5.0, true], ["walk", 6, 10.0, true], ["attack", 3, 14.0, false], ["guard", 2, 6.0, true],
		["hurt", 1, 10.0, false], ["downed", 2, 3.0, true], ["rise", 2, 6.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i]})
	for i in 6:
		f.append({"step": [3, 1, -2, -3, -1, 2][i], "bob": [0, 1, 0, 0, 1, 0][i]})
	for i in 3:
		f.append({"spear": [-10.0, 5.0, 0.0][i], "reach": [0, 8, 4][i], "lean": [-1, 3, 1][i]})
	for i in 2:
		f.append({"shield_up": true, "bob": i})
	f.append({"lean": -3, "hurt": true})
	for i in 2:
		f.append({"downed": i})
	for i in 2:
		f.append({"bob": 4 - i * 3, "lean": -2})
	return Sheets.sheet(f, Vector2i(48, 48), _draw_shieldbearer, defs)


static func _draw_shieldbearer(c: PixelCanvas, o: Dictionary) -> void:
	var skin := _ramp("c89070")
	var hair := _ramp("3a2418")
	var cloak := _ramp("2a6a6a")
	var steel := _ramp("a8b0c0")
	var wood := _ramp("7a5a3a")
	var sun := _ramp("f0c850")
	if o.has("downed"):
		c.poly(PackedVector2Array([Vector2(6, 46), Vector2(10, 40), Vector2(30, 39), Vector2(34, 46)]), cloak[1], P.TOP)
		c.ellipse(34, 42, 3.5, 3.5, skin[1], P.SKIN)
		c.ellipse(16 + o.downed, 42, 9, 4, steel[1], P.ITEM)
		c.put(16 + o.downed, 42, sun[1], P.GLOW)
		for pair: Array in [[P.TOP, cloak], [P.ITEM, steel], [P.SKIN, skin]]:
			c.shade(pair[0], pair[1][0], pair[1][2], 1)
		c.outline(_c("0e0a14"), 0.85)
		return
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var st: float = o.get("step", 0)
	var u := Vector2(lean, bob)
	# legs
	c.stroke(Vector2(20, 34) + u * 0.4, Vector2(19 - st, 46), 3, steel[2], P.BOTTOM)
	c.stroke(Vector2(24, 34) + u * 0.4, Vector2(25 + st, 46), 3, steel[1], P.BOTTOM)
	# cloak behind
	c.poly(PackedVector2Array([Vector2(16, 20) + u, Vector2(24, 20) + u, Vector2(22, 40) + u * 0.5, Vector2(12, 42) + u * 0.5]), cloak[2], P.APRON)
	# spear arm (back)
	var sh := Vector2(18, 22) + u
	var ang := deg_to_rad(o.get("spear", -10.0))
	var hand := sh + Vector2(6 + o.get("reach", 0), 6)
	c.stroke(sh, hand, 3, steel[2], P.TOP)
	c.stroke(hand - Vector2.from_angle(ang) * 10.0, hand + Vector2.from_angle(ang) * 16.0, 1, wood[1], P.ITEM2)
	var tip := hand + Vector2.from_angle(ang) * 16.0
	c.poly(PackedVector2Array([tip, tip + Vector2.from_angle(ang + 2.6) * 4.0, tip + Vector2.from_angle(ang) * 4.0, tip + Vector2.from_angle(ang - 2.6) * 4.0]), steel[0], P.ITEM)
	# torso: mail and a teal tabard
	c.poly(PackedVector2Array([Vector2(17, 20) + u, Vector2(27, 20) + u, Vector2(28, 35) + u * 0.5, Vector2(16, 35) + u * 0.5]), steel[1], P.ITEM)
	c.rect(int(19 + lean), int(22 + bob), 6, 13, cloak[1], P.TOP)
	# head
	var head := Vector2(23, 15) + u
	c.ellipse(head.x, head.y, 3.8, 4.2, skin[1], P.SKIN)
	c.poly(PackedVector2Array([head + Vector2(-4, 3), head + Vector2(-4, -3), head + Vector2(0, -5), head + Vector2(4, -3), head + Vector2(-1, -2), head + Vector2(-2, 4)]), hair[1], P.HAIR)
	c.put(int(head.x) + 2, int(head.y) - 1, _c("1a1418"), P.EYE)
	# the kite shield in front
	var sp := Vector2(29, 27) + Vector2(lean * 0.5, bob) + (Vector2(2, -6) if o.get("shield_up", false) else Vector2.ZERO)
	c.poly(PackedVector2Array([sp + Vector2(-5, -9), sp + Vector2(5, -9), sp + Vector2(5, 3), sp + Vector2(0, 11), sp + Vector2(-5, 3)]), steel[1], P.ITEM)
	c.poly(PackedVector2Array([sp + Vector2(-4, -8), sp + Vector2(4, -8), sp + Vector2(4, 2), sp + Vector2(0, 9), sp + Vector2(-4, 2)]), cloak[1], P.TOP)
	c.ellipse(sp.x, sp.y - 1, 2.4, 2.4, sun[1], P.GLOW)
	for k in 4:
		var a := k * PI / 2 + PI / 4
		c.put(int(sp.x + cos(a) * 3.6), int(sp.y - 1 + sin(a) * 3.6), sun[0], P.GLOW)
	for pair: Array in [[P.SKIN, skin], [P.HAIR, hair], [P.TOP, cloak], [P.APRON, cloak], [P.ITEM, steel], [P.BOTTOM, steel]]:
		c.shade(pair[0], pair[1][0], pair[1][2], 1)
	c.outline(_c("0e0a14"), 0.85)


# ---------------------------------------------------------------- Kess
## Kess the scout: hooded, lighter than Tamsin, a short bow in the front hand
## and a quiver on her back. Draw/shoot frames pull the string back to the
## cheek (the tell), hop frames crouch and lift the feet.
static func scout() -> Dictionary:
	var defs := [["idle", 4, 5.0, true], ["walk", 6, 11.0, true], ["draw", 2, 8.0, false], ["shoot", 2, 10.0, false],
		["hop", 2, 10.0, false], ["hurt", 1, 10.0, false], ["downed", 2, 3.0, true], ["rise", 2, 6.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i]})
	for i in 6:
		f.append({"step": [3, 1, -2, -3, -1, 2][i], "bob": [0, 1, 0, 0, 1, 0][i]})
	for i in 2:
		f.append({"aim": true, "pull": [3, 6][i]})
	for i in 2:
		f.append({"aim": true, "pull": 0, "loose": i == 0})
	for i in 2:
		f.append({"bob": [3, 1][i], "lean": -3, "tuck": [3, 1][i]})
	f.append({"lean": -3, "hurt": true})
	for i in 2:
		f.append({"downed": i})
	for i in 2:
		f.append({"bob": 4 - i * 3, "lean": -2})
	return Sheets.sheet(f, Vector2i(48, 48), _draw_scout, defs)


static func _draw_scout(c: PixelCanvas, o: Dictionary) -> void:
	var skin := _ramp("b07a58")
	var hair := _ramp("7a3424")
	var hood := _ramp("4a6a3a")
	var tunic := _ramp("2a5a5a")
	var leather := _ramp("6a4a30")
	var wood := _ramp("8a6a40")
	var string_col := _c("d8d0b8")
	if o.has("downed"):
		c.poly(PackedVector2Array([Vector2(8, 46), Vector2(12, 41), Vector2(30, 40), Vector2(33, 46)]), hood[1], P.TOP)
		c.ellipse(33, 43, 3.2, 3.2, skin[1], P.SKIN)
		c.stroke(Vector2(12 + o.downed, 44), Vector2(26 + o.downed, 38), 1, wood[1], P.ITEM)
		for pair: Array in [[P.TOP, hood], [P.SKIN, skin], [P.ITEM, wood]]:
			c.shade(pair[0], pair[1][0], pair[1][2], 1)
		c.outline(_c("0e0a14"), 0.85)
		return
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var st: float = o.get("step", 0)
	var tuck: float = o.get("tuck", 0)
	var u := Vector2(lean, bob)
	# legs (tucked up while hopping)
	c.stroke(Vector2(20, 34) + u * 0.4, Vector2(19 - st, 46 - tuck), 2, leather[2], P.BOTTOM)
	c.stroke(Vector2(23, 34) + u * 0.4, Vector2(24 + st, 46 - tuck), 2, leather[1], P.BOTTOM)
	# quiver on the back, fletchings showing
	var q := Vector2(15, 21) + u
	c.poly(PackedVector2Array([q, q + Vector2(3, -1), q + Vector2(5, 11), q + Vector2(2, 12)]), leather[1], P.APRON)
	for k in 3:
		c.put(int(q.x + k), int(q.y - 2 - k % 2), string_col, P.GLOW)
	# short cloak behind
	c.poly(PackedVector2Array([Vector2(17, 19) + u, Vector2(24, 19) + u, Vector2(22, 36) + u * 0.5, Vector2(14, 37) + u * 0.5]), hood[2], P.APRON)
	# torso: teal tunic, leather belt
	c.poly(PackedVector2Array([Vector2(18, 20) + u, Vector2(26, 20) + u, Vector2(26, 34) + u * 0.5, Vector2(17, 34) + u * 0.5]), tunic[1], P.TOP)
	c.rect(int(17 + lean * 0.5), int(29 + bob * 0.5), 9, 2, leather[1], P.BOTTOM)
	# head in a reed-green hood, a lock of red hair
	var head := Vector2(23, 14) + u
	c.ellipse(head.x, head.y, 3.4, 3.8, skin[1], P.SKIN)
	c.poly(PackedVector2Array([head + Vector2(-5, 4), head + Vector2(-4, -4), head + Vector2(0, -6), head + Vector2(4, -4), head + Vector2(2, -2), head + Vector2(-1, -2), head + Vector2(-2, 5)]), hood[1], P.HAIR)
	c.put(int(head.x) + 1, int(head.y) + 3, hair[1], P.EYE)
	c.put(int(head.x) + 2, int(head.y) - 1, _c("1a1418"), P.EYE)
	# the bow in the front hand; aiming holds it out level
	var sh := Vector2(24, 22) + u
	var aim: bool = o.get("aim", false)
	var hand := sh + (Vector2(9, -1) if aim else Vector2(4, 8))
	c.stroke(sh, hand, 2, tunic[2], P.TOP)
	var top := hand + Vector2(-2, -9)
	var bot := hand + Vector2(-2, 9)
	c.stroke(top, hand + Vector2(1, 0), 1, wood[1], P.ITEM)
	c.stroke(hand + Vector2(1, 0), bot, 1, wood[1], P.ITEM)
	var pull: float = o.get("pull", 0)
	var nock := Vector2(top.x - pull, hand.y)
	c.stroke(top, nock, 1, string_col, P.ITEM2)
	c.stroke(nock, bot, 1, string_col, P.ITEM2)
	if aim and not o.get("loose", false):
		# the arrow on the string, drawing arm back to the cheek
		c.stroke(nock, hand + Vector2(5, 0), 1, wood[0], P.ITEM)
		c.put(int(hand.x + 5), int(hand.y), _c("f0c850"), P.GLOW)
		c.stroke(sh + Vector2(-1, 1), nock, 2, tunic[1], P.TOP)
	for pair: Array in [[P.SKIN, skin], [P.HAIR, hood], [P.TOP, tunic], [P.APRON, hood], [P.ITEM, wood], [P.BOTTOM, leather]]:
		c.shade(pair[0], pair[1][0], pair[1][2], 1)
	c.outline(_c("0e0a14"), 0.85)
