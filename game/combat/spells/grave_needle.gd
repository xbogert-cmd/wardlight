extends SpellEffect
## Grave Needle: a swift bone-white needle that curses what it pierces.
## Upgrade (Needle Volley): three needles in a tight spread.


func cast(ctx: CastContext) -> void:
	release_fx(ctx, 0.7)
	Sfx.play("hex_release", -2.0)
	var spread := [0.0] if not ctx.upgraded else [-0.12, 0.0, 0.12]
	for a in spread:
		var p := make_projectile(ctx, &"needle", ctx.p("speed", 520.0), ctx.p("range", 340.0), 4.0)
		p.velocity = p.velocity.rotated(a)
		p.hit_actor.connect(func(t: Node2D, pos: Vector2) -> void:
			var d := ctx.dmg(1.0, Vector2(signf(p.velocity.x) * 50.0, 0))
			d.hit_pos = pos
			d.statuses.append({"id": &"curse", "duration": ctx.p("curse_time", 7.0)})
			ctx.hit(t, d)
			_impact(pos))
		p.hit_wall.connect(func(pos: Vector2) -> void: FX.burst(pos, 6, Pal.school(&"hex"), Vector2(20, 60), Vector2(0.15, 0.3)))


static func _impact(pos: Vector2) -> void:
	var ramp := Pal.school(&"hex")
	FX.flash(pos, 5.0, 0.06, Color(0.9, 0.8, 1.0, 0.8))
	FX.sprite(RUNE_S, pos, 0.35, ramp[1], 0.5, 1.0, -6.0)
	FX.burst(pos, 10, ramp, Vector2(30, 90), Vector2(0.2, 0.4), {"drag": 2.0})
	FX.burst(pos, 5, Pal.SPECTRAL, Vector2(10, 40), Vector2(0.3, 0.6), {"gravity": -40.0})
	Sfx.play("hex_impact", -4.0)
	TimeCtl.hitstop(0.03)
