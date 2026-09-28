extends SpellEffect
## Ashfall: a smouldering cloud forms over the aimed spot and rains embers,
## leaving the ground burning. Upgrade (Meteor Ashfall): a meteor strikes first.

const CLOUD_H := 3.6


func cast(ctx: CastContext) -> void:
	var ground := ground_at(ctx.aim_point, ctx.caster)
	var cloud := ground + Vector3(0, CLOUD_H, 0)
	release_fx(ctx, 0.8)
	Sfx.play("fire_release", -3.0)
	var ramp := Pal.school(&"fire")
	var width: float = ctx.p("width", 2.9)
	var dur: float = ctx.p("duration", 1.4)
	FX3.decal(RUNE_L, ground + Vector3(0, 0.04, 0), 0.7, Color(ramp[2], 0.7), 0.9, width / 2.4, 1.5)
	FX3.tele_ring(ground, width * 0.5, 0.45, Color(ramp[2], 0.5))
	FX3.smoke(CLOUD, cloud, dur + 0.9, Color(0.2, 0.15, 0.18, 0.95), 0.5, 1.0)
	FX3.smoke(CLOUD, cloud + Vector3(0.25, -0.15, 0.1), dur + 0.8, Color(0.33, 0.2, 0.18, 0.9), 0.4, 0.85)
	FX3.glow(cloud - Vector3(0, 0.4, 0), dur + 0.6, Color(ramp[3], 0.8), 0.9, 1.4, GLOW_L)
	FX3.light(cloud - Vector3(0, 0.8, 0), Color(1.0, 0.45, 0.2), 3.0, 7.0, dur + 0.8)
	for k in 6:
		later(0.1 + k * 0.25, func() -> void:
			FX3.burst(cloud - Vector3(0, 0.4, 0), 6, ramp, Vector2(0.2, 1.0), Vector2(0.3, 0.6), {"jitter": 1.1, "gravity": 1.2})
			FX3.burst(cloud, 5, Pal.SMOKE, Vector2(0.2, 0.8), Vector2(0.8, 1.2), {"jitter": 1.2, "gravity": -0.3}))
	if ctx.upgraded:
		later(0.3, func() -> void: _meteor(ctx, cloud, ground))
	var drops: int = int(ctx.p("drops", 16))
	for k in drops:
		later(0.45 + k * dur / drops, func() -> void: _drop(ctx, cloud, width))
	later(0.6, func() -> void:
		EmberPatch.place(ctx.world, ground, width * 0.45, 4.5, ctx.caster)
		Sfx.play("fire_rain", -4.0))


static func _drop(ctx: CastContext, cloud: Vector3, width: float) -> void:
	var p := Projectile.new()
	p.style = &"ember"
	p.ramp = Pal.school(&"fire")
	p.velocity = Vector3(randf_range(-0.8, 0.8), -10.8, randf_range(-0.8, 0.8))
	p.max_dist = CLOUD_H + 2.0
	p.radius = 0.2
	p.lit = false
	ctx.spawn(p)
	var a := randf() * TAU
	var r := sqrt(randf()) * width * 0.5
	p.global_position = cloud + Vector3(cos(a) * r, randf_range(-0.3, -0.1), sin(a) * r)
	p.hit_actor.connect(func(t: Node3D, pos: Vector3) -> void:
		var d := ctx.dmg(1.0, Vector3(0, 0.8, 0))
		d.hit_pos = pos
		d.stagger = 3.0
		d.statuses.append({"id": &"burn", "duration": 2.5, "power": 3.0 * ctx.power})
		ctx.hit(t, d)
		FX3.burst(pos, 5, Pal.school(&"fire"), Vector2(1.2, 3.3), Vector2(0.1, 0.3), {"gravity": 6.0}))
	p.hit_wall.connect(func(pos: Vector3) -> void:
		FX3.burst(pos, 4, Pal.school(&"fire"), Vector2(0.8, 2.9), Vector2(0.15, 0.3), {"dir": Vector3.UP, "spread": 2.0, "gravity": 8.0}))


static func _meteor(ctx: CastContext, cloud: Vector3, ground: Vector3) -> void:
	var p := Projectile.new()
	p.style = &"fireball"
	p.ramp = Pal.school(&"fire")
	p.velocity = Vector3(0, -17.5, 0)
	p.max_dist = CLOUD_H + 2.0
	p.radius = 0.4
	p.pierce = 99
	ctx.spawn(p, cloud)
	var boom := func(pos: Vector3) -> void:
		var ramp := Pal.school(&"fire")
		var at := ground_at(pos, ctx.caster)
		FX3.flash(at + Vector3(0, 0.6, 0), 1.2, 0.15, Color(1.0, 0.75, 0.45), 8.0)
		FX3.ring(at + Vector3(0, 0.05, 0), 0.2, 1.8, 0.35, ramp, 3.0)
		FX3.ring(at + Vector3(0, 0.06, 0), 0.1, 1.2, 0.3, ramp, 1.0)
		FX3.burst(at + Vector3(0, 0.2, 0), 40, ramp, Vector2(3.3, 10.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 2.6, "gravity": 12.0})
		FX3.burst(at + Vector3(0, 0.3, 0), 12, Pal.SMOKE, Vector2(0.8, 2.5), Vector2(0.8, 1.2), {"gravity": -1.2, "jitter": 0.4})
		for e: Node3D in SpellEffect.in_circle(at, 1.7):
			var d := ctx.dmg(float(ctx.p("meteor_mult", 4.0)), SpellEffect.push(at, e.global_position, 7.5, 6.0))
			d.statuses.append({"id": &"burn", "duration": 3.0, "power": 4.0 * ctx.power})
			ctx.hit(e, d)
		GameCamera3D.shake_all(5.0)
		TimeCtl.hitstop(0.06)
		Sfx.play("fire_burst")
	p.hit_wall.connect(boom)
	p.expired.connect(boom)
