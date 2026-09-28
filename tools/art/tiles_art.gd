extends RefCounted
## Terrain tiles. Each terrain is drawn for all 16 neighbour masks
## (bit 1 = solid above, 2 = right, 4 = below, 8 = left) in 2 variants.

const T := 16

const TERRAINS := {
	"ruin": {"hi": "6c6c92", "mid": "45425f", "lo": "2e2c45", "mortar": "1d1b2e", "cap": "7c7ea4", "moss": "4d6e52", "moss_hi": "6f9a62"},
	"earth": {"hi": "6b5652", "mid": "4a3a3c", "lo": "33272d", "mortar": "241b22", "cap": "7da04e", "moss": "4d7c3a", "moss_hi": "a2c45e"},
	"wood": {"hi": "a8784a", "mid": "7a5234", "lo": "4e3222", "mortar": "2c1c16", "cap": "c49a62", "moss": "4d6e52", "moss_hi": "6f9a62"},
	"village": {"hi": "a08a70", "mid": "7a6a58", "lo": "54483e", "mortar": "362c28", "cap": "86a85a", "moss": "5a8040", "moss_hi": "a6c86a"},
	"ward": {"hi": "8a88b8", "mid": "5c5a86", "lo": "3c3a5e", "mortar": "22203a", "cap": "9e9cd0", "moss": "5e4a7a", "moss_hi": "8a6ab0"},
}
const ORDER := ["ruin", "earth", "wood", "village", "ward"]


static func build() -> Image:
	var img := Image.create_empty(16 * T, ORDER.size() * 2 * T, false, Image.FORMAT_RGBA8)
	for ti in ORDER.size():
		for v in 2:
			for mask in 16:
				var c := PixelCanvas.new(T, T)
				var name: String = ORDER[ti]
				if name == "wood":
					_plank(c, mask, v, TERRAINS[name])
				elif name == "earth":
					_earth(c, mask, v, TERRAINS[name])
				else:
					_bricks(c, mask, v, TERRAINS[name], name)
				c.blit_into(img, mask * T, (ti * 2 + v) * T)
	return img


static func _col(p: Dictionary, k: String) -> Color:
	return Color.html(p[k])


static func _rng(mask: int, v: int, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = mask * 7919 + v * 104729 + salt * 31
	return r


static func _bricks(c: PixelCanvas, mask: int, v: int, p: Dictionary, name: String) -> void:
	var r := _rng(mask, v, name.hash())
	c.rect(0, 0, T, T, _col(p, "mid"))
	# 8x4 running bond, aligned so tiles join seamlessly
	for row in 4:
		var y := row * 4
		var off := 4 if row % 2 == 1 else 0
		for x in T:
			c.put(x, y, _col(p, "mortar"))
		for bx in [off, off + 8]:
			var x0: int = bx % T
			for yy in range(y, y + 4):
				c.put(x0, yy, _col(p, "mortar"))
			# light top-left edge, dark bottom edge on each brick
			for xx in range(x0 + 1, x0 + 7):
				c.put(xx % T, y + 1, _col(p, "hi").lerp(_col(p, "mid"), 0.55))
				c.put(xx % T, y + 3, _col(p, "lo"))
	# speckles and cracks
	for i in 6:
		c.put(r.randi_range(0, T - 1), r.randi_range(0, T - 1), _col(p, "lo"))
	if r.randf() < 0.5:
		var x := r.randi_range(2, 13)
		var y := r.randi_range(5, 12)
		c.line(x, y, x + r.randi_range(-2, 2), y + 3, _col(p, "mortar"))
	if name == "ward" and r.randf() < 0.35:
		var x := r.randi_range(3, 11)
		var y := r.randi_range(5, 10)
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 0), Vector2i(1, -1), Vector2i(1, 0)]:
			c.put(x + d.x, y + d.y, Color.html("7a6ad0"))
	_edges(c, mask, p, r, name != "village")


static func _earth(c: PixelCanvas, mask: int, v: int, p: Dictionary) -> void:
	var r := _rng(mask, v, 77)
	c.rect(0, 0, T, T, _col(p, "mid"))
	for i in 18:
		var col := _col(p, "lo") if r.randf() < 0.6 else _col(p, "hi")
		c.put(r.randi_range(0, T - 1), r.randi_range(0, T - 1), col)
	for i in r.randi_range(1, 2):
		var sx := r.randi_range(2, 12)
		var sy := r.randi_range(5, 13)
		c.rect(sx, sy, 3, 2, Color.html("5e566c"))
		c.put(sx, sy, Color.html("7a728a"))
		c.put(sx + 2, sy + 1, Color.html("3e3848"))
	if r.randf() < 0.5:
		var rx := r.randi_range(0, 10)
		c.line(rx, 6, rx + 5, 9, _col(p, "lo"))
	_edges(c, mask, p, r, true)


static func _plank(c: PixelCanvas, mask: int, v: int, p: Dictionary) -> void:
	var r := _rng(mask, v, 5)
	# one-way plank: 5px deck at the top, posts below where nothing is to the side
	c.rect(0, 0, T, 5, _col(p, "mid"))
	for x in T:
		c.put(x, 0, _col(p, "cap"))
		c.put(x, 4, _col(p, "lo"))
	for x in [r.randi_range(3, 6), r.randi_range(10, 13)]:
		c.put(x, 2, _col(p, "lo"))
	if not (mask & 8):
		c.rect(0, 0, 1, 5, _col(p, "mortar"))
		c.rect(2, 5, 2, 6, _col(p, "lo"))
	if not (mask & 2):
		c.rect(T - 1, 0, 1, 5, _col(p, "mortar"))
		c.rect(T - 4, 5, 2, 6, _col(p, "lo"))
	c.line(0, 5, T - 1, 5, _col(p, "mortar"))


static func _edges(c: PixelCanvas, mask: int, p: Dictionary, r: RandomNumberGenerator, mossy: bool) -> void:
	var open_up := not (mask & 1)
	if not (mask & 8):
		for y in T:
			c.put(0, y, _col(p, "mortar"))
			c.put(1, y, _col(p, "lo"))
	if not (mask & 2):
		for y in T:
			c.put(T - 1, y, _col(p, "mortar"))
			c.put(T - 2, y, _col(p, "lo"))
	if not (mask & 4):
		for x in T:
			c.put(x, T - 1, _col(p, "mortar"))
			c.put(x, T - 2, _col(p, "lo"))
	if open_up:
		# cap / grass layer with a ragged underside
		for x in T:
			var depth := 3 + (1 if r.randf() < 0.35 else 0)
			for y in depth:
				c.put(x, y, _col(p, "cap") if y > 0 else _col(p, "cap").lightened(0.15))
			c.put(x, depth, _col(p, "moss") if mossy else _col(p, "lo"))
		if mossy:
			for i in 5:
				var x := r.randi_range(0, T - 1)
				c.put(x, 0, _col(p, "moss_hi"))
			for i in 3:  # hanging moss drips
				var x := r.randi_range(1, T - 2)
				var ln := r.randi_range(1, 3)
				for y in range(3, 4 + ln):
					c.put(x, y, _col(p, "moss"))
		if not (mask & 8):
			c.erase(0, 0)
		if not (mask & 2):
			c.erase(T - 1, 0)
