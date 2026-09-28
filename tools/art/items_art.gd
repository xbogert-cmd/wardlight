extends RefCounted
## 16×16 item icons in one strip, in Items.DEFS "icon" order:
## 0 crook, 1 stormcoil, 2 cinderbrand, 3 gravewood, 4 wanderer robe,
## 5 wardweave, 6 mistcloak, 7 ember seed, 8 stormglass, 9 whisper bone,
## 10 gale feather, 11 moonstone, 12 ward bell, 13 coin.

const N := 14


static func _c(s: String) -> Color:
	return Color.html(s)


static func build() -> Image:
	var img := Image.create_empty(16 * N, 16, false, Image.FORMAT_RGBA8)
	for k in N:
		var c := PixelCanvas.new(16, 16)
		_draw(c, k)
		c.outline(_c("0e0a14"), 0.85)
		c.blit_into(img, k * 16, 0)
	return img


static func _staff(c: PixelCanvas, wood: String, gem: String, fork: bool) -> void:
	c.line(3, 14, 11, 4, _c(wood), 1)
	c.line(4, 14, 12, 4, Color.html(wood).darkened(0.3), 1)
	if fork:
		c.line(11, 4, 10, 1, _c(wood), 1)
		c.line(12, 4, 14, 2, _c(wood), 1)
	c.rect(11, 2, 3, 3, _c(gem), 2)
	c.put(11, 2, Color.WHITE, 2)


static func _robe(c: PixelCanvas, main: String, trim: String) -> void:
	c.poly(PackedVector2Array([Vector2(5, 2), Vector2(11, 2), Vector2(13, 14), Vector2(3, 14)]), _c(main), 1)
	c.rect(7, 2, 2, 12, _c(trim), 2)
	c.rect(3, 13, 11, 1, _c(trim), 2)
	c.shade(1, Color.html(main).lightened(0.25), Color.html(main).darkened(0.35), 1)


static func _draw(c: PixelCanvas, k: int) -> void:
	match k:
		0: _staff(c, "a8703e", "4cc8f4", false)
		1: _staff(c, "6a5a6e", "b4f6ff", false)
		2: _staff(c, "8a4a2a", "ff8a24", true)
		3: _staff(c, "4a3a48", "8affc8", true)
		4: _robe(c, "a53132", "f4cf66")
		5: _robe(c, "3449a6", "e2e5f5")
		6: _robe(c, "3a6c45", "d4ac68")
		7:
			c.ellipse(8, 9, 4, 5, _c("7a3a1c"), 1)
			c.poly(PackedVector2Array([Vector2(8, 2), Vector2(10, 6), Vector2(6, 6)]), _c("ffb030"), 2)
			c.put(8, 4, _c("fff0a0"), 2)
			c.shade(1, _c("a85a2a"), _c("4a2010"), 1)
		8:
			c.poly(PackedVector2Array([Vector2(8, 1), Vector2(13, 8), Vector2(8, 15), Vector2(3, 8)]), _c("52cfff"), 1)
			c.line(8, 3, 8, 12, _c("ffffff"), 2)
			c.shade(1, _c("b4f6ff"), _c("3a78f0"), 1)
		9:
			c.stroke(Vector2(3, 12), Vector2(12, 4), 2, _c("e8e0d0"), 1)
			c.ellipse(3, 12, 2, 2, _c("e8e0d0"), 1)
			c.ellipse(12, 4, 2, 2, _c("e8e0d0"), 1)
			c.put(8, 8, _c("8affc8"), 2)
			c.shade(1, _c("ffffff"), _c("a89888"), 1)
		10:
			c.poly(PackedVector2Array([Vector2(3, 14), Vector2(12, 2), Vector2(13, 5), Vector2(6, 13)]), _c("d8f0ff"), 1)
			c.line(3, 14, 12, 3, _c("8ab0c8"), 2)
			c.shade(1, _c("ffffff"), _c("8ab0c8"), 1)
		11:
			c.ellipse(8, 8, 5, 5, _c("c8c8f0"), 1)
			c.ellipse(6, 7, 2, 2, _c("ffffff"), 2)
			c.shade(1, _c("f0f0ff"), _c("7a78b0"), 1)
		12:
			c.poly(PackedVector2Array([Vector2(8, 2), Vector2(12, 11), Vector2(4, 11)]), _c("d8b060"), 1)
			c.rect(3, 11, 10, 2, _c("a88840"), 1)
			c.put(8, 14, _c("f0d890"), 2)
			c.shade(1, _c("f8e0a0"), _c("8a6a30"), 1)
		13:
			c.ellipse(8, 8, 4, 4, _c("f0c850"), 1)
			c.rect(7, 6, 2, 4, _c("a88830"), 2)
			c.shade(1, _c("fff0a0"), _c("a88830"), 1)
