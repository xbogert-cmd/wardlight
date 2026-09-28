extends SpellEffect
## Stormcaller basic attack: a short electric gust from the staff.
## Free, quick to repeat, modest knockback that is strongest up close.


func cast(ctx: CastContext) -> void:
	var ramp := Pal.school(&"storm")
	var o := ctx.origin
	var feet: Vector3 = ctx.caster.global_position
	var dir := ctx.dir
	var reach: float = ctx.p("range", 2.25)
	var half := deg_to_rad(float(ctx.p("arc", 36.0)))
	var mid := Vector3(o.x, feet.y + 1.0, o.z)
	for a in [-0.35, 0.0, 0.35]:
		FX3.bolt(o, mid + dir.rotated(Vector3.UP, a + randf_range(-0.1, 0.1)) * reach * randf_range(0.7, 0.95), 0.12, ramp, 0.1)
	FX3.arc(feet + Vector3(0, 0.05, 0), 0.4, reach * 0.9, dir, half * 2.0, 0.16, [Color("ffffff"), Color("d8f8ff"), Color("8ad8f0"), Color("52cfff")], 1.0)
	FX3.burst(o, 12, WIND, Vector2(6.5, 11.0), Vector2(0.08, 0.18), {"dir": dir, "spread": 0.9, "drag": 7.0})
	FX3.flash(o, 0.25, 0.06, Color(0.8, 0.95, 1.0), 1.2)
	Sfx.play("storm_gust", -5.0)
	var any := false
	for e: Node3D in in_cone(feet, dir, reach, half, ctx.caster):
		var dist := flat(feet, e.global_position)
		var close := 1.0 - clampf(dist / (reach + e.radius()), 0.0, 1.0)
		var d := ctx.dmg(1.0, dir * lerpf(2.5, 7.0, close) + Vector3(0, 2.0, 0))
		d.hit_pos = e.center()
		d.stagger = ctx.data.damage * 1.2
		ctx.hit(e, d)
		FX3.burst(e.center(), 6, ramp, Vector2(1.6, 4.6), Vector2(0.1, 0.25), {"gravity": 7.5})
		any = true
	if any:
		ctx.caster.mana.gain(ctx.caster.tuning.basic_hit_mana)
		TimeCtl.hitstop(0.025)
		GameCamera3D.shake_all(1.0)
		Sfx.play("storm_zap", -6.0)
