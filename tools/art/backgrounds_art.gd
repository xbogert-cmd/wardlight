extends RefCounted
## Parallax background layers. Every layer is 640 px wide and tiles horizontally.

const W := 640
const H := 360

const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

const REGIONS := {
	"woods": {
		"sky": ["0b0a1f", "141433", "1d2346", "26345a", "2f4a66"],
		"stars": 170, "moon": Vector2(470, 70), "moon_r": 16.0, "moon_col": ["f2ecd0", "cfc7a8", "a39c86"],
		"far": "243552", "far_hi": "2e4466", "mid": "17283a", "mid_hi": "213a4a", "near": "0f1b26", "near_hi": "183040",
		"fog": "3a5a70",
	},
	"ruins": {
		"sky": ["0a0818", "15112e", "221a44", "33265a", "43336c"],
		"stars": 220, "moon": Vector2(160, 64), "moon_r": 20.0, "moon_col": ["eeeaff", "c6c0e8", "948cc0"],
		"far": "2a2548", "far_hi": "3a3260", "mid": "1d1a36", "mid_hi": "2c2750", "near": "14122a", "near_hi": "231e40",
		"fog": "54477e",
	},
	"home": {
		"sky": ["2a1a30", "4a2838", "7a3e3a", "b0603e", "d88a4a"],
		"stars": 30, "moon": Vector2(520, 110), "moon_r": 13.0, "moon_col": ["ffe8b0", "f0c070", "c89048"],
		"far": "5a3444", "far_hi": "6e4250", "mid": "3a2634", "mid_hi": "4c3040", "near": "241824", "near_hi": "342432",
		"fog": "c07850",
	},
	"lake": {
		"sky": ["08101c", "10202e", "1a3442", "2a4a54", "3e6264"],
		"stars": 150, "moon": Vector2(430, 76), "moon_r": 15.0, "moon_col": ["eef4e8", "c4d4c8", "90a4a0"],
		"far": "1c3440", "far_hi": "284652", "mid": "142630", "mid_hi": "1e3640", "near": "0c1820", "near_hi": "16282e",
		"fog": "3a6a6a",
	},
	"village": {
		"sky": ["141026", "221a3a", "36264a", "553452", "7a4458"],
		"stars": 110, "moon": Vector2(120, 80), "moon_r": 14.0, "moon_col": ["f8e8c8", "d8c098", "a89070"],
		"far": "35284a", "far_hi": "46345a", "mid": "241c36", "mid_hi": "32284a", "near": "171226", "near_hi": "241c38",
		"fog": "6a4a6a",
	},
}


static func build(region: String) -> Dictionary:
	var p: Dictionary = REGIONS[region]
	var r := RandomNumberGenerator.new()
	r.seed = region.hash()
	return {
		"sky": _sky(p, r),
		"far": _mountains(p, r, 150, 70, p.far, p.far_hi),
		"mid": _trees(p, r, region, 205, p.mid, p.mid_hi, 0.8),
		"near": _trees(p, r, region, 250, p.near, p.near_hi, 1.25),
	}


static func _sky(p: Dictionary, r: RandomNumberGenerator) -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var cols: Array = p.sky
	var bands := cols.size() - 1
	for y in H:
		var t := clampf(float(y) / (H * 0.8), 0.0, 1.0) * bands
		var i := mini(int(t), bands - 1)
		var f := t - i
		for x in W:
			var thr: float = (BAYER[y % 4][x % 4] + 0.5) / 16.0
			img.set_pixel(x, y, Color.html(cols[i + 1] if f > thr else cols[i]))
	for s in p.stars:
		var x := r.randi_range(0, W - 1)
		var y := int(pow(r.randf(), 1.6) * H * 0.7)
		var b := r.randf()
		var c := Color(1, 1, 1).lerp(Color.html(cols[0]), 0.55 - b * 0.4)
		img.set_pixel(x, y, c)
		if b > 0.93 and x > 1 and x < W - 2 and y > 1:
			var dim := c.lerp(Color.html(cols[0]), 0.5)
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				img.set_pixel(x + o.x, y + o.y, dim)
	var m: Vector2 = p.moon
	var mr: float = p.moon_r
	var mc: Array = p.moon_col
	for y in range(int(m.y - mr - 8), int(m.y + mr + 9)):
		for x in range(int(m.x - mr - 8), int(m.x + mr + 9)):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(m)
			if d <= mr:
				var col := Color.html(mc[0])
				if d > mr - 2.0 or Vector2(x, y).distance_to(m + Vector2(-mr * 0.35, mr * 0.2)) < mr * 0.28:
					col = Color.html(mc[1])
				if Vector2(x, y).distance_to(m + Vector2(mr * 0.3, -mr * 0.3)) < mr * 0.2 or Vector2(x, y).distance_to(m + Vector2(mr * 0.1, mr * 0.5)) < mr * 0.15:
					col = Color.html(mc[2])
				img.set_pixel(x, y, col)
			elif d <= mr + 8.0:
				var halo := 1.0 - (d - mr) / 8.0
				var thr: float = (BAYER[y % 4][x % 4] + 0.5) / 16.0
				if halo * 0.6 > thr:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color.html(mc[1]), 0.18))
	return img


## Seamless ridge line from sines whose periods divide the layer width.
static func _ridge(r: RandomNumberGenerator, base: float, amp: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(W)
	var waves := []
	for k in [1, 2, 3, 5, 8, 13]:
		waves.append([k, r.randf() * TAU, amp / pow(k, 0.8)])
	for x in W:
		var h := base
		for w in waves:
			h += sin(float(x) / W * TAU * w[0] + w[1]) * w[2]
		out[x] = h
	return out


static func _mountains(p: Dictionary, r: RandomNumberGenerator, base: int, amp: int, col: String, hi: String) -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var ridge := _ridge(r, base, amp * 0.5)
	var c := Color.html(col)
	var ch := Color.html(hi)
	for x in W:
		var top := int(ridge[x])
		var slope := ridge[(x + 1) % W] - ridge[x]
		for y in range(maxi(top, 0), H):
			var lit := slope > 0.15 and y - top < 10
			img.set_pixel(x, y, ch if lit else c)
	_fog(img, p, 230, 0.35)
	return img


static func _trees(p: Dictionary, r: RandomNumberGenerator, region: String, base: int, col: String, hi: String, scale: float) -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var c := Color.html(col)
	var ch := Color.html(hi)
	var ground := _ridge(r, base, 10)
	for x in W:
		for y in range(int(ground[x]), H):
			img.set_pixel(x, y, c)
	var x := 0.0
	while x < W:
		var gx := int(x) % W
		var gy := int(ground[gx])
		match region:
			"ruins":
				if r.randf() < 0.45:
					_column(img, gx, gy, int(r.randi_range(40, 90) * scale), int(7 * scale), c, ch, r)
				else:
					_pine(img, gx, gy, int(r.randi_range(30, 60) * scale), c, ch)
			"home", "village":
				if r.randf() < 0.3:
					_house(img, gx, gy, scale, c, ch, r)
				else:
					_round_tree(img, gx, gy, int(r.randi_range(24, 44) * scale), c, ch, r)
			_:
				if r.randf() < 0.65:
					_pine(img, gx, gy, int(r.randi_range(40, 90) * scale), c, ch)
				else:
					_round_tree(img, gx, gy, int(r.randi_range(28, 52) * scale), c, ch, r)
		x += r.randf_range(14, 34) * scale
	_fog(img, p, base + 20, 0.22 if scale > 1.0 else 0.3)
	return img


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if y >= 0 and y < H:
		img.set_pixel(posmod(x, W), y, c)


static func _pine(img: Image, x: int, gy: int, h: int, c: Color, ch: Color) -> void:
	for yy in range(gy - h, gy + 1):
		var t := float(yy - (gy - h)) / h
		# tiers: width saw-tooths down the trunk
		var tier := fmod(t * 4.0, 1.0)
		var half := int((t * 0.6 + tier * 0.5) * h * 0.28) + 1
		for xx in range(-half, half + 1):
			_px(img, x + xx, yy, ch if xx < -half + 2 and tier < 0.6 else c)
	for yy in range(gy - 4, gy + 1):
		_px(img, x, yy, c)


static func _round_tree(img: Image, x: int, gy: int, h: int, c: Color, ch: Color, r: RandomNumberGenerator) -> void:
	var trunk_h := int(h * 0.4)
	for yy in range(gy - trunk_h, gy + 1):
		for xx in range(-1, 2):
			_px(img, x + xx, yy, c)
	var cr := h * 0.42
	var cy := gy - trunk_h - cr * 0.6
	for k in 4:
		var ox := r.randf_range(-cr * 0.6, cr * 0.6)
		var oy := r.randf_range(-cr * 0.4, cr * 0.3)
		var rr := cr * r.randf_range(0.55, 0.8)
		for yy in range(int(cy + oy - rr), int(cy + oy + rr) + 1):
			for xx in range(int(ox - rr), int(ox + rr) + 1):
				var d := Vector2(xx - ox, yy - cy - oy).length()
				if d <= rr:
					var edge := Vector2(xx - ox + rr * 0.3, yy - cy - oy + rr * 0.3).length() > rr * 0.95
					_px(img, x + xx, yy, ch if edge and xx - ox < 0 else c)


static func _column(img: Image, x: int, gy: int, h: int, w: int, c: Color, ch: Color, r: RandomNumberGenerator) -> void:
	var broken := r.randi_range(0, 6)
	for yy in range(gy - h, gy + 1):
		var jag := broken if yy < gy - h + 6 else 0
		for xx in range(0, w - (jag if yy % 3 == 0 else 0)):
			_px(img, x + xx, yy, ch if xx == 1 else c)
	for xx in range(-2, w + 2):
		_px(img, x + xx, gy - h + 6, c)
		_px(img, x + xx, gy - 2, c)
	if r.randf() < 0.3:  # arch fragment to the right
		for a in 20:
			var ang := PI + a / 20.0 * PI * 0.5
			var ax := int(cos(ang) * -18) + x + w
			var ay := int(sin(ang) * 18) + gy - h + 8
			for t in 3:
				_px(img, ax, ay + t, c)


static func _house(img: Image, x: int, gy: int, scale: float, c: Color, ch: Color, r: RandomNumberGenerator) -> void:
	var w := int(r.randi_range(22, 34) * scale)
	var h := int(r.randi_range(14, 22) * scale)
	for yy in range(gy - h, gy + 1):
		for xx in w:
			_px(img, x + xx, yy, c)
	var roof := int(w * 0.6)
	for k in roof:
		for xx in range(-2 + k, w + 2 - k):
			_px(img, x + xx, gy - h - k, c)
	# warm windows
	var win := Color.html("f0b050") if scale < 1.0 else Color.html("ffcc66")
	for wx in [int(w * 0.25), int(w * 0.62)]:
		for yy in range(gy - h + 4, gy - h + 7):
			for xx in 2:
				_px(img, x + wx + xx, yy, win.darkened(0.25) if scale < 1.0 else win)
	# chimney
	for yy in range(gy - h - roof, gy - h - roof + 6):
		for xx in 3:
			_px(img, x + int(w * 0.7) + xx, yy, c)


static func _fog(img: Image, p: Dictionary, from_y: int, strength: float) -> void:
	var fc := Color.html(p.fog)
	for y in range(from_y, H):
		var t := clampf(float(y - from_y) / 60.0, 0.0, 1.0) * strength
		for x in W:
			var px := img.get_pixel(x, y)
			if px.a > 0.0:
				var thr: float = (BAYER[y % 4][x % 4] + 0.5) / 16.0
				if t > thr * 0.9:
					img.set_pixel(x, y, px.lerp(fc, 0.35))
