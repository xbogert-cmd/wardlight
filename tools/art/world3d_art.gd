extends RefCounted
## Art for the 3D world: seamless 32×32 surface textures (24 px per metre)
## and upright billboard sprites. Everything tiles by wrapping coordinates.

const S := 32


static func _c(s: String) -> Color:
	return Color.html(s)


static func _wrap_put(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, img.get_width()), posmod(y, img.get_height()), c)


static func _rng(seed: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	return r


static func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				_wrap_put(img, x, y, c)


# ---------------------------------------------------------------- surfaces
static func grass() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("2a402c"))
	var r := _rng(11)
	for k in 6:  # soft clumps
		_blob(img, r.randf_range(0, S), r.randf_range(0, S), r.randf_range(3, 6), r.randf_range(2, 4), _c("304a30"))
	for k in 26:  # blade tufts
		var x := r.randi_range(0, S - 1)
		var y := r.randi_range(0, S - 1)
		var col: Color = [_c("3a5634"), _c("365032"), _c("243a26")][r.randi_range(0, 2)]
		_wrap_put(img, x, y, col)
		_wrap_put(img, x, y - 1, col.lightened(0.08))
	for k in 4:  # fallen leaves
		var x := r.randi_range(0, S - 1)
		var y := r.randi_range(0, S - 1)
		var col: Color = [_c("8a5a2e"), _c("a8702e"), _c("6a3a2a")][r.randi_range(0, 2)]
		_wrap_put(img, x, y, col)
		_wrap_put(img, x + 1, y, col.darkened(0.2))
	return img


static func cobble() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("1e1a22"))
	var r := _rng(23)
	# 4×4 staggered stones, jittered, wrapping at the edges
	for row in 4:
		for col in 4:
			var cx := col * 8.0 + (4.0 if row % 2 else 0.0) + r.randf_range(-0.8, 0.8) + 4.0
			var cy := row * 8.0 + r.randf_range(-0.6, 0.6) + 4.0
			var base: Color = [_c("5e5866"), _c("6a6470"), _c("54505c"), _c("625a58")][r.randi_range(0, 3)]
			_blob(img, cx, cy, 3.4, 3.2, base.darkened(0.25))
			_blob(img, cx - 0.4, cy - 0.5, 3.0, 2.7, base)
			_wrap_put(img, int(cx) - 2, int(cy) - 2, base.lightened(0.18))
			_wrap_put(img, int(cx) - 1, int(cy) - 2, base.lightened(0.1))
			if r.randf() < 0.25:
				_wrap_put(img, int(cx) + 1, int(cy), _c("8a90a8"))  # wet glint
	for k in 10:  # moss in the gaps
		var x := r.randi_range(0, S - 1)
		var y := r.randi_range(0, S - 1)
		if img.get_pixel(x, y).v < 0.15:
			_wrap_put(img, x, y, _c("3a5230"))
	return img


static func dirt() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("3e3028"))
	var r := _rng(31)
	for k in 70:
		_wrap_put(img, r.randi_range(0, S - 1), r.randi_range(0, S - 1), [_c("4a3a30"), _c("33271f"), _c("574434")][r.randi_range(0, 2)])
	for k in 5:
		var x := r.randi_range(0, S - 1)
		var y := r.randi_range(0, S - 1)
		_wrap_put(img, x, y, _c("6a6270"))
		_wrap_put(img, x + 1, y, _c("4a4450"))
	return img


static func rock() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("4a4a56"))
	var r := _rng(41)
	for k in 9:
		var cx := r.randf_range(0, S)
		var cy := r.randf_range(0, S)
		var col := _c("5a5a68").lerp(_c("3c3c48"), r.randf())
		_blob(img, cx, cy, r.randf_range(3, 7), r.randf_range(2, 4), col)
		for x in range(int(cx - 4), int(cx + 4)):
			_wrap_put(img, x, int(cy + 3), _c("2e2e38"))
	for k in 4:  # strata cracks
		var y := r.randi_range(0, S - 1)
		var x0 := r.randi_range(0, S - 1)
		for x in range(x0, x0 + r.randi_range(6, 14)):
			_wrap_put(img, x, y + (x / 5) % 2, _c("24242c"))
	for k in 30:
		_wrap_put(img, r.randi_range(0, S - 1), r.randi_range(0, S - 1), _c("626272"))
	return img


static func bricks(runes: bool) -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("24222c"))
	var r := _rng(53 if runes else 57)
	for row in 4:
		var off := 8 if row % 2 else 0
		for col in 2:
			var x0 := col * 16 + off
			var base := _c("5c5a66").lerp(_c("4a4854"), r.randf())
			for y in range(row * 8 + 1, row * 8 + 7):
				for x in range(x0 + 1, x0 + 15):
					_wrap_put(img, x, y, base)
			for x in range(x0 + 1, x0 + 15):
				_wrap_put(img, x, row * 8 + 1, base.lightened(0.12))
				_wrap_put(img, x, row * 8 + 6, base.darkened(0.2))
			if r.randf() < 0.4:
				var mx := x0 + r.randi_range(2, 12)
				for y in range(row * 8 + 1, row * 8 + r.randi_range(3, 7)):
					_wrap_put(img, mx, y, _c("3e5a34"))
	if runes:
		var cx := 16.0
		var cy := 16.0
		for k in 40:
			var a := k / 40.0 * TAU
			_wrap_put(img, int(cx + cos(a) * 7.0), int(cy + sin(a) * 7.0), _c("2a2632"))
		for k in 4:
			var a := k * PI / 2.0
			for t in 6:
				_wrap_put(img, int(cx + cos(a) * t), int(cy + sin(a) * t), _c("2a2632"))
	return img


static func wood() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	var r := _rng(61)
	for plank in 4:
		var base := _c("6a4a32").lerp(_c("54382a"), r.randf())
		for y in S:
			for x in range(plank * 8, plank * 8 + 8):
				var c := base
				if x == plank * 8:
					c = _c("2a1c16")
				elif (y + plank * 7) % 11 == 0 and x % 3 == 0:
					c = base.darkened(0.25)
				elif x == plank * 8 + 1:
					c = base.lightened(0.12)
				img.set_pixel(x, y, c)
		var ky := r.randi_range(4, 28)
		_blob(img, plank * 8 + 4, ky, 1.2, 1.5, base.darkened(0.35))
	return img


static func water() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("1e3a4a"))
	var r := _rng(71)
	for k in 14:
		var x := r.randi_range(0, S - 1)
		var y := r.randi_range(0, S - 1)
		for d in r.randi_range(2, 5):
			_wrap_put(img, x + d, y, _c("3a6a7e") if d % 2 == 0 else _c("2e5668"))
	for k in 6:
		_wrap_put(img, r.randi_range(0, S - 1), r.randi_range(0, S - 1), _c("8ac0d0"))
	return img


# ---------------------------------------------------------------- billboards
static func pine(h: int, seed: int) -> Image:
	var c := PixelCanvas.new(int(h * 0.62), h)
	var r := _rng(seed)
	var w := c.w
	var cx := w * 0.5
	var dark := [_c("2a4a3a"), _c("1c3428"), _c("12241c")]
	c.rect(roundi(cx) - 2, h - 14, 4, 14, _c("3a2a22"), 1)
	var tiers := 6
	for t in tiers:
		var top := h * 0.04 + t * (h * 0.13)
		var bot := top + h * 0.2
		var half := (t + 1.0) / tiers * w * 0.47
		var pts := PackedVector2Array([Vector2(cx, top), Vector2(cx + half, bot), Vector2(cx + half * 0.5, bot - 2), Vector2(cx, bot + 1),
			Vector2(cx - half * 0.5, bot - 2), Vector2(cx - half, bot)])
		c.poly(pts, dark[1], 2)
	c.shade(2, dark[0], dark[2], 2)
	for k in 30:
		var x := r.randi_range(2, w - 3)
		var y := r.randi_range(4, h - 16)
		if c.region_at(x, y) == 2 and c.region_at(x - 2, y) == 0:
			c.put(x, y, _c("4a6e4a"), 2)
	c.outline(_c("0a100e"), 0.7)
	return c.img


static func oak(w: int, h: int, seed: int) -> Image:
	var c := PixelCanvas.new(w, h)
	var r := _rng(seed)
	var bark := [_c("5a4a44"), _c("3e322e"), _c("2a2020")]
	var leaf := [_c("4a5e3a"), _c("33452c"), _c("22301e")]
	var base := Vector2(w * 0.5, h)
	c.poly(PackedVector2Array([base + Vector2(-5, 0), base + Vector2(-3, -h * 0.45), base + Vector2(3, -h * 0.45), base + Vector2(6, 0)]), bark[1], 1)
	c.stroke(base + Vector2(-2, -h * 0.4), base + Vector2(-w * 0.3, -h * 0.62), 3, bark[1], 1)
	c.stroke(base + Vector2(2, -h * 0.42), base + Vector2(w * 0.28, -h * 0.66), 3, bark[1], 1)
	# canopy: many small leaf clusters inside a rounded crown
	for k in 34:
		var a := r.randf() * TAU
		var rr := sqrt(r.randf())
		var cx := w * 0.5 + cos(a) * rr * w * 0.36
		var cy := h * 0.34 + sin(a) * rr * h * 0.22
		c.ellipse(cx, cy, r.randf_range(4.0, 7.0), r.randf_range(3.0, 5.0), leaf[1], 2)
	c.shade(1, bark[0], bark[2], 1)
	c.shade(2, leaf[0], leaf[2], 2)
	for k in 24:
		var x := r.randi_range(2, w - 3)
		var y := r.randi_range(2, int(h * 0.6))
		if c.region_at(x, y) == 2:
			c.put(x, y, [_c("8a6a32"), _c("5e7442"), _c("a8742e")][k % 3], 2)
	c.outline(_c("0c0c0a"), 0.7)
	return c.img


static func dead_tree(w: int, h: int, seed: int) -> Image:
	var c := PixelCanvas.new(w, h)
	var r := _rng(seed)
	var bark := [_c("5a4e56"), _c("3e3440"), _c("28222c")]
	var base := Vector2(w * 0.5, h)
	c.poly(PackedVector2Array([base + Vector2(-7, 0), base + Vector2(-3, -h * 0.55), base + Vector2(0, -h * 0.95), base + Vector2(3, -h * 0.6), base + Vector2(7, 0)]), bark[1], 1)
	for k in 6:
		var y0 := -h * r.randf_range(0.35, 0.8)
		var s := -1.0 if k % 2 == 0 else 1.0
		var a := base + Vector2(s * 2.0, y0)
		var b := a + Vector2(s * r.randf_range(w * 0.2, w * 0.42), -r.randf_range(6, 18))
		c.stroke(a, b, 2, bark[1], 1)
		c.stroke(b, b + Vector2(s * 4, -5), 1, bark[1], 1)
	c.poly(PackedVector2Array([base + Vector2(-7, 0), base + Vector2(-13, 0), base + Vector2(-6, -7)]), bark[1], 1)
	c.poly(PackedVector2Array([base + Vector2(7, 0), base + Vector2(13, 0), base + Vector2(6, -7)]), bark[1], 1)
	c.shade(1, bark[0], bark[2], 1)
	c.outline(_c("0a080c"), 0.7)
	return c.img


static func lantern() -> Image:
	var c := PixelCanvas.new(10, 14)
	c.rect(4, 0, 2, 2, _c("3a3030"), 1)
	c.rect(1, 2, 8, 2, _c("4a3a30"), 1)
	c.rect(2, 4, 6, 7, _c("ffd070"), 2)
	c.rect(3, 5, 4, 5, _c("fff0b0"), 2)
	c.rect(1, 11, 8, 2, _c("4a3a30"), 1)
	c.line(2, 4, 2, 10, _c("3a3030"), 1)
	c.line(7, 4, 7, 10, _c("3a3030"), 1)
	c.outline(_c("100c0c"), 0.8)
	return c.img


static func banner() -> Image:
	var c := PixelCanvas.new(18, 44)
	c.rect(0, 0, 18, 2, _c("4a3a30"), 1)
	c.poly(PackedVector2Array([Vector2(2, 2), Vector2(16, 2), Vector2(16, 40), Vector2(9, 35), Vector2(2, 40)]), _c("5a1e2a"), 2)
	c.shade(2, _c("7a2a36"), _c("3a1018"), 1)
	# faded sun-and-tree sigil
	c.ring(9, 15, 4, 1, _c("c8a070"), 3)
	c.line(9, 19, 9, 28, _c("c8a070"), 3)
	c.line(9, 23, 6, 20, _c("c8a070"), 3)
	c.line(9, 23, 12, 20, _c("c8a070"), 3)
	c.outline(_c("100808"), 0.8)
	return c.img


## Lime plaster with a little grime (house walls; tinted per house).
static func plaster() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("b8ab94"))
	var r := _rng(61)
	for k in 90:
		_wrap_put(img, r.randi_range(0, S - 1), r.randi_range(0, S - 1), _c("a89a84") if r.randf() < 0.7 else _c("c8bca4"))
	for k in 5:
		var x := r.randi_range(0, S - 1)
		var y := r.randi_range(0, S - 1)
		for d in r.randi_range(2, 5):
			_wrap_put(img, x + d, y + (d % 2), _c("8a7c68"))
	return img


## Overlapping dark slate shingles (roofs).
static func roof() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("1e1c2a"))
	var r := _rng(67)
	for row in 4:
		var off := 4 if row % 2 else 0
		for col in 4:
			var base := _c("3c3a50").lerp(_c("2e2c40"), r.randf())
			for y in range(row * 8, row * 8 + 7):
				for x in range(col * 8 + off + 1, col * 8 + off + 8):
					_wrap_put(img, x, y, base if y < row * 8 + 5 else base.darkened(0.25))
			_wrap_put(img, col * 8 + off + 2, row * 8, base.lightened(0.2))
	return img


## Straw thatch (sheds, the sanctuary cottage).
static func thatch() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(_c("6a5430"))
	var r := _rng(71)
	for k in 160:
		var x := r.randi_range(0, S - 1)
		var y := r.randi_range(0, S - 1)
		var c: Color = [_c("8a7040"), _c("9a8050"), _c("5a4628"), _c("b09460")][r.randi_range(0, 3)]
		for d in r.randi_range(2, 5):
			_wrap_put(img, x, y + d, c)
	for row in 4:
		for x in S:
			_wrap_put(img, x, row * 8 + 7, _c("4a3a22"))
	return img


static func window(lit: bool) -> Image:
	var c := PixelCanvas.new(10, 12)
	c.rect(0, 0, 10, 12, _c("3a2a20"), 1)
	var glass := _c("ffc868") if lit else _c("1a2030")
	c.rect(1, 1, 8, 10, glass, 2)
	if lit:
		c.rect(2, 2, 3, 3, _c("fff0b0"), 2)
	else:
		c.put(2, 2, _c("3a4a60"), 2)
	c.line(5, 1, 5, 10, _c("3a2a20"), 1)
	c.line(1, 6, 8, 6, _c("3a2a20"), 1)
	return c.img


static func door() -> Image:
	var c := PixelCanvas.new(14, 24)
	c.poly(PackedVector2Array([Vector2(0, 24), Vector2(0, 5), Vector2(3, 1), Vector2(11, 1), Vector2(14, 5), Vector2(14, 24)]), _c("5a3a26"), 1)
	for x in [3, 7, 10]:
		c.line(x, 3, x, 23, _c("3a2418"), 1)
	c.rect(2, 8, 11, 1, _c("2a2a2a"), 2)
	c.rect(2, 17, 11, 1, _c("2a2a2a"), 2)
	c.put(10, 13, _c("c8a040"), 3)
	c.shade(1, _c("7a5238"), _c("3a2418"), 1)
	c.outline(_c("140c08"), 0.9)
	return c.img


static func signpost() -> Image:
	var c := PixelCanvas.new(22, 40)
	c.rect(10, 6, 3, 34, _c("5a3e2a"), 1)
	c.poly(PackedVector2Array([Vector2(1, 4), Vector2(17, 4), Vector2(21, 8), Vector2(17, 12), Vector2(1, 12)]), _c("7a5a3a"), 2)
	c.line(4, 8, 14, 8, _c("3a2a1a"), 3)
	c.shade(1, _c("7a5a3e"), _c("3a2618"), 1)
	c.outline(_c("120c08"), 0.9)
	return c.img


static func crate() -> Image:
	var c := PixelCanvas.new(18, 18)
	c.rect(0, 2, 18, 16, _c("6a4a30"), 1)
	c.rect(0, 2, 18, 2, _c("8a6a44"), 1)
	c.line(1, 4, 16, 16, _c("4a3220"), 1)
	c.line(1, 16, 16, 4, _c("4a3220"), 1)
	c.rect(0, 9, 18, 1, _c("4a3220"), 1)
	c.outline(_c("140c08"), 0.9)
	return c.img


static func barrel() -> Image:
	var c := PixelCanvas.new(14, 18)
	c.ellipse(7, 9, 6.5, 8.5, _c("6a4a30"), 1)
	c.rect(1, 4, 12, 1, _c("3a3a40"), 2)
	c.rect(1, 13, 12, 1, _c("3a3a40"), 2)
	c.shade(1, _c("8a6a44"), _c("3a2618"), 2)
	c.outline(_c("140c08"), 0.9)
	return c.img


## A clump of thorned briar stems bursting from the ground (Briar Knot).
static func thorns() -> Image:
	var c := PixelCanvas.new(16, 22)
	var r := _rng(31)
	for k in 3:
		var x0 := 3 + k * 5
		var lean := r.randi_range(-3, 3)
		var h := r.randi_range(14, 21)
		c.stroke(Vector2(x0, 21), Vector2(x0 + lean, 21 - h), 2, _c("5a3e2a"), 1)
		for t in 3:
			var ty := 21 - int(h * (0.35 + t * 0.2))
			var tx := x0 + int(lean * (0.35 + t * 0.2))
			c.put(tx + (2 if t % 2 else -2), ty - 1, _c("d8c8a0"), 2)
			c.put(tx + (1 if t % 2 else -1), ty, _c("8a6a4a"), 1)
		c.put(x0 + lean, 21 - h, _c("e8dcc0"), 2)
	c.shade(1, _c("7a5a3a"), _c("3a2618"), 1)
	c.outline(_c("120c08"), 0.9)
	return c.img


## Twisting roots with faint hex glow at the tips (Binding Roots).
static func roots() -> Image:
	var c := PixelCanvas.new(18, 26)
	var r := _rng(47)
	for k in 3:
		var x0 := 4 + k * 5
		var pts := [Vector2(x0, 25)]
		var y := 25.0
		var x := float(x0)
		while y > 4.0 + k * 2:
			y -= r.randf_range(3.0, 5.0)
			x += r.randf_range(-2.5, 2.5)
			pts.append(Vector2(x, y))
		for n in pts.size() - 1:
			c.stroke(pts[n], pts[n + 1], 3 if n < 2 else 2, _c("6a4a3a"), 1)
		var tip: Vector2 = pts[pts.size() - 1]
		c.put(int(tip.x), int(tip.y), _c("c88cff"), 2)
		c.put(int(tip.x), int(tip.y) - 1, _c("f4e8ff"), 2)
	c.shade(1, _c("9a7a5a"), _c("3a2a20"), 1)
	c.outline(_c("120c08"), 0.9)
	return c.img


## Small hooded spirit carrying a lantern (Spirit Lantern).
static func spirit() -> Image:
	var c := PixelCanvas.new(16, 14)
	var body := _c("8affc8")
	c.poly(PackedVector2Array([Vector2(4, 2), Vector2(10, 2), Vector2(11, 10), Vector2(9, 12), Vector2(7, 10), Vector2(5, 12), Vector2(3, 10)]), body, 1)
	c.rect(5, 1, 4, 1, _c("e8fff4"), 1)
	c.rect(5, 4, 1, 2, _c("0e2a22"), 2)
	c.rect(8, 4, 1, 2, _c("0e2a22"), 2)
	c.line(10, 6, 12, 6, _c("3ad69a"), 1)
	c.rect(12, 5, 3, 4, _c("f4e890"), 3)
	c.put(13, 4, _c("a89060"), 3)
	c.shade(1, _c("e8fff4"), _c("1e8a66"), 1)
	c.outline(_c("0a2a20"), 0.6)
	return c.img


## Glowing ward crystal that sits atop a wardlight post (lit / dark).
static func ward_crystal(lit: bool) -> Image:
	var c := PixelCanvas.new(12, 18)
	var body := _c("9ae8ff") if lit else _c("3a4458")
	c.poly(PackedVector2Array([Vector2(6, 0), Vector2(11, 7), Vector2(6, 17), Vector2(1, 7)]), body, 1)
	c.poly(PackedVector2Array([Vector2(6, 2), Vector2(8, 7), Vector2(6, 13), Vector2(4, 7)]), _c("f0ffff") if lit else _c("56607a"), 2)
	c.shade(1, _c("d8ffff") if lit else _c("5a6480"), _c("3a78c0") if lit else _c("242a3a"), 1)
	c.outline(_c("0c1420"), 0.8)
	return c.img


## Four-frame flame loop, frames side by side.
static func flames() -> Image:
	var img := Image.create_empty(16 * 4, 20, false, Image.FORMAT_RGBA8)
	for f in 4:
		var c := PixelCanvas.new(16, 20)
		var r := _rng(90 + f)
		var sway: float = [0.0, 1.0, 0.0, -1.0][f]
		c.poly(PackedVector2Array([Vector2(2, 19), Vector2(4 + sway, 9), Vector2(7 + sway * 1.5, 2 + f % 2), Vector2(9, 8), Vector2(12 - sway, 4 + (f + 1) % 2),
			Vector2(14, 19)]), _c("e8601c"), 1)
		c.poly(PackedVector2Array([Vector2(4, 19), Vector2(6 + sway, 11), Vector2(8 + sway, 6), Vector2(10, 11), Vector2(12, 19)]), _c("ffb030"), 2)
		c.poly(PackedVector2Array([Vector2(6, 19), Vector2(8 + sway * 0.5, 12), Vector2(10, 19)]), _c("fff0a0"), 3)
		if r.randf() < 0.8:
			c.put(r.randi_range(4, 12), r.randi_range(0, 4), _c("ffb030"), 1)
		c.blit_into(img, f * 16, 0)
	return img


## Distant castle silhouette with a few lit windows (seen through valley fog).
static func castle() -> Image:
	var w := 220
	var h := 150
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var body := _c("1e1a2e")
	var hi := _c("2a2440")
	var r := _rng(99)
	var fill := func(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
		for y in range(maxi(y0, 0), mini(y1, h)):
			for x in range(maxi(x0, 0), mini(x1, w)):
				img.set_pixel(x, y, c)
	# hill
	for x in w:
		var top := int(h - 30 + sin(x * 0.03) * 8.0 - (1.0 - absf(x - w * 0.5) / (w * 0.5)) * 22.0)
		fill.call(x, top, x + 1, h, body)
	# keep, towers and walls
	fill.call(80, 60, 140, 110, body)
	for t: Array in [[70, 30, 86], [134, 38, 150], [100, 12, 116], [50, 70, 62], [158, 64, 170]]:
		fill.call(t[0], t[1], t[2], 112, body)
		for k in range(t[0], t[2], 3):  # crenellations
			fill.call(k, t[1] - 3, k + 2, t[1], body)
		fill.call(t[0], t[1], t[0] + 1, 112, hi)
	fill.call(104, 2, 112, 12, body)  # spire
	fill.call(107, 0, 109, 2, body)
	for k in 12:  # lit windows
		var x := r.randi_range(72, 168)
		var y := r.randi_range(24, 104)
		if img.get_pixel(x, y).a > 0.0:
			fill.call(x, y, x + 1, y + 2, _c("f0a850"))
	return img


## Far village: roofs and warm windows along a ridge.
static func village_far() -> Image:
	var w := 200
	var h := 80
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var body := _c("221c30")
	var r := _rng(7)
	var x := 4
	while x < w - 20:
		var bw := r.randi_range(14, 24)
		var bh := r.randi_range(14, 26)
		var base := h - 8
		for yy in range(base - bh, h):
			for xx in range(x, x + bw):
				img.set_pixel(xx, yy, body)
		for k in bw / 2 + 2:  # roof
			for xx in range(x - 1 + k, x + bw + 1 - k):
				if base - bh - k >= 0:
					img.set_pixel(xx, base - bh - k, body)
		for k in r.randi_range(1, 3):
			var wx := x + r.randi_range(2, bw - 4)
			var wy := base - r.randi_range(4, bh - 4)
			img.set_pixel(wx, wy, _c("ffc060"))
			img.set_pixel(wx + 1, wy, _c("ffc060"))
			img.set_pixel(wx, wy + 1, _c("e09040"))
			img.set_pixel(wx + 1, wy + 1, _c("e09040"))
		x += bw + r.randi_range(2, 8)
	for xx in w:
		for yy in range(h - 8, h):
			img.set_pixel(xx, yy, body)
	return img
