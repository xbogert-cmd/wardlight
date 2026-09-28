extends SpellEffect
## Stormcaller basic attack: a short electric gust from the staff.
## Free, quick to repeat, modest knockback that is strongest up close.


func cast(ctx: CastContext) -> void:
	var ramp := Pal.school(&"storm")
	var o := ctx.origin
	var dir := ctx.dir
	var reach: float = ctx.p("range", 54.0)
	var half := deg_to_rad(float(ctx.p("arc", 36.0)))
	for a in [-0.35, 0.0, 0.35]:
		FX.bolt(o, o + dir.rotated(a + randf_range(-0.1, 0.1)) * reach * randf_range(0.7, 0.95), 0.12, ramp, 2.5)
	FX.arc(o, 8.0, reach * 0.9, dir.angle(), half * 2.0, 0.16, [Color("ffffff"), Color("d8f8ff"), Color("8ad8f0"), Color("52cfff")], 1.0)
	FX.burst(o, 12, [Color("ffffff"), Color("d8f8ff"), Color("8ad8f0")], Vector2(160, 260), Vector2(0.08, 0.18), {"dir": dir, "spread": 0.9, "drag": 7.0})
	FX.flash(o, 5.0, 0.06, Color(0.8, 0.95, 1.0, 0.8))
	Sfx.play("storm_gust", -5.0)
	var any := false
	for e: Node2D in SpellEffect.enemies():
		var v: Vector2 = e.center() - o
		var r: float = reach + e.data.body_size.x * 0.5
		if v.length() > r:
			continue
		if v.length() > 14.0 and absf(v.angle_to(dir)) > half:
			continue
		if not SpellEffect.has_los(o, e.center(), ctx.caster):
			continue
		var close := 1.0 - clampf(v.length() / r, 0.0, 1.0)
		var d := ctx.dmg(1.0, Vector2(signf(dir.x) * lerpf(60.0, 170.0, close), -50.0))
		d.hit_pos = e.center()
		d.stagger = ctx.data.damage * 1.2
		ctx.hit(e, d)
		FX.burst(e.center(), 6, ramp, Vector2(40, 110), Vector2(0.1, 0.25), {"gravity": 180.0})
		any = true
	if any:
		ctx.caster.mana.gain(ctx.caster.tuning.basic_hit_mana)
		TimeCtl.hitstop(0.025)
		GameCamera.shake_all(1.0)
		Sfx.play("storm_zap", -6.0)
