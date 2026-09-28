extends SpellEffect
## Ember Spear: a piercing spear of fire that sets targets burning.
## Upgrade (Splitting Spear): on its first hit the spear bursts into three shards.


func cast(ctx: CastContext) -> void:
	release_fx(ctx)
	Sfx.play("fire_release", -1.0)
	GameCamera3D.shake_all(1.2)
	var p := make_projectile(ctx, &"spear", ctx.p("speed", 16.7), ctx.p("range", 12.5), 0.25)
	p.pierce = int(ctx.p("pierce", 2))
	var split := [false]
	p.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
		var d := ctx.dmg(1.0, flat_dir(p.velocity) * 3.3 + Vector3(0, 1.2, 0))
		d.hit_pos = pos
		d.statuses.append({"id": &"burn", "duration": ctx.p("burn_time", 3.0), "power": 4.0 * ctx.power})
		ctx.hit(a, d)
		_impact(pos, 0.8)
		if ctx.upgraded and not split[0]:
			split[0] = true
			_split(ctx, pos, flat_dir(p.velocity), a))
	p.hit_wall.connect(func(pos: Vector3) -> void: _impact(pos, 1.0))


static func _impact(pos: Vector3, s: float) -> void:
	var ramp := Pal.school(&"fire")
	FX3.flash(pos, 0.5 * s, 0.08, Color(1.0, 0.8, 0.5), 3.5 * s)
	FX3.ring(pos, 0.1, 0.7 * s, 0.25, ramp, 1.0, false)
	FX3.burst(pos, int(18 * s), ramp, Vector2(1.6, 6.6), Vector2(0.2, 0.5), {"gravity": 8.0})
	FX3.burst(pos, 4, Pal.SMOKE, Vector2(0.2, 0.8), Vector2(0.5, 0.9), {"gravity": -1.0})
	Sfx.play("fire_impact", -3.0)
	TimeCtl.hitstop(0.035)
	GameCamera3D.shake_all(1.8)


static func _split(ctx: CastContext, pos: Vector3, dir: Vector3, skip: Node3D) -> void:
	for a in [-0.35, 0.0, 0.35]:
		var sp := Projectile.new()
		sp.style = &"ember"
		sp.ramp = Pal.school(&"fire")
		sp.velocity = dir.rotated(Vector3.UP, a) * 13.7
		sp.max_dist = 5.4
		sp.radius = 0.2
		sp.lit = false
		sp._hit.append(skip)
		ctx.spawn(sp)
		sp.global_position = pos
		sp.hit_actor.connect(func(b: Node3D, bpos: Vector3) -> void:
			var d := ctx.dmg(float(ctx.p("shard_mult", 0.5)))
			d.hit_pos = bpos
			d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0})
			ctx.hit(b, d)
			_impact(bpos, 0.5))
	FX3.burst(pos, 10, Pal.school(&"fire"), Vector2(2.5, 5.8), Vector2(0.15, 0.3), {"dir": dir, "spread": 1.2})
