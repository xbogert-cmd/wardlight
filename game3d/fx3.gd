class_name FX3
extends Node3D
## 3D pixel effects: camera-facing pixel particles (one MultiMesh), textured
## decals (ground runes, glows), jagged 1-pixel lightning lines and short-lived
## lights that actually illuminate the terrain.

static var i: FX3

const PX := 1.0 / 24.0
const MAX := 1200
const PARTICLE_SHADER := preload("res://game3d/fx_particle.gdshader")
const DECAL_SHADER := preload("res://game3d/fx_decal.gdshader")

var mm: MultiMesh
var parts: Array = []      # [pos, vel, life, max, size, grav, drag, ramp]
var decals: Array = []     # {node, life, t, s0, s1, spin, col}
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
	lm.no_depth_test = false
	lmi.material_override = lm
	lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lmi)


static func _step(ramp: Array, t: float) -> Color:
	return ramp[clampi(int(t * ramp.size()), 0, ramp.size() - 1)]


# ------------------------------------------------------------------ API
static func burst(pos: Vector3, count: int, ramp: Array, speed: Vector2, life: Vector2, opts: Dictionary = {}) -> void:
	if i == null:
		return
	var dir: Vector3 = opts.get("dir", Vector3.ZERO)
	var spread: float = opts.get("spread", PI)
	for k in count:
		if i.parts.size() >= MAX:
			return
		var v: Vector3
		if dir == Vector3.ZERO:
			v = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		else:
			v = dir.normalized().rotated(Vector3.UP, randf_range(-spread, spread) * 0.5)
			v = v.rotated(v.cross(Vector3.UP).normalized() if absf(v.y) < 0.99 else Vector3.RIGHT, randf_range(-spread, spread) * 0.25)
		v *= randf_range(speed.x, speed.y)
		var l := randf_range(life.x, life.y)
		var jit: float = opts.get("jitter", 0.0)
		var p := pos + Vector3(randf_range(-jit, jit), randf_range(-jit, jit) * 0.5, randf_range(-jit, jit))
		i.parts.append([p, v, l, l, float(opts.get("size", 1.0)), float(opts.get("gravity", 0.0)), float(opts.get("drag", 0.0)), ramp])


static func converge(center: Vector3, radius: float, count: int, ramp: Array, life: float, swirl: float = 1.0) -> void:
	if i == null:
		return
	for k in count:
		var a := randf() * TAU
		var off := Vector3(cos(a), randf_range(-0.6, 0.6), sin(a)).normalized() * radius
		var tang := Vector3(-off.z, 0, off.x) * swirl
		var v := (-off + tang * 0.6) / life
		i.parts.append([center + off, v, life, life, 1.0, 0.0, 0.0, ramp])


## Textured quad: flat on the ground (runes) or camera-facing (glows).
static func decal(tex: Texture2D, pos: Vector3, life: float, col: Color, s0: float, s1: float, spin: float = 0.0, flat: bool = true) -> MeshInstance3D:
	if i == null:
		return null
	var q := QuadMesh.new()
	q.size = Vector2(tex.get_width(), tex.get_height()) * PX
	var m := MeshInstance3D.new()
	m.mesh = q
	var mat := ShaderMaterial.new()
	mat.shader = DECAL_SHADER
	mat.set_shader_parameter(&"tex", tex)
	mat.set_shader_parameter(&"color", col)
	mat.set_shader_parameter(&"billboard", not flat)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	i.add_child(m)
	m.global_position = pos
	if flat:
		m.rotation = Vector3(-PI / 2, 0, 0)
	m.scale = Vector3.ONE * s0
	i.decals.append({"node": m, "mat": mat, "life": life, "t": 0.0, "s0": s0, "s1": s1, "spin": spin, "col": col, "flat": flat})
	return m


static func bolt(a: Vector3, b: Vector3, life: float, ramp: Array, jag: float = 0.2) -> void:
	if i:
		i.bolts.append({"a": a, "b": b, "life": life, "t": 0.0, "ramp": ramp, "jag": jag, "pts": [], "next": 0.0})


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
		var node: MeshInstance3D = d.node
		if d.t >= d.life:
			node.queue_free()
			continue
		var t: float = d.t / d.life
		node.scale = Vector3.ONE * lerpf(d.s0, d.s1, 1.0 - pow(1.0 - t, 2.0))
		if d.flat:
			node.rotation.y += d.spin * delta
		var c: Color = d.col
		(d.mat as ShaderMaterial).set_shader_parameter(&"color", Color(c, c.a * (1.0 - t * t)))
		keep.append(d)
	decals = keep
	var keep_l: Array = []
	for l: Dictionary in lights:
		l.t += delta
		var node: OmniLight3D = l.node
		if l.t >= l.life:
			node.queue_free()
			continue
		node.light_energy = l.e0 * (1.0 - l.t / l.life)
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
