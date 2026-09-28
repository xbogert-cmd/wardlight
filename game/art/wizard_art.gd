class_name WizardArt
extends RefCounted
## Builds the wizard sprite sheet from an appearance dictionary.
## All layers (robe, skin, hair, beard, hat, staff) are drawn from one shared
## pose per frame, so they can never drift out of alignment.

const CELL := 64        # cell height
const CELL_W := 80      # wide enough for an outstretched staff
const COLS := 16
const DRAW_OX := 8      # art is authored in a 64-wide space, centred in the cell
const FOOT := Vector2i(32 + DRAW_OX, 61)  # feet contact point inside a cell
const STAFF_LEN := 46.0
const AIM_ANGLES := [-60.0, -30.0, 0.0, 30.0, 60.0]

enum R { NONE, ROBE, TRIM, SKIN, BEARD, HAIR, HAT, BAND, WOOD, CRYSTAL, BOOT, SLEEVE, BACK, EYE, METAL, PANTS, MANTLE, BROW }

const COMPLEXIONS := {
	"porcelain": ["fde6d4", "ebc3a8", "bd8a74"],
	"fair": ["f6cba2", "dba27c", "aa6c54"],
	"tan": ["dea677", "ba7d52", "8b5436"],
	"brown": ["ac6c40", "87492c", "5f301f"],
	"deep": ["74462c", "56331f", "3a2116"],
}
const HAIR_COLORS := {
	"white": ["f6f2ea", "d2cbc4", "928898"],
	"silver": ["cdd2dc", "949bac", "5f637b"],
	"auburn": ["cf653e", "9e4028", "68271d"],
	"black": ["57506a", "343044", "1c1a28"],
	"gold": ["f3d474", "cba243", "8c662a"],
}
const ROBES := {
	"wanderer": {"main": ["d9503f", "a53132", "681d2e"], "trim": ["f4cf66", "cc9534", "8c5c22"], "short": false, "mantle": false},
	"mantle": {"main": ["5474d8", "3449a6", "20296c"], "trim": ["e2e5f5", "a7afcf", "6a7294"], "short": false, "mantle": true},
	"coat": {"main": ["5a9660", "3a6c45", "224530"], "trim": ["d4ac68", "a07544", "684a2a"], "short": true, "mantle": false},
}
const STAFFS := {
	"crook": {"wood": ["a8703e", "7a4c2a", "4c2c1c"], "gem": ["b8fcff", "4cc8f4", "2a6ad0"]},
	"rod": {"wood": ["6a5a6e", "463a4c", "2a2230"], "gem": ["f0e6ff", "ae9ef0", "6454b8"]},
	"fork": {"wood": ["b08a58", "846238", "523a22"], "gem": ["f4ffb0", "aee468", "5c9c3c"]},
}
const BOOTS := ["5a4050", "3c2a38", "24182a"]
const PANTS := ["4a3e52", "342a3c", "201a28"]
const INK := "140c1c"

const DEFAULT_LOOK := {
	"robe": "wanderer", "complexion": "fair", "hair": "long", "hair_color": "white",
	"beard": "long", "hat": "pointed", "staff": "crook",
}
const HAIR_STYLES := ["short", "long", "braid", "wild"]
const BEARDS := ["none", "short", "long"]
const HATS := ["pointed", "hood", "none"]


## Returns {texture, anims, tips, hframes, vframes}.
## anims: name -> {frames: PackedInt32Array, fps: float, loop: bool}
## tips: per-frame staff gem position relative to the feet origin.
static func build(look: Dictionary) -> Dictionary:
	var l := DEFAULT_LOOK.duplicate()
	l.merge(look, true)
	var frames: Array[Dictionary] = []
	var anims := {}
	for a in _anim_defs():
		var idx := PackedInt32Array()
		for p: Dictionary in a.poses:
			idx.append(frames.size())
			frames.append(p)
		anims[a.name] = {"frames": idx, "fps": a.fps, "loop": a.loop}
	var rows := ceili(frames.size() / float(COLS))
	var sheet := Image.create_empty(COLS * CELL_W, rows * CELL, false, Image.FORMAT_RGBA8)
	var tips := PackedVector2Array()
	for i in frames.size():
		var c := PixelCanvas.new(CELL_W, CELL)
		c.ox = DRAW_OX
		var tip := _draw_frame(c, _pose(frames[i]), l)
		c.blit_into(sheet, (i % COLS) * CELL_W, (i / COLS) * CELL)
		tips.append(tip + Vector2(DRAW_OX, 0) - Vector2(FOOT))
	return {
		"image": sheet, "texture": ImageTexture.create_from_image(sheet),
		"anims": anims, "tips": tips, "hframes": COLS, "vframes": rows,
	}


static func aim_dir(deg: float) -> Vector2:
	return Vector2.RIGHT.rotated(deg_to_rad(deg))


static func _pose(o: Dictionary) -> Dictionary:
	var p := {
		"bob": 0, "lean": 0, "ff": Vector2i.ZERO, "bf": Vector2i.ZERO,
		"hem": 0, "flare": 0, "hem_lift": 0, "hat": 0, "hat_up": 0, "beard": 0,
		"hand": Vector2(37, 47), "staff": Vector2(0, -1), "grip": 0.34,
		"back_hand": Vector2(-3, 8), "eye": true, "head_dy": 0, "lying": false,
	}
	p.merge(o, true)
	return p


static func _anim_defs() -> Array:
	var defs := []
	# Idle: slow breath; beard and hat tip follow a beat later.
	var idle := []
	var ib := [0, 0, 1, 1, 1, 0]
	var ibeard := [0, 0, 0, 1, 1, 1]
	for i in 6:
		idle.append({"bob": ib[i], "beard": ibeard[i], "hat": ib[(i + 5) % 6], "hand": Vector2(37, 47 + ib[i])})
	defs.append({"name": "idle", "fps": 7.0, "loop": true, "poses": idle})
	# Run: 8-frame cycle, robe hem and hat trail behind.
	var run := []
	var rb := [1, 0, -1, 0, 1, 0, -1, 0]
	var ffx := [Vector2i(4, 0), Vector2i(2, 0), Vector2i(0, 0), Vector2i(-3, 0), Vector2i(-4, 0), Vector2i(-2, 2), Vector2i(1, 3), Vector2i(3, 1)]
	var bfx := [Vector2i(-4, 0), Vector2i(-2, 2), Vector2i(1, 3), Vector2i(3, 1), Vector2i(4, 0), Vector2i(2, 0), Vector2i(0, 0), Vector2i(-3, 0)]
	var trail := [2, 3, 3, 2, 2, 3, 3, 2]
	for i in 8:
		run.append({
			"bob": rb[i], "lean": 2, "ff": ffx[i], "bf": bfx[i], "hem": trail[i], "flare": 1 - (trail[i] - 2),
			"hat": trail[i] + 1, "beard": trail[i] - 1, "hand": Vector2(39, 45 + rb[i]), "staff": Vector2(0.35, -1),
			"grip": 0.36, "back_hand": Vector2(-3 - bfx[i].x / 2, 7),
		})
	defs.append({"name": "run", "fps": 12.0, "loop": true, "poses": run})
	defs.append({"name": "jump", "fps": 8.0, "loop": true, "poses": [
		{"bob": -1, "lean": 1, "ff": Vector2i(2, 4), "bf": Vector2i(-2, 3), "hem_lift": 2, "hem": 1, "hat": 3, "beard": 2,
			"hand": Vector2(38, 42), "staff": Vector2(0.2, -1), "back_hand": Vector2(-4, 5)},
		{"bob": -1, "lean": 1, "ff": Vector2i(2, 5), "bf": Vector2i(-2, 3), "hem_lift": 2, "hem": 2, "hat": 4, "beard": 2,
			"hand": Vector2(38, 41), "staff": Vector2(0.2, -1), "back_hand": Vector2(-4, 4)},
	]})
	defs.append({"name": "fall", "fps": 8.0, "loop": true, "poses": [
		{"ff": Vector2i(1, 2), "bf": Vector2i(-2, 1), "flare": 2, "hem_lift": 1, "hat": 1, "hat_up": 2, "beard": -1,
			"hand": Vector2(39, 40), "staff": Vector2(0.25, -1), "back_hand": Vector2(-6, 1)},
		{"ff": Vector2i(1, 2), "bf": Vector2i(-2, 1), "flare": 3, "hem_lift": 1, "hat": 0, "hat_up": 3, "beard": -1,
			"hand": Vector2(39, 39), "staff": Vector2(0.25, -1), "back_hand": Vector2(-6, 0)},
	]})
	defs.append({"name": "land", "fps": 16.0, "loop": false, "poses": [
		{"bob": 3, "flare": 2, "ff": Vector2i(2, 0), "bf": Vector2i(-2, 0), "hand": Vector2(38, 49), "beard": -1, "hat": -1},
		{"bob": 1, "flare": 1, "hand": Vector2(37, 48)},
	]})
	# Casting: raise → gather (loops while channelling) → aimed release/follow → recover.
	defs.append({"name": "raise", "fps": 14.0, "loop": false, "poses": [
		{"bob": 1, "lean": -1, "hand": Vector2(35, 36), "staff": Vector2(-0.25, -1), "grip": 0.45, "back_hand": Vector2(-4, 5), "hat": 1},
	]})
	defs.append({"name": "gather", "fps": 10.0, "loop": true, "poses": [
		{"bob": 0, "lean": -1, "hand": Vector2(36, 30), "staff": Vector2(0.05, -1), "grip": 0.5, "back_hand": Vector2(-5, 3), "flare": 1, "hat": 1},
		{"bob": -1, "lean": -1, "hand": Vector2(36, 29), "staff": Vector2(0.05, -1), "grip": 0.5, "back_hand": Vector2(-5, 2), "flare": 2, "hat": 2, "beard": 1},
	]})
	for i in AIM_ANGLES.size():
		var d := aim_dir(AIM_ANGLES[i])
		var sh := Vector2(33, 38)
		var g: float = 0.38 + absf(AIM_ANGLES[i]) / 60.0 * 0.1
		defs.append({"name": "release_%d" % i, "fps": 16.0, "loop": false, "poses": [
			{"lean": 2, "hand": sh + d * 9.0, "staff": d, "grip": g, "back_hand": Vector2(-6, 4), "hem": 1, "hat": 2, "beard": 1, "ff": Vector2i(3, 0), "bf": Vector2i(-3, 0)},
			{"lean": 1, "bob": 1, "hand": sh + d * 8.0, "staff": d, "grip": g + 0.03, "back_hand": Vector2(-5, 6), "hem": 1, "hat": 1, "ff": Vector2i(3, 0), "bf": Vector2i(-3, 0)},
		]})
	defs.append({"name": "recover", "fps": 12.0, "loop": false, "poses": [
		{"bob": 1, "hand": Vector2(37, 45), "staff": Vector2(0.15, -1), "hat": 1},
	]})
	defs.append({"name": "dodge", "fps": 20.0, "loop": false, "poses": [
		{"bob": 3, "lean": 3, "ff": Vector2i(5, 0), "bf": Vector2i(-6, 1), "hem": 4, "hat": 5, "beard": 3, "hand": Vector2(40, 50), "staff": Vector2(1, -0.2), "grip": 0.55, "back_hand": Vector2(-6, 6)},
		{"bob": 4, "lean": 4, "ff": Vector2i(5, 0), "bf": Vector2i(-6, 2), "hem": 6, "hat": 6, "beard": 4, "hand": Vector2(41, 51), "staff": Vector2(1, -0.15), "grip": 0.55, "back_hand": Vector2(-7, 6)},
		{"bob": 4, "lean": 4, "ff": Vector2i(4, 0), "bf": Vector2i(-5, 1), "hem": 5, "hat": 5, "beard": 3, "hand": Vector2(41, 51), "staff": Vector2(1, -0.15), "grip": 0.55, "back_hand": Vector2(-7, 5)},
		{"bob": 2, "lean": 2, "ff": Vector2i(3, 0), "bf": Vector2i(-3, 0), "hem": 3, "hat": 3, "beard": 2, "hand": Vector2(39, 48), "staff": Vector2(0.6, -1), "grip": 0.45},
	]})
	defs.append({"name": "hurt", "fps": 10.0, "loop": false, "poses": [
		{"bob": 1, "lean": -2, "hat": 4, "hat_up": 1, "beard": -2, "hand": Vector2(35, 42), "staff": Vector2(-0.3, -1), "back_hand": Vector2(-6, 1), "eye": false, "flare": 1},
		{"bob": 1, "lean": -1, "hat": 3, "beard": -1, "hand": Vector2(36, 44), "staff": Vector2(-0.15, -1), "back_hand": Vector2(-5, 4), "eye": false},
	]})
	defs.append({"name": "death", "fps": 7.0, "loop": false, "poses": [
		{"bob": 1, "lean": -2, "hat": 4, "hand": Vector2(35, 42), "staff": Vector2(-0.3, -1), "back_hand": Vector2(-6, 1), "eye": false},
		{"bob": 5, "lean": -1, "ff": Vector2i(3, 0), "bf": Vector2i(-4, 0), "flare": 2, "hand": Vector2(38, 49), "staff": Vector2(0.3, -1), "grip": 0.3, "eye": false, "hat": 2},
		{"bob": 7, "lean": 1, "head_dy": 1, "ff": Vector2i(3, 0), "bf": Vector2i(-4, 0), "flare": 3, "hand": Vector2(39, 52), "staff": Vector2(0.7, -1), "grip": 0.25, "eye": false, "hat": 1},
		{"bob": 8, "lean": 2, "head_dy": 2, "ff": Vector2i(3, 0), "bf": Vector2i(-4, 0), "flare": 3, "hand": Vector2(40, 54), "staff": Vector2(1, -0.35), "grip": 0.2, "eye": false},
		{"lying": true},
		{"lying": true, "hat": 1},
	]})
	return defs


## Draws one frame. Returns the gem centre (cell coords).
static func _draw_frame(c: PixelCanvas, p: Dictionary, l: Dictionary) -> Vector2:
	if p.lying:
		return _draw_lying(c, p, l)
	var robe: Dictionary = ROBES[l.robe]
	var main := _cols(robe.main)
	var trim := _cols(robe.trim)
	var skin := _cols(COMPLEXIONS[l.complexion])
	var hair := _cols(HAIR_COLORS[l.hair_color])
	var st: Dictionary = STAFFS[l.staff]
	var wood := _cols(st.wood)
	var gem := _cols(st.gem)
	var boots := _cols(BOOTS)
	var pants := _cols(PANTS)
	var u := Vector2(p.lean, p.bob)
	var hu := u + Vector2(0, p.head_dy)
	var short: bool = robe.short
	var hem_y := 51.0 if short else 58.0
	hem_y -= p.hem_lift

	# 1. back arm (behind everything)
	var bsh := Vector2(27, 39) + u
	var bhand: Vector2 = bsh + p.back_hand
	c.stroke(bsh, bhand, 3, main[2], R.BACK)
	c.rect(roundi(bhand.x) - 1, roundi(bhand.y), 2, 2, skin[2], R.SKIN)

	# 2. legs and boots
	var ffoot := Vector2(32 + p.ff.x, 60 - p.ff.y)
	var bfoot := Vector2(27 + p.bf.x, 60 - p.bf.y)
	if short:
		c.stroke(Vector2(28, 49) + u * 0.5, bfoot + Vector2(1, -3), 3, pants[2], R.PANTS)
		c.stroke(Vector2(32, 49) + u * 0.5, ffoot + Vector2(1, -3), 3, pants[1], R.PANTS)
	var boot_h := 5 if short else 4
	for f: Vector2 in [bfoot, ffoot]:
		c.rect(roundi(f.x), roundi(f.y) - boot_h + 1, 4, boot_h, boots[1], R.BOOT)
		c.put(roundi(f.x) + 4, roundi(f.y), boots[1], R.BOOT)

	# 3. robe body
	var hem_back := float(p.hem) + float(p.flare)
	var body := PackedVector2Array([
		Vector2(25, 37) + u, Vector2(36, 37) + u, Vector2(37.5, 45) + u,
		Vector2(39.5 + p.flare - p.hem * 0.5, hem_y + 1), Vector2(21.5 - hem_back, hem_y + 1),
		Vector2(24, 46) + u,
	])
	c.poly(body, main[1], R.ROBE)
	# hem trim: lowest two robe rows of each column
	_trim_bottom(c, R.ROBE, trim[1], R.TRIM, 2)
	# sash
	for x in range(10, 54):
		for y in [45, 46]:
			if c.region_at(x, y + int(p.bob)) == R.ROBE:
				c.put(x, y + int(p.bob), trim[1] if y == 45 else trim[2], R.TRIM)
	if robe.mantle:
		c.poly(PackedVector2Array([
			Vector2(24, 36) + u, Vector2(37, 36) + u, Vector2(38.5, 42) + u,
			Vector2(31, 43.5) + u, Vector2(23 - p.hem * 0.5, 43) + u,
		]), trim[2].lerp(main[2], 0.35), R.MANTLE)

	# 4. head, hair behind the head, face
	var head_c := Vector2(31, 31.5) + hu
	_draw_hair_back(c, l, hair, hu)
	c.ellipse(head_c.x, head_c.y, 4.2, 4.6, skin[1], R.SKIN)
	c.put(roundi(head_c.x) + 4, roundi(head_c.y) + 1, skin[1], R.SKIN)  # nose
	if p.eye:
		c.rect(roundi(head_c.x) + 2, roundi(head_c.y) - 1, 1, 2, Color.html("2a1830"), R.EYE)
	else:
		c.rect(roundi(head_c.x) + 1, roundi(head_c.y), 2, 1, Color.html("2a1830"), R.EYE)
	c.rect(roundi(head_c.x) + 1, roundi(head_c.y) - 2, 3, 1, hair[1], R.BROW)

	# 5. beard
	_draw_beard(c, l, hair, hu, p)

	# 6. hat / hood / bare hair top
	_draw_hat(c, l, main, trim, hair, hu, p)

	# 7. front sleeve
	var sh := Vector2(33, 38) + u
	var hand: Vector2 = p.hand + Vector2(p.lean, 0) * 0.5
	c.stroke(sh, sh.lerp(hand, 0.78), 4, main[1], R.SLEEVE)
	var cuff := sh.lerp(hand, 0.72)
	c.ellipse(cuff.x, cuff.y, 2.4, 2.4, trim[1], R.TRIM)

	# 8. staff
	var d: Vector2 = (p.staff as Vector2).normalized()
	var bottom: Vector2 = hand - d * STAFF_LEN * p.grip
	var top: Vector2 = hand + d * STAFF_LEN * (1.0 - p.grip)
	c.stroke(bottom, top, 2, wood[1], R.WOOD)
	var gem_c := _draw_staff_head(c, l.staff, top, d, wood, gem)

	# 9. front hand gripping the staff
	c.rect(roundi(hand.x) - 1, roundi(hand.y) - 1, 3, 3, skin[1], R.SKIN)

	# shading pass
	c.shade(R.ROBE, main[0], main[2], 2)
	c.shade(R.SLEEVE, main[0], main[2], 1)
	c.shade(R.BACK, main[2], main[2].darkened(0.25), 1)
	c.shade(R.MANTLE, trim[1].lerp(main[1], 0.4), main[2].darkened(0.2), 1)
	c.shade(R.TRIM, trim[0], trim[2], 1)
	c.shade(R.SKIN, skin[0], skin[2], 1)
	c.shade(R.HAIR, hair[0], hair[2], 1)
	c.shade(R.BEARD, hair[0], hair[2], 1)
	c.shade(R.HAT, main[0], main[2], 2)
	c.shade(R.BAND, trim[0], trim[2], 1)
	c.shade(R.WOOD, wood[0], wood[2], 1)
	c.shade(R.CRYSTAL, gem[0], gem[2], 1)
	c.shade(R.BOOT, boots[0], boots[2], 1)
	c.shade(R.PANTS, pants[0], pants[2], 1)
	c.shade(R.METAL, Color.html("f0eee0"), Color.html("8c8a9c"), 1)
	# robe folds: one crease from the sash down to the hem
	var fold_top := Vector2(31, 48) + u
	var fold_bot := Vector2(30 - p.hem * 0.7, hem_y - 2)
	_line_on(c, fold_top, fold_bot, main[2], R.ROBE)
	_line_on(c, fold_top + Vector2(-4, 2), fold_bot + Vector2(-6, 0), main[2], R.ROBE)
	if robe.mantle:
		for s: Vector2 in [Vector2(28, 51), Vector2(34, 54), Vector2(26, 56)]:
			if c.region_at(roundi(s.x + p.lean), roundi(s.y)) == R.ROBE:
				c.put(roundi(s.x + p.lean), roundi(s.y), trim[0], R.ROBE)
	# gem sparkle
	c.put(roundi(gem_c.x) - 1, roundi(gem_c.y) - 1, Color.WHITE, R.CRYSTAL)
	c.outline(Color.html(INK))
	return gem_c


static func _draw_hair_back(c: PixelCanvas, l: Dictionary, hair: Array, u: Vector2) -> void:
	var o := u
	match l.hair:
		"short":
			c.poly(_pts([Vector2(26, 28), Vector2(29, 28), Vector2(29, 35), Vector2(26, 35)], o), hair[1], R.HAIR)
		"long":
			c.poly(_pts([Vector2(26, 28), Vector2(30, 28), Vector2(29.5, 38), Vector2(27, 42), Vector2(24.5, 40), Vector2(25, 31)], o), hair[1], R.HAIR)
		"braid":
			c.poly(_pts([Vector2(26, 28), Vector2(29, 28), Vector2(29, 35), Vector2(26, 35)], o), hair[1], R.HAIR)
			for i in 5:
				var bx := 25.5 - (i % 2) * 0.8
				c.ellipse(bx + o.x, 36.5 + i * 2.2 + o.y, 1.6, 1.3, hair[1], R.HAIR)
			c.rect(roundi(24 + o.x), roundi(47.5 + o.y), 2, 1, Color.html("c8433a"), R.TRIM)
		"wild":
			c.poly(_pts([Vector2(29, 27), Vector2(24, 26.5), Vector2(25.5, 29), Vector2(22, 30.5), Vector2(25, 32), Vector2(22.5, 35),
				Vector2(26, 35), Vector2(25, 38), Vector2(29, 36)], o), hair[1], R.HAIR)


static func _draw_beard(c: PixelCanvas, l: Dictionary, hair: Array, u: Vector2, p: Dictionary) -> void:
	var s := float(p.beard)
	match l.beard:
		"long":
			c.poly(_pts([Vector2(29, 32.5), Vector2(35.5, 32.5), Vector2(36.5, 36), Vector2(35.5, 41), Vector2(33.5 - s * 0.5, 45),
				Vector2(31.5 - s, 48), Vector2(30.5 - s * 0.5, 43), Vector2(28.5, 37)], u), hair[1], R.BEARD)
		"short":
			c.poly(_pts([Vector2(29, 32.5), Vector2(35.5, 32.5), Vector2(36, 36), Vector2(33, 39.5), Vector2(29.5, 37)], u), hair[1], R.BEARD)
		_:
			c.put(roundi(34 + u.x), roundi(34 + u.y), Color.html("9a5a50"), R.EYE)
	if l.beard != "none":
		c.rect(roundi(32 + u.x), roundi(33 + u.y), 4, 1, hair[0], R.BEARD)  # moustache


static func _draw_hat(c: PixelCanvas, l: Dictionary, main: Array, trim: Array, hair: Array, u: Vector2, p: Dictionary) -> void:
	var t := float(p.hat)
	var up := float(p.hat_up)
	match l.hat:
		"pointed":
			c.poly(_pts([Vector2(25.5, 27.5), Vector2(36.5, 27.5), Vector2(34.5, 22), Vector2(31.5, 16.5),
				Vector2(27.5 - t * 0.4, 12 - up * 0.3), Vector2(22.5 - t * 0.8, 9.5 - up * 0.8), Vector2(18 - t, 10.5 - up),
				Vector2(22 - t * 0.6, 12.5 - up * 0.5), Vector2(25, 17), Vector2(26, 22)], u), main[1], R.HAT)
			c.ellipse(31 + u.x, 27.8 + u.y, 8.2, 1.7, main[1], R.HAT)
			for x in range(10, 54):
				for y in [25, 26]:
					var yy: int = y + roundi(u.y)
					if c.region_at(x, yy) == R.HAT:
						c.put(x, yy, trim[1], R.BAND)
		"hood":
			c.poly(_pts([Vector2(24.5, 29), Vector2(27, 24.5), Vector2(31, 23.5), Vector2(35, 25.5), Vector2(36.8, 30),
				Vector2(37, 36), Vector2(35, 38.5), Vector2(26, 39), Vector2(21.5 - t * 0.5, 31 - up * 0.3)], u), main[1], R.HAT)
			c.ellipse(33.2 + u.x, 32.2 + u.y, 2.6, 3.3, Color.html("2a1830"), R.EYE)  # shadowed opening
			c.ellipse(33.8 + u.x, 32.4 + u.y, 2.0, 2.8, _cols(COMPLEXIONS[l.complexion])[2], R.SKIN)
			c.rect(roundi(34 + u.x), roundi(31 + u.y), 1, 2, Color.html("2a1830"), R.EYE)
			if l.beard != "none":
				c.rect(roundi(33 + u.x), roundi(34 + u.y), 3, 2 if l.beard == "short" else 3, hair[1], R.BEARD)
		_:
			match l.hair:
				"short":
					c.poly(_pts([Vector2(26, 31), Vector2(26, 27.5), Vector2(29, 25.8), Vector2(33, 26), Vector2(35.5, 28.5), Vector2(33, 29), Vector2(29, 29)], u), hair[1], R.HAIR)
				"long", "braid":
					c.poly(_pts([Vector2(25.5, 32), Vector2(25.5, 27.5), Vector2(28.5, 25.5), Vector2(33, 25.5), Vector2(36, 28), Vector2(35.5, 29.5), Vector2(32, 28.8), Vector2(29, 29.5)], u), hair[1], R.HAIR)
					if l.hair == "braid":
						c.ellipse(27 + u.x, 25 + u.y, 2, 1.6, hair[1], R.HAIR)
				"wild":
					c.poly(_pts([Vector2(25, 30), Vector2(24, 25), Vector2(27, 26.5), Vector2(28, 23), Vector2(30.5, 26), Vector2(32.5, 23.5),
						Vector2(33.5, 26.5), Vector2(36.5, 25.5), Vector2(35.5, 29.5)], u), hair[1], R.HAIR)
				_:
					pass


## Staff head ornaments are defined in staff-local space (along, across).
static func _draw_staff_head(c: PixelCanvas, style: String, top: Vector2, d: Vector2, wood: Array, gem: Array) -> Vector2:
	var n := Vector2(d.y, -d.x)  # "back" side of the staff
	var at := func(a: float, b: float) -> Vector2: return top + d * a + n * b
	match style:
		"crook":
			for pr: Vector2 in [Vector2(-1, 2), Vector2(0, 2), Vector2(1, 2.5), Vector2(2, 2.5), Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2.5), Vector2(2, -2.5), Vector2(-1, 1), Vector2(-1, -1)]:
				var q: Vector2 = at.call(pr.x, pr.y)
				c.put(roundi(q.x), roundi(q.y), wood[1], R.WOOD)
			var g: Vector2 = at.call(2.5, 0)
			c.ellipse(g.x, g.y, 1.8, 1.8, gem[1], R.CRYSTAL)
			var tipq: Vector2 = at.call(4.5, 0)
			c.put(roundi(tipq.x), roundi(tipq.y), gem[1], R.CRYSTAL)
			return g
		"rod":
			for k in [-5.0, -11.0]:
				for s in [-1.0, 0.0, 1.0]:
					var q: Vector2 = at.call(k, s)
					c.put(roundi(q.x), roundi(q.y), Color.html("c8c4d0"), R.METAL)
			for pr: Vector2 in [Vector2(0, -1.5), Vector2(0, 1.5), Vector2(1, -1), Vector2(1, 1), Vector2(0, 0)]:
				var q: Vector2 = at.call(pr.x, pr.y)
				c.put(roundi(q.x), roundi(q.y), Color.html("c8c4d0"), R.METAL)
			var g: Vector2 = at.call(2.5, 0)
			c.ellipse(g.x, g.y, 1.5, 2.0, gem[1], R.CRYSTAL)
			return g
		_:
			var l1: Vector2 = at.call(5, 3)
			var l2: Vector2 = at.call(5, -3)
			c.stroke(top, l1, 1, wood[1], R.WOOD)
			c.stroke(top, l2, 1, wood[1], R.WOOD)
			var g: Vector2 = at.call(3.5, 0)
			c.ellipse(g.x, g.y, 2.0, 2.0, gem[1], R.CRYSTAL)
			return g


static func _draw_lying(c: PixelCanvas, p: Dictionary, l: Dictionary) -> Vector2:
	var robe: Dictionary = ROBES[l.robe]
	var main := _cols(robe.main)
	var trim := _cols(robe.trim)
	var skin := _cols(COMPLEXIONS[l.complexion])
	var hair := _cols(HAIR_COLORS[l.hair_color])
	var st: Dictionary = STAFFS[l.staff]
	var wood := _cols(st.wood)
	var gem := _cols(st.gem)
	c.stroke(Vector2(8, 60), Vector2(52, 59), 2, wood[1], R.WOOD)
	c.ellipse(54, 58.5, 1.8, 1.8, gem[1], R.CRYSTAL)
	c.poly(PackedVector2Array([Vector2(14, 60.5), Vector2(18, 54), Vector2(30, 52.5), Vector2(40, 54), Vector2(42, 60.5)]), main[1], R.ROBE)
	_trim_bottom(c, R.ROBE, trim[1], R.TRIM, 1)
	c.rect(10, 57, 5, 4, _cols(BOOTS)[1], R.BOOT)
	c.ellipse(44.5, 57.5, 4, 3.5, skin[1], R.SKIN)
	if l.beard != "none":
		c.poly(PackedVector2Array([Vector2(44, 59), Vector2(48, 58), Vector2(52, 60.5), Vector2(44, 60.5)]), hair[1], R.BEARD)
	if l.hat == "pointed":
		var hx: float = 50.0 + p.hat * 2
		c.poly(PackedVector2Array([Vector2(hx - 4, 60.5), Vector2(hx + 5, 60.5), Vector2(hx + 2, 55), Vector2(hx + 6, 51)]), main[1], R.HAT)
	c.shade(R.ROBE, main[0], main[2], 2)
	c.shade(R.SKIN, skin[0], skin[2], 1)
	c.shade(R.BEARD, hair[0], hair[2], 1)
	c.shade(R.HAT, main[0], main[2], 1)
	c.shade(R.WOOD, wood[0], wood[2], 1)
	c.shade(R.TRIM, trim[0], trim[2], 1)
	c.outline(Color.html(INK))
	return Vector2(54, 58.5)


static func _trim_bottom(c: PixelCanvas, r: int, col: Color, nr: int, rows: int) -> void:
	for x in range(-c.ox, c.w - c.ox):
		var found := 0
		for y in range(c.h - 1, -1, -1):
			if c.region_at(x, y) == r:
				c.put(x, y, col, nr)
				found += 1
				if found >= rows:
					break
			elif found > 0:
				break


static func _line_on(c: PixelCanvas, a: Vector2, b: Vector2, col: Color, r: int) -> void:
	var n := maxi(1, ceili(a.distance_to(b)))
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		var x := roundi(q.x)
		var y := roundi(q.y)
		if c.region_at(x, y) == r:
			c.put(x, y, col, r)


static func _pts(arr: Array, o: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in arr:
		out.append(v + o)
	return out


static func _cols(a: Array) -> Array[Color]:
	var out: Array[Color] = []
	for s: String in a:
		out.append(Color.html(s))
	return out
