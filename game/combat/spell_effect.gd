class_name SpellEffect
extends RefCounted
## Base for spell behaviours. Override cast(); gather() has a per-school
## default (embers / violet smoke / sparks rushing into the staff gem).
## World is 3D: Y up, metres; "flat" distances ignore height (the game is
## played on the ground plane, hills only lift things a little).

const PX := 1.0 / 24.0
const RUNE_S := preload("res://assets/generated/rune24.png")
const RUNE_M := preload("res://assets/generated/rune40.png")
const RUNE_L := preload("res://assets/generated/rune64.png")
const GLOW_S := preload("res://assets/generated/glow16.png")
const GLOW_M := preload("res://assets/generated/glow32.png")
const GLOW_L := preload("res://assets/generated/glow64.png")
const CLOUD := preload("res://assets/generated/cloud96.png")
const WIND := [Color("ffffff"), Color("d8f8ff"), Color("8ad8f0")]


## Called every frame of the windup with t in 0..1.
func gather(ctx: CastContext, t: float, delta: float) -> void:
	gather_fx(ctx, t, delta)


static func gather_fx(ctx: CastContext, t: float, delta: float) -> void:
	var o := ctx.origin
	var sch := ctx.data.school_name()
	var ramp := Pal.school(sch)
	match sch:
		&"fire":
			if randf() < delta * 110.0:
				FX3.converge(o, 0.9 - 0.4 * t, 2, ramp, 0.16, 0.8)
			if randf() < delta * 30.0:
				FX3.burst(o, 1, ramp, Vector2(0.4, 1.2), Vector2(0.2, 0.4), {"dir": Vector3.UP, "spread": 1.0, "gravity": -2.5})
		&"hex":
			if randf() < delta * 90.0:
				FX3.converge(o, 1.0 - 0.4 * t, 1, ramp, 0.2, 1.8)
			if randf() < delta * 50.0:
				FX3.converge(o, 0.75, 1, Pal.SPECTRAL, 0.22, -1.5)
		_:
			if randf() < delta * 140.0:
				FX3.converge(o, 1.1 - 0.5 * t, 2, ramp, 0.14, 1.5)
			if randf() < delta * 30.0:
				FX3.bolt(o + Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)).normalized() * randf_range(0.4, 0.7), o, 0.06, ramp, 0.06)
	FX3.glow(o, 0.05, Color(ramp[2], 0.8), 0.6 + t * 0.9, 0.6 + t * 0.9, GLOW_S)
	if not ctx.bonus.has("gather_rune"):
		ctx.bonus["gather_rune"] = FX3.decal(RUNE_L, feet(ctx) + Vector3(0, 0.03, 0), maxf(ctx.data.windup, 0.1) + 0.35, Color(ramp[1], 0.9), 0.3, 1.1, 2.5 if sch != &"hex" else -2.0)
	var rune: Variant = ctx.bonus["gather_rune"]
	if rune is MeshInstance3D and is_instance_valid(rune):
		(rune as MeshInstance3D).global_position = feet(ctx) + Vector3(0, 0.03, 0)


static func feet(ctx: CastContext) -> Vector3:
	return ctx.caster.global_position


func cast(_ctx: CastContext) -> void:
	pass


# ---- shared helpers ---------------------------------------------------------
## The staff-release flourish shared by every school.
static func release_fx(ctx: CastContext, scale: float = 1.0) -> void:
	var ramp := Pal.school(ctx.data.school_name())
	var o := ctx.origin
	FX3.flash(o, 0.35 * scale, 0.08, Color(ramp[1], 0.9), 2.0 * scale)
	FX3.glow(o, 0.2, Color(ramp[2], 0.9), 0.7 * scale, 1.3 * scale)
	FX3.decal(RUNE_M, o + ctx.dir * 0.2, 0.3, Color(ramp[1], 1.0), 0.3 * scale, 0.7 * scale, 0.0, false)
	FX3.burst(o, int(12 * scale), ramp, Vector2(2.0, 6.0), Vector2(0.1, 0.25), {"dir": ctx.dir, "spread": 1.1, "drag": 5.0})


static func enemies() -> Array:
	return Engine.get_main_loop().get_nodes_in_group(&"enemy").filter(func(e: Node) -> bool: return e.is_alive())


static func flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func flat_dir(v: Vector3, fallback: Vector3 = Vector3.RIGHT) -> Vector3:
	var f := Vector3(v.x, 0.0, v.z)
	return f.normalized() if f.length() > 0.001 else fallback


static func has_los(from: Vector3, to: Vector3, space_owner: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	return space_owner.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


static func nearest(from: Vector3, radius: float, exclude: Array, space_owner: Node3D) -> Node3D:
	var best: Node3D = null
	var bd := radius
	for e: Node3D in enemies():
		if exclude.has(e):
			continue
		var d := flat(from, e.center())
		if d < bd and has_los(from, e.center(), space_owner):
			bd = d
			best = e
	return best


## Enemies whose body overlaps a flat circle.
static func in_circle(c: Vector3, r: float) -> Array:
	return enemies().filter(func(e: Node3D) -> bool: return flat(c, e.global_position) <= r + e.radius())


## Enemies inside a flat cone from `o` along `dir` (half-angle in radians).
static func in_cone(o: Vector3, dir: Vector3, reach: float, half: float, space_owner: Node3D) -> Array:
	return enemies().filter(func(e: Node3D) -> bool:
		var v := e.global_position - o
		v.y = 0.0
		var r: float = reach + e.radius()
		if v.length() > r:
			return false
		if v.length() > e.radius() + 0.4 and absf(flat_dir(v).angle_to(dir)) > half + atan2(e.radius(), v.length()):
			return false
		return has_los(o, e.center(), space_owner))


## Enemies whose body touches the flat segment a→b widened by `pad`.
static func in_segment(a: Vector3, b: Vector3, pad: float) -> Array:
	var a2 := Vector2(a.x, a.z)
	var b2 := Vector2(b.x, b.z)
	return enemies().filter(func(e: Node3D) -> bool:
		var p := Vector2(e.global_position.x, e.global_position.z)
		return Geometry2D.get_closest_point_to_segment(p, a2, b2).distance_to(p) <= pad + e.radius())


## Ground point under `p` (searches from a little above it).
static func ground_at(p: Vector3, space_owner: Node3D) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 6, 0), p + Vector3(0, -30, 0), 1)
	var hit := space_owner.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else p


## Point along a ray from `from`, stopped by walls and terrain.
static func ray_end(from: Vector3, to: Vector3, space_owner: Node3D) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := space_owner.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else to


## Where shots start: under the staff gem at chest height (the release flash
## at the gem covers the drop, and chest height reads well from above).
static func launch_point(ctx: CastContext) -> Vector3:
	return Vector3(ctx.origin.x, ctx.caster.global_position.y + 1.0, ctx.origin.z) + ctx.dir * 0.1


## Straight at a locked target's centre, else level along the aim.
static func launch_dir(ctx: CastContext, start: Vector3) -> Vector3:
	if ctx.target and is_instance_valid(ctx.target) and flat(start, ctx.target.center()) > 0.5:
		return (ctx.target.center() - start).normalized()
	return ctx.dir


static func make_projectile(ctx: CastContext, style: StringName, speed: float, dist: float, r: float = 0.25) -> Projectile:
	var p := Projectile.new()
	p.style = style
	p.ramp = Pal.school(ctx.data.school_name())
	var start := launch_point(ctx)
	p.velocity = launch_dir(ctx, start) * speed
	p.max_dist = dist
	p.radius = r
	ctx.spawn(p)
	p.global_position = start
	return p


## Horizontal push away from `from` (plus a small hop).
static func push(from: Vector3, to: Vector3, strength: float, hop: float = 0.0) -> Vector3:
	return flat_dir(to - from) * strength + Vector3(0, hop, 0)


static func later(sec: float, f: Callable) -> void:
	(Engine.get_main_loop() as SceneTree).create_timer(sec, false).timeout.connect(f)
