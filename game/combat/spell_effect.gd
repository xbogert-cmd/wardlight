class_name SpellEffect
extends RefCounted
## Base for spell behaviours. Override cast(); gather() has a per-school
## default (embers / violet smoke / sparks rushing into the staff gem).

const RUNE_S := preload("res://assets/generated/rune24.png")
const RUNE_M := preload("res://assets/generated/rune40.png")
const RUNE_L := preload("res://assets/generated/rune64.png")
const GLOW_S := preload("res://assets/generated/glow16.png")
const GLOW_M := preload("res://assets/generated/glow32.png")
const GLOW_L := preload("res://assets/generated/glow64.png")


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
				FX.converge(o, 22.0 - 10.0 * t, 2, ramp, 0.16, {"swirl": 0.8})
			if randf() < delta * 30.0:
				FX.burst(o, 1, ramp, Vector2(10, 30), Vector2(0.2, 0.4), {"dir": Vector2.UP, "spread": 1.0, "gravity": -60.0})
		&"hex":
			if randf() < delta * 90.0:
				FX.converge(o, 24.0 - 10.0 * t, 1, ramp, 0.2, {"swirl": 1.8})
			if randf() < delta * 50.0:
				FX.converge(o, 18.0, 1, Pal.SPECTRAL, 0.22, {"swirl": -1.5})
		_:
			if randf() < delta * 140.0:
				FX.converge(o, 26.0 - 12.0 * t, 2, ramp, 0.14, {"swirl": 1.5})
			if randf() < delta * 30.0:
				FX.bolt(o + Vector2.from_angle(randf() * TAU) * randf_range(9, 16), o, 0.06, ramp, 1.5)
	FX.sprite(GLOW_S, o, 0.05, ramp[2], 0.6 + t * 0.9, 0.6 + t * 0.9, 0.0, false)
	if t > 0.25 and not ctx.bonus.has("gather_ring"):
		ctx.bonus["gather_ring"] = true
		FX.sprite(RUNE_S, o, 0.2, Color(ramp[1], 0.9), 0.4, 0.9, 6.0 if sch != &"hex" else -4.0, false)


func cast(_ctx: CastContext) -> void:
	pass


# ---- shared helpers ---------------------------------------------------------
## The staff-release flourish shared by every school.
static func release_fx(ctx: CastContext, scale: float = 1.0) -> void:
	var ramp := Pal.school(ctx.data.school_name())
	var o := ctx.origin
	FX.flash(o, 4.0 * scale, 0.06, Color(1, 1, 1, 0.9))
	FX.sprite(GLOW_M, o, 0.2, ramp[2], 0.7 * scale, 1.2 * scale, 0.0, false)
	FX.sprite(RUNE_M, o + ctx.dir * 4.0, 0.3, ramp[1], 0.35 * scale, 0.8 * scale, 5.0, false, true, ctx.dir.angle())
	FX.burst(o, int(10 * scale), ramp, Vector2(50, 150), Vector2(0.1, 0.25), {"dir": ctx.dir, "spread": 1.1, "drag": 5.0})


static func enemies() -> Array:
	return Engine.get_main_loop().get_nodes_in_group(&"enemy").filter(func(e: Node) -> bool: return e.is_alive())


static func has_los(from: Vector2, to: Vector2, space_owner: Node2D) -> bool:
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	return space_owner.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


static func nearest(from: Vector2, radius: float, exclude: Array, space_owner: Node2D) -> Node2D:
	var best: Node2D = null
	var bd := radius
	for e: Node2D in enemies():
		if exclude.has(e):
			continue
		var d := from.distance_to(e.center())
		if d < bd and has_los(from, e.center(), space_owner):
			bd = d
			best = e
	return best


static func in_circle(c: Vector2, r: float) -> Array:
	return enemies().filter(func(e: Node2D) -> bool:
		var hr: Rect2 = e.hurt_rect()
		var closest := Vector2(clampf(c.x, hr.position.x, hr.end.x), clampf(c.y, hr.position.y, hr.end.y))
		return closest.distance_to(c) <= r)


static func in_rect(r: Rect2) -> Array:
	return enemies().filter(func(e: Node2D) -> bool: return r.intersects(e.hurt_rect()))


## First ground point straight below `from` (or `from` if none within range).
static func ground_below(from: Vector2, space_owner: Node2D, reach: float = 240.0) -> Vector2:
	var q := PhysicsRayQueryParameters2D.create(from + Vector2(0, -4), from + Vector2(0, reach), 1)
	var hit := space_owner.get_world_2d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else from


## Point along a ray from `from`, stopped by walls.
static func ray_end(from: Vector2, to: Vector2, space_owner: Node2D) -> Vector2:
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := space_owner.get_world_2d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else to


static func make_projectile(ctx: CastContext, style: StringName, speed: float, dist: float, r: float = 4.0) -> Projectile:
	var p := Projectile.new()
	p.style = style
	p.ramp = Pal.school(ctx.data.school_name())
	p.velocity = ctx.dir * speed
	p.max_dist = dist
	p.radius = r
	ctx.spawn(p)
	p.global_position = ctx.origin + ctx.dir * 2.0
	return p


static func later(sec: float, f: Callable) -> void:
	(Engine.get_main_loop() as SceneTree).create_timer(sec, false).timeout.connect(f)
