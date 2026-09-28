extends SpellEffect
## Grave Needle: a swift bone-white needle that curses what it pierces.
## Upgrade (Needle Volley): three needles in a tight spread.


func cast(ctx: CastContext) -> void:
	release_fx(ctx, 0.7)
	Sfx.play("hex_release", -2.0)
	var spread := [0.0] if not ctx.upgraded else [-0.12, 0.0, 0.12]
	for a in spread:
		var p := make_projectile(ctx, &"needle", ctx.p("speed", 21.7), ctx.p("range", 14.2), 0.2)
		p.velocity = p.velocity.rotated(Vector3.UP, a)
		p.lit = a == 0.0
		p.hit_actor.connect(func(t: Node3D, pos: Vector3) -> void:
			var d := ctx.dmg(1.0, flat_dir(p.velocity) * 2.0)
			d.hit_pos = pos
			d.statuses.append({"id": &"curse", "duration": ctx.p("curse_time", 7.0)})
			ctx.hit(t, d)
			_impact(pos))
		p.hit_wall.connect(func(pos: Vector3) -> void: FX3.burst(pos, 6, Pal.school(&"hex"), Vector2(0.8, 2.5), Vector2(0.15, 0.3)))


static func _impact(pos: Vector3) -> void:
	var ramp := Pal.school(&"hex")
	FX3.flash(pos, 0.35, 0.07, Color(0.85, 0.75, 1.0), 2.0)
	FX3.decal(RUNE_S, pos, 0.35, Color(ramp[1], 1.0), 0.5, 1.0, 0.0, false)
	FX3.burst(pos, 10, ramp, Vector2(1.2, 3.8), Vector2(0.2, 0.4), {"drag": 2.0})
	FX3.burst(pos, 5, Pal.SPECTRAL, Vector2(0.4, 1.6), Vector2(0.3, 0.6), {"gravity": -1.6})
	Sfx.play("hex_impact", -4.0)
	TimeCtl.hitstop(0.03)
