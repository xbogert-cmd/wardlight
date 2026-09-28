extends SpellEffect
## Pyromancer basic attack: a short flame pulse from the staff.


func cast(ctx: CastContext) -> void:
	var ramp := Pal.school(&"fire")
	var o := ctx.origin
	FX.flash(o, 4.0, 0.05, Color(1, 0.85, 0.5, 0.8))
	FX.burst(o, 8, ramp, Vector2(40, 120), Vector2(0.08, 0.2), {"dir": ctx.dir, "spread": 0.9, "drag": 6.0})
	Sfx.play("fire_pulse", -5.0)
	var p := make_projectile(ctx, &"fireball", 330.0, ctx.p("range", 64.0), 5.0)
	p.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void:
		var close := 1.0 - clampf(pos.distance_to(o) / 64.0, 0.0, 1.0)
		var d := ctx.dmg(1.0, Vector2(signf(ctx.dir.x) * lerpf(60.0, 160.0, close), -50.0))
		d.hit_pos = pos
		d.stagger = ctx.data.damage * 1.2
		ctx.hit(a, d)
		ctx.caster.mana.gain(ctx.caster.tuning.basic_hit_mana)
		FX.burst(pos, 8, ramp, Vector2(40, 120), Vector2(0.1, 0.3), {"gravity": 150.0})
		FX.ring(pos, 1.0, 8.0, 0.12, ramp)
		TimeCtl.hitstop(0.025)
		Sfx.play("fire_impact", -9.0))
	var fizz := func(pos: Vector2) -> void:
		FX.burst(pos, 6, ramp, Vector2(20, 60), Vector2(0.1, 0.25), {"gravity": -40.0})
	p.hit_wall.connect(fizz)
	p.expired.connect(fizz)
