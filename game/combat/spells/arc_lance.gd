extends SpellEffect
## Arc Lance: lightning gathered at the staff, released through a rune circle
## as a fast bolt carrying real light. Upgrade (Forked Lance): the impact forks
## to 2 more enemies.


func cast(ctx: CastContext) -> void:
	var ramp := Pal.school(&"storm")
	var o := ctx.origin
	# release: flash, magic circle facing the shot, shock arcs, recoil sparks
	FX3.flash(o, 0.4, 0.08, Color(0.8, 0.95, 1.0), 3.0)
	FX3.glow(o, 0.2, Color(ramp[2], 0.9), 0.8, 1.4)
	FX3.decal(RUNE_M, o, 0.3, Color(ramp[1], 1.0), 0.25, 0.6, 0.0, false)
	FX3.arc(ctx.caster.global_position + Vector3(0, 0.05, 0), 0.4, 1.4, ctx.dir, 1.4, 0.16, ramp, 1.0)
	FX3.burst(o, 16, ramp, Vector2(2.5, 7.5), Vector2(0.1, 0.25), {"dir": ctx.dir, "spread": 1.0, "drag": 5.0})
	FX3.burst(o, 6, ramp, Vector2(0.8, 3.0), Vector2(0.15, 0.3), {"dir": -ctx.dir, "spread": 1.6, "drag": 4.0})
	for k in 3:
		FX3.bolt(o, o + ctx.dir.rotated(Vector3.UP, randf_range(-0.9, 0.9)) * randf_range(0.4, 0.8) + Vector3(0, randf_range(-0.2, 0.3), 0), 0.07, ramp, 0.08)
	GameCamera3D.shake_all(1.5)
	Sfx.play("storm_release", -1.0)
	var pr := make_projectile(ctx, &"arc", float(ctx.p("speed", 19.6)), float(ctx.p("range", 13.75)), 0.25)
	pr.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void: _impact(ctx, a, pos, pr.velocity))
	pr.hit_wall.connect(func(pos: Vector3) -> void: _impact(ctx, null, pos, pr.velocity))
	pr.expired.connect(func(pos: Vector3) -> void:
		FX3.burst(pos, 10, ramp, Vector2(0.8, 3.0), Vector2(0.15, 0.3), {"drag": 3.0})
		FX3.ring(pos, 0.05, 0.35, 0.15, ramp, 1.0, false))


func _impact(ctx: CastContext, actor: Node3D, pos: Vector3, vel: Vector3) -> void:
	var ramp := Pal.school(&"storm")
	FX3.flash(pos, 0.6, 0.1, Color(0.85, 0.95, 1.0), 4.0)
	FX3.glow(pos, 0.3, Color(ramp[2], 1.0), 1.2, 2.2)
	FX3.ring(pos, 0.1, 1.1, 0.3, ramp, 1.0, false)
	var ground := ground_at(pos, ctx.caster)
	FX3.decal(RUNE_M, ground + Vector3(0, 0.04, 0), 0.4, Color(ramp[1], 0.9), 0.3, 0.9, 3.0)
	FX3.ring(ground + Vector3(0, 0.05, 0), 0.2, 1.4, 0.35, ramp, 1.0)
	for k in 6:
		FX3.bolt(pos, pos + Vector3(randf_range(-1, 1), randf_range(-0.6, 0.8), randf_range(-1, 1)).normalized() * randf_range(0.5, 1.1), 0.14, ramp, 0.12)
	FX3.burst(pos, 26, ramp, Vector2(2.0, 7.0), Vector2(0.15, 0.5), {"gravity": 9.0, "drag": 1.0})
	FX3.burst(pos, 5, Pal.SMOKE, Vector2(0.2, 0.8), Vector2(0.5, 0.8), {"gravity": -0.8})
	if actor == null:
		Sfx.play("storm_fizzle", -4.0)
		return
	var d := ctx.dmg(1.0, flat_dir(vel, ctx.dir) * 4.6 + Vector3(0, 1.5, 0))
	d.hit_pos = pos
	ctx.hit(actor, d)
	TimeCtl.hitstop(0.05)
	GameCamera3D.shake_all(2.5)
	Sfx.play("storm_impact", -1.0)
	crackle(actor, 5)
	if ctx.upgraded:
		var hit := [actor]
		var from := pos
		for k in int(ctx.p("forks", 2)):
			var e := SpellEffect.nearest(from, float(ctx.p("fork_range", 4.6)), hit, actor)
			if e == null:
				break
			hit.append(e)
			FX3.bolt(from, e.center(), 0.22, ramp, 0.18)
			FX3.bolt(from, e.center(), 0.22, ramp, 0.08)
			var fd := ctx.dmg(float(ctx.p("fork_mult", 0.5)))
			fd.hit_pos = e.center()
			ctx.hit(e, fd)
			FX3.burst(e.center(), 10, ramp, Vector2(1.6, 5.0), Vector2(0.1, 0.3), {"gravity": 8.0})
			FX3.light(e.center(), Color(0.55, 0.9, 1.0), 2.5, 5.0, 0.2)
			from = e.center()


## Lingering static on the victim for a moment after the hit.
static func crackle(actor: Node3D, n: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for k in n:
		tree.create_timer(0.07 * (k + 1)).timeout.connect(func() -> void:
			if is_instance_valid(actor):
				var c: Vector3 = actor.center()
				var r: float = actor.radius() + 0.1
				FX3.bolt(c + Vector3(randf_range(-r, r), randf_range(-0.35, 0.35), randf_range(-r, r)), c + Vector3(randf_range(-r, r), randf_range(-0.35, 0.35), randf_range(-r, r)), 0.07, Pal.school(&"storm"), 0.08)
				FX3.burst(c, 2, Pal.school(&"storm"), Vector2(0.8, 2.5), Vector2(0.1, 0.2), {"gravity": 4.0}))
