extends RefCounted
## Terrain tiles. Columns 0–15: the 16 neighbour masks (bit 1 = solid above,
## 2 = right, 4 = below, 8 = left). Columns 16–21: slopes (see SLOPES).
## Two variant rows per terrain.

const T := 16
const MASK_COLS := 16

const TERRAINS := {
	"ruin": {"hi": "6c6c92", "mid": "45425f", "lo": "2e2c45", "mortar": "1d1b2e", "cap": "7c7ea4", "moss": "4d6e52", "moss_hi": "6f9a62"},
	"earth": {"hi": "6b5652", "mid": "4a3a3c", "lo": "33272d", "mortar": "241b22", "cap": "7da04e", "moss": "4d7c3a", "moss_hi": "a2c45e"},
	"rock": {"hi": "7a7a8c", "mid": "575868", "lo": "3c3c4c", "mortar": "25242f", "cap": "6f9a4c", "moss": "4a7038", "moss_hi": "98c05a"},
	"village": {"hi": "a08a70", "mid": "7a6a58", "lo": "54483e", "mortar": "362c28", "cap": "86a85a", "moss": "5a8040", "moss_hi": "a6c86a"},
	"ward": {"hi": "8a88b8", "mid": "5c5a86", "lo": "3c3a5e", "mortar": "22203a", "cap": "9e9cd0", "moss": "5e4a7a", "moss_hi": "8a6ab0"},
}
const ORDER := ["ruin", "earth", "rock", "village", "ward"]
## slope id -> surface height function kind; order = atlas column 16 + index
const SLOPES := ["/", "\\", "1", "2", "3", "4"]


static func surface_y(kind: String, x: int) -> int:
	match kind:
		"/": return T - 1 - x
		"\\": return x
		"1": return T - 1 - x / 2
		"2": return 7 - x / 2
		"3": return x / 2
		"4": return 8 + x / 2
	return 0


static func build() -> Image:
	var img := Image.create_empty((MASK_COLS + SLOPES.size()) * T, ORDER.size() * 2 * T, false, Image.FORMAT_RGBA8)
	for ti in ORDER.size():
		var name: String = ORDER[ti]
		var p: Dictionary = TERRAINS[name]
		for v in 2:
			for mask in 16:
				var c := PixelCanvas.new(T, T)
				_fill(c, name, mask, v, p)
				c.blit_into(img, mask * T, (ti * 2 + v) * T)
			for si in SLOPES.size():
				var c := PixelCanvas.new(T, T)
				_slope(c, name, SLOPES[si], v, p)
				c.blit_into(img, (MASK_COLS + si) * T, (ti * 2 + v) * T)
	return img


static func _col(p: Dictionary, k: String) -> Color:
	return Color.html(p[k])


static func _rng(mask: int, v: int, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = mask * 7919 + v * 104729 + salt * 31
	return r


static func _fill(c: PixelCanvas, name: String, mask: int, v: int, p: Dictionary) -> void:
	var r := _rng(mask, v, name.hash())
	match name:
		"earth":
			_earth(c, r, p)
		"rock":
			_rock(c, r, p)
		_:
			_bricks(c, r, p, name)
	_edges(c, mask, p, r, name != "village")


static func _bricks(c: PixelCanvas, r: RandomNumberGenerator, p: Dictionary, name: String) -> void:
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
			for xx in range(x0 + 1, x0 + 7):
				c.put(xx % T, y + 1, _col(p, "hi").lerp(_col(p, "mid"), 0.55))
				c.put(xx % T, y + 3, _col(p, "lo"))
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


static func _earth(c: PixelCanvas, r: RandomNumberGenerator, p: Dictionary) -> void:
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


## Natural rock: irregular stones with cracks, no grid.
static func _rock(c: PixelCanvas, r: RandomNumberGenerator, p: Dictionary) -> void:
	c.rect(0, 0, T, T, _col(p, "mid"))
	for i in 5:
		var cx := r.randf_range(1, 15)
		var cy := r.randf_range(1, 15)
		var rx := r.randf_range(2.5, 5.0)
		var ry := r.randf_range(2.0, 3.5)
		c.ellipse(cx, cy, rx, ry, _col(p, "hi").lerp(_col(p, "mid"), r.randf_range(0.35, 0.8)))
		# lower-right shadow lip on each stone
		for x in range(int(cx - rx) + 1, int(cx + rx)):
			c.put(x, int(cy + ry), _col(p, "lo"))
	for i in 2:
		var x := r.randi_range(1, 14)
		var y := r.randi_range(1, 14)
		var dx := r.randi_range(-1, 1)
		c.line(x, y, x + dx * 3, y + r.randi_range(2, 5), _col(p, "mortar"))
	for i in 8:
		c.put(r.randi_range(0, T - 1), r.randi_range(0, T - 1), _col(p, "lo"))


static func _edges(c: PixelCanvas, mask: int, p: Dictionary, r: RandomNumberGenerator, mossy: bool) -> void:
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
	if not (mask & 1):
		var surf := PackedInt32Array()
		surf.resize(T)
		_cap(c, surf, p, r, mossy)
		if not (mask & 8):
			c.erase(0, 0)
		if not (mask & 2):
			c.erase(T - 1, 0)


## Grass / cap band that follows a surface line (surf[x] = top pixel row).
static func _cap(c: PixelCanvas, surf: PackedInt32Array, p: Dictionary, r: RandomNumberGenerator, mossy: bool) -> void:
	for x in T:
		var s := surf[x]
		var depth := 3 + (1 if r.randf() < 0.35 else 0)
		for d in depth:
			c.put(x, s + d, _col(p, "cap").lightened(0.15) if d == 0 else _col(p, "cap"))
		c.put(x, s + depth, _col(p, "moss") if mossy else _col(p, "lo"))
		if mossy and r.randf() < 0.3:
			c.put(x, s, _col(p, "moss_hi"))
		if mossy and r.randf() < 0.18:  # hanging moss drip
			for y in range(s + depth, s + depth + r.randi_range(1, 3)):
				c.put(x, y, _col(p, "moss"))


static func _slope(c: PixelCanvas, name: String, kind: String, v: int, p: Dictionary) -> void:
	var r := _rng(20 + SLOPES.find(kind), v, name.hash())
	# interior texture everywhere, then carve away the air above the surface
	match name:
		"earth":
			_earth(c, r, p)
		"rock":
			_rock(c, r, p)
		_:
			_bricks(c, r, p, name)
	var surf := PackedInt32Array()
	surf.resize(T)
	for x in T:
		surf[x] = surface_y(kind, x)
		for y in surf[x]:
			c.erase(x, y)
	_cap(c, surf, p, r, name != "village")
