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
