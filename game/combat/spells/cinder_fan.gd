extends SpellEffect
## Cinder Fan: a close cone of flame that burns and leaves embers on the ground.
## Upgrade (Wildfire): a second, longer wave rolls out and more ground catches.

const HALF := 0.56  # ~32°


func cast(ctx: CastContext) -> void:
	var feet: Vector3 = ctx.caster.global_position
	var dir := ctx.dir
	release_fx(ctx, 0.8)
	Sfx.play("fire_whoosh", -1.0)
	_wave(ctx, feet, dir, ctx.p("reach", 2.9), 1.0)
	_patches(ctx, feet, dir, int(ctx.p("patches", 1)), ctx.p("reach", 2.9))
	if ctx.upgraded:
		later(0.16, func() -> void:
			_wave(ctx, feet, dir, ctx.p("reach2", 4.8), 0.6)
			Sfx.play("fire_whoosh", -4.0))


static func _wave(ctx: CastContext, feet: Vector3, dir: Vector3, reach: float, mult: float) -> void:
	var ramp := Pal.school(&"fire")
	var o := feet + Vector3(0, 0.9, 0) + dir * 0.3
	FX3.arc(feet + Vector3(0, 0.05, 0), 0.4, reach, dir, HALF * 2.0, 0.22, ramp, 3.0)
	FX3.arc(feet + Vector3(0, 0.06, 0), 0.25, reach * 0.75, dir, HALF * 1.6, 0.18, ramp, 2.0)
	for k in 34:
		var v := dir.rotated(Vector3.UP, randf_range(-HALF, HALF)) + Vector3(0, randf_range(-0.25, 0.15), 0)
		FX3.burst(o, 1, ramp, Vector2(reach * 2.0, reach * 3.6), Vector2(0.18, 0.32),
			{"dir": v, "spread": 0.05, "drag": 6.0, "size": 2.0 if randf() < 0.3 else 1.0})
	FX3.burst(o, 6, Pal.SMOKE, Vector2(0.8, 2.5), Vector2(0.5, 0.8), {"dir": dir, "spread": 1.0, "gravity": -0.8})
	FX3.light(o + dir * reach * 0.5, Color(1.0, 0.55, 0.2), 4.0, reach * 2.5, 0.3)
	GameCamera3D.shake_all(1.5)
	for e: Node3D in in_cone(feet, dir, reach, HALF + 0.15, ctx.caster):
		var d := ctx.dmg(mult, dir * 5.0 + Vector3(0, 2.5, 0))
		d.statuses.append({"id": &"burn", "duration": 2.5, "power": 4.0 * ctx.power})
		ctx.hit(e, d)


static func _patches(ctx: CastContext, feet: Vector3, dir: Vector3, n: int, reach: float) -> void:
	for k in n:
		var side := 0.0 if n == 1 else lerpf(-HALF * 0.6, HALF * 0.6, float(k) / (n - 1))
		var at := feet + dir.rotated(Vector3.UP, side) * reach * 0.7
		EmberPatch.place(ctx.world, at, 0.75, 4.0, ctx.caster)
