class_name FX3
extends Node3D
## 3D pixel effects: camera-facing pixel particles (one MultiMesh), textured
## decals (ground runes, glows), procedural pixel rings / cone arcs / dashed
## telegraph lines, jagged 1-pixel lightning lines and short-lived lights that
## actually illuminate the terrain. Speeds are m/s, sizes metres unless noted.

static var i: FX3

const PX := 1.0 / 24.0
const MAX := 1600
const PARTICLE_SHADER := preload("res://game3d/fx_particle.gdshader")
const DECAL_SHADER := preload("res://game3d/fx_decal.gdshader")
const GLOW_S := preload("res://assets/generated/glow16.png")
const GLOW_M := preload("res://assets/generated/glow32.png")
const GLOW_L := preload("res://assets/generated/glow64.png")
const RUNE_S := preload("res://assets/generated/rune24.png")
const RUNE_M := preload("res://assets/generated/rune40.png")
const RUNE_L := preload("res://assets/generated/rune64.png")

static var _top_shader: Shader
static var _mix_shader: Shader

var mm: MultiMesh
var parts: Array = []      # [pos, vel, life, max, size, grav, drag, ramp]
var decals: Array = []     # see _add_decal
var bolts: Array = []      # {a, b, life, t, ramp, jag, pts, next}
var lights: Array = []     # {node, life, t, e0}
var lines: ImmediateMesh


func _enter_tree() -> void:
	i = self


func _exit_tree() -> void:
	if i == self:
		i = null


func _ready() -> void:
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	mm.mesh = q
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var pm := ShaderMaterial.new()
	pm.shader = PARTICLE_SHADER
	mmi.material_override = pm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 16384.0
	add_child(mmi)
	lines = ImmediateMesh.new()
	var lmi := MeshInstance3D.new()
	lmi.mesh = lines
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.vertex_color_use_as_albedo = true
	lm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	lmi.material_override = lm
	lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lmi.extra_cull_margin = 16384.0
	add_child(lmi)


static func _step(ramp: Array, t: float) -> Color:
	return ramp[clampi(int(t * ramp.size()), 0, ramp.size() - 1)]


func total_particles() -> int:
	return parts.size()


# ------------------------------------------------------------------ particles
## opts: dir (Vector3), spread (rad), jitter (m), size (px), gravity (m/s²,
## negative floats up), drag.
static func burst(pos: Vector3, count: int, ramp: Array, speed: Vector2, life: Vector2, opts: Dictionary = {}) -> void:
	if i == null:
		return
	var dir: Vector3 = opts.get("dir", Vector3.ZERO)
	var spread: float = opts.get("spread", PI)
	var jit: float = opts.get("jitter", 0.0)
	for k in count:
		if i.parts.size() >= MAX:
			return
		var v: Vector3
		if dir == Vector3.ZERO:
			v = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		else:
			v = dir.normalized().rotated(Vector3.UP, randf_range(-spread, spread) * 0.5)
			var side := v.cross(Vector3.UP)
			v = v.rotated(side.normalized() if side.length() > 0.01 else Vector3.RIGHT, randf_range(-spread, spread) * 0.25)
		v *= randf_range(speed.x, speed.y)
		var l := randf_range(life.x, life.y)
		var p := pos + Vector3(randf_range(-jit, jit), randf_range(-jit, jit) * 0.5, randf_range(-jit, jit))
		i.parts.append([p, v, l, l, float(opts.get("size", 1.0)), float(opts.get("gravity", 0.0)), float(opts.get("drag", 0.0)), ramp])


static func converge(center: Vector3, radius: float, count: int, ramp: Array, life: float, swirl: float = 1.0) -> void:
	if i == null:
		return
	for k in count:
		if i.parts.size() >= MAX:
			return
		var a := randf() * TAU
		var off := Vector3(cos(a), randf_range(-0.6, 0.6), sin(a)).normalized() * radius
		var tang := Vector3(-off.z, 0, off.x) * swirl
		var v := (-off + tang * 0.6) / life
		i.parts.append([center + off, v, life, life, 1.0, 0.0, 0.0, ramp])


# ------------------------------------------------------------------ decals
static func _mat(top: bool, mix: bool = false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	if mix:
		if _mix_shader == null:
			_mix_shader = Shader.new()
			_mix_shader.code = DECAL_SHADER.code.replace("blend_add", "blend_mix")
		mat.shader = _mix_shader
	elif top:
		if _top_shader == null:
			_top_shader = Shader.new()
			_top_shader.code = DECAL_SHADER.code.replace("depth_draw_never;", "depth_draw_never, depth_test_disabled;")
		mat.shader = _top_shader
	else:
		mat.shader = DECAL_SHADER
	return mat


static func _add_decal(size: Vector2, pos: Vector3, mat: ShaderMaterial, flat: bool, entry: Dictionary) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var m := MeshInstance3D.new()
	m.mesh = q
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	i.add_child(m)
	m.global_position = pos
	if flat:
		m.rotation = Vector3(-PI / 2, 0, 0)
	entry["node"] = m
	entry["mat"] = mat
	entry["t"] = 0.0
	entry["flat"] = flat
	i.decals.append(entry)
	return m


## Textured quad: flat on the ground (runes) or camera-facing (glows).
static func decal(tex: Texture2D, pos: Vector3, life: float, col: Color, s0: float, s1: float, spin: float = 0.0, flat: bool = true, yaw: float = 0.0, mix: bool = false) -> MeshInstance3D:
	if i == null:
		return null
	var mat := _mat(false, mix)
	mat.set_shader_parameter(&"tex", tex)
	mat.set_shader_parameter(&"color", col)
	mat.set_shader_parameter(&"billboard", not flat)
	var m := _add_decal(Vector2(tex.get_width(), tex.get_height()) * PX, pos, mat, flat,
		{"kind": &"tex", "life": life, "s0": s0, "s1": s1, "spin": spin, "col": col})
	m.scale = Vector3.ONE * s0
	if flat:
		m.rotation.y = yaw
	return m


## Camera-facing smoke/cloud drawn with normal blending (dark colours show).
static func smoke(tex: Texture2D, pos: Vector3, life: float, col: Color, s0: float = 1.0, s1: float = 1.0) -> void:
	decal(tex, pos, life, col, s0, s1, 0.0, false, 0.0, true)


## Camera-facing glow (the 2D FX.sprite equivalent).
static func glow(pos: Vector3, life: float, col: Color, s0: float = 1.0, s1: float = 1.0, tex: Texture2D = GLOW_M) -> void:
	decal(tex, pos, life, col, s0, s1, 0.0, false)


## A persistent camera-facing glow node for lingering effects to carry
## (not tracked by FX3: the owner frees it).
static func make_glow(tex: Texture2D, col: Color, scale: float = 1.0) -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = DECAL_SHADER
	mat.set_shader_parameter(&"tex", tex)
	mat.set_shader_parameter(&"billboard", true)
	mat.set_shader_parameter(&"color", col)
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tex.get_width(), tex.get_height()) * PX
	m.mesh = q
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.scale = Vector3.ONE * scale
	return m


## Expanding pixel ring stepping through `ramp`. `flat` lies on the ground.
static func ring(pos: Vector3, r0: float, r1: float, life: float, ramp: Array, width_px: float = 1.0, flat: bool = true, fill: float = 0.0) -> MeshInstance3D:
	return _ring(pos, r0, r1, life, ramp, width_px, flat, fill, Vector3.ZERO, PI + 1.0, false)


## Cone sweep: a ring segment of `spread` radians around horizontal `dir`.
static func arc(pos: Vector3, r0: float, r1: float, dir: Vector3, spread: float, life: float, ramp: Array, width_px: float = 2.0) -> MeshInstance3D:
	return _ring(pos, r0, r1, life, ramp, width_px, true, 0.0, dir, spread * 0.5, false)


static func _ring(pos: Vector3, r0: float, r1: float, life: float, ramp: Array, width_px: float, flat: bool, fill: float, dir: Vector3, half: float, top: bool) -> MeshInstance3D:
	if i == null:
		return null
	var mat := _mat(top)
	var rmax := maxf(r0, r1) + 3.0 * PX + width_px * PX
	var size := Vector2(rmax, rmax) * 2.0
	mat.set_shader_parameter(&"mode", 1)
	mat.set_shader_parameter(&"billboard", not flat)
	mat.set_shader_parameter(&"size_m", size)
	mat.set_shader_parameter(&"width", width_px)
	mat.set_shader_parameter(&"fill", fill)
	mat.set_shader_parameter(&"radius", r0)
	mat.set_shader_parameter(&"color", ramp[0])
	if half < PI:
		mat.set_shader_parameter(&"half_angle", half)
		mat.set_shader_parameter(&"arc_dir", Vector2(dir.x, -dir.z))
	return _add_decal(size, pos, mat, flat, {"kind": &"ring", "life": life, "r0": r0, "r1": r1, "ramp": ramp})


## Telegraph: a pulsing ring with a faint fill, drawn over everything.
static func tele_ring(pos: Vector3, radius: float, life: float, col: Color) -> MeshInstance3D:
	var m := _ring(pos + Vector3(0, 0.04, 0), radius, radius, life, [col], 1.0, true, 0.18, Vector3.ZERO, PI + 1.0, true)
	if m:
		i.decals[-1]["kind"] = &"tele"
		i.decals[-1]["col"] = col
	return m


## Telegraph: a marching dashed (or solid) line on the ground from a to b.
static func tele_line(a: Vector3, b: Vector3, life: float, col: Color, width_px: float = 2.0, dashed: bool = true) -> MeshInstance3D:
	if i == null:
		return null
	var d := b - a
	var len := Vector2(d.x, d.z).length()
	if len < 0.05:
		return null
	var mat := _mat(true)
	var size := Vector2(len, (width_px + 1.0) * PX)
	mat.set_shader_parameter(&"mode", 2)
	mat.set_shader_parameter(&"size_m", size)
	mat.set_shader_parameter(&"width", width_px)
	mat.set_shader_parameter(&"solid_line", not dashed)
	mat.set_shader_parameter(&"color", col)
	var m := _add_decal(size, (a + b) * 0.5 + Vector3(0, 0.05, 0), mat, true, {"kind": &"line", "life": life, "col": col})
	m.rotation = Vector3(-PI / 2, -atan2(d.z, d.x), 0)
	m.rotation_order = EULER_ORDER_YXZ
	return m


## Bright pop: a camera-facing glow plus a brief real light.
static func flash(pos: Vector3, radius: float, life: float, col: Color, light_energy: float = 2.0) -> void:
	var calm := Settings.reduce_flash
	glow(pos, life, Color(col, col.a * (0.35 if calm else 1.0)), radius / 1.3, radius / 1.1, GLOW_L)
	if light_energy > 0.0:
		light(pos, col, light_energy * (0.35 if calm else 1.0), radius * 3.0, life * 1.5)


# ------------------------------------------------------------------ lines, lights
static func bolt(a: Vector3, b: Vector3, life: float, ramp: Array, jag: float = 0.2) -> void:
	if i:
		i.bolts.append({"a": a, "b": b, "life": life, "t": 0.0, "ramp": ramp, "jag": jag, "pts": [], "next": 0.0})


## A straight segment that lasts about one physics tick (projectile bodies).
static func seg(a: Vector3, b: Vector3, col: Color) -> void:
	if i:
		i.bolts.append({"a": a, "b": b, "life": 0.02, "t": 0.0, "ramp": [col], "jag": 0.0, "pts": [a, b], "next": 99.0})


static func light(pos: Vector3, col: Color, energy: float, rng: float, life: float) -> OmniLight3D:
	if i == null:
		return null
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	i.add_child(l)
	l.global_position = pos
	i.lights.append({"node": l, "life": life, "t": 0.0, "e0": energy})
	return l


# ------------------------------------------------------------------ update
func _process(delta: float) -> void:
	var alive: Array = []
	for p in parts:
		p[2] -= delta
		if p[2] <= 0.0:
			continue
		if p[6] > 0.0:
			p[1] *= maxf(0.0, 1.0 - p[6] * delta)
		p[1].y -= p[5] * delta
		p[0] += p[1] * delta
		alive.append(p)
	parts = alive
	mm.visible_instance_count = parts.size()
	for k in parts.size():
		var p: Array = parts[k]
		var s: float = p[4] * PX
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(s, s, s)), p[0]))
		mm.set_instance_color(k, _step(p[7], 1.0 - p[2] / p[3]))
	var keep: Array = []
	for d: Dictionary in decals:
		d.t += delta
		if not is_instance_valid(d.node):
			continue
		var node: MeshInstance3D = d.node
		if d.t >= d.life:
			node.queue_free()
			continue
		var t: float = d.t / d.life
		var mat: ShaderMaterial = d.mat
		match d.kind:
			&"tex":
				node.scale = Vector3.ONE * lerpf(d.s0, d.s1, 1.0 - pow(1.0 - t, 2.0))
				if d.flat:
					node.rotation.y += d.spin * delta
				var c: Color = d.col
				mat.set_shader_parameter(&"color", Color(c, c.a * (1.0 - t * t)))
			&"ring":
				mat.set_shader_parameter(&"radius", lerpf(d.r0, d.r1, 1.0 - pow(1.0 - t, 2.0)))
				mat.set_shader_parameter(&"color", _step(d.ramp, t))
			&"tele":
				var c2: Color = d.col
				var pulse := 0.65 + 0.35 * (1.0 if int(d.t * 12.0) % 2 == 0 else 0.0)
				mat.set_shader_parameter(&"color", Color(c2, c2.a * pulse))
			&"line":
				mat.set_shader_parameter(&"dash_phase", -floorf(d.t * 24.0))
		keep.append(d)
	decals = keep
	var keep_l: Array = []
	for l: Dictionary in lights:
		l.t += delta
		var ln: OmniLight3D = l.node
		if l.t >= l.life:
			ln.queue_free()
			continue
		ln.light_energy = l.e0 * (1.0 - l.t / l.life)
		keep_l.append(l)
	lights = keep_l
	_draw_bolts(delta)


func _draw_bolts(delta: float) -> void:
	lines.clear_surfaces()
	var keep: Array = []
	for b: Dictionary in bolts:
		b.t += delta
		if b.t >= b.life:
			continue
		keep.append(b)
		b.next -= delta
		if b.next <= 0.0:
			b.next = 0.035
			b.pts = _jag(b.a, b.b, b.jag)
	bolts = keep
	if bolts.is_empty():
		return
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for b: Dictionary in bolts:
		var c := _step(b.ramp, b.t / b.life)
		var pts: Array = b.pts
		for k in pts.size() - 1:
			lines.surface_set_color(c)
			lines.surface_add_vertex(pts[k])
			lines.surface_set_color(c)
			lines.surface_add_vertex(pts[k + 1])
			# faint doubled strand for thickness
			lines.surface_set_color(Color(c, 0.4))
			lines.surface_add_vertex(pts[k] + Vector3(0, PX, 0))
			lines.surface_set_color(Color(c, 0.4))
			lines.surface_add_vertex(pts[k + 1] + Vector3(0, PX, 0))
	lines.surface_end()


static func _jag(a: Vector3, b: Vector3, jag: float) -> Array:
	var out := [a]
	var d := b - a
	var n := maxi(2, int(d.length() / 0.3))
	for k in range(1, n):
		out.append(a + d * (float(k) / n) + Vector3(randf_range(-jag, jag), randf_range(-jag, jag), randf_range(-jag, jag)))
	out.append(b)
	return out
