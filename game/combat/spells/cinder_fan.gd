extends SpellEffect
## Cinder Fan: a close cone of flame that burns and leaves embers on the ground.
## Upgrade (Wildfire): a second, longer wave rolls out and more ground catches.


func cast(ctx: CastContext) -> void:
	var o := ctx.origin
	var dir := Vector2(signf(ctx.dir.x) if ctx.dir.x != 0.0 else 1.0, clampf(ctx.dir.y, -0.5, 0.5)).normalized()
	release_fx(ctx, 0.8)
	Sfx.play("fire_whoosh", -1.0)
	_wave(ctx, o, dir, ctx.p("reach", 70.0), 1.0)
	_patches(ctx, o, dir, int(ctx.p("patches", 1)), ctx.p("reach", 70.0))
	if ctx.upgraded:
		later(0.16, func() -> void:
			_wave(ctx, o, dir, ctx.p("reach2", 115.0), 0.6)
			Sfx.play("fire_whoosh", -4.0))


static func _wave(ctx: CastContext, o: Vector2, dir: Vector2, reach: float, mult: float) -> void:
	var ramp := Pal.school(&"fire")
	var half := deg_to_rad(32.0)
	FX.arc(o, 10.0, reach, dir.angle(), half * 2.0, 0.22, ramp, 3.0)
	FX.arc(o, 6.0, reach * 0.75, dir.angle(), half * 1.6, 0.18, ramp, 2.0)
	for k in 26:
		var a := dir.angle() + randf_range(-half, half)
		FX.burst(o, 1, ramp, Vector2(reach * 2.0, reach * 3.6), Vector2(0.18, 0.32),
			{"dir": Vector2.from_angle(a), "spread": 0.05, "drag": 6.0, "size": 2 if randf() < 0.3 else 1, "glow": true})
	FX.burst(o, 6, Pal.SMOKE, Vector2(20, 60), Vector2(0.5, 0.8), {"dir": dir, "spread": 1.0, "add": false, "gravity": -20.0, "front": false})
	GameCamera.shake_all(1.5)
	for e: Node2D in enemies():
		var v: Vector2 = e.center() - o
		var r: float = reach + e.data.body_size.x * 0.5
		if v.length() > r or (v.length() > 14.0 and absf(v.angle_to(dir)) > half + 0.15):
			continue
		if not has_los(o, e.center(), ctx.caster):
			continue
		var d := ctx.dmg(mult, Vector2(dir.x * 120.0, -60.0))
		d.statuses.append({"id": &"burn", "duration": 2.5, "power": 4.0 * ctx.power})
		ctx.hit(e, d)


static func _patches(ctx: CastContext, o: Vector2, dir: Vector2, n: int, reach: float) -> void:
	for k in n:
		var at := o + dir * reach * (0.55 + 0.4 * k / maxf(1.0, n))
		EmberPatch.place(ctx.world, at, 36.0, 4.0, ctx.caster)
