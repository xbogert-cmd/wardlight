extends RefCounted
## White effect textures, tinted at runtime (additive blending).

const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


## Dithered radial glow: stepped alpha so it stays pixel-crisp when additive.
static func glow(size: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c) / (size * 0.5)
			if d >= 1.0:
				continue
			var v := pow(1.0 - d, 1.6)
			var thr: float = (BAYER[y % 4][x % 4] + 0.5) / 16.0
			var a := floorf(v * 4.0) / 4.0
			if fmod(v * 4.0, 1.0) > thr:
				a += 0.25
			if a > 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, minf(a, 1.0) * 0.55))
	return img


## Billowing cloud silhouette (tinted at runtime, normal blending).
static func cloud(w: int, h: int, seed: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var lumps := []
	for k in 7:
		lumps.append([r.randf_range(w * 0.2, w * 0.8), r.randf_range(h * 0.35, h * 0.65), r.randf_range(h * 0.25, h * 0.45)])
	for y in h:
		for x in w:
			var best := 0.0
			for l in lumps:
				var d: float = Vector2(x + 0.5 - l[0], (y + 0.5 - l[1]) * 1.3).length() / l[2]
				best = maxf(best, 1.0 - d)
			if best <= 0.0:
				continue
			var thr: float = (BAYER[y % 4][x % 4] + 0.5) / 16.0
			if best * 3.0 > thr:
				var shade := 1.0 if y < h * 0.45 else 0.8
				img.set_pixel(x, y, Color(shade, shade, shade, 1.0))
	return img


## Magic circle: two rings with rune ticks and glyph dots between them.
static func rune_ring(size: int, seed: int) -> Image:
	var c := PixelCanvas.new(size, size)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var ctr := size * 0.5
	var outer := ctr - 1.0
	var inner := outer - maxf(4.0, size * 0.16)
	c.ring(ctr, ctr, outer, 1.0, Color.WHITE)
	c.ring(ctr, ctr, inner + 1.0, 1.0, Color(1, 1, 1, 1))
	var n := 8 if size < 40 else 12
	for i in n:
		var a := TAU * i / n
		var mid := (outer + inner) * 0.5
		var p := Vector2(ctr, ctr) + Vector2(cos(a), sin(a)) * mid
		match r.randi_range(0, 2):
			0:
				c.linev(p - Vector2(cos(a), sin(a)) * 1.5, p + Vector2(cos(a), sin(a)) * 1.5, Color.WHITE)
			1:
				c.put(roundi(p.x), roundi(p.y), Color.WHITE)
				c.put(roundi(p.x + cos(a + PI / 2)), roundi(p.y + sin(a + PI / 2)), Color.WHITE)
			_:
				c.rect(roundi(p.x) - 1, roundi(p.y) - 1, 2, 2, Color.WHITE)
	# inner star
	var k := 5 if size < 40 else 6
	for i in k:
		var a1 := TAU * i / k - PI / 2
		var a2 := TAU * ((i + 2) % k) / k - PI / 2
		c.linev(Vector2(ctr, ctr) + Vector2(cos(a1), sin(a1)) * (inner - 1), Vector2(ctr, ctr) + Vector2(cos(a2), sin(a2)) * (inner - 1), Color(1, 1, 1, 1))
	return c.img
