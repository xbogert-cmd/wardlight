extends SpellEffect
## Siphon Circle: a hex circle at the aimed spot that drains enemies inside
## and restores a little health to the wizard (capped per cast).
## Upgrade (Soul Siphon): also restores mana and drags enemies toward the centre.


func cast(ctx: CastContext) -> void:
	var c := Circle.new()
	c.ctx = ctx
	ctx.spawn(c, ground_at(ctx.aim_point, ctx.caster))
	Sfx.play("hex_siphon", -2.0)


class Circle extends Node3D:
	var ctx: CastContext
	var t := 0.0
	var tick := 0.2
	var healed := 0.0
	var _outer: ShaderMaterial
	var _inner: ShaderMaterial
	var _rune: MeshInstance3D
	var _lamp: OmniLight3D
	const R := 2.25

	func _ready() -> void:
		var ramp := Pal.school(&"hex")
		_outer = _disc(R, 3.0, 0.12)
		_inner = _disc(R * 0.45, 1.0, 0.0)
		_rune = MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(64, 64) * FX3.PX
		_rune.mesh = q
		var m := ShaderMaterial.new()
		m.shader = FX3.DECAL_SHADER
		m.set_shader_parameter(&"tex", RUNE_L)
		m.set_shader_parameter(&"color", Color(Pal.SPECTRAL[1], 0.7))
		_rune.material_override = m
		_rune.rotation.x = -PI / 2
		_rune.position.y = 0.05
		_rune.scale = Vector3.ONE * (R * 1.6 / 2.67)
		add_child(_rune)
		_lamp = OmniLight3D.new()
		_lamp.light_color = Color(0.65, 0.45, 1.0)
		_lamp.light_energy = 1.5
		_lamp.omni_range = R * 2.2
		_lamp.position.y = 0.8
		add_child(_lamp)
		FX3.ring(global_position + Vector3(0, 0.05, 0), 0.2, R, 0.3, ramp, 1.0)

	func _disc(r: float, w: float, fill: float) -> ShaderMaterial:
		var mat := ShaderMaterial.new()
		mat.shader = FX3.DECAL_SHADER
		var size := Vector2.ONE * (r * 2.0 + 0.4)
		mat.set_shader_parameter(&"mode", 1)
		mat.set_shader_parameter(&"size_m", size)
		mat.set_shader_parameter(&"radius", r)
		mat.set_shader_parameter(&"width", w)
		mat.set_shader_parameter(&"fill", fill)
		var m := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = size
		m.mesh = q
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.rotation.x = -PI / 2
		m.position.y = 0.04
		add_child(m)
		return mat

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		var dur: float = ctx.p("duration", 3.0)
		var ramp := Pal.school(&"hex")
		var fade := clampf((dur - t) / 0.4, 0.0, 1.0) * clampf(t / 0.15, 0.0, 1.0)
		_outer.set_shader_parameter(&"color", Color(ramp[1], 0.95 * fade))
		_inner.set_shader_parameter(&"color", Color(Pal.SPECTRAL[2], 0.7 * fade))
		_rune.rotation.y = -t * 1.2
		_lamp.light_energy = 1.5 * fade
		if tick <= 0.0:
			tick = 0.5
			var cap: float = ctx.p("heal_cap", 12.0)
			for e: Node3D in SpellEffect.in_circle(global_position, R):
				var d := ctx.dmg(1.0)
				d.stagger = 2.0
				ctx.hit(e, d)
				var from: Vector3 = e.center()
				var to: Vector3 = ctx.caster.center()
				FX3.bolt(from, from.lerp(to, 0.5), 0.12, Pal.SPECTRAL, 0.12)
				FX3.converge(to, 0.6, 3, Pal.SPECTRAL, 0.25, 1.0)
				if healed < cap:
					var amt := minf(1.5 * ctx.power, cap - healed)
					healed += amt
					ctx.caster.health.heal(amt)
				if ctx.upgraded:
					ctx.caster.mana.gain(1.5)
					e._knock += SpellEffect.flat_dir(global_position - e.global_position) * 2.9
		if randf() < delta * 70.0:
			var a := randf() * TAU
			var rr := randf_range(0.3, 1.0) * R
			FX3.burst(global_position + Vector3(cos(a) * rr, 0.08, sin(a) * rr), 1, Pal.SPECTRAL if randf() < 0.6 else ramp,
				Vector2(0.4, 1.2), Vector2(0.4, 0.8), {"dir": Vector3.UP, "spread": 0.5, "gravity": -1.2})
		if t >= dur:
			queue_free()
