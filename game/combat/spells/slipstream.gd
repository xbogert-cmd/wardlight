extends SpellEffect
## Slipstream: the wizard rides a burst of wind in the aimed direction,
## untouchable for the moment, buffeting enemies passed through. Dashing
## across burning ground scatters its embers forward (Cinderflight).
## Upgrade (Tailwind): leaves a lingering gale that keeps shoving enemies.


func cast(ctx: CastContext) -> void:
	var p: Node2D = ctx.caster
	var dir := ctx.dir
	dir.y = clampf(dir.y, -0.55, 0.3)
	dir = dir.normalized()
	var time: float = ctx.p("time", 0.18)
	var dist: float = ctx.p("distance", 120.0)
	var hit := {}
	var start := p.global_position
	FX.ring(ctx.origin, 2.0, 14.0, 0.2, Pal.school(&"storm"), 1.0, true)
	FX.burst(p.center(), 14, [Color("ffffff"), Color("d8f8ff"), Color("8ad8f0")], Vector2(60, 160), Vector2(0.15, 0.3), {"dir": -dir, "spread": 1.0, "drag": 5.0})
	Sfx.play("storm_wind", -1.0)
	p.spell_dash(dir * dist / time, time, func() -> void:
		var c: Vector2 = p.center()
		FX.burst(c, 3, [Color("ffffff"), Color("d8f8ff"), Color("8ad8f0")], Vector2(30, 90), Vector2(0.15, 0.3), {"dir": -dir, "spread": 0.6, "drag": 4.0, "front": false})
		for e: Node2D in SpellEffect.in_circle(c, 18.0):
			if not hit.has(e):
				hit[e] = true
				var d := ctx.dmg(1.0, Vector2(signf(dir.x) * 150.0, -140.0))
				d.stagger = 20.0
				ctx.hit(e, d)
				FX.burst(e.center(), 8, Pal.school(&"storm"), Vector2(40, 120), Vector2(0.1, 0.3))
		Interactions.cinderflight(ctx, func(pt: EmberPatch) -> bool: return pt.contains(p.global_position, 8.0), dir))
	if ctx.upgraded:
		later(time, func() -> void:
			var g := Gale.new()
			g.ctx = ctx
			g.a = start
			g.b = p.global_position
			g.dir = dir
			ctx.spawn(g))


class Gale extends Node2D:
	var ctx: CastContext
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var dir := Vector2.RIGHT
	var t := 0.0
	var tick := 0.0
	const LIFE := 1.2

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		if tick <= 0.0:
			tick = 0.3
			var r := Rect2(minf(a.x, b.x), minf(a.y, b.y) - 30.0, absf(b.x - a.x), absf(b.y - a.y) + 34.0)
			for e: Node2D in SpellEffect.in_rect(r):
				var d := ctx.dmg(0.4, Vector2(signf(dir.x) * 120.0, -120.0))
				d.stagger = 8.0
				ctx.hit(e, d)
		for k in 2:
			var p := a.lerp(b, randf()) + Vector2(0, randf_range(-28, -4))
			FX.burst(p, 1, [Color("ffffff"), Color("c8f0ff"), Color("8ad8f0")], Vector2(80, 160), Vector2(0.1, 0.2), {"dir": dir.rotated(-0.3), "spread": 0.3, "drag": 3.0, "front": false})
		if t >= LIFE:
			queue_free()
