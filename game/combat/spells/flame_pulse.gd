extends SpellEffect
## Pyromancer basic attack: a short flame pulse from the staff.


func cast(ctx: CastContext) -> void:
	var ramp := Pal.school(&"fire")
	var o := ctx.origin
	var reach: float = ctx.p("range", 2.67)
	FX3.flash(o, 0.25, 0.06, Color(1.0, 0.8, 0.5), 1.2)
	FX3.burst(o, 8, ramp, Vector2(1.6, 5.0), Vector2(0.08, 0.2), {"dir": ctx.dir, "spread": 0.9, "drag": 6.0})
	Sfx.play("fire_pulse", -5.0)
	var p := make_projectile(ctx, &"fireball", 13.7, reach, 0.3)
	var start := p.global_position
	p.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
		var close := 1.0 - clampf(flat(pos, start) / reach, 0.0, 1.0)
		var d := ctx.dmg(1.0, ctx.dir * lerpf(2.5, 6.6, close) + Vector3(0, 2.0, 0))
		d.hit_pos = pos
		d.stagger = ctx.data.damage * 1.2
		ctx.hit(a, d)
		ctx.caster.mana.gain(ctx.caster.tuning.basic_hit_mana)
		FX3.burst(pos, 8, ramp, Vector2(1.6, 5.0), Vector2(0.1, 0.3), {"gravity": 6.0})
		FX3.ring(pos, 0.05, 0.35, 0.12, ramp, 1.0, false)
		TimeCtl.hitstop(0.025)
		Sfx.play("fire_impact", -9.0))
	var fizz := func(pos: Vector3) -> void:
		FX3.burst(pos, 6, ramp, Vector2(0.8, 2.5), Vector2(0.1, 0.25), {"gravity": -1.6})
	p.hit_wall.connect(fizz)
	p.expired.connect(fizz)
