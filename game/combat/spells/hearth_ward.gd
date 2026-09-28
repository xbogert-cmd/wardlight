extends SpellEffect
## Hearth Ward: a protective ring of fire around the wizard for a few seconds.
## Damage taken is reduced and enemies touching the ring burn.
## Upgrade (Kindled Ward): as the ward ends it bursts outward in a second ring.


func cast(ctx: CastContext) -> void:
	var w := WardRing.new()
	w.ctx = ctx
	w.player = ctx.caster
	w.duration = ctx.p("duration", 4.0)
	ctx.caster.add_child(w)
	ctx.caster.guard_mult = ctx.p("guard", 0.6)
	ctx.caster.guard_t = w.duration
	var feet: Vector3 = ctx.caster.global_position
	FX3.ring(feet + Vector3(0, 0.05, 0), 0.2, 1.2, 0.35, Pal.school(&"fire"), 2.0)
	FX3.burst(ctx.caster.center(), 20, Pal.school(&"fire"), Vector2(1.6, 5.0), Vector2(0.2, 0.5), {"gravity": -2.5})
	FX3.light(ctx.caster.center(), Color(1.0, 0.55, 0.2), 4.0, 6.0, 0.4)
	Sfx.play("fire_ward", -1.0)


class WardRing extends Node3D:
	var ctx: CastContext
	var player: Node3D
	var duration := 4.0
	var t := 0.0
	var tick := 0.0
	var _mat: ShaderMaterial
	var _inner: ShaderMaterial
	var _lamp: OmniLight3D
	const R := 1.1

	func _ready() -> void:
		_mat = _disc(0.18)
		_inner = _disc(0.0)
		_lamp = OmniLight3D.new()
		_lamp.light_color = Color(1.0, 0.55, 0.22)
		_lamp.light_energy = 2.0
		_lamp.omni_range = 4.5
		_lamp.position.y = 0.9
		add_child(_lamp)

	func _disc(fill: float) -> ShaderMaterial:
		var mat := ShaderMaterial.new()
		mat.shader = FX3.DECAL_SHADER
		var size := Vector2.ONE * (R * 2.0 + 0.4)
		mat.set_shader_parameter(&"mode", 1)
		mat.set_shader_parameter(&"size_m", size)
		mat.set_shader_parameter(&"radius", R)
		mat.set_shader_parameter(&"width", 2.0)
		mat.set_shader_parameter(&"fill", fill)
		var m := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = size
		m.mesh = q
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.rotation.x = -PI / 2
		m.position.y = 0.06
		add_child(m)
		return mat

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		var feet: Vector3 = player.global_position
		var ramp := Pal.school(&"fire")
		var fade := clampf((duration - t) / 0.4, 0.0, 1.0)
		var flick := 1.0 if int(t * 15.0) % 2 == 0 else 0.85
		_mat.set_shader_parameter(&"color", Color(ramp[2], 0.9 * fade * flick))
		_inner.set_shader_parameter(&"radius", R - 0.15 + 0.05 * sin(t * 6.0))
		_inner.set_shader_parameter(&"color", Color(ramp[1], 0.6 * fade))
		_lamp.light_energy = 2.0 * fade * flick
		if tick <= 0.0:
			tick = 0.4
			for e: Node3D in SpellEffect.in_circle(feet, R + 0.15):
				var d := ctx.dmg(1.0, SpellEffect.push(feet, e.global_position, 3.8, 1.5))
				d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0 * ctx.power})
				ctx.hit(e, d)
		for k in 3:
			var a := randf() * TAU
			FX3.burst(feet + Vector3(cos(a) * R, 0.1, sin(a) * R), 1, ramp, Vector2(0.4, 1.2), Vector2(0.25, 0.45),
				{"dir": Vector3.UP, "spread": 0.8, "gravity": -2.5, "size": 2.0 if randf() < 0.25 else 1.0})
		if t >= duration:
			if ctx.upgraded:
				FX3.ring(feet + Vector3(0, 0.05, 0), R, R + 1.8, 0.35, ramp, 3.0)
				FX3.ring(feet + Vector3(0, 0.06, 0), R * 0.5, R + 1.2, 0.3, ramp, 1.0)
				FX3.flash(player.center(), 0.9, 0.12, Color(1.0, 0.7, 0.4), 6.0)
				FX3.burst(player.center(), 34, ramp, Vector2(4.0, 9.0), Vector2(0.2, 0.45), {"drag": 3.0})
				for e: Node3D in SpellEffect.in_circle(feet, R + 1.7):
					var d := ctx.dmg(float(ctx.p("burst_mult", 2.5)), SpellEffect.push(feet, e.global_position, 10.0, 5.0))
					d.statuses.append({"id": &"burn", "duration": 3.0, "power": 4.0 * ctx.power})
					ctx.hit(e, d)
				GameCamera3D.shake_all(3.0)
				TimeCtl.hitstop(0.04)
				Sfx.play("fire_burst", -1.0)
			queue_free()
