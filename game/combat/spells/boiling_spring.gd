extends SpellEffect
## Boiling Spring (fire, a gift of the Deepwillow): the aimed ground bubbles
## for a moment (the tell), then a scalding geyser erupts, tossing small
## enemies up and burning them. Upgrade (Twin Spring): it erupts again.

const STEAM := [Color("ffffff"), Color("e8f4ff"), Color("b8d0e0"), Color("7890a0")]


func cast(ctx: CastContext) -> void:
	var ground := ground_at(ctx.aim_point, ctx.caster)
	var r: float = ctx.p("radius", 1.8)
	var delay: float = ctx.p("delay", 0.6)
	release_fx(ctx, 0.8)
	Sfx.play("fire_release", -4.0)
	FX3.tele_ring(ground, r, delay, Color(1.0, 0.6, 0.3, 0.6))
	for k in 6:
		later(k * delay / 6.0, func() -> void:
			FX3.burst(ground + Vector3(randf_range(-r, r) * 0.6, 0.05, randf_range(-r, r) * 0.6), 4, STEAM, Vector2(0.3, 1.2), Vector2(0.2, 0.4), {"dir": Vector3.UP, "spread": 0.8, "gravity": 3.0}))
	later(delay, func() -> void: _erupt(ctx, ground, r, 1.0))
	if ctx.upgraded:
		later(delay + float(ctx.p("second_delay", 1.0)), func() -> void: _erupt(ctx, ground, r, float(ctx.p("second_mult", 0.7))))


static func _erupt(ctx: CastContext, at: Vector3, r: float, mult: float) -> void:
	var ramp := Pal.school(&"fire")
	FX3.flash(at + Vector3(0, 0.8, 0), 1.0, 0.12, Color(1.0, 0.85, 0.6), 5.0)
	FX3.ring(at + Vector3(0, 0.05, 0), 0.2, r, 0.3, ramp, 3.0)
	FX3.burst(at + Vector3(0, 0.2, 0), 46, STEAM, Vector2(4.0, 11.0), Vector2(0.4, 0.9), {"dir": Vector3.UP, "spread": 0.7, "gravity": 7.0})
	FX3.burst(at + Vector3(0, 0.2, 0), 20, ramp, Vector2(3.0, 8.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 1.2, "gravity": 9.0})
	FX3.smoke(CLOUD, at + Vector3(0, 2.2, 0), 1.2, Color(0.85, 0.88, 0.92, 0.6), 0.4, 0.9)
	GameCamera3D.shake_all(3.0)
	Sfx.play("fire_burst", -2.0)
	var any := false
	for e: Node3D in in_circle(at, r):
		var d := ctx.dmg(mult, push(at, e.global_position, 2.0, 7.0))
		d.stagger = 25.0
		d.statuses.append({"id": &"burn", "duration": 2.5, "power": 3.0 * ctx.power})
		ctx.hit(e, d)
		any = true
	if any:
		TimeCtl.hitstop(0.05)
