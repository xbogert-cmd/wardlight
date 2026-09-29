class_name Region
extends Node3D
## A playable place built in code: heightfield terrain shaped by hills,
## plateaus, roads and streams; props from generated pixel art; entries,
## walk-off exits, a checkpoint and encounters. Subclasses describe the place
## in _layout() (data, before the terrain is built) and _build() (props),
## and apply saved world consequences in apply_state().

signal player_respawned
signal exit_requested(to_region: StringName, to_entry: StringName)

const D := "res://assets/generated/w3d/"
const PX := 1.0 / 24.0
## Collision layer of invisible walls (edges, cliff guards, the sealed arena).
## Walkers collide with it; mouse picking and spell rays (mask 1) don't, since
## these walls are taller than the camera and would catch its view rays.
const INVISIBLE := 128
const PROP_SHADER := preload("res://game3d/prop.gdshader")
const WATER_SHADER := preload("res://game3d/water.gdshader")
const ENEMIES := {
	&"hound": [preload("res://game/enemies/hound.gd"), preload("res://data/enemies/hound.tres")],
	&"raider": [preload("res://game/enemies/raider.gd"), preload("res://data/enemies/raider.tres")],
	&"hexer": [preload("res://game/enemies/hexer.gd"), preload("res://data/enemies/hexer.tres")],
	&"knot": [preload("res://game/enemies/knot.gd"), preload("res://data/enemies/knot.tres")],
	&"sentinel": [preload("res://game/enemies/sentinel.gd"), preload("res://data/enemies/sentinel.tres")],
	&"troll": [preload("res://game/enemies/troll.gd"), preload("res://data/enemies/troll.tres")],
	&"guardian": [preload("res://game/enemies/guardian.gd"), preload("res://data/enemies/guardian.tres")],
}

var id := &"region"
var display_name := "Region"
var music := "explore"
var env_preset := &"night"
var seed_value := 1
# terrain grid (1 m cells)
var origin := Vector2(-40, -40)
var grid := Vector2i(80, 80)
## Walkable rectangle (x, z); invisible walls stand on its edges.
var bounds := Rect2(-30, -30, 60, 60)
var roads: Array = []      # cobble polylines [Vector2...]
var paths: Array = []      # dirt polylines
var streams: Array = []    # {pts, width, depth, water_y}
var hills: Array = []      # [x, z, height, radius]
var pads: Array = []       # [x, z, radius, height]: flat ground for buildings
var dirt_spots: Array = [] # [x, z, radius]
## entry id -> [Vector3 feet position, look direction x]
var entries := {}
## walk-off exits: {rect: Rect2 (x, z), to: region id, entry: entry id}
var exits: Array = []
## [kind, x, z]
var spawns: Array = []
var respawn_entry := &"start"

## Chasms: Rect2 (x, z) areas that swallow walkers (levitate to cross).
var hazards: Array = []

static var current: Region

var noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var terrain: HeightTerrain
var player: Player
var cam: GameCamera3D
var fader := OcclusionFader.new()
var _exiting := false


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func is_hazard(p: Vector3) -> bool:
	for h: Rect2 in hazards:
		if h.has_point(Vector2(p.x, p.z)):
			return true
	return false


func _ready() -> void:
	rng.seed = seed_value
	noise.seed = seed_value * 7 + 3
	noise.frequency = 0.08
	_layout()
	_environment()
	terrain = HeightTerrain.new()
	terrain.origin = origin
	terrain.nx = grid.x
	terrain.nz = grid.y
	add_child(terrain)
	terrain.build(_height, _splat)
	add_child(FX3.new())
	for s: Dictionary in streams:
		_water(s)
	_build()
	_bounds_walls()
	cam = GameCamera3D.new()
	add_child(cam)
	add_child(fader)
	_spawn_enemies()
	apply_state()


# ------------------------------------------------------------------ virtuals
func _layout() -> void:
	pass


func _build() -> void:
	pass


## Apply saved world consequences (lit lanterns, removed trunks...). Must be
## idempotent: it runs on every visit.
func apply_state() -> void:
	pass


## Extra shaping on top of hills/pads/roads/streams (cliffs, chasms).
func _shape(_x: float, _z: float, h: float) -> float:
	return h


# ------------------------------------------------------------------ entering
func enter(p: Player, entry: StringName) -> void:
	player = p
	if p.get_parent():
		p.reparent(self)
	else:
		add_child(p)
	var e: Array = entries.get(entry, entries.get(&"start", [Vector3.ZERO, 1.0]))
	p.global_position = _ground(e[0].x, e[0].z)
	p.velocity = Vector3.ZERO
	p.face(int(signf(e[1])) if e[1] != 0.0 else 1)
	p.look_dir = Vector3(signf(e[1]) if e[1] != 0.0 else 1.0, 0, 0)
	cam.target = p
	fader.target = p
	cam.snap()
	if not p.died.is_connected(_on_player_died):
		p.died.connect(_on_player_died)
	_exiting = false
	Sfx.music(music)


func leave() -> void:
	if player and player.died.is_connected(_on_player_died):
		player.died.disconnect(_on_player_died)


func _physics_process(_delta: float) -> void:
	_boss_music()
	if player == null or _exiting or not player.is_alive():
		return
	var p2 := Vector2(player.global_position.x, player.global_position.z)
	for ex: Dictionary in exits:
		if (ex.rect as Rect2).has_point(p2) and (not ex.has("flag") or GameState.flag(ex.flag)):
			_exiting = true
			exit_requested.emit(ex.to, ex.entry)
			return


func _boss_music() -> void:
	var fighting := false
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if e.is_boss and e.is_alive() and e.get("engaged"):
			fighting = true
			break
	Sfx.music("boss" if fighting else music)


## Make `entry` the respawn point (checkpoint shrines call this).
func set_checkpoint(entry: StringName) -> void:
	respawn_entry = entry
	GameState.region = id
	GameState.entry = entry
	SaveSystem.autosave()


func _spawn_enemies() -> void:
	for s: Array in spawns:
		spawn(s[0], s[1], s[2])


func spawn(kind: StringName, x: float, z: float) -> Enemy:
	var def: Array = ENEMIES[kind]
	var e: Enemy = def[0].new()
	e.data = def[1]
	add_child(e)
	e.global_position = _ground(x, z)
	return e


func _on_player_died() -> void:
	await get_tree().create_timer(1.6).timeout
	# checkpoint: restore health/mana and reset the encounters
	for e in get_tree().get_nodes_in_group(&"enemy"):
		e.queue_free()
	for n in get_children():
		if n is Projectile or n is EmberPatch or n is Knot.ThornPatch:
			n.queue_free()
	await get_tree().process_frame
	_spawn_enemies()
	_on_respawn()
	var e: Array = entries.get(respawn_entry, entries.get(&"start"))
	player.respawn_at(_ground(e[0].x, e[0].z))
	cam.snap()
	player_respawned.emit()


## Subclass hook: reset boss arenas etc. after a defeat.
func _on_respawn() -> void:
	pass


# ------------------------------------------------------------------ shape
static func gauss(dx: float, dz: float, r: float) -> float:
	return exp(-(dx * dx + dz * dz) / (r * r))


static func dist_poly(p: Vector2, pts: Array) -> float:
	var best := INF
	for k in pts.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pts[k], pts[k + 1])))
	return best


func _dist_any(p: Vector2, lines: Array) -> float:
	var best := INF
	for l in lines:
		best = minf(best, dist_poly(p, l))
	return best


func _height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var base := 0.0
	for hl: Array in hills:
		base += hl[2] * gauss(x - hl[0], z - hl[1], hl[3])
	var h := base + noise.get_noise_2d(x, z) * 0.35
	var rd := minf(_dist_any(p, roads), _dist_any(p, paths))
	h = lerpf(base * 0.9, h, clampf((rd - 1.4) / 1.6, 0.0, 1.0))
	for pd: Array in pads:
		var t := smoothstep(pd[2] + 2.0, pd[2], p.distance_to(Vector2(pd[0], pd[1])))
		h = lerpf(h, pd[3], t)
	for s: Dictionary in streams:
		var sd := dist_poly(p, s.pts)
		h -= float(s.get("depth", 1.5)) * smoothstep(float(s.get("width", 1.4)) + 1.1, float(s.get("width", 1.4)) - 0.5, sd)
	return _shape(x, z, h)


func _splat(x: float, z: float) -> Color:
	var p := Vector2(x, z)
	var r := 1.0 - smoothstep(1.45, 1.75, _dist_any(p, roads))
	var g := 1.0 - smoothstep(0.9, 1.5, _dist_any(p, paths))
	for s: Dictionary in streams:
		g = maxf(g, smoothstep(float(s.get("width", 1.4)) + 1.4, float(s.get("width", 1.4)) + 0.2, dist_poly(p, s.pts)) * 0.9)
	for ds: Array in dirt_spots:
		g = maxf(g, 1.0 - smoothstep(ds[2] * 0.6, ds[2], p.distance_to(Vector2(ds[0], ds[1]))))
	g = maxf(g, (1.0 - smoothstep(1.8, 2.6, _dist_any(p, roads))) * 0.45)
	return Color(r, g, 0, 1)


func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, terrain.height_at(x, z), z)


# ------------------------------------------------------------------ environment
func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.85
	var moon := DirectionalLight3D.new()
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 70.0
	match env_preset:
		&"dusk":   # sanctuary / village evening: warmer, a touch brighter
			env.background_color = Color(0.07, 0.06, 0.1)
			env.ambient_light_color = Color(0.36, 0.3, 0.42)
			env.ambient_light_energy = 0.7
			env.fog_light_color = Color(0.3, 0.24, 0.34)
			env.fog_density = 0.004
			moon.light_color = Color(0.9, 0.7, 0.62)
			moon.light_energy = 0.5
			moon.rotation_degrees = Vector3(-38, 55, 0)
		&"ruins":  # old ward: cold, misty, violet
			env.background_color = Color(0.04, 0.035, 0.07)
			env.ambient_light_color = Color(0.26, 0.24, 0.42)
			env.ambient_light_energy = 0.58
			env.fog_light_color = Color(0.24, 0.2, 0.38)
			env.fog_density = 0.012
			moon.light_color = Color(0.62, 0.6, 1.0)
			moon.light_energy = 0.38
			moon.rotation_degrees = Vector3(-52, 20, 0)
		_:         # night woods
			env.background_color = Color(0.05, 0.05, 0.09)
			env.ambient_light_color = Color(0.26, 0.26, 0.42)
			env.ambient_light_energy = 0.62
			env.fog_light_color = Color(0.2, 0.22, 0.36)
			env.fog_density = 0.002
			env.fog_height = -10.0
			env.fog_height_density = 0.07
			moon.light_color = Color(0.62, 0.68, 1.0)
			moon.light_energy = 0.42
			moon.rotation_degrees = Vector3(-48, 35, 0)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	add_child(moon)


func _water(s: Dictionary) -> void:
	var src: Array = s.pts
	var pts: Array = []
	for k in src.size() - 1:
		var a: Vector2 = src[k]
		var b: Vector2 = src[k + 1]
		var n := maxi(1, int(a.distance_to(b) / 0.5))
		for j in n:
			pts.append(a.lerp(b, float(j) / n))
	pts.append(src[src.size() - 1])
	var y: float = s.get("water_y", -0.95)
	var half: float = float(s.get("width", 1.4))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		if s.has("stop") and (s.stop as Callable).call(b):
			break
		var n := (b - a).normalized().orthogonal() * half
		var v := [Vector3(a.x + n.x, y, a.y + n.y), Vector3(a.x - n.x, y, a.y - n.y), Vector3(b.x + n.x, y, b.y + n.y), Vector3(b.x - n.x, y, b.y - n.y)]
		st.set_normal(Vector3.UP)
		for idx in [0, 2, 1, 1, 2, 3]:
			st.add_vertex(v[idx])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter(&"tex", load(D + "water.png"))
	mat.set_shader_parameter(&"flow", s.get("flow", Vector2(0.25, -0.55)))
	mi.material_override = mat
	add_child(mi)


func _bounds_walls() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var b := bounds
	for w: Array in [[Vector3(b.position.x, 0, b.get_center().y), Vector3(0.6, 40, b.size.y)],
			[Vector3(b.end.x, 0, b.get_center().y), Vector3(0.6, 40, b.size.y)],
			[Vector3(b.get_center().x, 0, b.position.y), Vector3(b.size.x, 40, 0.6)],
			[Vector3(b.get_center().x, 0, b.end.y), Vector3(b.size.x, 40, 0.6)]]:
		_wall(body, w[0], w[1])


func _wall(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	body.collision_layer = INVISIBLE
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


# ------------------------------------------------------------------ building blocks
func box(size: Vector3, pos: Vector3, tex: String, rot := Vector3.ZERO, solid := true, tint := Color.WHITE) -> MeshInstance3D:
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


func bill(tex: Texture2D, pos: Vector3, scale := 1.0, region := Rect2()) -> PixelBillboard:
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


func light(pos: Vector3, col: Color, energy: float, rng_m: float, flicker := true) -> OmniLight3D:
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


## A lantern on a post. Returns {lantern, light} so it can be lit later.
func lantern_post(x: float, z: float, side := 1.0, lit := true) -> Dictionary:
	var g := _ground(x, z)
	box(Vector3(0.2, 3.0, 0.2), g + Vector3(0, 1.5, 0), "wood.png", Vector3.ZERO, true)
	box(Vector3(0.9, 0.12, 0.12), g + Vector3(0.4 * side, 2.9, 0), "wood.png", Vector3.ZERO, false)
	var lan := bill(load(D + "lantern.png"), g + Vector3(0.8 * side, 2.25, 0))
	var l := light(g + Vector3(0.8 * side, 2.2, 0.3), Color(1.0, 0.56, 0.24), 3.0, 6.5)
	var out := {"lantern": lan, "light": l}
	set_lantern(out, lit)
	return out


func set_lantern(d: Dictionary, lit: bool) -> void:
	(d.lantern as PixelBillboard).mat.set_shader_parameter(&"emit", 1.0 if lit else 0.0)
	(d.lantern as PixelBillboard).set_tint(Color.WHITE if lit else Color(0.35, 0.33, 0.4))
	(d.light as OmniLight3D).visible = lit


func fence(a: Vector2, b: Vector2, n: int) -> void:
	var prev := Vector3.ZERO
	for k in n + 1:
		var p := a.lerp(b, float(k) / n)
		var g := _ground(p.x, p.y)
		box(Vector3(0.18, 1.2, 0.18), g + Vector3(0, 0.5, 0), "wood.png", Vector3(0, 0, deg_to_rad(rng.randf_range(-6, 6))))
		if k > 0:
			var mid := (prev + g) * 0.5
			var d := g - prev
			var yaw := -atan2(d.z, d.x)
			var len := Vector2(d.x, d.z).length()
			box(Vector3(len, 0.1, 0.1), mid + Vector3(0, 0.85, 0), "wood.png", Vector3(0, yaw, atan2(d.y, len)), false)
			box(Vector3(len, 0.09, 0.09), mid + Vector3(0, 0.45, 0), "wood.png", Vector3(0, yaw, atan2(d.y, len)), false)
		prev = g


func bridge(a: Vector2, b: Vector2, deck_y: float, width := 2.3) -> void:
	var c := (a + b) * 0.5
	var dir := (b - a).normalized()
	var len := a.distance_to(b)
	var ang := -dir.angle()
	box(Vector3(len, 0.3, width), Vector3(c.x, deck_y - 0.15, c.y), "wood.png", Vector3(0, ang, 0))
	var side := Vector2(-dir.y, dir.x)
	for s in [-1.0, 1.0]:
		for k in [-0.42, -0.15, 0.15, 0.42]:
			var p: Vector2 = c + dir * len * k + side * (width * 0.46) * s
			box(Vector3(0.18, 1.1, 0.18), Vector3(p.x, deck_y + 0.45, p.y), "wood.png", Vector3(0, ang, 0), false)
		var rp: Vector2 = c + side * (width * 0.46) * s
		box(Vector3(len * 0.9, 0.12, 0.12), Vector3(rp.x, deck_y + 0.9, rp.y), "wood.png", Vector3(0, ang, 0), false)
		box(Vector3(len * 0.9, 0.1, 0.1), Vector3(rp.x, deck_y + 0.5, rp.y), "wood.png", Vector3(0, ang, 0), false)


## A cottage with plaster walls, a gabled roof, a door and windows on the
## camera-facing (south) wall. Returns {windows: [PixelBillboard], ...}.
func house(x: float, z: float, w: float, d: float, wall_h: float, opts := {}) -> Dictionary:
	var g := _ground(x, z)
	var tint: Color = opts.get("tint", Color(1, 1, 1))
	box(Vector3(w, wall_h, d), g + Vector3(0, wall_h * 0.5 - 0.1, 0), opts.get("wall", "plaster.png"), Vector3.ZERO, true, tint)
	if opts.get("wall", "plaster.png") == "plaster.png":
		for cx: float in [-w * 0.5, w * 0.5]:
			box(Vector3(0.22, wall_h, 0.22), g + Vector3(cx, wall_h * 0.5 - 0.1, d * 0.5), "wood.png", Vector3.ZERO, false, Color(0.55, 0.42, 0.35))
		box(Vector3(w + 0.1, 0.22, 0.22), g + Vector3(0, wall_h - 0.2, d * 0.5 + 0.02), "wood.png", Vector3.ZERO, false, Color(0.55, 0.42, 0.35))
	var roof_h: float = opts.get("roof_h", w * 0.35)
	_roof(g + Vector3(0, wall_h - 0.1, 0), w + 0.6, d + 0.6, roof_h, opts.get("roof", "roof.png"), tint.lerp(Color.WHITE, 0.5))
	var front := g.z + d * 0.5 + 0.03
	var out := {"windows": [], "door": null}
	if opts.get("door", true):
		out.door = bill(load(D + "door.png"), Vector3(g.x + float(opts.get("door_x", 0.0)), g.y - 0.05, front))
		out.door.mat.set_shader_parameter(&"depth_bias", 0.02)
	var lit: bool = opts.get("lit", true)
	for wx: float in opts.get("windows", [-w * 0.3, w * 0.3]):
		var win := bill(load(D + ("window_lit.png" if lit else "window_dark.png")), Vector3(g.x + wx, g.y + wall_h * 0.45, front))
		win.mat.set_shader_parameter(&"depth_bias", 0.02)
		win.mat.set_shader_parameter(&"emit", 1.2 if lit else 0.0)
		out.windows.append(win)
	if opts.get("chimney", false):
		var cx := g.x + w * 0.28
		box(Vector3(0.6, roof_h + 1.0, 0.6), Vector3(cx, g.y + wall_h + roof_h * 0.5 + 0.2, g.z - d * 0.15), "bricks.png", Vector3.ZERO, false)
		var top := Vector3(cx, g.y + wall_h + roof_h + 0.8, g.z - d * 0.15)
		var t := Timer.new()
		t.wait_time = 0.25
		t.autostart = true
		t.timeout.connect(func() -> void:
			FX3.burst(top, 1, Pal.SMOKE, Vector2(0.2, 0.5), Vector2(1.5, 2.5), {"dir": Vector3(0.3, 1, 0), "spread": 0.4, "gravity": -0.2, "size": 2.0}))
		add_child(t)
	if lit and opts.get("light", true):
		out["light"] = light(Vector3(g.x, g.y + wall_h * 0.5, front + 0.8), Color(1.0, 0.65, 0.35), 1.6, 4.5, false)
	return out


func set_windows(h: Dictionary, lit: bool) -> void:
	for win: PixelBillboard in h.windows:
		win.setup(load(D + ("window_lit.png" if lit else "window_dark.png")), Vector2i(10, 12), 1, {}, Vector2(5, 12))
		win.mat.set_shader_parameter(&"depth_bias", 0.02)
		win.mat.set_shader_parameter(&"emit", 1.2 if lit else 0.0)
	if h.has("light"):
		(h.light as OmniLight3D).visible = lit


func _roof(base: Vector3, w: float, d: float, rh: float, tex: String, tint: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := w * 0.5
	var hd := d * 0.5
	var ridge_l := Vector3(-hw, rh, 0)
	var ridge_r := Vector3(hw, rh, 0)
	# south and north slopes
	for side: float in [1.0, -1.0]:
		var e_l := Vector3(-hw, 0, hd * side)
		var e_r := Vector3(hw, 0, hd * side)
		st.set_normal(Vector3(0, hd, rh * side).normalized())
		# clockwise when seen from outside (Godot's front face)
		var tri := [e_l, ridge_r, e_r, e_l, ridge_l, ridge_r] if side > 0 else [e_r, ridge_l, e_l, e_r, ridge_r, ridge_l]
		for v: Vector3 in tri:
			st.add_vertex(v)
	# gables
	for side: float in [1.0, -1.0]:
		st.set_normal(Vector3(side, 0, 0))
		var tri2 := [Vector3(hw * side, 0, -hd), Vector3(hw * side, 0, hd), Vector3(hw * side, rh, 0)]
		if side < 0:
			tri2.reverse()
		for v: Vector3 in tri2:
			st.add_vertex(v)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = PROP_SHADER
	mat.set_shader_parameter(&"tex", load(D + tex))
	mat.set_shader_parameter(&"tint", tint)
	m.material_override = mat
	add_child(m)
	m.global_position = base


## Scatter trees across rect `area`, avoiding `keep_clear(p) == false` spots.
func trees(area: Rect2, count: int, keep_clear: Callable, kinds := ["pine_a.png", "pine_b.png", "oak.png", "dead_tree.png", "pine_a.png"]) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 30:
		tries += 1
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if not keep_clear.call(p):
			continue
		var k: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var t := bill(load(D + k), _ground(p.x, p.y), rng.randf_range(0.85, 1.15))
		fader.add(t)
		if bounds.has_point(p):
			_tree_trunk(p)
		placed += 1


## Trees inside the playable area get a thin solid trunk.
func _tree_trunk(p: Vector2) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.3
	sh.height = 3.0
	cs.shape = sh
	body.add_child(cs)
	add_child(body)
	body.global_position = _ground(p.x, p.y) + Vector3(0, 1.4, 0)


func scenery(area: Rect2, count: int, keep_clear: Callable, table := ["tuft_a", "tuft_b", "tuft_c", "tuft_a", "fern", "bush_s", "bush_l", "rock_s", "rock_l", "shrooms", "shrooms_red", "flowers", "stump", "roots"]) -> void:
	var tex: Texture2D = load("res://assets/generated/props_woods.png")
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
	for k in count:
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if not keep_clear.call(p):
			continue
		var pick: String = table[rng.randi_range(0, table.size() - 1)]
		var r: Array = props[pick]
		bill(tex, _ground(p.x, p.y), 1.0, Rect2(r[0], r[1], r[2], r[3]))


## Distance from p to the nearest road or path.
func path_dist(p: Vector2) -> float:
	return minf(_dist_any(p, roads), _dist_any(p, paths))


# ------------------------------------------------------------------ story props
func brazier(x: float, z: float) -> void:
	var bp := _ground(x, z)
	box(Vector3(0.7, 0.8, 0.7), bp + Vector3(0, 0.4, 0), "bricks.png")
	box(Vector3(1.0, 0.18, 1.0), bp + Vector3(0, 0.88, 0), "rock.png", Vector3.ZERO, false)
	var fl := PixelBillboard.new()
	fl.setup(load(D + "flames.png"), Vector2i(16, 20), 4, {"burn": {"frames": [0, 1, 2, 3], "fps": 10.0, "loop": true}}, Vector2(8, 20))
	add_child(fl)
	fl.global_position = bp + Vector3(0, 0.95, 0)
	fl.play(&"burn")
	fl.mat.set_shader_parameter(&"emit", 1.2)
	light(bp + Vector3(0, 1.6, 0), Color(1.0, 0.5, 0.2), 4.0, 8.0)
	var t := Timer.new()
	t.wait_time = 0.12
	t.autostart = true
	t.timeout.connect(func() -> void:
		FX3.burst(bp + Vector3(0, 1.3, 0), 2, Pal.school(&"fire"), Vector2(0.3, 1.0), Vector2(0.6, 1.2), {"dir": Vector3.UP, "spread": 0.8, "gravity": -0.6}))
	add_child(t)


## A ward stone: a carved pillar holding a crystal that is dark or lit.
## `tall` makes the village wardlight. Returns {crystal, light, pos}.
func ward_stone(x: float, z: float, lit: bool, tall := false) -> Dictionary:
	var g := _ground(x, z)
	var h := 3.2 if tall else 1.4
	box(Vector3(0.7 if tall else 0.55, h, 0.7 if tall else 0.55), g + Vector3(0, h * 0.5 - 0.1, 0), "rune_bricks.png")
	box(Vector3(1.1 if tall else 0.8, 0.25, 1.1 if tall else 0.8), g + Vector3(0, 0.1, 0), "bricks.png", Vector3.ZERO, false)
	var cr := bill(load(D + "ward_dark.png"), g + Vector3(0, h - 0.05, 0), 1.3 if tall else 1.0)
	var l := light(g + Vector3(0, h + 0.4, 0.3), Color(0.55, 0.85, 1.0), 3.5 if tall else 2.5, 9.0 if tall else 6.0, false)
	var d := {"crystal": cr, "light": l, "pos": g + Vector3(0, h + 0.3, 0), "tall": tall}
	set_ward(d, lit)
	return d


func set_ward(d: Dictionary, lit: bool) -> void:
	var cr: PixelBillboard = d.crystal
	var sc := cr.scale
	cr.setup(load(D + ("ward_lit.png" if lit else "ward_dark.png")), Vector2i(12, 18), 1, {}, Vector2(6, 18))
	cr.scale = sc
	cr.mat.set_shader_parameter(&"emit", 1.4 if lit else 0.0)
	(d.light as OmniLight3D).visible = lit


## The ward lights up: a rising column of motes, rings, and a flash.
func ward_flare(d: Dictionary) -> void:
	var p: Vector3 = d.pos
	var ramp := [Color("ffffff"), Color("d8f8ff"), Color("9ae8ff"), Color("3a78c0")]
	FX3.flash(p, 1.2, 0.3, Color(0.75, 0.95, 1.0), 8.0)
	FX3.ring(Vector3(p.x, _ground(p.x, p.z).y + 0.05, p.z), 0.3, 6.0, 0.8, ramp, 2.0)
	FX3.ring(p, 0.2, 2.0, 0.5, ramp, 1.0, false)
	FX3.burst(p, 40, ramp, Vector2(1.0, 5.0), Vector2(0.5, 1.2), {"gravity": -1.5})
	for k in 24:
		var a := randf() * TAU
		FX3.burst(Vector3(p.x, _ground(p.x, p.z).y + 0.1, p.z) + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, 5.0), 1, ramp, Vector2(1.0, 3.0), Vector2(0.6, 1.2), {"dir": Vector3.UP, "spread": 0.3})
	Sfx.play("ward_light", 0.0)
	Sfx.play("storm_thunder", -8.0)
	GameCamera3D.shake_all(2.0)


## A waystone pillar with a humming crystal. Returns its Interactable.
func waystone(x: float, z: float, text: String) -> Interactable:
	var g := _ground(x, z)
	box(Vector3(0.9, 2.6, 0.9), g + Vector3(0, 1.2, 0), "rune_bricks.png", Vector3(0, 0.3, 0), true, Color(0.85, 0.9, 1.1))
	box(Vector3(1.6, 0.3, 1.6), g + Vector3(0, 0.1, 0), "bricks.png", Vector3.ZERO, false)
	var cr := bill(load(D + "ward_lit.png"), g + Vector3(0, 2.6, 0), 1.2)
	cr.mat.set_shader_parameter(&"emit", 1.2)
	cr.set_tint(Color(0.8, 0.7, 1.0))
	light(g + Vector3(0, 3.0, 0.4), Color(0.7, 0.6, 1.0), 2.5, 7.0, false)
	FX3.decal(FX3.RUNE_L, g + Vector3(0, 0.04, 0), 1e9, Color(0.7, 0.6, 1.0, 0.6), 0.9, 0.9, 0.4)
	var it := Interactable.make(g, text, 2.2, 3.4)
	add_child(it)
	return it


## A small rune stone that becomes the respawn point when the wizard walks by.
func checkpoint_stone(x: float, z: float, entry: StringName) -> void:
	var g := _ground(x, z)
	box(Vector3(0.5, 1.0, 0.4), g + Vector3(0, 0.45, 0), "rune_bricks.png", Vector3(0, 0.4, 0.05))
	var glow := bill(load(D + "ward_lit.png"), g + Vector3(0, 1.0, 0), 0.6)
	glow.mat.set_shader_parameter(&"emit", 0.3)
	var t := Timer.new()
	t.wait_time = 0.25
	t.autostart = true
	t.timeout.connect(func() -> void:
		if player and respawn_entry != entry and SpellEffect.flat(player.global_position, g) < 2.2:
			set_checkpoint(entry)
			glow.mat.set_shader_parameter(&"emit", 1.4)
			player.health.heal(player.health.max_hp)
			player.mana.refill()
			FX3.ring(g + Vector3(0, 0.05, 0), 0.2, 2.2, 0.5, [Color("ffffff"), Color("d8f8ff"), Color("9ae8ff")], 1.0)
			FX3.burst(g + Vector3(0, 1.0, 0), 16, [Color("ffffff"), Color("d8f8ff"), Color("9ae8ff")], Vector2(0.5, 2.0), Vector2(0.4, 0.8), {"gravity": -1.0})
			Sfx.play("mote", -4.0)
			var hud := get_tree().get_first_node_in_group(&"hud") as HUD
			if hud:
				hud.banner("Checkpoint"))
	add_child(t)
	entries[entry] = [g + Vector3(0.8, 0, 1.0), 1.0]


## A chest that gives `contents` ([[item id, tier], ...]) and `coins` once
## (event `event_id`). Opened chests stay open on later visits.
func chest(x: float, z: float, event_id: StringName, contents: Array, coins := 0, yaw := 0.0) -> void:
	var g := _ground(x, z)
	box(Vector3(1.0, 0.55, 0.65), g + Vector3(0, 0.27, 0), "wood.png", Vector3(0, yaw, 0), true, Color(0.75, 0.55, 0.4))
	var lid := box(Vector3(1.05, 0.2, 0.7), g + Vector3(0, 0.62, 0), "wood.png", Vector3(0, yaw, 0), false, Color(0.85, 0.65, 0.45))
	box(Vector3(1.08, 0.08, 0.72), g + Vector3(0, 0.45, 0), "bricks.png", Vector3(0, yaw, 0), false, Color(0.9, 0.8, 0.5))
	var it := Interactable.make(g, "Open the chest", 1.6, 1.2)
	add_child(it)
	var opened := func() -> void:
		it.enabled = false
		lid.position.y += 0.25
		lid.rotation.x = -0.6
	if GameState.events.has(event_id):
		opened.call()
		return
	it.activated.connect(func(_p: Player) -> void:
		opened.call()
		# guaranteed contents go straight into the bags (nothing to lose on the ground)
		GameState.once(event_id, func() -> void:
			for c: Array in contents:
				give(c[0], c[1] if c.size() > 1 else 1)
			if coins > 0:
				GameState.inv.earn(coins)
				reward(["+%d coins" % coins])
			SaveSystem.autosave()
			Sfx.play("ward_light", -6.0)
			FX3.burst(g + Vector3(0, 0.8, 0), 20, [Color("fff0c0"), Color("f0c870"), Color("a07840")], Vector2(1.0, 3.0), Vector2(0.4, 0.8), {"gravity": 3.0})))


## A reward notice (items go straight to the bags).
func reward(lines: Array) -> void:
	var hud := get_tree().get_first_node_in_group(&"hud") as HUD
	for l: String in lines:
		if hud:
			hud.toast(l)


## Grant an item directly (quest gifts), with a notice.
func give(id: StringName, tier := 1) -> void:
	var inst := GameState.inv.add(id, tier)
	if not inst.is_empty():
		reward(["Received: " + Items.display(inst)])
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.fusion_hint()


func give_point(n := 1) -> void:
	GameState.inv.points += n
	GameState.inv.changed.emit()
	reward(["+%d progression point%s" % [n, "s" if n > 1 else ""]])


func give_decor(id: StringName, label: String) -> void:
	GameState.inv.decor[id] = true
	GameState.inv.changed.emit()
	reward(["New for your home: " + label])


## Contextual magic: lock the wizard in the raise/gather pose for `secs`,
## drawing motes of `ramp` toward the staff, while `during` animates.
func channel(p: Player, target: Vector3, ramp: Array, secs: float) -> void:
	p.lock(true)
	p.face(int(signf(target.x - p.global_position.x)) if absf(target.x - p.global_position.x) > 0.2 else p.facing)
	p.sprite.play(&"raise", true)
	var t := 0.0
	while t < secs:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if t > 0.15:
			p.sprite.play(&"gather")
		var tip := p.staff_tip()
		if randf() < 0.7:
			FX3.converge(tip, 0.8, 1, ramp, 0.2, 1.2)
		if randf() < 0.5:
			FX3.burst(tip.lerp(target, randf()), 1, ramp, Vector2(0.1, 0.5), Vector2(0.3, 0.6), {"gravity": -0.8})
	p.sprite.play(&"release_2", true)
	FX3.flash(p.staff_tip(), 0.4, 0.12, ramp[1], 2.0)
	p.lock(false)
