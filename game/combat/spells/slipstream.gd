extends SpellEffect
## Slipstream: the wizard rides a burst of wind in the aimed direction,
## untouchable for the moment, buffeting enemies passed through. Dashing
## across burning ground scatters its embers forward (Cinderflight).
## Upgrade (Tailwind): leaves a lingering gale that keeps shoving enemies.


func cast(ctx: CastContext) -> void:
	var p: Node3D = ctx.caster
	var dir := ctx.dir
	var time: float = ctx.p("time", 0.18)
	var dist: float = ctx.p("distance", 5.0)
	var hit := {}
	var start := p.global_position
	FX3.ring(start + Vector3(0, 0.05, 0), 0.2, 1.2, 0.25, Pal.school(&"storm"), 1.0)
	FX3.burst(p.center(), 14, WIND, Vector2(2.5, 6.5), Vector2(0.15, 0.3), {"dir": -dir, "spread": 1.0, "drag": 5.0})
	Sfx.play("storm_wind", -1.0)
	p.spell_dash(dir * dist / time, time, func() -> void:
		var c: Vector3 = p.center()
		FX3.burst(c, 3, WIND, Vector2(1.2, 3.8), Vector2(0.15, 0.3), {"dir": -dir, "spread": 0.6, "drag": 4.0})
		FX3.seg(c - dir * 0.8 + Vector3(0, 0.3, 0), c + Vector3(0, 0.3, 0), WIND[1])
		for e: Node3D in in_circle(p.global_position, 0.8):
			if not hit.has(e):
				hit[e] = true
				var d := ctx.dmg(1.0, dir * 6.3 + Vector3(0, 4.0, 0))
				d.stagger = 20.0
				ctx.hit(e, d)
				FX3.burst(e.center(), 8, Pal.school(&"storm"), Vector2(1.6, 5.0), Vector2(0.1, 0.3))
		Interactions.cinderflight(ctx, func(pt: EmberPatch) -> bool: return pt.contains(p.global_position, 0.35), dir))
	if ctx.upgraded:
		later(time, func() -> void:
			var g := Gale.new()
			g.ctx = ctx
			g.a = start
			g.b = p.global_position
			g.dir = dir
			ctx.spawn(g))


class Gale extends Node3D:
	var ctx: CastContext
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var dir := Vector3.RIGHT
	var t := 0.0
	var tick := 0.0
	const LIFE := 1.2

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		if tick <= 0.0:
			tick = 0.3
			for e: Node3D in SpellEffect.in_segment(a, b, 0.9):
				var d := ctx.dmg(0.4, dir * 5.0 + Vector3(0, 2.0, 0))
				d.stagger = 8.0
				ctx.hit(e, d)
		for k in 3:
			var p := a.lerp(b, randf()) + Vector3(randf_range(-0.6, 0.6), randf_range(0.2, 1.4), randf_range(-0.6, 0.6))
			FX3.burst(p, 1, [Color("ffffff"), Color("c8f0ff"), Color("8ad8f0")], Vector2(3.3, 6.6), Vector2(0.1, 0.2), {"dir": dir, "spread": 0.3, "drag": 3.0})
		if t >= LIFE:
			queue_free()
