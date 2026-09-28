class_name Crossing
extends Node3D
## Briarwood Crossing: a plateau road over a stream, a ruined rune arch with a
## brazier, lantern posts and fences, and a cliff edge above a misty valley
## with a distant castle. Everything is built here in code from generated
## pixel art. For now it doubles as the combat proving ground (all enemy
## roles); stage 3 turns it into part of the Briarwood region.

signal player_respawned

const ENEMIES := {
	&"hound": [preload("res://game/enemies/hound.gd"), preload("res://data/enemies/hound.tres")],
	&"raider": [preload("res://game/enemies/raider.gd"), preload("res://data/enemies/raider.tres")],
	&"hexer": [preload("res://game/enemies/hexer.gd"), preload("res://data/enemies/hexer.tres")],
	&"knot": [preload("res://game/enemies/knot.gd"), preload("res://data/enemies/knot.tres")],
	&"sentinel": [preload("res://game/enemies/sentinel.gd"), preload("res://data/enemies/sentinel.tres")],
}
## [kind, x, z]
const SPAWNS := [
	[&"hound", 9.0, -4.0], [&"hound", 13.0, 1.0],
	[&"raider", 19.0, -6.5], [&"hexer", 22.0, -4.0],
	[&"knot", -14.0, 4.5],
	[&"sentinel", 24.0, -11.5],
]

const D := "res://assets/generated/w3d/"
const PROP_SHADER := preload("res://game3d/prop.gdshader")
const WATER_SHADER := preload("res://game3d/water.gdshader")

var noise := FastNoiseLite.new()
var terrain: HeightTerrain
var player: Player
var cam: GameCamera3D
var spawn_point := Vector3.ZERO
var checkpoint := Vector3.ZERO
var display_name := "Briarwood Crossing"
var fader := OcclusionFader.new()
var road := [Vector2(-26, 20), Vector2(-15, 11), Vector2(-7, 5), Vector2(1, 1), Vector2(6.5, -1.5), Vector2(13, -5), Vector2(20, -9), Vector2(28, -12)]
var side_path := [Vector2(-7, 5), Vector2(-11, 1), Vector2(-15.5, -2.2)]
var stream := [Vector2(27, 21), Vector2(15, 9), Vector2(7, 1.8), Vector2(3.8, -0.5), Vector2(2.0, -6), Vector2(0.8, -12), Vector2(0.3, -17.5)]
var ruins := Vector2(-17, -3)
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 4242
	noise.seed = 7
	noise.frequency = 0.08
	_environment()
	terrain = HeightTerrain.new()
	terrain.origin = Vector2(-50, -90)
	terrain.nx = 100
	terrain.nz = 122
	add_child(terrain)
	terrain.build(_height, _splat)
	add_child(FX3.new())
	_water()
	_bridge()
	_ruins()
	_lanterns_and_fences()
	_trees()
	_scenery()
	_valley()
	_bounds()
	spawn_point = _ground(-5, 6)
	checkpoint = spawn_point
	cam = GameCamera3D.new()
	add_child(cam)
	add_child(fader)
	_spawn_enemies()


func enter(p: Player) -> void:
	player = p
	if p.get_parent():
		p.reparent(self)
	else:
		add_child(p)
	p.global_position = spawn_point
	cam.target = p
	fader.target = p
	cam.snap()
	if not p.died.is_connected(_on_player_died):
		p.died.connect(_on_player_died)
	Sfx.music("explore")


func _spawn_enemies() -> void:
	for s in SPAWNS:
		var def: Array = ENEMIES[s[0]]
		var e: Enemy = def[0].new()
		e.data = def[1]
		add_child(e)
		e.global_position = _ground(s[1], s[2])


func _on_player_died() -> void:
	await get_tree().create_timer(1.6).timeout
	# checkpoint: restore health/mana and reset the encounter
	for e in get_tree().get_nodes_in_group(&"enemy"):
		e.queue_free()
	for n in get_children():
		if n is Projectile or n is EmberPatch or n is Knot.ThornPatch:
			n.queue_free()
	await get_tree().process_frame
	_spawn_enemies()
	player.respawn_at(checkpoint)
	cam.snap()
	player_respawned.emit()


# ------------------------------------------------------------------ shape
static func _gauss(dx: float, dz: float, r: float) -> float:
	return exp(-(dx * dx + dz * dz) / (r * r))


static func _dist_poly(p: Vector2, pts: Array) -> float:
	var best := INF
	for k in pts.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pts[k], pts[k + 1])))
	return best


func _cliff_z(x: float) -> float:
	return -16.0 + 1.8 * sin(x * 0.17) + 0.8 * sin(x * 0.41 + 1.0)


func _height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var hills := 2.4 * _gauss(x - ruins.x, z - ruins.y, 6.5) + 1.4 * _gauss(x - 18, z + 5, 5.5) + 0.9 * _gauss(x + 3, z - 15, 5.0)
	# a steep-sided rock shelf (natural high ground) east of the bridge
	var shelf := smoothstep(0.9, 0.0, maxf(absf(x - 21.5) - 2.2, 0.0)) * smoothstep(0.9, 0.0, maxf(absf(z + 3.5) - 1.8, 0.0))
	var h := hills + noise.get_noise_2d(x, z) * 0.35 + shelf * 1.6
	var rd := minf(_dist_poly(p, road), _dist_poly(p, side_path))
	h = lerpf(hills * 0.8 + shelf * 1.6, h, clampf((rd - 1.4) / 1.6, 0.0, 1.0))
	var sd := _dist_poly(p, stream)
	h -= 1.5 * smoothstep(2.5, 0.9, sd)
	var zc := _cliff_z(x)
	if z < zc:
		var t := clampf((zc - z) / 2.2, 0.0, 1.0)
		var valley := -24.0 + noise.get_noise_2d(x * 0.5, z * 0.5) * 4.0 - (zc - z) * 0.05 + 6.0 * _gauss(x + 16, z + 40, 9.0)
		h = lerpf(h, valley, smoothstep(0.0, 1.0, t))
	return h


func _splat(x: float, z: float) -> Color:
	var p := Vector2(x, z)
	var r := 1.0 - smoothstep(1.45, 1.75, _dist_poly(p, road))
	var g := 1.0 - smoothstep(0.9, 1.5, _dist_poly(p, side_path))
	g = maxf(g, 1.0 - smoothstep(2.5, 4.0, p.distance_to(ruins)))
	var sd := _dist_poly(p, stream)
	g = maxf(g, smoothstep(2.8, 1.6, sd) * 0.9)
	g = maxf(g, (1.0 - smoothstep(1.8, 2.6, _dist_poly(p, road))) * 0.45)
	return Color(r, g, 0, 1)


func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, terrain.height_at(x, z), z)


# ------------------------------------------------------------------ building blocks
func _box(size: Vector3, pos: Vector3, tex: String, rot := Vector3.ZERO, solid := true, tint := Color.WHITE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := ShaderMaterial.new()
	mat.shader = PROP_SHADER
	mat.set_shader_parameter(&"tex", load(D + tex))
	mat.set_shader_parameter(&"tint", tint)
	m.material_override = mat
	add_child(m)
	m.global_position = pos
	m.rotation = rot
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		m.add_child(body)
	return m


func _bill(tex: Texture2D, pos: Vector3, scale := 1.0, region := Rect2()) -> PixelBillboard:
	var b: PixelBillboard
	if region.size != Vector2.ZERO:
		b = PixelBillboard.new()
		b.setup(tex, Vector2i(region.size), 1, {}, Vector2(region.size.x * 0.5, region.size.y))
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		b.mat.set_shader_parameter(&"region", Vector4(region.position.x / tw, region.position.y / th, region.size.x / tw, region.size.y / th))
	else:
		b = PixelBillboard.still(tex)
	add_child(b)
	b.global_position = pos
	b.scale = Vector3.ONE * scale
	return b


func _light(pos: Vector3, col: Color, energy: float, rng_m: float, flicker := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.1
	add_child(l)
	l.global_position = pos
	if flicker:
		var tw := l.create_tween().set_loops()
		tw.tween_property(l, "light_energy", energy * 0.8, 0.13)
		tw.tween_property(l, "light_energy", energy * 1.05, 0.09)
		tw.tween_property(l, "light_energy", energy * 0.9, 0.17)
		tw.tween_property(l, "light_energy", energy, 0.11)
	return l


# ------------------------------------------------------------------ scene
func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.26, 0.26, 0.42)
	env.ambient_light_energy = 0.62
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.2, 0.22, 0.36)
	env.fog_density = 0.002
	env.fog_height = -10.0
	env.fog_height_density = 0.07
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.85
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.62, 0.68, 1.0)
	moon.light_energy = 0.42
	moon.rotation_degrees = Vector3(-48, 35, 0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 70.0
	add_child(moon)


func _water() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for k in stream.size() - 1:
		var a: Vector2 = stream[k]
		var b: Vector2 = stream[k + 1]
		var n := maxi(1, int(a.distance_to(b) / 0.5))
		for j in n:
			pts.append(a.lerp(b, float(j) / n))
	var y := -0.95
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		if b.y < _cliff_z(b.x) + 0.3:
			break
		var n := (b - a).normalized().orthogonal() * 1.4
		var v := [Vector3(a.x + n.x, y, a.y + n.y), Vector3(a.x - n.x, y, a.y - n.y), Vector3(b.x + n.x, y, b.y + n.y), Vector3(b.x - n.x, y, b.y - n.y)]
		st.set_normal(Vector3.UP)
		for idx in [0, 2, 1, 1, 2, 3]:
			st.add_vertex(v[idx])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter(&"tex", load(D + "water.png"))
	mat.set_shader_parameter(&"flow", Vector2(0.25, -0.55))
	mi.material_override = mat
	add_child(mi)
	# the stream pours over the cliff edge: foam at the lip, mist rising from below
	var ex := 0.35
	var ez := _cliff_z(ex) + 0.5
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(func() -> void:
		FX3.burst(Vector3(ex + randf_range(-1.0, 1.0), y + 0.1, ez), 1, [Color("e8f4ff", 0.8), Color("a8c8e0", 0.6), Color("6a8aa8", 0.4)],
			Vector2(0.5, 1.5), Vector2(0.3, 0.6), {"dir": Vector3(0, 0.3, -1), "spread": 0.6, "gravity": 3.0})
		FX3.burst(Vector3(ex + randf_range(-2.5, 2.5), y - randf_range(1.0, 4.0), ez - randf_range(1.0, 3.0)), 1,
			[Color("c8d8f0", 0.35), Color("a0b0d0", 0.25), Color("8090b0", 0.15)], Vector2(0.2, 0.6), Vector2(1.2, 2.2), {"dir": Vector3.UP, "spread": 1.0, "size": 2.0}))
	add_child(t)


func _bridge() -> void:
	var c := Vector2(3.8, -0.4)
	var dir := (Vector2(6.5, -1.5) - Vector2(1, 1)).normalized()
	var ang := -dir.angle()
	var top := 0.28
	var center := Vector3(c.x, top - 0.15, c.y)
	_box(Vector3(6.2, 0.3, 2.3), center, "wood.png", Vector3(0, ang, 0))
	var side := Vector2(-dir.y, dir.x)
	for s in [-1.0, 1.0]:
		for k in [-2.6, -0.9, 0.9, 2.6]:
			var p: Vector2 = c + dir * k + side * 1.05 * s
			_box(Vector3(0.18, 1.1, 0.18), Vector3(p.x, top + 0.45, p.y), "wood.png", Vector3(0, ang, 0), false)
		var rp: Vector2 = c + side * 1.05 * s
		_box(Vector3(5.6, 0.12, 0.12), Vector3(rp.x, top + 0.9, rp.y), "wood.png", Vector3(0, ang, 0), false)
		_box(Vector3(5.6, 0.1, 0.1), Vector3(rp.x, top + 0.5, rp.y), "wood.png", Vector3(0, ang, 0), false)


func _ruins() -> void:
	var base := terrain.height_at(ruins.x, ruins.y - 0.8)
	# rune arch, lintel slipped slightly
	_box(Vector3(0.9, 3.8, 0.9), Vector3(ruins.x - 1.7, base + 1.7, ruins.y - 0.8), "bricks.png")
	_box(Vector3(0.9, 3.4, 0.9), Vector3(ruins.x + 1.7, base + 1.5, ruins.y - 0.8), "bricks.png")
	_box(Vector3(4.4, 0.8, 1.0), Vector3(ruins.x, base + 3.55, ruins.y - 0.8), "bricks.png", Vector3(0, 0, deg_to_rad(-4)), false)
	_box(Vector3(1.2, 1.4, 0.2), Vector3(ruins.x, base + 2.4, ruins.y - 0.8), "rune_bricks.png", Vector3.ZERO, false, Color(1.0, 0.95, 1.1))
	# standing stones and broken walls
	for s: Array in [[Vector2(-21, -0.2), Vector3(0.8, 2.4, 0.5), 10.0], [Vector2(-12.8, 0.6), Vector3(0.8, 2.0, 0.5), -14.0],
			[Vector2(-19.5, -6.0), Vector3(3.0, 1.2, 0.7), 5.0], [Vector2(-13.8, -6.4), Vector3(2.2, 0.8, 0.7), -8.0]]:
		var p: Vector2 = s[0]
		var sz: Vector3 = s[1]
		_box(sz, _ground(p.x, p.y) + Vector3(0, sz.y * 0.5 - 0.1, 0), "rune_bricks.png" if sz.y > 1.5 else "bricks.png", Vector3(0, deg_to_rad(s[2]), deg_to_rad(s[2] * 0.3)))
	# brazier: stone bowl, living flame, warm light, drifting embers
	var bp := _ground(-15.2, -0.6)
	_box(Vector3(0.7, 0.8, 0.7), bp + Vector3(0, 0.4, 0), "bricks.png")
	_box(Vector3(1.0, 0.18, 1.0), bp + Vector3(0, 0.88, 0), "rock.png", Vector3.ZERO, false)
	var fl := PixelBillboard.new()
	fl.setup(load(D + "flames.png"), Vector2i(16, 20), 4, {"burn": {"frames": [0, 1, 2, 3], "fps": 10.0, "loop": true}}, Vector2(8, 20))
	add_child(fl)
	fl.global_position = bp + Vector3(0, 0.95, 0)
	fl.play(&"burn")
	fl.mat.set_shader_parameter(&"emit", 1.2)
	_light(bp + Vector3(0, 1.6, 0), Color(1.0, 0.5, 0.2), 4.0, 8.0)
	var t := Timer.new()
	t.wait_time = 0.12
	t.autostart = true
	t.timeout.connect(func() -> void:
		FX3.burst(bp + Vector3(0, 1.3, 0), 2, Pal.school(&"fire"), Vector2(0.3, 1.0), Vector2(0.6, 1.2), {"dir": Vector3.UP, "spread": 0.8, "gravity": -0.6}))
	add_child(t)


func _lanterns_and_fences() -> void:
	for lp: Array in [[Vector2(8.6, 0.9), 1.0], [Vector2(16.4, -3.2), 1.0], [Vector2(-9.5, 8.4), -1.0], [Vector2(-1.5, 4.2), 1.0]]:
		var p: Vector2 = lp[0]
		var g := _ground(p.x, p.y)
		_box(Vector3(0.2, 3.0, 0.2), g + Vector3(0, 1.5, 0), "wood.png", Vector3.ZERO, true)
		_box(Vector3(0.9, 0.12, 0.12), g + Vector3(0.4 * lp[1], 2.9, 0), "wood.png", Vector3.ZERO, false)
		var lan := _bill(load(D + "lantern.png"), g + Vector3(0.8 * lp[1], 2.25, 0))
		lan.mat.set_shader_parameter(&"emit", 1.0)
		_light(g + Vector3(0.8 * lp[1], 2.2, 0.3), Color(1.0, 0.56, 0.24), 3.0, 6.5)
	# fence along the north side of the road beyond the bridge
	var a := Vector2(7.6, -3.6)
	var b := Vector2(18.5, -9.5)
	var n := 7
	var prev := Vector3.ZERO
	for k in n + 1:
		var p := a.lerp(b, float(k) / n)
		var g := _ground(p.x, p.y)
		_box(Vector3(0.18, 1.2, 0.18), g + Vector3(0, 0.5, 0), "wood.png", Vector3(0, 0, deg_to_rad(rng.randf_range(-6, 6))))
		if k > 0:
			var mid := (prev + g) * 0.5
			var d := g - prev
			var yaw := -atan2(d.z, d.x)
			var len := Vector2(d.x, d.z).length()
			_box(Vector3(len, 0.1, 0.1), mid + Vector3(0, 0.85, 0), "wood.png", Vector3(0, yaw, atan2(d.y, len)), false)
			_box(Vector3(len, 0.09, 0.09), mid + Vector3(0, 0.45, 0), "wood.png", Vector3(0, yaw, atan2(d.y, len)), false)
		prev = g
	# banner post
	var bpnt := _ground(11.2, -6.6)
	_box(Vector3(0.22, 3.6, 0.22), bpnt + Vector3(0, 1.8, 0), "wood.png")
	_box(Vector3(1.0, 0.14, 0.14), bpnt + Vector3(0.4, 3.45, 0), "wood.png", Vector3.ZERO, false)
	_bill(load(D + "banner.png"), bpnt + Vector3(0.75, 1.55, 0.05))


func _clear_of_paths(p: Vector2, margin: float) -> bool:
	return _dist_poly(p, road) > margin and _dist_poly(p, stream) > margin - 0.5 and _dist_poly(p, side_path) > margin - 1.0 \
		and p.distance_to(ruins) > 5.5 and p.distance_to(Vector2(-5, 6)) > 4.0


func _trees() -> void:
	var kinds := ["pine_a.png", "pine_b.png", "oak.png", "dead_tree.png", "pine_a.png"]
	var placed := 0
	var tries := 0
	while placed < 70 and tries < 2000:
		tries += 1
		var p := Vector2(rng.randf_range(-40, 40), rng.randf_range(-15, 30))
		if p.y < _cliff_z(p.x) + 1.5 or not _clear_of_paths(p, 3.2):
			continue
		# keep the central play space fairly open
		if absf(p.x) < 22.0 and p.y > -12.0 and p.y < 16.0 and rng.randf() < 0.75:
			continue
		var k: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		fader.add(_bill(load(D + k), _ground(p.x, p.y), rng.randf_range(0.85, 1.15)))
		placed += 1


func _scenery() -> void:
	var tex: Texture2D = load("res://assets/generated/props_woods.png")
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
	var table := ["tuft_a", "tuft_b", "tuft_c", "tuft_a", "fern", "bush_s", "bush_l", "rock_s", "rock_l", "shrooms", "shrooms_red", "flowers", "stump", "roots"]
	for k in 260:
		var p := Vector2(rng.randf_range(-32, 32), rng.randf_range(-14, 26))
		if p.y < _cliff_z(p.x) + 0.8 or _dist_poly(p, road) < 1.7 or _dist_poly(p, stream) < 1.8:
			continue
		var pick: String = table[rng.randi_range(0, table.size() - 1)]
		var r: Array = props[pick]
		_bill(tex, _ground(p.x, p.y), 1.0, Rect2(r[0], r[1], r[2], r[3]))


func _valley() -> void:
	for k in 160:
		var x := rng.randf_range(-48, 48)
		var z := rng.randf_range(-86, -20)
		if z > _cliff_z(x) - 3.0 or Vector2(x + 16, z + 40).length() < 8.0 or Vector2(x - 22, z + 42).length() < 6.0:
			continue
		_bill(load(D + ("pine_a.png" if k % 3 else "pine_b.png")), Vector3(x, _height(x, z), z), rng.randf_range(0.9, 1.3))
	# castle on a rise in the valley, village lights further east
	var castle := _bill(load(D + "castle.png"), Vector3(-16, _height(-16, -40) - 1.0, -40), 2.0)
	castle.mat.set_shader_parameter(&"emit", 0.15)
	var vil := _bill(load(D + "village_far.png"), Vector3(22, _height(22, -42) - 0.5, -42), 1.6)
	vil.mat.set_shader_parameter(&"emit", 0.2)
	_light(Vector3(22, _height(22, -42) + 4.0, -40), Color(1.0, 0.6, 0.3), 2.5, 16.0, false)
	_light(Vector3(-16, _height(-16, -40) + 8.0, -37), Color(1.0, 0.6, 0.3), 1.5, 14.0, false)


## Invisible walls: map bounds and the cliff edge (no walking off into the valley).
func _bounds() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	for x in range(-30, 31, 2):
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.2, 6, 0.6)
		cs.shape = sh
		cs.position = Vector3(x, _height(x, _cliff_z(x) + 1.0) + 2.0, _cliff_z(x) + 0.9)
		body.add_child(cs)
	for w: Array in [[Vector3(-26, 0, 5), Vector3(0.6, 12, 50)], [Vector3(26, 0, 5), Vector3(0.6, 12, 50)], [Vector3(0, 0, 22), Vector3(56, 12, 0.6)]]:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = w[1]
		cs.shape = sh
		cs.position = w[0]
		body.add_child(cs)
