extends RefCounted
## 16×16 spell icons, one per cell in a single row atlas (index = SpellData.icon).

const S := 16
const FIRE := ["fff6c8", "ffd24a", "ff8a24", "d9401c", "7a1c14"]
const HEX := ["f4e8ff", "c88cff", "8a4ae0", "4f2a9a", "2a1650"]
const SPEC := ["e8fff4", "8affc8", "3ad69a", "1e8a66", "0e4a3a"]
const STORM := ["ffffff", "b4f6ff", "52cfff", "3a78f0", "5a3ab8"]
const WOOD := ["a8703e", "7a4c2a", "4c2c1c"]


static func build() -> Image:
	var fns := [_ember_spear, _cinder_fan, _hearth_ward, _ashfall, _grave_needle, _binding_roots, _siphon_circle,
		_spirit_lantern, _arc_lance, _thunder_ring, _slipstream, _tempest_orb, _flame_pulse, _spectral_thrust,
		_static_gust, _empty]
	var img := Image.create_empty(S * fns.size(), S, false, Image.FORMAT_RGBA8)
	for k in fns.size():
		var c := PixelCanvas.new(S, S)
		(fns[k] as Callable).call(c)
		c.outline(Color.html("0e0a18"), 0.8)
		c.blit_into(img, k * S, 0)
	return img


static func _c(a: Array, i: int) -> Color:
	return Color.html(a[i])


static func _flame(c: PixelCanvas, x: float, y: float, h: float, r: Array) -> void:
	c.poly(PackedVector2Array([Vector2(x - h * 0.35, y), Vector2(x, y - h), Vector2(x + h * 0.35, y)]), _c(r, 2), 2)
	c.ellipse(x, y - h * 0.15, h * 0.35, h * 0.3, _c(r, 2), 2)
	c.poly(PackedVector2Array([Vector2(x - h * 0.18, y - 1), Vector2(x, y - h * 0.6), Vector2(x + h * 0.18, y - 1)]), _c(r, 1), 3)
	c.put(roundi(x), roundi(y - 2), _c(r, 0), 3)


static func _ember_spear(c: PixelCanvas) -> void:
	c.stroke(Vector2(2, 13), Vector2(10, 5), 2, _c(FIRE, 3), 1)
	c.poly(PackedVector2Array([Vector2(9, 4), Vector2(14, 1.5), Vector2(12, 7)]), _c(FIRE, 1), 2)
	c.put(12, 4, _c(FIRE, 0), 3)
	for p: Vector2i in [Vector2i(3, 9), Vector2i(1, 10), Vector2i(5, 13), Vector2i(2, 14)]:
		c.put(p.x, p.y, _c(FIRE, 2), 2)


static func _cinder_fan(c: PixelCanvas) -> void:
	_flame(c, 4, 13, 7, FIRE)
	_flame(c, 8, 11, 9, FIRE)
	_flame(c, 12, 13, 7, FIRE)


static func _hearth_ward(c: PixelCanvas) -> void:
	c.ring(8, 8, 7, 2, _c(FIRE, 2), 1)
	c.ring(8, 8, 7, 1, _c(FIRE, 1), 2)
	_flame(c, 8, 11, 6, FIRE)
	for a in 6:
		var p := Vector2(8, 8) + Vector2.from_angle(a * TAU / 6) * 7
		c.put(roundi(p.x), roundi(p.y) - 1, _c(FIRE, 0), 3)


static func _ashfall(c: PixelCanvas) -> void:
	c.ellipse(8, 4, 6.5, 3, Color.html("5a4a50"), 1)
	c.ellipse(6, 3, 3, 2, Color.html("7a6a6a"), 1)
	for p: Vector2i in [Vector2i(3, 9), Vector2i(7, 11), Vector2i(11, 9), Vector2i(5, 14), Vector2i(10, 14), Vector2i(13, 12)]:
		c.rect(p.x, p.y, 2, 2, _c(FIRE, 2), 2)
		c.put(p.x, p.y, _c(FIRE, 0), 3)


static func _grave_needle(c: PixelCanvas) -> void:
	c.stroke(Vector2(2, 14), Vector2(12, 4), 1, _c(HEX, 2), 1)
	c.poly(PackedVector2Array([Vector2(11, 3), Vector2(15, 1), Vector2(13, 5)]), _c(HEX, 1), 2)
	c.ellipse(5, 6, 2.6, 2.4, Color.html("e8e0f0"), 4)
	c.put(4, 6, Color.html("2a1a3a"), 5)
	c.put(6, 6, Color.html("2a1a3a"), 5)
	c.put(3, 13, _c(SPEC, 1), 3)
	c.put(1, 15, _c(SPEC, 2), 3)


static func _binding_roots(c: PixelCanvas) -> void:
	var col := Color.html("6a4a3a")
	c.stroke(Vector2(3, 15), Vector2(4, 7), 2, col, 1)
	c.stroke(Vector2(4, 7), Vector2(8, 3), 1, col, 1)
	c.stroke(Vector2(12, 15), Vector2(11, 8), 2, col, 1)
	c.stroke(Vector2(11, 8), Vector2(7, 5), 1, col, 1)
	c.ring(8, 10, 4, 1, _c(HEX, 1), 2)
	c.put(8, 3, _c(SPEC, 1), 3)


static func _siphon_circle(c: PixelCanvas) -> void:
	c.ring(8, 8, 7, 1, _c(HEX, 2), 1)
	c.ellipse(8, 8, 2.5, 2.5, _c(SPEC, 1), 2)
	for a in 4:
		var d := Vector2.from_angle(a * TAU / 4 + PI / 4)
		var p := Vector2(8, 8) + d * 5.5
		c.linev(p, p - d * 2.5, _c(HEX, 1), 3)


static func _spirit_lantern(c: PixelCanvas) -> void:
	c.rect(6, 2, 4, 1, Color.html("6a5a4a"), 1)
	c.rect(4, 4, 8, 9, Color.html("4a3a3a"), 1)
	c.rect(5, 5, 6, 7, _c(SPEC, 3), 2)
	_flame(c, 8, 11, 5, SPEC)
	c.rect(4, 13, 8, 1, Color.html("6a5a4a"), 1)
	c.put(8, 1, Color.html("6a5a4a"), 1)


static func _arc_lance(c: PixelCanvas) -> void:
	var pts := [Vector2(11, 1), Vector2(5, 8), Vector2(9, 8), Vector2(3, 15)]
	for k in 3:
		c.stroke(pts[k], pts[k + 1], 2, _c(STORM, 2), 1)
	for k in 3:
		c.linev(pts[k], pts[k + 1], _c(STORM, 0), 2)
	c.put(12, 3, _c(STORM, 1), 2)
	c.put(2, 12, _c(STORM, 1), 2)


static func _thunder_ring(c: PixelCanvas) -> void:
	c.ring(8, 9, 7, 1, _c(STORM, 2), 1)
	c.ring(8, 9, 4, 1, _c(STORM, 1), 2)
	c.linev(Vector2(8, 1), Vector2(7, 5), _c(STORM, 0), 3)
	c.linev(Vector2(7, 5), Vector2(9, 6), _c(STORM, 0), 3)
	c.linev(Vector2(9, 6), Vector2(8, 9), _c(STORM, 0), 3)


static func _slipstream(c: PixelCanvas) -> void:
	for k in 3:
		var y := 4 + k * 4
		c.line(2 + k, y, 11 + k, y, Color.html("d8f8ff"), 1)
		c.line(11 + k, y, 9 + k, y - 2, Color.html("d8f8ff"), 1)
	c.put(14, 8, _c(STORM, 1), 2)


static func _tempest_orb(c: PixelCanvas) -> void:
	c.ellipse(8, 8, 5, 5, _c(STORM, 3), 1)
	c.ellipse(7, 7, 3, 3, _c(STORM, 2), 2)
	c.put(6, 6, _c(STORM, 0), 3)
	c.linev(Vector2(13, 3), Vector2(15, 1), _c(STORM, 1), 3)
	c.linev(Vector2(2, 13), Vector2(0, 15), _c(STORM, 1), 3)
	c.linev(Vector2(13, 12), Vector2(15, 14), _c(STORM, 1), 3)


static func _staff(c: PixelCanvas) -> void:
	c.stroke(Vector2(3, 15), Vector2(9, 5), 1, _c(WOOD, 1), 1)


static func _flame_pulse(c: PixelCanvas) -> void:
	_staff(c)
	c.ellipse(11.5, 4.5, 3.5, 3.5, _c(FIRE, 2), 2)
	c.ellipse(11.5, 4.5, 1.8, 1.8, _c(FIRE, 0), 3)


static func _spectral_thrust(c: PixelCanvas) -> void:
	_staff(c)
	c.poly(PackedVector2Array([Vector2(9, 5), Vector2(15, 1), Vector2(12, 7)]), _c(SPEC, 1), 2)
	c.put(13, 3, _c(SPEC, 0), 3)


static func _static_gust(c: PixelCanvas) -> void:
	_staff(c)
	c.linev(Vector2(10, 4), Vector2(15, 2), _c(STORM, 1), 2)
	c.linev(Vector2(10, 5), Vector2(15, 7), _c(STORM, 1), 2)
	c.linev(Vector2(10, 4), Vector2(12, 0), _c(STORM, 0), 2)


static func _empty(c: PixelCanvas) -> void:
	c.ring(8, 8, 5, 1, Color.html("3a3450"), 1)
