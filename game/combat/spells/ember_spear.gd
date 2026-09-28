extends SpellEffect
## Ember Spear: a piercing spear of fire that sets targets burning.
## Upgrade (Splitting Spear): on its first hit the spear bursts into three shards.


func cast(ctx: CastContext) -> void:
	release_fx(ctx)
	Sfx.play("fire_release", -1.0)
	GameCamera.shake_all(1.2)
	var p := make_projectile(ctx, &"spear", ctx.p("speed", 400.0), ctx.p("range", 300.0), 5.0)
	p.pierce = int(ctx.p("pierce", 2))
	var split := [false]
	p.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void:
		var d := ctx.dmg(1.0, Vector2(signf(p.velocity.x) * 80.0, -30.0))
		d.hit_pos = pos
		d.statuses.append({"id": &"burn", "duration": ctx.p("burn_time", 3.0), "power": 4.0 * ctx.power})
		ctx.hit(a, d)
		_impact(pos, 0.8)
		if ctx.upgraded and not split[0]:
			split[0] = true
			_split(ctx, pos, p.velocity.normalized(), a))
	p.hit_wall.connect(func(pos: Vector2) -> void: _impact(pos, 1.0))


static func _impact(pos: Vector2, s: float) -> void:
	var ramp := Pal.school(&"fire")
	FX.flash(pos, 6.0 * s, 0.07, Color(1, 0.9, 0.6, 0.9))
	FX.ring(pos, 2.0, 16.0 * s, 0.25, ramp)
	FX.burst(pos, int(16 * s), ramp, Vector2(40, 160), Vector2(0.2, 0.5), {"gravity": 200.0, "glow": true})
	FX.burst(pos, 4, Pal.SMOKE, Vector2(5, 20), Vector2(0.5, 0.9), {"add": false, "gravity": -25.0, "front": false})
	Sfx.play("fire_impact", -3.0)
	TimeCtl.hitstop(0.035)
	GameCamera.shake_all(1.8)


static func _split(ctx: CastContext, pos: Vector2, dir: Vector2, skip: Node2D) -> void:
	for a in [-0.35, 0.0, 0.35]:
		var sp := Projectile.new()
		sp.style = &"ember"
		sp.ramp = Pal.school(&"fire")
		sp.velocity = dir.rotated(a) * 330.0
		sp.max_dist = 130.0
		sp.radius = 3.0
		sp._hit.append(skip)
		ctx.spawn(sp)
		sp.global_position = pos
		sp.hit_actor.connect(func(b: Node2D, bpos: Vector2) -> void:
			var d := ctx.dmg(float(ctx.p("shard_mult", 0.5)))
			d.hit_pos = bpos
			d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0})
			ctx.hit(b, d)
			_impact(bpos, 0.5))
	FX.burst(pos, 10, Pal.school(&"fire"), Vector2(60, 140), Vector2(0.15, 0.3), {"dir": dir, "spread": 1.2})
