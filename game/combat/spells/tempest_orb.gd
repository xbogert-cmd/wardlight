extends SpellEffect
## Tempest Orb: a slow orb of storm that drifts to the aimed point and hangs
## there, striking the nearest enemy with lightning several times.
## Upgrade (Eye of the Storm): each strike hits two enemies and the orb drags
## enemies toward it.


func cast(ctx: CastContext) -> void:
	release_fx(ctx, 0.9)
	Sfx.play("storm_release", -3.0)
	var rng: float = ctx.p("range", 9.6)
	var p := make_projectile(ctx, &"orb", 6.3, rng, 0.3)
	p.team = &"none"
	var goal := Vector3(ctx.aim_point.x, ctx.caster.global_position.y + 1.3, ctx.aim_point.z)
	if flat(ctx.origin, goal) < rng:
		p.velocity = (goal - p.global_position).normalized() * 6.3
		p.stop_at = goal
	p.arrived.connect(func(pos: Vector3) -> void: _hang(ctx, pos))
	p.expired.connect(func(pos: Vector3) -> void: _hang(ctx, pos))
	p.hit_wall.connect(func(pos: Vector3) -> void: _hang(ctx, pos - p.velocity.normalized() * 0.3))


static func _hang(ctx: CastContext, pos: Vector3) -> void:
	var z := Zone.new()
	z.ctx = ctx
	ctx.spawn(z)
	z.global_position = pos
	Sfx.play("storm_hum", -4.0)


class Zone extends Node3D:
	var ctx: CastContext
	var t := 0.0
	var tick := 0.2
	var _lamp: OmniLight3D
	var _glow: MeshInstance3D
	var _core: MeshInstance3D
	const R := 3.0

	func _ready() -> void:
		_lamp = OmniLight3D.new()
		_lamp.light_color = Color(0.5, 0.85, 1.0)
		_lamp.light_energy = 2.0
		_lamp.omni_range = 5.0
		add_child(_lamp)
		var g := SpellEffect.ground_at(global_position, self)
		var ramp := Pal.school(&"storm")
		FX3.ring(g + Vector3(0, 0.05, 0), R, R, float(ctx.p("duration", 3.5)), [Color(ramp[3], 0.5)], 1.0, true, 0.06)
		_glow = FX3.make_glow(GLOW_M, Color(ramp[2], 0.9), 1.1)
		add_child(_glow)
		_core = FX3.make_glow(GLOW_S, Color(ramp[0], 0.8), 0.4)
		add_child(_core)

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		var dur: float = ctx.p("duration", 3.5)
		var ramp := Pal.school(&"storm")
		var pos := global_position
		if tick <= 0.0:
			tick = float(ctx.p("interval", 0.45))
			var hit: Array = []
			for k in int(ctx.p("targets", 1)):
				var e := SpellEffect.nearest(pos, R, hit, self)
				if e == null:
					break
				hit.append(e)
				FX3.bolt(pos, e.center(), 0.14, ramp, 0.2)
				FX3.bolt(pos, e.center(), 0.14, ramp, 0.08)
				FX3.burst(e.center(), 8, ramp, Vector2(1.6, 5.0), Vector2(0.1, 0.3), {"gravity": 7.5})
				FX3.light(e.center(), Color(0.55, 0.9, 1.0), 2.0, 4.0, 0.12)
				var d := ctx.dmg(1.0, Vector3(0, 1.2, 0))
				d.hit_pos = e.center()
				d.stagger = 6.0
				ctx.hit(e, d)
				Sfx.play("storm_zap", -6.0)
			if ctx.upgraded:
				for e: Node3D in SpellEffect.in_circle(pos, R * 1.3):
					e._knock += SpellEffect.flat_dir(pos - e.global_position) * 2.5
		# the orb itself: pulsing glow, orbiting sparks, crackles
		var pulse := 1.0 + 0.15 * sin(t * 14.0)
		_glow.scale = Vector3.ONE * 1.1 * pulse
		for k in 3:
			var a := t * (4.0 + k) + k * TAU / 3.0
			FX3.burst(pos + Vector3(cos(a), sin(a * 0.7) * 0.3, sin(a)) * (0.45 + k * 0.12), 1, ramp, Vector2(0.0, 0.1), Vector2(0.08, 0.12))
		if randf() < delta * 12.0:
			FX3.bolt(pos, pos + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0.35, 0.7), 0.06, ramp, 0.08)
		_lamp.light_energy = 2.0 * pulse
		if t >= dur:
			FX3.ring(pos, 0.1, 0.9, 0.25, ramp, 1.0, false)
			FX3.burst(pos, 16, ramp, Vector2(1.6, 5.8), Vector2(0.15, 0.35))
			queue_free()
