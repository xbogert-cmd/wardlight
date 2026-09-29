extends RefCounted
## Ground scenery (no collision). Each prop is drawn standing on its bottom
## edge; the level scatters them along flat ground. Returns {image, props}.

enum R { NONE, LEAF, LEAF2, WOOD, STONE, CAP, STEM, GRASS, FLOWER, MOSS }

const LEAF := ["5f8f4e", "3f6a3c", "274730"]
const LEAF_DARK := ["3f6a4a", "2a4a3a", "1a3028"]
const BARK := ["7a5a44", "574032", "3a2a24"]
const STONE := ["8a8a9c", "626274", "40404e"]
const GLOW := ["c8fff8", "6ae8e0", "2aa0b0"]
const RED := ["ff9a7a", "d05040", "8a2a2a"]
const GRASS := ["9ac85a", "6a9a44", "44703a"]


static func build() -> Dictionary:
	var defs := {
		"bush_s": [18, 12, _bush.bind(0.8), 1.0],
		"bush_l": [30, 18, _bush.bind(1.3), 1.0],
		"fern": [16, 12, _fern, 1.0],
		"tuft_a": [8, 6, _tuft.bind(3), 1.0],
		"tuft_b": [10, 7, _tuft.bind(5), 1.0],
		"tuft_c": [7, 5, _tuft.bind(2), 1.0],
		"rock_s": [12, 7, _rock.bind(0.7), 1.0],
		"rock_l": [22, 12, _rock.bind(1.3), 1.0],
		"shrooms": [10, 9, _shrooms.bind(GLOW), 1.0],
		"shrooms_red": [10, 8, _shrooms.bind(RED), 1.0],
		"stump": [18, 13, _stump, 1.0],
		"log": [36, 11, _log, 1.0],
		"flowers": [9, 7, _flowers, 1.0],
		"dead_tree": [30, 76, _dead_tree, 1.0],
		"roots": [22, 6, _roots, 1.0],
		# Chapter 2 marsh (appended so earlier atlas positions don't move)
		"reeds": [12, 22, _reeds.bind(7, false), 1.0],
		"cattails": [10, 26, _reeds.bind(4, true), 1.0],
	}
	var canvases := {}
	var total_w := 0
	var max_h := 0
	for k in defs:
		var d: Array = defs[k]
		var c := PixelCanvas.new(d[0] + 2, d[1] + 2)
		c.ox = 1
		c.oy = 1
		(d[2] as Callable).call(c, d[0], d[1])
		c.outline(Color.html("10101a"), 0.75)
		canvases[k] = c
		total_w += c.w + 1
		max_h = maxi(max_h, c.h)
	var img := Image.create_empty(total_w, max_h, false, Image.FORMAT_RGBA8)
	var props := {}
	var x := 0
	for k in canvases:
		var c: PixelCanvas = canvases[k]
		c.blit_into(img, x, max_h - c.h)
		props[k] = [x, max_h - c.h, c.w, c.h]
		x += c.w + 1
	return {"image": img, "props": props}


static func _cols(a: Array) -> Array[Color]:
	var out: Array[Color] = []
	for s: String in a:
		out.append(Color.html(s))
	return out


static func _bush(c: PixelCanvas, w: int, h: int, scale: float) -> void:
	var l := _cols(LEAF)
	var r := RandomNumberGenerator.new()
	r.seed = int(scale * 100)
	for k in int(5 * scale):
		var cx := r.randf_range(w * 0.2, w * 0.8)
		var cy := r.randf_range(h * 0.35, h * 0.75)
		c.ellipse(cx, cy, r.randf_range(3.5, 5.5) * scale, r.randf_range(3.0, 4.5) * scale, l[1], R.LEAF)
	c.ellipse(w * 0.5, h - 3.0, w * 0.45, 3.0, l[1], R.LEAF)
	c.shade(R.LEAF, l[0], l[2], 2)
	for k in int(6 * scale):  # leaf speckles
		c.put(r.randi_range(2, w - 3), r.randi_range(2, h - 4), l[0].lightened(0.15), R.LEAF)


static func _fern(c: PixelCanvas, w: int, h: int) -> void:
	var l := _cols(LEAF)
	for a in [-1.1, -0.6, -0.15, 0.3, 0.8, 1.2]:
		var base := Vector2(w * 0.5, h)
		var tip := base + Vector2(sin(a) * w * 0.5, -cos(a) * h * 0.95)
		var mid := base.lerp(tip, 0.5) + Vector2(sin(a) * 2.0, -2.0)
		c.linev(base, mid, l[1], R.LEAF)
		c.linev(mid, tip, l[1], R.LEAF)
		for t in [0.35, 0.55, 0.75]:
			var p := base.lerp(tip, t)
			c.put(roundi(p.x + 1), roundi(p.y), l[0], R.LEAF2)
			c.put(roundi(p.x - 1), roundi(p.y), l[2], R.LEAF2)


## Tall marsh reeds; cattails get brown seed heads.
static func _reeds(c: PixelCanvas, w: int, h: int, n: int, heads: bool) -> void:
	var g := _cols(["a8c070", "6a8a4a", "3e5a36"])
	var head := _cols(["a07050", "6a4430", "4a2e22"])
	for k in n:
		var x := 1.0 + (w - 2.0) * k / maxf(1.0, n - 1.0)
		var tall := h * (0.62 + 0.38 * float((k * 5) % 3) / 2.0)
		var lean := (k - n * 0.5) * 0.35
		var tip := Vector2(x + lean, h - tall)
		c.linev(Vector2(x, h), tip, g[k % 3], R.GRASS)
		if heads and k % 2 == 0:
			c.rect(int(tip.x), int(tip.y) + 2, 2, 5, head[1], R.WOOD)
			c.put(int(tip.x), int(tip.y) + 2, head[0], R.WOOD)


static func _tuft(c: PixelCanvas, w: int, h: int, n: int) -> void:
	var g := _cols(GRASS)
	for k in n:
		var x := 1.0 + (w - 2.0) * k / maxf(1.0, n - 1.0)
		var lean := (k - n * 0.5) * 0.4
		c.linev(Vector2(x, h), Vector2(x + lean, h - (h * (0.6 if k % 2 else 1.0))), g[k % 3], R.GRASS)


static func _rock(c: PixelCanvas, w: int, h: int, scale: float) -> void:
	var s := _cols(STONE)
	c.poly(PackedVector2Array([Vector2(1, h), Vector2(w * 0.15, h * 0.35), Vector2(w * 0.45, 0.5), Vector2(w * 0.8, h * 0.25),
		Vector2(w - 1.0, h * 0.7), Vector2(w - 1.0, h)]), s[1], R.STONE)
	c.shade(R.STONE, s[0], s[2], 2)
	var m := _cols(LEAF)
	for x in range(int(w * 0.3), int(w * 0.7)):  # moss cap
		for y in range(0, h):
			if c.region_at(x, y) == R.STONE:
				c.put(x, y, m[1], R.MOSS)
				if (x + int(scale * 7)) % 3 == 0:
					c.put(x, y + 1, m[2], R.MOSS)
				break


static func _shrooms(c: PixelCanvas, w: int, h: int, ramp: Array) -> void:
	var g := _cols(ramp)
	var stem := Color.html("e8dcc8")
	for m: Array in [[2.5, 5.0, 2.2], [6.5, 3.0, 2.8], [8.5, 6.0, 1.6]]:
		var x: float = m[0]
		var top: float = m[1]
		c.line(roundi(x), h, roundi(x), roundi(top + 1), stem, R.STEM)
		c.ellipse(x, top, m[2], 1.6, g[1], R.CAP)
		c.put(roundi(x - 1), roundi(top - 1), g[0], R.CAP)


static func _stump(c: PixelCanvas, w: int, h: int) -> void:
	var b := _cols(BARK)
	c.rect(3, 3, w - 6, h - 3, b[1], R.WOOD)
	c.poly(PackedVector2Array([Vector2(0, h), Vector2(3, h - 4), Vector2(3, h)]), b[1], R.WOOD)
	c.poly(PackedVector2Array([Vector2(w, h), Vector2(w - 3, h - 4), Vector2(w - 3, h)]), b[1], R.WOOD)
	c.shade(R.WOOD, b[0], b[2], 1)
	c.ellipse(w * 0.5, 3.5, w * 0.5 - 3.0, 2.2, Color.html("c8a070"), R.CAP)
	c.ring(w * 0.5, 3.5, 2.5, 1.0, Color.html("a07a50"), R.CAP)
	for y in range(5, h - 1, 3):
		c.put(5 + (y % 4), y, b[2], R.WOOD)
		c.put(w - 7 - (y % 3), y + 1, b[2], R.WOOD)
	var m := _cols(LEAF)
	c.rect(3, h - 3, 4, 2, m[1], R.MOSS)


static func _log(c: PixelCanvas, w: int, h: int) -> void:
	var b := _cols(BARK)
	c.rect(2, 2, w - 6, h - 2, b[1], R.WOOD)
	c.shade(R.WOOD, b[0], b[2], 2)
	c.ellipse(w - 4.0, h * 0.5 + 1.0, 3.0, h * 0.5 - 1.0, Color.html("c8a070"), R.CAP)
	c.put(w - 4, roundi(h * 0.5 + 1.0), Color.html("8a6a44"), R.CAP)
	for x in range(5, w - 8, 4):
		c.put(x, 4 + (x % 3), b[2], R.WOOD)
	var m := _cols(LEAF)
	for x in range(6, w - 12):
		if x % 5 < 3:
			c.put(x, 2, m[1], R.MOSS)
	c.line(8, 1, 10, -1, m[0], R.MOSS)  # sprout


static func _flowers(c: PixelCanvas, w: int, h: int) -> void:
	var g := _cols(GRASS)
	for f: Array in [[1.5, 3.0, "f0d8ff"], [4.5, 1.0, "a8d8ff"], [7.0, 3.5, "f0d8ff"]]:
		c.line(roundi(f[0]), h, roundi(f[0]), roundi(f[1] + 1), g[1], R.GRASS)
		c.put(roundi(f[0]), roundi(f[1]), Color.html(f[2]), R.FLOWER)
		c.put(roundi(f[0]) + 1, roundi(f[1]), Color.html(f[2]).darkened(0.25), R.FLOWER)


static func _dead_tree(c: PixelCanvas, w: int, h: int) -> void:
	var b := _cols(["5a4a52", "3e3240", "2a2230"])
	var base := Vector2(w * 0.5, h)
	c.poly(PackedVector2Array([base + Vector2(-6, 0), base + Vector2(-3, -h * 0.5), base + Vector2(-1, -h + 2.0),
		base + Vector2(2, -h * 0.6), base + Vector2(4, 0)]), b[1], R.WOOD)
	c.stroke(base + Vector2(-2, -h * 0.55), base + Vector2(-12, -h * 0.75), 2, b[1], R.WOOD)
	c.stroke(base + Vector2(-12, -h * 0.75), base + Vector2(-14, -h * 0.85), 1, b[1], R.WOOD)
	c.stroke(base + Vector2(1, -h * 0.4), base + Vector2(12, -h * 0.58), 2, b[1], R.WOOD)
	c.stroke(base + Vector2(12, -h * 0.58), base + Vector2(14, -h * 0.66), 1, b[1], R.WOOD)
	c.stroke(base + Vector2(0, -h * 0.75), base + Vector2(7, -h * 0.9), 1, b[1], R.WOOD)
	c.poly(PackedVector2Array([base + Vector2(-6, 0), base + Vector2(-10, 0), base + Vector2(-5, -5)]), b[1], R.WOOD)
	c.poly(PackedVector2Array([base + Vector2(4, 0), base + Vector2(9, 0), base + Vector2(3, -5)]), b[1], R.WOOD)
	c.shade(R.WOOD, b[0], b[2], 1)
	c.ellipse(base.x - 1, base.y - h * 0.3, 1.2, 2.0, Color.html("1a1420"), R.STEM)


static func _roots(c: PixelCanvas, w: int, h: int) -> void:
	var b := _cols(BARK)
	c.stroke(Vector2(1, h - 1), Vector2(w * 0.4, 1), 2, b[1], R.WOOD)
	c.stroke(Vector2(w * 0.4, 1), Vector2(w - 2.0, h - 2.0), 1, b[1], R.WOOD)
	c.stroke(Vector2(w * 0.55, 3), Vector2(w * 0.7, h), 1, b[2], R.WOOD)
	c.shade(R.WOOD, b[0], b[2], 1)
