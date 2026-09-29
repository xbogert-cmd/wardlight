extends SpellEffect
## Chain Current (storm, a gift of the Deepwillow): a bolt strikes the
## target nearest the aim and leaps from enemy to enemy within reach, each
## jump weaker than the last. Upgrade (Endless Current): more jumps, and a
## jump may return to an enemy already struck (never the one it came from).


func cast(ctx: CastContext) -> void:
	var ramp := Pal.school(&"storm")
	release_fx(ctx, 0.9)
	Sfx.play("storm_release", -1.0)
	var first: Node3D = ctx.target if is_instance_valid(ctx.target) else null
	if first == null:
		first = nearest(ctx.aim_point, float(ctx.p("reach", 4.0)), [], ctx.caster)
	if first == null:
		FX3.bolt(ctx.origin, ctx.aim_point + Vector3(0, 0.6, 0), 0.15, ramp, 0.2)
		Sfx.play("storm_fizzle", -4.0)
		return
	FX3.bolt(ctx.origin, first.center(), 0.2, ramp, 0.2)
	_strike(ctx, first, 1.0)
	var hit := [first]
	var prev := first
	var mult := 1.0
	for k in int(ctx.p("jumps", 4)):
		mult *= float(ctx.p("falloff", 0.8))
		var skip: Array = [prev] if ctx.upgraded else hit
		var e := nearest(prev.call("center"), float(ctx.p("reach", 4.0)), skip, ctx.caster)
		if e == null:
			break
		var from: Vector3 = prev.center()
		var m := mult
		later(0.07 * (k + 1), func() -> void:
			if is_instance_valid(e) and e.is_alive():
				FX3.bolt(from, e.center(), 0.18, ramp, 0.16)
				_strike(ctx, e, m))
		hit.append(e)
		prev = e


static func _strike(ctx: CastContext, e: Node3D, mult: float) -> void:
	var ramp := Pal.school(&"storm")
	var d := ctx.dmg(mult, Vector3(0, 1.2, 0))
	d.hit_pos = e.center()
	d.stagger = 8.0
	ctx.hit(e, d)
	FX3.burst(e.center(), 10, ramp, Vector2(1.5, 5.0), Vector2(0.1, 0.3), {"drag": 3.0})
	Sfx.play("storm_impact", -6.0, 0.15)
