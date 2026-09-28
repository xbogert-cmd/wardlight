extends SpellEffect
## Hexbinder basic attack: a spectral spear-thrust from the staff that
## passes through a short line of enemies.


func cast(ctx: CastContext) -> void:
	var o := ctx.origin
	var reach: float = ctx.p("range", 60.0)
	var end := ray_end(o, o + ctx.dir * reach, ctx.caster)
	var ramp := Pal.SPECTRAL
	FX.bolt(o, end, 0.1, ramp, 1.0, 2.0, true)
	FX.burst(end, 5, ramp, Vector2(20, 60), Vector2(0.1, 0.25), {"dir": ctx.dir, "spread": 1.0})
	FX.burst(o, 6, Pal.school(&"hex"), Vector2(40, 100), Vector2(0.08, 0.2), {"dir": ctx.dir, "spread": 0.6, "drag": 6.0})
	Sfx.play("hex_thrust", -5.0)
	var any := false
	for e: Node2D in enemies():
		var hr: Rect2 = e.hurt_rect().grow(5.0)
		if _seg_hits(o, end, hr):
			var d := ctx.dmg(1.0, Vector2(signf(ctx.dir.x) * 110.0, -40.0))
			d.stagger = ctx.data.damage * 1.2
			ctx.hit(e, d)
			FX.burst(e.center(), 6, ramp, Vector2(40, 110), Vector2(0.1, 0.25), {"gravity": 150.0})
			any = true
	if any:
		ctx.caster.mana.gain(ctx.caster.tuning.basic_hit_mana)
		TimeCtl.hitstop(0.025)
		Sfx.play("hex_impact", -9.0)


static func _seg_hits(a: Vector2, b: Vector2, r: Rect2) -> bool:
	for k in 13:
		if r.has_point(a.lerp(b, k / 12.0)):
			return true
	return false
