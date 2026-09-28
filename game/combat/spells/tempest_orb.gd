extends SpellEffect
## Tempest Orb: a slow orb of storm that drifts to the aimed point and hangs
## there, striking the nearest enemy with lightning several times.
## Upgrade (Eye of the Storm): each strike hits two enemies and the orb drags
## enemies toward it.


func cast(ctx: CastContext) -> void:
	release_fx(ctx, 0.9)
	Sfx.play("storm_release", -3.0)
	var p := make_projectile(ctx, &"orb", 150.0, ctx.p("range", 230.0), 6.0)
	p.team = &"none"
	p.collision_mask = 0
	p.stop_at = ctx.aim_point if ctx.origin.distance_to(ctx.aim_point) < float(ctx.p("range", 230.0)) else Vector2.INF
	p.arrived.connect(func(pos: Vector2) -> void: _hang(ctx, pos))
	p.expired.connect(func(pos: Vector2) -> void: _hang(ctx, pos))


static func _hang(ctx: CastContext, pos: Vector2) -> void:
	var z := Zone.new()
	z.ctx = ctx
	ctx.spawn(z)
	z.global_position = pos
	Sfx.play("storm_hum", -4.0)


class Zone extends Node2D:
	var ctx: CastContext
	var t := 0.0
	var tick := 0.2
	const R := 72.0

	func _ready() -> void:
		z_index = FX.Z_FRONT
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		var dur: float = ctx.p("duration", 3.5)
		var ramp := Pal.school(&"storm")
		if tick <= 0.0:
			tick = float(ctx.p("interval", 0.45))
			var hit: Array = []
			for k in int(ctx.p("targets", 1)):
				var e := SpellEffect.nearest(global_position, R, hit, self)
				if e == null:
					break
				hit.append(e)
				FX.bolt(global_position, e.center(), 0.14, ramp, 4.0, 1.0, true, 1)
				FX.burst(e.center(), 8, ramp, Vector2(40, 120), Vector2(0.1, 0.3), {"gravity": 180.0})
				var d := ctx.dmg(1.0, Vector2(0, -30))
				d.hit_pos = e.center()
				d.stagger = 6.0
				ctx.hit(e, d)
				Sfx.play("storm_zap", -6.0)
			if ctx.upgraded:
				for e: Node2D in SpellEffect.in_circle(global_position, R * 1.3):
					e._knock.x += signf(global_position.x - e.global_position.x) * 60.0
		if randf() < delta * 12.0:
			FX.bolt(global_position, global_position + Vector2.from_angle(randf() * TAU) * randf_range(8, 16), 0.06, ramp, 2.0)
		if t >= dur:
			FX.ring(global_position, 3.0, 20.0, 0.25, ramp)
			FX.burst(global_position, 16, ramp, Vector2(40, 140), Vector2(0.15, 0.35), {"glow": true})
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var ramp := Pal.school(&"storm")
		var pulse := 1.0 + sin(t * 14.0)
		draw_texture(GLOW_M, -GLOW_M.get_size() * 0.5, Color(ramp[2], 0.8))
		draw_circle(Vector2.ZERO, 7.0 + pulse, Color(ramp[3], 0.5))
		draw_circle(Vector2.ZERO, 5.0, Color(ramp[2], 0.9))
		draw_circle(Vector2(-1, -1), 2.5, ramp[0])
		for k in 3:
			var a := t * (4.0 + k) + k * TAU / 3.0
			draw_arc(Vector2.ZERO, 10.0 + k * 3.0, a, a + 1.4, 10, Color(ramp[1], 0.7), 1.0)
		if ctx.upgraded:
			draw_arc(Vector2.ZERO, R, -t * 2.0, -t * 2.0 + TAU * 0.25, 16, Color(ramp[2], 0.35), 1.0)
			draw_arc(Vector2.ZERO, R, -t * 2.0 + PI, -t * 2.0 + PI + TAU * 0.25, 16, Color(ramp[2], 0.35), 1.0)
