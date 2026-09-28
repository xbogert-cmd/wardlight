class_name SpellEffect
extends RefCounted
## Base for spell behaviours. Override cast(); gather() is optional.


## Called every frame of the windup with t in 0..1.
func gather(ctx: CastContext, t: float, delta: float) -> void:
	var ramp := Pal.school(ctx.data.school_name())
	if randf() < delta * 60.0:
		FX.converge(ctx.origin, 16.0, 2, ramp, 0.16, {"swirl": 1.0})


func cast(_ctx: CastContext) -> void:
	pass


# ---- shared helpers for effects ------------------------------------------
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
