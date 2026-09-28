extends SpellEffect
## Thunder Ring: a crack of thunder around the wizard that hurls close
## enemies away. Wind from the blast scatters burning ground (Cinderflight).
## Upgrade (Rolling Thunder): a second, wider ring follows a beat later.


func cast(ctx: CastContext) -> void:
	_ring(ctx, ctx.caster.center(), ctx.p("radius", 56.0), 1.0)
	if ctx.upgraded:
		later(0.3, func() -> void: _ring(ctx, ctx.caster.center(), ctx.p("radius2", 84.0), float(ctx.p("second_mult", 0.6))))


static func _ring(ctx: CastContext, c: Vector2, r: float, mult: float) -> void:
	var ramp := Pal.school(&"storm")
	FX.flash(c, 10.0, 0.08, Color(1, 1, 1, 0.8))
	FX.sprite(RUNE_L, c, 0.35, ramp[1], 0.4, r / 32.0, 4.0, false)
	FX.ring(c, 6.0, r, 0.25, ramp, 3.0, true)
	FX.ring(c, 3.0, r * 0.7, 0.2, ramp, 1.0, true)
	for k in 10:
		var a := k * TAU / 10.0 + randf_range(-0.2, 0.2)
		FX.bolt(c + Vector2.from_angle(a) * 8.0, c + Vector2.from_angle(a) * r * randf_range(0.8, 1.0), 0.14, ramp, 3.0)
	FX.burst(c, 24, ramp, Vector2(120, 260), Vector2(0.15, 0.35), {"drag": 4.0, "glow": true})
	GameCamera.shake_all(4.0)
	Sfx.play("storm_thunder", 0.0)
	var any := false
	for e: Node2D in SpellEffect.in_circle(c, r):
		var away: Vector2 = (e.center() - c).normalized()
		var d := ctx.dmg(mult, Vector2(signf(away.x) * float(ctx.p("push", 280.0)), -170.0))
		d.stagger = 30.0
		ctx.hit(e, d)
		any = true
	if any:
		TimeCtl.hitstop(0.05)
	Interactions.cinderflight(ctx, func(p: EmberPatch) -> bool: return p.global_position.distance_to(c) < r + p.width * 0.5,
		Vector2.UP)
