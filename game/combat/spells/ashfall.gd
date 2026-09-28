extends SpellEffect
## Ashfall: a smouldering cloud forms over the aimed spot and rains embers,
## leaving the ground burning. Upgrade (Meteor Ashfall): a meteor strikes first.


func cast(ctx: CastContext) -> void:
	var ground := ground_below(ctx.aim_point, ctx.caster, 260.0)
	var cloud := Vector2(ground.x, ground.y - 84.0)
	cloud = ray_end(ground + Vector2(0, -2), cloud, ctx.caster)
	release_fx(ctx, 0.8)
	Sfx.play("fire_release", -3.0)
	var ramp := Pal.school(&"fire")
	FX.sprite(RUNE_L, ground + Vector2(0, -2), 0.6, Color(ramp[2], 0.6), 0.9, 1.0, 1.5, false)
	var dur: float = ctx.p("duration", 1.4)
	FX.sprite(FX.tex("cloud96.png"), cloud, dur + 0.9, Color(0.2, 0.15, 0.18, 0.95), 0.5, 1.0, 0.0, false, false)
	FX.sprite(FX.tex("cloud96.png"), cloud + Vector2(6, 4), dur + 0.8, Color(0.33, 0.2, 0.18, 0.9), 0.4, 0.8, 0.0, false, false)
	FX.sprite(GLOW_L, cloud + Vector2(0, 10), dur + 0.6, Color(ramp[3], 0.8), 0.9, 1.4, 0.0, false)
	for k in 6:
		later(0.1 + k * 0.25, func() -> void:
			FX.burst(cloud + Vector2(0, 12), 6, ramp, Vector2(5, 25), Vector2(0.3, 0.6), {"jitter": 26.0, "gravity": 30.0})
			FX.burst(cloud, 5, Pal.SMOKE, Vector2(5, 20), Vector2(0.8, 1.2), {"add": false, "front": false, "jitter": 30.0, "gravity": -8.0}))
	if ctx.upgraded:
		later(0.3, func() -> void: _meteor(ctx, cloud, ground))
	var width: float = ctx.p("width", 70.0)
	var drops: int = int(ctx.p("drops", 16))
	for k in drops:
		later(0.45 + k * float(ctx.p("duration", 1.4)) / drops, func() -> void: _drop(ctx, cloud, width))
	later(0.6, func() -> void:
		EmberPatch.place(ctx.world, ground + Vector2(0, -6), width * 0.9, 4.5, ctx.caster)
		Sfx.play("fire_rain", -4.0))


static func _drop(ctx: CastContext, cloud: Vector2, width: float) -> void:
	var p := Projectile.new()
	p.style = &"ember"
	p.ramp = Pal.school(&"fire")
	p.velocity = Vector2(randf_range(-20, 20), 260.0)
	p.max_dist = 200.0
	p.radius = 3.0
	p.pierce = 0
	ctx.spawn(p)
	p.global_position = cloud + Vector2(randf_range(-width * 0.5, width * 0.5), randf_range(-6, 6))
	p.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void:
		var d := ctx.dmg(1.0, Vector2(0, -20))
		d.hit_pos = pos
		d.stagger = 3.0
		d.statuses.append({"id": &"burn", "duration": 2.5, "power": 3.0 * ctx.power})
		ctx.hit(a, d)
		FX.burst(pos, 5, Pal.school(&"fire"), Vector2(30, 80), Vector2(0.1, 0.3), {"gravity": 150.0}))
	p.hit_wall.connect(func(pos: Vector2) -> void:
		FX.burst(pos, 4, Pal.school(&"fire"), Vector2(20, 70), Vector2(0.15, 0.3), {"dir": Vector2.UP, "spread": 2.0, "gravity": 200.0}))


static func _meteor(ctx: CastContext, cloud: Vector2, ground: Vector2) -> void:
	var p := Projectile.new()
	p.style = &"fireball"
	p.ramp = Pal.school(&"fire")
	p.velocity = Vector2(0, 420.0)
	p.max_dist = 300.0
	p.radius = 7.0
	p.pierce = 99
	ctx.spawn(p)
	p.global_position = cloud
	var boom := func(pos: Vector2) -> void:
		var ramp := Pal.school(&"fire")
		FX.flash(pos, 14.0, 0.1, Color(1, 0.9, 0.6, 0.9))
		FX.sprite(GLOW_L, pos, 0.4, ramp[2], 0.8, 1.6)
		FX.ring(pos, 4.0, 40.0, 0.35, ramp, 2.0)
		FX.burst(pos, 36, ramp, Vector2(80, 240), Vector2(0.3, 0.6), {"dir": Vector2.UP, "spread": 2.6, "gravity": 300.0, "glow": true})
		FX.burst(pos, 10, Pal.SMOKE, Vector2(20, 60), Vector2(0.8, 1.2), {"add": false, "gravity": -30.0, "front": false, "jitter": 10.0})
		for e: Node2D in SpellEffect.in_circle(pos, 40.0):
			var d := ctx.dmg(float(ctx.p("meteor_mult", 4.0)), Vector2(signf(e.center().x - pos.x) * 180.0, -200.0))
			d.statuses.append({"id": &"burn", "duration": 3.0, "power": 4.0 * ctx.power})
			ctx.hit(e, d)
		GameCamera.shake_all(5.0)
		TimeCtl.hitstop(0.06)
		Sfx.play("fire_burst")
	p.hit_wall.connect(boom)
	p.expired.connect(boom)
	p.hit_actor.connect(func(_a: Node2D, _pos: Vector2) -> void: pass)
