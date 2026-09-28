class_name PixelCanvas
extends RefCounted
## Tiny raster helper for authoring pixel art in code.
## Every pixel also stores a region id so parts can be auto-shaded and outlined.

var w: int
var h: int
var img: Image
var reg: PackedByteArray
## Drawing offset applied to logical coordinates (put/erase/region_at).
var ox := 0
var oy := 0

const EMPTY := 0
const OUTLINE_REG := 255


func _init(width: int, height: int) -> void:
	w = width
	h = height
	img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	reg = PackedByteArray()
	reg.resize(w * h)


static func hex(s: String) -> Color:
	return Color.html(s)


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func region_at(x: int, y: int) -> int:
	x += ox
	y += oy
	return reg[y * w + x] if inside(x, y) else EMPTY


func put(x: int, y: int, c: Color, r: int = 1) -> void:
	x += ox
	y += oy
	if not inside(x, y):
		return
	if c.a < 1.0:
		var base := img.get_pixel(x, y)
		if base.a > 0.0:
			img.set_pixel(x, y, base.lerp(Color(c, 1.0), c.a))
			return
	img.set_pixel(x, y, c)
	reg[y * w + x] = r


func erase(x: int, y: int) -> void:
	x += ox
	y += oy
	if inside(x, y):
		img.set_pixel(x, y, Color(0, 0, 0, 0))
		reg[y * w + x] = EMPTY


func rect(x: int, y: int, rw: int, rh: int, c: Color, r: int = 1) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			put(xx, yy, c, r)


func line(x0: int, y0: int, x1: int, y1: int, c: Color, r: int = 1) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		put(x0, y0, c, r)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func linev(a: Vector2, b: Vector2, c: Color, r: int = 1) -> void:
	line(roundi(a.x), roundi(a.y), roundi(b.x), roundi(b.y), c, r)


## Filled convex/concave polygon via scanline (even-odd).
func poly(pts: PackedVector2Array, c: Color, r: int = 1) -> void:
	if pts.size() < 3:
		return
	var miny := INF
	var maxy := -INF
	for p in pts:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	for y in range(floori(miny), ceili(maxy) + 1):
		var sy := y + 0.5
		var xs: Array[float] = []
		for i in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		for k in range(0, xs.size() - 1, 2):
			for x in range(ceili(xs[k] - 0.5), floori(xs[k + 1] - 0.5) + 1):
				put(x, y, c, r)


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color, r: int = 1) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				put(x, y, c, r)


func ring(cx: float, cy: float, radius: float, thickness: float, c: Color, r: int = 1) -> void:
	for y in range(floori(cy - radius - 1), ceili(cy + radius) + 2):
		for x in range(floori(cx - radius - 1), ceili(cx + radius) + 2):
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if d <= radius and d > radius - thickness:
				put(x, y, c, r)


## Thick stroke: a line of square dabs.
func stroke(a: Vector2, b: Vector2, width: int, c: Color, r: int = 1) -> void:
	var n := maxi(1, ceili(a.distance_to(b)))
	var off := (width - 1) >> 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		rect(roundi(p.x) - off, roundi(p.y) - off, width, width, c, r)


## Auto-shade one region: light on silhouette edges facing up/left,
## shadow on edges facing down/right (any other region counts as occluder).
func shade(r: int, hi: Color, lo: Color, depth: int = 1, hi_depth: int = 1) -> void:
	var snap := reg.duplicate()
	for y in h:
		for x in w:
			if snap[y * w + x] != r:
				continue
			var dark := false
			for d in range(1, depth + 1):
				if _snap_at(snap, x + d, y) != r or _snap_at(snap, x, y + d) != r:
					dark = true
					break
			if dark:
				img.set_pixel(x, y, lo)
				continue
			for d in range(1, hi_depth + 1):
				if _snap_at(snap, x - d, y) == EMPTY or _snap_at(snap, x, y - d) == EMPTY:
					img.set_pixel(x, y, hi)
					break


func _snap_at(snap: PackedByteArray, x: int, y: int) -> int:
	return snap[y * w + x] if inside(x, y) else EMPTY


## Selective outline: each empty pixel touching the sprite takes a darkened
## version of its neighbour, so outlines stay tinted instead of flat black.
func outline(ink: Color, strength: float = 0.72) -> void:
	var snap := reg.duplicate()
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if snap[y * w + x] != EMPTY:
				continue
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + o.x
				var ny := y + o.y
				if inside(nx, ny) and snap[ny * w + nx] != EMPTY and snap[ny * w + nx] != OUTLINE_REG:
					img.set_pixel(x, y, src.get_pixel(nx, ny).lerp(ink, strength))
					reg[y * w + x] = OUTLINE_REG
					break


## Copy another canvas onto this one (opaque pixels only).
func stamp(o: PixelCanvas, ox: int, oy: int, flip: bool = false) -> void:
	for y in o.h:
		for x in o.w:
			var rr := o.reg[y * o.w + x]
			if rr == EMPTY:
				continue
			var tx := ox + (o.w - 1 - x if flip else x)
			put(tx - self.ox, oy + y - self.oy, o.img.get_pixel(x, y), rr)


func blit_into(dst: Image, ox: int, oy: int) -> void:
	dst.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(ox, oy))
