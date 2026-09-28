class_name FX
extends Node2D
## Pixel effect layer: particles, rings, flashes, lightning and textured
## sprites. Four canvases split effects behind/in front of actors and
## additive/normal blending. Danger telegraphs use `tele`, which always
## draws above everything decorative.

static var i: FX

const Z_BACK := -5
const Z_FRONT := 8
const Z_TELE := 30

var back_mix: FXCanvas
var back_add: FXCanvas
var front_mix: FXCanvas
var front_add: FXCanvas
var tele: FXCanvas

var max_particles := 900


func _enter_tree() -> void:
	i = self


func _exit_tree() -> void:
	if i == self:
		i = null


func _ready() -> void:
	back_mix = _canvas(Z_BACK, false)
	back_add = _canvas(Z_BACK + 1, true)
	front_mix = _canvas(Z_FRONT, false)
	front_add = _canvas(Z_FRONT + 1, true)
	tele = _canvas(Z_TELE, false)


func _canvas(z: int, additive: bool) -> FXCanvas:
	var c := FXCanvas.new()
	c.z_index = z
	c.z_as_relative = false
	c.owner_fx = self
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		c.material = m
	add_child(c)
	return c


func pick(front: bool, additive: bool) -> FXCanvas:
	if front:
		return front_add if additive else front_mix
	return back_add if additive else back_mix


func total_particles() -> int:
	return back_mix.parts.size() + back_add.parts.size() + front_mix.parts.size() + front_add.parts.size()


# ------------------------------------------------------------------ helpers
## Spray of particles. opts: dir (Vector2), spread (rad), size, gravity, drag,
## front (bool), add (bool), glow (bool), jitter (spawn radius).
static func burst(pos: Vector2, count: int, ramp: Array, speed: Vector2, life: Vector2, opts: Dictionary = {}) -> void:
	if i == null:
		return
	var c := i.pick(opts.get("front", true), opts.get("add", true))
	var dir: Vector2 = opts.get("dir", Vector2.ZERO)
	var spread: float = opts.get("spread", TAU)
	var base_ang := dir.angle() if dir != Vector2.ZERO else 0.0
	var jitter: float = opts.get("jitter", 0.0)
	for k in count:
		if i.total_particles() >= i.max_particles:
			return
		var a := base_ang + randf_range(-spread * 0.5, spread * 0.5)
		var sp := randf_range(speed.x, speed.y)
		var p := pos + Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
		c.add_particle(p, Vector2.from_angle(a) * sp, randf_range(life.x, life.y), ramp,
			opts.get("size", 1), opts.get("gravity", 0.0), opts.get("drag", 0.0), opts.get("glow", false))


## Particles that start on a circle and rush inward (spell gathering).
static func converge(center: Vector2, radius: float, count: int, ramp: Array, life: float, opts: Dictionary = {}) -> void:
	if i == null:
		return
	var c := i.pick(opts.get("front", true), true)
	for k in count:
		var a := randf() * TAU
		var r := radius * randf_range(0.7, 1.0)
		var p := center + Vector2.from_angle(a) * r
		var tangent: Vector2 = Vector2.from_angle(a + PI / 2) * r * 1.6 * opts.get("swirl", 1.0)
		var v: Vector2 = (center - p) / life + tangent * 0.6
		c.add_particle(p, v, life * randf_range(0.8, 1.0), ramp, opts.get("size", 1), 0.0, 0.0, true)


static func ring(pos: Vector2, r0: float, r1: float, life: float, ramp: Array, width: float = 1.0, front: bool = false) -> void:
	if i:
		i.pick(front, true).shapes.append({"k": "ring", "p": pos, "r0": r0, "r1": r1, "t": 0.0, "life": life, "ramp": ramp, "w": width})


## Crescent / cone sweep: an arc of radius r0→r1 spanning `spread` radians around `ang`.
static func arc(pos: Vector2, r0: float, r1: float, ang: float, spread: float, life: float, ramp: Array, width: float = 2.0, front: bool = true) -> void:
	if i:
		i.pick(front, true).shapes.append({"k": "arc", "p": pos, "r0": r0, "r1": r1, "a": ang, "s": spread, "t": 0.0, "life": life, "ramp": ramp, "w": width})


static func flash(pos: Vector2, radius: float, life: float, col: Color, front: bool = true) -> void:
	if i == null:
		return
	if Settings.reduce_flash:
		radius = minf(radius, 8.0)
		col.a *= 0.5
	i.pick(front, true).shapes.append({"k": "flash", "p": pos, "r": radius, "t": 0.0, "life": life, "c": col})


## Jagged lightning between two points; re-jags every few frames.
static func bolt(a: Vector2, b: Vector2, life: float, ramp: Array, jag: float = 4.0, width: float = 1.0, front: bool = true, branches: int = 0) -> void:
	if i:
		i.pick(front, true).shapes.append({"k": "bolt", "a": a, "b": b, "t": 0.0, "life": life, "ramp": ramp, "jag": jag,
			"w": width, "pts": PackedVector2Array(), "next": 0.0, "br": branches})


## Textured sprite (glow, rune circle) that can grow, spin and fade.
static func sprite(tex: Texture2D, pos: Vector2, life: float, col: Color, s0: float = 1.0, s1: float = 1.0, spin: float = 0.0, front: bool = false, add: bool = true, rot: float = 0.0) -> Dictionary:
	if i == null:
		return {}
	var d := {"k": "sprite", "tex": tex, "p": pos, "t": 0.0, "life": life, "c": col, "s0": s0, "s1": s1, "spin": spin, "rot": rot}
	i.pick(front, add).shapes.append(d)
	return d


## Ground-mark style telegraph (always above decorative effects).
static func tele_mark(pos: Vector2, width: float, life: float, col: Color) -> void:
	if i:
		i.tele.shapes.append({"k": "mark", "p": pos, "w": width, "t": 0.0, "life": life, "c": col})


static func tele_ring(pos: Vector2, radius: float, life: float, col: Color) -> void:
	if i:
		i.tele.shapes.append({"k": "tring", "p": pos, "r": radius, "t": 0.0, "life": life, "c": col})


static func tex(path: String) -> Texture2D:
	return load("res://assets/generated/" + path)


# ------------------------------------------------------------------ canvas
class FXCanvas extends Node2D:
	var owner_fx: FX
	## particle: [x, y, vx, vy, life, max, size, grav, drag, ramp, glow]
	var parts: Array = []
	var shapes: Array = []

	func add_particle(p: Vector2, v: Vector2, life: float, ramp: Array, size: int, grav: float, drag: float, glow: bool) -> void:
		parts.append([p.x, p.y, v.x, v.y, life, life, size, grav, drag, ramp, glow])

	func _process(delta: float) -> void:
		var alive: Array = []
		for p in parts:
			p[4] -= delta
			if p[4] <= 0.0:
				continue
			if p[8] > 0.0:
				var f := maxf(0.0, 1.0 - p[8] * delta)
				p[2] *= f
				p[3] *= f
			p[3] += p[7] * delta
			p[0] += p[2] * delta
			p[1] += p[3] * delta
			alive.append(p)
		parts = alive
		var keep: Array = []
		for s: Dictionary in shapes:
			s.t += delta
			if s.t < s.life:
				keep.append(s)
				if s.k == "bolt":
					s.next -= delta
					if s.next <= 0.0:
						s.next = 0.035
						s.pts = _jag(s.a, s.b, s.jag)
				elif s.k == "sprite":
					s.rot += s.spin * delta
		shapes = keep
		queue_redraw()

	static func _step(ramp: Array, t: float) -> Color:
		var idx := clampi(int(t * ramp.size()), 0, ramp.size() - 1)
		return ramp[idx]

	func _draw() -> void:
		for p in parts:
			var t: float = 1.0 - p[4] / p[5]
			var c := _step(p[9], t)
			var x := roundf(p[0])
			var y := roundf(p[1])
			var s: int = p[6]
			if p[10]:
				draw_rect(Rect2(x - 1, y - 1, s + 2, s + 2), Color(c, c.a * 0.3))
			draw_rect(Rect2(x, y, s, s), c)
		for s: Dictionary in shapes:
			var t: float = s.t / s.life
			match s.k:
				"ring":
					var r := lerpf(s.r0, s.r1, 1.0 - pow(1.0 - t, 2.0))
					draw_arc((s.p as Vector2).round(), roundf(r), 0, TAU, maxi(12, int(r * 1.5)), _step(s.ramp, t), s.w)
				"arc":
					var r := lerpf(s.r0, s.r1, 1.0 - pow(1.0 - t, 2.0))
					var c := _step(s.ramp, t)
					var half: float = s.s * 0.5
					draw_arc((s.p as Vector2).round(), roundf(r), s.a - half, s.a + half, maxi(8, int(r * s.s)), Color(c, 0.35), s.w + 2.0)
					draw_arc((s.p as Vector2).round(), roundf(r), s.a - half * 0.8, s.a + half * 0.8, maxi(8, int(r * s.s)), c, s.w)
				"flash":
					var c: Color = s.c
					draw_circle((s.p as Vector2).round(), roundf(s.r * (1.0 - t * 0.5)), Color(c, c.a * (1.0 - t)))
				"bolt":
					if (s.pts as PackedVector2Array).size() > 1:
						var c := _step(s.ramp, t)
						draw_polyline(s.pts, Color(c, 0.35), s.w + 2.0)
						draw_polyline(s.pts, c, s.w)
						if s.br > 0 and s.pts.size() > 3:
							var k: int = s.pts.size() / 2
							var start: Vector2 = s.pts[k]
							var bend := ((s.b as Vector2) - (s.a as Vector2)).normalized().rotated(randf_range(-1.0, 1.0)) * 10.0
							draw_polyline(_jag(start, start + bend, 2.0), Color(c, 0.8), 1.0)
				"sprite":
					var tx: Texture2D = s.tex
					var sc := lerpf(s.s0, s.s1, 1.0 - pow(1.0 - t, 2.0))
					var c: Color = s.c
					draw_set_transform((s.p as Vector2).round(), s.rot, Vector2(sc, sc))
					draw_texture(tx, -tx.get_size() * 0.5, Color(c, c.a * (1.0 - t * t)))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"mark":
					# blinking chevrons on the ground
					if int(s.t * 12.0) % 2 == 0:
						var c: Color = s.c
						var p: Vector2 = (s.p as Vector2).round()
						var hw: float = s.w * 0.5
						draw_rect(Rect2(p.x - hw, p.y - 1, s.w, 1), c)
						for k in 3:
							var cx: float = p.x - hw + (k + 0.5) * s.w / 3.0
							draw_line(Vector2(cx - 3, p.y - 5), Vector2(cx, p.y - 2), c, 1.0)
							draw_line(Vector2(cx + 3, p.y - 5), Vector2(cx, p.y - 2), c, 1.0)
				"tring":
					var c: Color = s.c
					var fill := Color(c, 0.12 + 0.18 * t)
					draw_circle((s.p as Vector2).round(), s.r, fill)
					draw_arc((s.p as Vector2).round(), s.r, 0, TAU, 32, Color(c, 0.9), 1.0)
					draw_arc((s.p as Vector2).round(), s.r * t, 0, TAU, 24, Color(c, 0.7), 1.0)

	static func _jag(a: Vector2, b: Vector2, jag: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		var d := b - a
		var n := maxi(2, int(d.length() / 6.0))
		var perp := d.normalized().orthogonal()
		out.append(a.round())
		for k in range(1, n):
			var p := a + d * (float(k) / n) + perp * randf_range(-jag, jag)
			out.append(p.round())
		out.append(b.round())
		return out
