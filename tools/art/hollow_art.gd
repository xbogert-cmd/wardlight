extends RefCounted
## Chapter 2 creatures of the Hollowing (side view, facing right): the Husk,
## the Mire Lurker, the Hollow Moth and its spore. All share the hollow
## mask motif: pale wood, dark empty eyes.

const Sheets = preload("res://tools/art/enemies_art.gd")

enum R { NONE, BODY, BODY2, MASK, EYE, GLOW, LIMB, MUD, WING }

const MASK := ["f0e8d4", "d0c4a8", "9a8e74"]
const INK := "0e0a14"


static func _c(a: Array) -> Array[Color]:
	var out: Array[Color] = []
	for s: String in a:
		out.append(Color.html(s))
	return out


static func _mask(c: PixelCanvas, at: Vector2, s: float) -> void:
	var m := _c(MASK)
	c.ellipse(at.x, at.y, 3.2 * s, 3.8 * s, m[1], R.MASK)
	c.put(int(at.x) - 1, int(at.y) - 1, Color(INK), R.EYE)
	c.put(int(at.x) + 1, int(at.y) - 1, Color(INK), R.EYE)
	c.put(int(at.x), int(at.y) + 2, Color(INK), R.EYE)


# ---------------------------------------------------------------- Husk
## A hollowed villager: hunched, bark-grey, arms too long, mask for a face.
## The lunge windup rears back with arms raised (the tell).
static func husk() -> Dictionary:
	var defs := [["idle", 4, 4.0, true], ["walk", 6, 6.0, true], ["windup", 2, 6.0, false], ["lunge", 2, 12.0, false],
		["recover", 2, 5.0, false], ["hurt", 1, 10.0, false], ["death", 4, 7.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "arm": 0.0})
	for i in 6:
		f.append({"step": [3, 1, -2, -3, -1, 2][i], "bob": [0, 1, 0, 0, 1, 0][i], "arm": [0.2, 0.1, -0.1, -0.2, -0.1, 0.1][i]})
	for i in 2:
		f.append({"lean": -3 - i, "arm": -1.8 - i * 0.3, "glow": true})
	for i in 2:
		f.append({"lean": 5, "arm": 0.9, "reach": 4 + i * 2, "step": 3})
	for i in 2:
		f.append({"lean": 2 - i, "arm": 0.6, "bob": 2 - i})
	f.append({"lean": -3, "arm": -0.4})
	for i in 4:
		f.append({"fall": i})
	return Sheets.sheet(f, Vector2i(48, 48), _draw_husk, defs)


static func _draw_husk(c: PixelCanvas, o: Dictionary) -> void:
	var bark := _c(["8a8478", "625c52", "403c36"])
	var rag := _c(["5a6a5a", "3e4a40", "283028"])
	if o.has("fall"):
		var k: int = o.fall
		var sink: int = k * 3
		c.poly(PackedVector2Array([Vector2(12, 46), Vector2(16, 38 + sink), Vector2(30, 36 + sink), Vector2(34, 46)]), rag[1], R.BODY2)
		if k < 3:
			_mask(c, Vector2(31 + k, 37 + sink), 1.0)
		for j in k + 2:
			c.put(14 + j * 5, 40 - j % 3 + sink / 2, Color("a8c070", 0.8), R.GLOW)
		c.shade(R.BODY2, rag[0], rag[2], 1)
		c.outline(Color(INK), 0.8)
		return
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var st: float = o.get("step", 0)
	var u := Vector2(lean, bob)
	# legs, knees bent
	c.stroke(Vector2(20, 33) + u * 0.3, Vector2(18 - st, 46), 3, bark[2], R.LIMB)
	c.stroke(Vector2(24, 33) + u * 0.3, Vector2(26 + st, 46), 3, bark[1], R.LIMB)
	# ragged tunic over a stooped trunk
	c.poly(PackedVector2Array([Vector2(15, 20) + u, Vector2(27, 17) + u, Vector2(29, 34) + u * 0.4, Vector2(15, 35) + u * 0.4]), rag[1], R.BODY2)
	c.poly(PackedVector2Array([Vector2(16, 34) + u * 0.4, Vector2(19, 38), Vector2(22, 35) + u * 0.4, Vector2(26, 39), Vector2(28, 34) + u * 0.4]), rag[2], R.BODY2)
	# long arms: rest hanging, raised for the tell, thrust forward to lunge
	var sh: Vector2 = Vector2(25, 21) + u
	var arm: float = o.get("arm", 0.0)
	var hand: Vector2 = sh + Vector2.from_angle(PI * 0.5 - arm) * (14.0 + float(o.get("reach", 0)))
	c.stroke(sh, sh.lerp(hand, 0.5) + Vector2(1, 0), 2, bark[1], R.LIMB)
	c.stroke(sh.lerp(hand, 0.5) + Vector2(1, 0), hand, 2, bark[1], R.LIMB)
	for k in 3:
		c.put(int(hand.x) + k - 1, int(hand.y) + 1 + k % 2, bark[0], R.LIMB)
	# the head, hung low and forward, masked
	var head: Vector2 = Vector2(28, 16) + u
	c.ellipse(head.x - 1, head.y, 4.0, 4.2, bark[1], R.BODY)
	_mask(c, head + Vector2(1.5, 0), 1.0)
	if o.get("glow", false):
		c.put(int(head.x), int(head.y) - 1, Color("d8ff90"), R.GLOW)
		c.put(int(head.x) + 3, int(head.y) - 1, Color("d8ff90"), R.GLOW)
	# spore tufts growing out of the shoulders
	for k in 3:
		c.put(int(17 + k * 3 + lean), int(18 + bob - k % 2), Color("a8c070"), R.GLOW)
	for pair: Array in [[R.BODY, bark], [R.LIMB, bark], [R.BODY2, rag]]:
		c.shade(pair[0], pair[1][0], pair[1][2], 1)
	c.shade(R.MASK, Color(MASK[0]), Color(MASK[2]), 1)
	c.outline(Color(INK), 0.85)


# ---------------------------------------------------------------- Mire Lurker
## A long, flat mud-thing: a wide jaw, moss along its back and a small mask
## pressed into its brow. Surfacing frames rise out of the ground line.
static func lurker() -> Dictionary:
	var defs := [["surface", 3, 12.0, false], ["idle", 4, 5.0, true], ["bite", 2, 12.0, false], ["dive", 3, 10.0, false],
		["hurt", 1, 10.0, false], ["death", 3, 6.0, false]]
	var f := []
	for i in 3:
		f.append({"rise": [0.35, 0.7, 1.0][i], "jaw": 6})
	for i in 4:
		f.append({"rise": 1.0, "bob": [0, 0, 1, 1][i], "jaw": [0, 1, 1, 0][i]})
	for i in 2:
		f.append({"rise": 1.0, "jaw": 8 - i * 6, "lean": 3})
	for i in 3:
		f.append({"rise": [0.75, 0.45, 0.15][i], "jaw": 0})
	f.append({"rise": 1.0, "jaw": 3, "lean": -3})
	for i in 3:
		f.append({"rise": [0.8, 0.5, 0.25][i], "jaw": 4, "dead": true})
	return Sheets.sheet(f, Vector2i(56, 32), _draw_lurker, defs)


static func _draw_lurker(c: PixelCanvas, o: Dictionary) -> void:
	var mud := _c(["7a6a4a", "54482f", "36301f"])
	var moss := _c(["8aa050", "5e7a38", "3e5428"])
	var rise: float = o.get("rise", 1.0)
	var bob: float = o.get("bob", 0)
	var lean: float = o.get("lean", 0)
	var jaw: float = o.get("jaw", 0)
	var sink: float = (1.0 - rise) * 16.0
	var base := 30.0
	# a long low body (back half dragged through the mud)
	c.ellipse(24 + lean * 0.5, base - 6 + sink + bob, 17.0, 6.5, mud[1], R.MUD)
	c.ellipse(9 + lean * 0.3, base - 3 + sink, 8.0, 3.5, mud[2], R.MUD)
	# head and a wide jaw that opens to bite
	var head: Vector2 = Vector2(40 + lean, base - 9 + sink + bob)
	c.ellipse(head.x, head.y, 7.5, 5.0, mud[1], R.MUD)
	c.poly(PackedVector2Array([head + Vector2(-4, 3), head + Vector2(10, 2 + jaw * 0.3), head + Vector2(9, 5 + jaw), head + Vector2(-3, 6)]), mud[2], R.BODY2)
	if jaw > 2:
		c.poly(PackedVector2Array([head + Vector2(0, 3), head + Vector2(9, 2.5), head + Vector2(8, 3 + jaw)]), Color("3a1420"), R.EYE)
		for k in 3:
			c.put(int(head.x) + 2 + k * 3, int(head.y) + 3, Color("e8e0cc"), R.GLOW)
	_mask(c, head + Vector2(1, -2), 0.8)
	c.put(int(head.x) + 5, int(head.y) - 2, Color("e4ff6a"), R.GLOW)
	# moss ridge down the back
	for k in 7:
		c.put(12 + k * 4, int(base - 12 + sink + bob + (k % 2)), moss[k % 3], R.WING)
	if o.get("dead", false):
		c.put(int(head.x) + 5, int(head.y) - 2, mud[2], R.MUD)
	# everything below the ground line stays hidden while surfacing
	for y in range(int(base) + 1, c.h):
		for x in c.w:
			c.erase(x, y)
	c.shade(R.MUD, mud[0], mud[2], 1)
	c.shade(R.MASK, Color(MASK[0]), Color(MASK[2]), 1)
	c.outline(Color(INK), 0.8)


# ---------------------------------------------------------------- Hollow Moth
## A pale moth with a mask for a face and sickly eye-spots on its wings;
## the spots flare before it looses a spore.
static func moth() -> Dictionary:
	var defs := [["idle", 4, 10.0, true], ["windup", 2, 8.0, false], ["shoot", 2, 12.0, false], ["hurt", 1, 10.0, false],
		["death", 4, 8.0, false]]
	var f := []
	for i in 4:
		f.append({"flap": [1.0, 0.4, -0.3, 0.4][i]})
	for i in 2:
		f.append({"flap": 0.8, "glow": 1 + i})
	for i in 2:
		f.append({"flap": [-0.4, 0.2][i], "lean": 2})
	f.append({"flap": 0.6, "lean": -2})
	for i in 4:
		f.append({"flap": [0.2, -0.2, -0.5, -0.7][i], "fall": i})
	return Sheets.sheet(f, Vector2i(40, 40), _draw_moth, defs)


static func _draw_moth(c: PixelCanvas, o: Dictionary) -> void:
	var wing := _c(["c8c0d0", "9a90a8", "6a6078"])
	var body := _c(["6a5a6a", "4a3e4a", "2e262e"])
	var spot: Color = Color("c8ff70") if o.get("glow", 0) >= 2 else (Color("9ad850") if o.get("glow", 0) == 1 else Color("5a7a3a"))
	var flap: float = o.get("flap", 0.0)
	var fall: int = o.get("fall", 0)
	var lean: float = o.get("lean", 0)
	var cy: float = 20.0 + fall * 3
	var body_c: Vector2 = Vector2(20 + lean, cy)
	# back wing, then the front wing on top (up/down with the flap)
	for side: float in [-1.0, 1.0]:
		var tip: Vector2 = body_c + Vector2(-9 * side + 2, -14.0 * flap - 2)
		var low: Vector2 = body_c + Vector2(-6 * side, 8.0 * (1.0 - absf(flap)) + 4)
		var col: Color = wing[2] if side < 0 else wing[1]
		c.poly(PackedVector2Array([body_c + Vector2(-2, -2), tip, tip + Vector2(-6 * side, 4), low, body_c + Vector2(0, 3)]), col, R.WING)
		var sp: Vector2 = body_c.lerp(tip, 0.55) + Vector2(-2 * side, 1)
		c.put(int(sp.x), int(sp.y), spot, R.GLOW)
		c.put(int(sp.x) + 1, int(sp.y), spot, R.GLOW)
	# furry body and a mask for a face
	c.ellipse(body_c.x, body_c.y + 2, 3.0, 6.0, body[1], R.BODY)
	_mask(c, body_c + Vector2(3, -4), 0.8)
	c.stroke(body_c + Vector2(4, -7), body_c + Vector2(8, -11), 1, body[0], R.LIMB)
	c.stroke(body_c + Vector2(2, -7), body_c + Vector2(4, -12), 1, body[0], R.LIMB)
	c.shade(R.WING, wing[0], wing[2], 1)
	c.shade(R.BODY, body[0], body[2], 1)
	c.outline(Color(INK), 0.8)


# ---------------------------------------------------------------- the Herald
## The Hollowing's gardener: tall and thin in a tattered violet-black robe,
## a smooth pale mask split by one crack, pale branches budding from its
## cowl, and a long pruning sickle. Blinking, it dissolves into dither.
static func herald() -> Dictionary:
	var defs := [["idle", 4, 4.0, true], ["walk", 4, 6.0, true], ["slash_windup", 2, 6.0, false], ["slash", 3, 14.0, false],
		["recover", 2, 5.0, false], ["cast", 3, 6.0, false], ["blink_out", 4, 10.0, false], ["blink_in", 4, 10.0, false],
		["hurt", 1, 10.0, false], ["death", 4, 6.0, false]]
	var f := []
	for i in 4:
		f.append({"bob": [0, 0, 1, 1][i], "sway": [0, 1, 0, -1][i]})
	for i in 4:
		f.append({"bob": [0, 1, 0, 1][i], "sway": [2, 1, -2, -1][i], "lean": 1})
	for i in 2:
		f.append({"pose": "windup", "lean": -2 - i, "sway": -1})
	for i in 3:
		f.append({"pose": "slash", "lean": 3, "smear": i, "sway": 2})
	for i in 2:
		f.append({"pose": "slash", "lean": 2 - i, "sway": 1})
	for i in 3:
		f.append({"cast": i, "sway": 0})
	for i in 4:
		f.append({"fade": 0.2 + i * 0.25})
	for i in 4:
		f.append({"fade": 0.95 - i * 0.25})
	f.append({"lean": -3, "sway": -2})
	for i in 4:
		f.append({"fade": 0.15 + i * 0.25, "lean": -2})
	return Sheets.sheet(f, Vector2i(72, 76), _draw_herald, defs)


static func _draw_herald(c: PixelCanvas, o: Dictionary) -> void:
	var robe := _c(["4e3e62", "2e2440", "1a1426"])
	var wood := _c(["e0d8c0", "b0a488", "6e6450"])
	var steel := _c(["f0f0f8", "b0b0c8", "6a6a88"])
	var bob: float = o.get("bob", 0)
	var sway: float = o.get("sway", 0)
	var lean: float = o.get("lean", 0)
	var pose: String = o.get("pose", "")
	var foot := 74.0
	var cx := 32.0 + lean
	# branches from the cowl, budding pale green
	var crown := Vector2(cx - 1, 14 + bob)
	for br: Array in [[Vector2(-4, -8), Vector2(-9, -12)], [Vector2(3, -9), Vector2(8, -13)], [Vector2(-1, -11), Vector2(-3, -16)]]:
		var a: Vector2 = crown + br[0]
		c.stroke(crown, a, 1, wood[1], R.LIMB)
		c.stroke(a, crown + br[1], 1, wood[1], R.LIMB)
		c.put(int(crown.x + br[1].x), int(crown.y + br[1].y), Color("c8f0a0"), R.GLOW)
		c.put(int(a.x) + 1, int(a.y), Color("a8d880"), R.GLOW)
	# back arm (raised with a glowing seed when casting)
	var sh_b := Vector2(cx - 3, 27 + bob)
	if o.has("cast"):
		var hand_b := sh_b + Vector2(-3, -14)
		c.stroke(sh_b, hand_b, 2, robe[2], R.BODY2)
		c.ellipse(hand_b.x, hand_b.y - 1, 1.5 + o.cast * 0.6, 1.5 + o.cast * 0.6, Color("c8ff90"), R.GLOW)
		c.put(int(hand_b.x), int(hand_b.y) - 2, Color("ffffff"), R.GLOW)
	# robe: narrow shoulders, sweeping hem, roots stitched along it
	var hem_l := Vector2(cx - 12 + sway * 0.5, foot)
	var hem_r := Vector2(cx + 11 + sway, foot)
	c.poly(PackedVector2Array([Vector2(cx - 6, 24 + bob), Vector2(cx + 6, 24 + bob), Vector2(cx + 8, 44 + bob), hem_r,
		Vector2(cx + 5 + sway, foot - 2), Vector2(cx + 1 + sway, foot), Vector2(cx - 4, foot - 2), hem_l, Vector2(cx - 8, 44 + bob)]), robe[1], R.BODY)
	for k in 5:
		var x := int(hem_l.x + 3 + k * 4.5)
		c.stroke(Vector2(x, foot - 1), Vector2(x + (k % 2) - 0.5, foot - 6 - k % 3), 1, wood[2], R.LIMB)
	c.stroke(Vector2(cx - 1, 26 + bob), Vector2(cx - 1 + sway * 0.4, foot - 3), 1, robe[2], R.BODY2)
	# cowl and mask
	var head := Vector2(cx + 1, 18 + bob)
	c.ellipse(head.x - 1, head.y, 6.0, 7.0, robe[2], R.BODY2)
	c.ellipse(head.x + 1.5, head.y + 1, 3.6, 4.8, wood[0], R.MASK)
	c.put(int(head.x), int(head.y), Color(INK), R.EYE)
	c.put(int(head.x) + 3, int(head.y), Color(INK), R.EYE)
	c.line(int(head.x) + 2, int(head.y) - 3, int(head.x) + 1, int(head.y) + 5, Color("3a2a3a"), R.EYE)
	# front arm and the pruning sickle
	var sh := Vector2(cx + 4, 28 + bob)
	var hand: Vector2
	var tip: Vector2
	match pose:
		"windup":
			hand = sh + Vector2(-6, -10)
			tip = hand + Vector2(-10, -22)
		"slash":
			hand = sh + Vector2(10, 4)
			tip = hand + Vector2(24, -4)
		_:
			hand = sh + Vector2(5, 10)
			tip = hand + Vector2(3, -34)
	c.stroke(sh, hand, 2, robe[0], R.BODY)
	var butt := hand - (tip - hand).normalized() * 12.0
	c.stroke(butt, tip, 1, wood[2], R.LIMB)
	var d := (tip - hand).normalized()
	var n := Vector2(d.y, -d.x) * (1.0 if pose != "windup" else -1.0)
	var blade := [tip, tip + n * 5 + d * 2, tip + n * 9 - d * 2, tip + n * 8 - d * 6, tip + n * 4 - d * 3]
	for k in blade.size() - 1:
		c.stroke(blade[k], blade[k + 1], 2 if k < 2 else 1, steel[1], R.WING)
	c.rect(int(hand.x) - 1, int(hand.y) - 1, 3, 3, wood[0], R.MASK)
	if pose == "slash" and o.has("smear"):
		var sm: float = o.smear
		for k in 7:
			var a := -1.2 + k * 0.35 + sm * 0.2
			var p := sh + Vector2.from_angle(a) * (22 + sm * 2)
			c.put(int(p.x), int(p.y), Color("d8b8ff", 0.9 - k * 0.1), R.GLOW)
	c.shade(R.BODY, robe[0], robe[2], 1)
	c.shade(R.MASK, wood[0], wood[2], 1)
	c.shade(R.WING, steel[0], steel[2], 1)
	c.outline(Color(INK), 0.85)
	# dissolving: dither the figure away into shadow
	var fade: float = o.get("fade", 0.0)
	if fade > 0.0:
		for y in c.h:
			for x in c.w:
				if fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0) < fade:
					c.erase(x, y)


# ---------------------------------------------------------------- Herald's seeds and tether
## A hollow seed: a dark bulb with a pale crack that brightens as it swells.
static func hollow_seed() -> Dictionary:
	var defs := [["idle", 2, 3.0, true], ["death", 3, 14.0, false]]
	var f := [{"r": 4.0}, {"r": 4.6}, {"r": 5.5, "pop": 1}, {"r": 7.0, "pop": 2}, {"r": 8.0, "pop": 3}]
	return Sheets.sheet(f, Vector2i(20, 20), _draw_seed, defs)


static func _draw_seed(c: PixelCanvas, o: Dictionary) -> void:
	var r: float = o.r
	if o.has("pop"):
		for k in 10:
			var a := k * TAU / 10.0
			c.put(int(10 + cos(a) * r), int(12 + sin(a) * r * 0.7), Color("c8b0e8", 1.0 - o.pop * 0.25), R.GLOW)
		return
	c.ellipse(10, 13, r, r * 0.9, Color("3a2a44"), R.BODY)
	c.stroke(Vector2(10, 13 - r), Vector2(10, 13 - r - 3), 1, Color("6a8a4a"), R.LIMB)
	c.line(9, 10, 11, 16, Color("e8ffc0"), R.GLOW)
	c.put(10, 12, Color("ffffff"), R.GLOW)
	c.shade(R.BODY, Color("6a5480"), Color("1a1224"), 1)
	c.outline(Color(INK), 0.7)


## The tether's knot: a snarl of dark cords glowing violet where they cross.
static func tether_knot() -> Dictionary:
	var defs := [["idle", 2, 8.0, true], ["death", 3, 14.0, false]]
	var f := [{"t": 0}, {"t": 1}, {"pop": 1}, {"pop": 2}, {"pop": 3}]
	return Sheets.sheet(f, Vector2i(16, 16), _draw_knot, defs)


static func _draw_knot(c: PixelCanvas, o: Dictionary) -> void:
	if o.has("pop"):
		for k in 8:
			var a := k * TAU / 8.0
			c.put(int(8 + cos(a) * (2 + o.pop * 2)), int(8 + sin(a) * (2 + o.pop * 2)), Color("d8b8ff", 1.0 - o.pop * 0.25), R.GLOW)
		return
	var tw: float = o.t
	for k in 3:
		var a := k * PI / 3.0 + tw * 0.3
		c.stroke(Vector2(8, 8) - Vector2.from_angle(a) * 5, Vector2(8, 8) + Vector2.from_angle(a) * 5, 2, Color("2e2440"), R.BODY)
	c.ellipse(8, 8, 2.0, 2.0, Color("b890ff"), R.GLOW)
	c.put(8, 8, Color("ffffff"), R.GLOW)
	c.outline(Color(INK), 0.7)


# ---------------------------------------------------------------- Spore
static func spore() -> Dictionary:
	var defs := [["idle", 2, 6.0, true], ["death", 3, 14.0, false]]
	var f := [{"r": 3.0}, {"r": 3.5}, {"r": 4.5, "pop": 1}, {"r": 5.5, "pop": 2}, {"r": 6.0, "pop": 3}]
	return Sheets.sheet(f, Vector2i(16, 16), _draw_spore, defs)


static func _draw_spore(c: PixelCanvas, o: Dictionary) -> void:
	var r: float = o.r
	if o.has("pop"):
		for k in 8:
			var a := k * TAU / 8.0
			c.put(int(8 + cos(a) * r), int(8 + sin(a) * r), Color("c8ff70", 1.0 - o.pop * 0.25), R.GLOW)
		return
	c.ellipse(8, 8, r, r, Color("7ab83a"), R.BODY)
	c.put(7, 7, Color("e8ffb0"), R.GLOW)
	for k in 6:
		var a := k * TAU / 6.0 + r
		c.put(int(8 + cos(a) * (r + 1.5)), int(8 + sin(a) * (r + 1.5)), Color("a8d860"), R.GLOW)
	c.shade(R.BODY, Color("c8ff70"), Color("4a7a2a"), 1)
	c.outline(Color(INK), 0.6)
