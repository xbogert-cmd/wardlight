extends SpellEffect
## Hexbinder basic attack: a spectral spear-thrust from the staff that
## passes through a short line of enemies.


func cast(ctx: CastContext) -> void:
	var o := launch_point(ctx)
	var reach: float = ctx.p("range", 2.5)
	var end := ray_end(o, o + ctx.dir * reach, ctx.caster)
	var ramp := Pal.SPECTRAL
	FX3.bolt(ctx.origin, end, 0.1, ramp, 0.03)
	FX3.bolt(o, end, 0.1, ramp, 0.05)
	FX3.seg(o + Vector3(0, FX3.PX, 0), end + Vector3(0, FX3.PX, 0), ramp[0])
	FX3.glow(end, 0.12, Color(ramp[2], 0.9), 0.5, 0.8)
	FX3.burst(end, 5, ramp, Vector2(0.8, 2.5), Vector2(0.1, 0.25), {"dir": ctx.dir, "spread": 1.0})
	FX3.burst(ctx.origin, 6, Pal.school(&"hex"), Vector2(1.6, 4.2), Vector2(0.08, 0.2), {"dir": ctx.dir, "spread": 0.6, "drag": 6.0})
	Sfx.play("hex_thrust", -5.0)
	var any := false
	for e: Node3D in in_segment(o, end, 0.25):
		var d := ctx.dmg(1.0, ctx.dir * 4.6 + Vector3(0, 1.6, 0))
		d.stagger = ctx.data.damage * 1.2
		ctx.hit(e, d)
		FX3.burst(e.center(), 6, ramp, Vector2(1.6, 4.6), Vector2(0.1, 0.25), {"gravity": 6.0})
		any = true
	if any:
		ctx.caster.mana.gain(ctx.caster.tuning.basic_hit_mana)
		TimeCtl.hitstop(0.025)
		Sfx.play("hex_impact", -9.0)
