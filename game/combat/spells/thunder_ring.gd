extends SpellEffect
## Thunder Ring: a crack of thunder around the wizard that hurls close
## enemies away. Wind from the blast scatters burning ground (Cinderflight).
## Upgrade (Rolling Thunder): a second, wider ring follows a beat later.


func cast(ctx: CastContext) -> void:
	_ring(ctx, ctx.caster.global_position, ctx.p("radius", 2.33), 1.0)
	if ctx.upgraded:
		later(0.3, func() -> void: _ring(ctx, ctx.caster.global_position, ctx.p("radius2", 3.5), float(ctx.p("second_mult", 0.6))))


static func _ring(ctx: CastContext, feet: Vector3, r: float, mult: float) -> void:
	var ramp := Pal.school(&"storm")
	var c := feet + Vector3(0, 0.9, 0)
	FX3.flash(c, 0.9, 0.1, Color(0.85, 0.95, 1.0), 6.0)
	FX3.decal(RUNE_L, feet + Vector3(0, 0.04, 0), 0.4, Color(ramp[1], 1.0), 0.4, r / 1.33, 4.0)
	FX3.ring(feet + Vector3(0, 0.05, 0), 0.3, r, 0.25, ramp, 3.0)
	FX3.ring(feet + Vector3(0, 0.06, 0), 0.15, r * 0.7, 0.2, ramp, 1.0)
	FX3.ring(c, 0.2, r * 0.6, 0.2, ramp, 1.0, false)
	for k in 10:
		var a := k * TAU / 10.0 + randf_range(-0.2, 0.2)
		var v := Vector3(cos(a), 0, sin(a))
		FX3.bolt(c + v * 0.35, feet + v * r * randf_range(0.8, 1.0) + Vector3(0, randf_range(0.1, 0.8), 0), 0.14, ramp, 0.12)
	FX3.burst(c, 28, ramp, Vector2(5.0, 11.0), Vector2(0.15, 0.35), {"drag": 4.0})
	FX3.burst(feet + Vector3(0, 0.1, 0), 14, Pal.DUST, Vector2(2.0, 5.0), Vector2(0.25, 0.45), {"dir": Vector3.UP, "spread": 3.0, "gravity": 6.0, "drag": 3.0})
	GameCamera3D.shake_all(4.0)
	Sfx.play("storm_thunder", 0.0)
	var any := false
	for e: Node3D in in_circle(feet, r):
		var d := ctx.dmg(mult, push(feet, e.global_position, float(ctx.p("push", 11.7)), 5.0))
		d.stagger = 30.0
		ctx.hit(e, d)
		any = true
	if any:
		TimeCtl.hitstop(0.05)
	Interactions.cinderflight(ctx, func(p: EmberPatch) -> bool: return flat(p.global_position, feet) < r + p.radius, Vector3.ZERO)
