extends SpellEffect
## Arc Lance: lightning gathered at the staff, released through a rune circle
## as a fast bolt. Upgrade (Forked Lance): the impact forks to 2 more enemies.


func cast(ctx: CastContext) -> void:
	var ramp := Pal.school(&"storm")
	var o := ctx.origin + ctx.dir * 2.0
	# release: flash, magic circle facing the target, shock arcs, recoil sparks
	FX.flash(o, 4.0, 0.06, Color(1, 1, 1, 0.9))
	FX.sprite(FX.tex("glow32.png"), o, 0.2, ramp[2], 0.7, 1.2, 0.0, false)
	FX.sprite(FX.tex("rune40.png"), o + ctx.dir * 4.0, 0.32, ramp[1], 0.35, 0.8, 5.0, false, true, ctx.dir.angle())
	FX.ring(o, 3.0, 16.0, 0.2, ramp, 1.0, true)
	FX.arc(o, 4.0, 18.0, ctx.dir.angle(), 1.4, 0.14, ramp, 1.0)
	FX.burst(o, 16, ramp, Vector2(60, 180), Vector2(0.1, 0.25), {"dir": ctx.dir, "spread": 1.0, "drag": 5.0})
	FX.burst(o, 6, ramp, Vector2(20, 70), Vector2(0.15, 0.3), {"dir": -ctx.dir, "spread": 1.6, "drag": 4.0})
	for k in 3:
		FX.bolt(o, o + ctx.dir.rotated(randf_range(-0.9, 0.9)) * randf_range(10, 18), 0.07, ramp, 2.0)
	GameCamera.shake_all(1.5)
	Sfx.play("storm_release", -1.0)
	var pr := Projectile.new()
	pr.style = &"arc"
	pr.ramp = ramp
	pr.velocity = ctx.dir * float(ctx.p("speed", 470.0))
	pr.max_dist = ctx.p("range", 330.0)
	pr.radius = 5.0
	ctx.spawn(pr)
	pr.global_position = o
	pr.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void: _impact(ctx, a, pos))
	pr.hit_wall.connect(func(pos: Vector2) -> void: _impact(ctx, null, pos))
	pr.expired.connect(func(pos: Vector2) -> void:
		FX.burst(pos, 10, ramp, Vector2(20, 70), Vector2(0.15, 0.3), {"drag": 3.0})
		FX.ring(pos, 1.0, 8.0, 0.15, ramp))


func _impact(ctx: CastContext, actor: Node2D, pos: Vector2) -> void:
	var ramp := Pal.school(&"storm")
	FX.flash(pos, 7.0, 0.07, Color(1, 1, 1, 0.85))
	FX.sprite(FX.tex("glow64.png"), pos, 0.3, ramp[2], 0.45, 0.9, 0.0, false)
	FX.ring(pos, 4.0, 26.0, 0.3, ramp, 1.0, false)
	FX.ring(pos, 2.0, 14.0, 0.2, ramp, 1.0, true)
	for k in 6:
		FX.bolt(pos, pos + Vector2.from_angle(randf() * TAU) * randf_range(10, 24), 0.14, ramp, 3.0)
	FX.burst(pos, 22, ramp, Vector2(60, 200), Vector2(0.15, 0.5), {"gravity": 260.0, "drag": 1.5, "glow": true})
	FX.burst(pos, 5, Pal.SMOKE, Vector2(5, 20), Vector2(0.5, 0.8), {"add": false, "gravity": -20.0, "front": false})
	if actor == null:
		Sfx.play("storm_fizzle", -4.0)
		return
	var d := ctx.dmg(1.0, Vector2(ctx.dir.x * 110.0, -40.0))
	d.hit_pos = pos
	ctx.hit(actor, d)
	TimeCtl.hitstop(0.05)
	GameCamera.shake_all(2.5)
	Sfx.play("storm_impact", -1.0)
	_crackle(actor, 5)
	if ctx.upgraded:
		var hit := [actor]
		var from := pos
		for k in int(ctx.p("forks", 2)):
			var e := SpellEffect.nearest(from, float(ctx.p("fork_range", 110.0)), hit, actor)
			if e == null:
				break
			hit.append(e)
			FX.bolt(from, e.center(), 0.22, ramp, 4.0, 1.0, true, 1)
			var fd := ctx.dmg(float(ctx.p("fork_mult", 0.5)))
			fd.hit_pos = e.center()
			ctx.hit(e, fd)
			FX.burst(e.center(), 10, ramp, Vector2(40, 120), Vector2(0.1, 0.3), {"gravity": 200.0})
			from = e.center()


## Lingering static on the victim for a moment after the hit.
static func _crackle(actor: Node2D, n: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for k in n:
		tree.create_timer(0.07 * (k + 1)).timeout.connect(func() -> void:
			if is_instance_valid(actor):
				var c: Vector2 = actor.center()
				FX.bolt(c + Vector2(randf_range(-9, 9), randf_range(-8, 8)), c + Vector2(randf_range(-9, 9), randf_range(-8, 8)), 0.07, Pal.school(&"storm"), 2.0)
				FX.burst(c, 2, Pal.school(&"storm"), Vector2(20, 60), Vector2(0.1, 0.2), {"gravity": 100.0}))
