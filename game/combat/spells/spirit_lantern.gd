extends SpellEffect
## Spirit Lantern: a spirit circles the wizard for a while. The next enemy
## attack that would land is caught by the spirit, which answers with a
## cursing bolt. Upgrade (Twin Lanterns): two spirits.


func cast(ctx: CastContext) -> void:
	release_fx(ctx, 0.6)
	var n := 2 if ctx.upgraded else 1
	for k in n:
		var s := Spirit.new()
		s.ctx = ctx
		s.phase = k * PI
		s.life = ctx.p("duration", 12.0)
		ctx.caster.add_child(s)
		ctx.caster.spirits.append(s)
	Sfx.play("hex_spirit", -1.0)


class Spirit extends Node2D:
	var ctx: CastContext
	var phase := 0.0
	var life := 12.0
	var t := 0.0

	func _ready() -> void:
		top_level = true
		z_index = FX.Z_FRONT
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _physics_process(delta: float) -> void:
		t += delta
		var c: Vector2 = ctx.caster.center()
		global_position = c + Vector2(cos(t * 3.0 + phase) * 18.0, sin(t * 3.0 + phase) * 8.0 - 6.0)
		if randf() < delta * 20.0:
			FX.burst(global_position, 1, Pal.SPECTRAL, Vector2(4, 12), Vector2(0.3, 0.5), {"gravity": -30.0})
		if t >= life:
			ctx.caster.spirits.erase(self)
			FX.burst(global_position, 8, Pal.SPECTRAL, Vector2(10, 40), Vector2(0.2, 0.4))
			queue_free()
		queue_redraw()

	## Called by the player when this spirit absorbs a hit.
	func intercept(d: Damage) -> void:
		FX.flash(global_position, 8.0, 0.1, Color(0.7, 1.0, 0.85, 0.9))
		FX.ring(global_position, 2.0, 18.0, 0.3, Pal.SPECTRAL, 1.0, true)
		Sfx.play("hex_block", -1.0)
		var attacker: Node2D = d.source as Node2D
		if is_instance_valid(attacker) and attacker.has_method("is_alive") and attacker.is_alive():
			var p := Projectile.new()
			p.style = &"spectral"
			p.ramp = Pal.SPECTRAL
			p.velocity = (attacker.center() - global_position).normalized() * 200.0
			p.homing = true
			p.turn_rate = 10.0
			p.speed_cap = 320.0
			p.max_dist = 400.0
			ctx.spawn(p)
			p.global_position = global_position
			p.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void:
				var rd := ctx.dmg(1.0, Vector2(signf(a.center().x - pos.x) * 100.0, -60.0))
				rd.hit_pos = pos
				rd.statuses.append({"id": &"curse", "duration": 6.0})
				ctx.hit(a, rd)
				FX.burst(pos, 12, Pal.SPECTRAL, Vector2(40, 120), Vector2(0.15, 0.35), {"gravity": 120.0}))
		queue_free()

	func _draw() -> void:
		var bob := roundf(sin(t * 8.0))
		var ramp := Pal.SPECTRAL
		draw_texture(SpellEffect.GLOW_M, -SpellEffect.GLOW_M.get_size() * 0.5 + Vector2(0, bob), Color(ramp[2], 0.9))
		# a small hooded spirit carrying a lantern
		draw_rect(Rect2(-3, -5 + bob, 6, 7), ramp[1])
		draw_rect(Rect2(-2, -6 + bob, 4, 1), ramp[0])
		draw_rect(Rect2(-2, -3 + bob, 1, 2), Color("0e2a22"))
		draw_rect(Rect2(1, -3 + bob, 1, 2), Color("0e2a22"))
		var wave := 1.0 if int(t * 10.0) % 2 == 0 else 0.0
		draw_rect(Rect2(-3, 2 + bob, 1, 2 + wave), ramp[2])
		draw_rect(Rect2(-1, 2 + bob, 1, 3 - wave), ramp[2])
		draw_rect(Rect2(2, 2 + bob, 1, 2 + wave), ramp[2])
		draw_rect(Rect2(4, -1 + bob, 3, 3), Color("f4e890"))
		draw_rect(Rect2(5, -2 + bob, 1, 1), Color("a89060"))
