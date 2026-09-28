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
	FX.ring(ctx.caster.center(), 4.0, 28.0, 0.35, Pal.school(&"fire"), 2.0, false)
	FX.burst(ctx.caster.center(), 20, Pal.school(&"fire"), Vector2(40, 120), Vector2(0.2, 0.5), {"gravity": -60.0})
	Sfx.play("fire_ward", -1.0)


class WardRing extends Node2D:
	var ctx: CastContext
	var player: Node2D
	var duration := 4.0
	var t := 0.0
	var tick := 0.0
	const R := 26.0

	func _ready() -> void:
		z_index = FX.Z_BACK + 3
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		var c: Vector2 = player.center()
		position = Vector2(0, -16)
		if tick <= 0.0:
			tick = 0.4
			for e: Node2D in SpellEffect.in_circle(c, R + 4.0):
				var d := ctx.dmg(1.0, Vector2(signf(e.center().x - c.x) * 90.0, -40.0))
				d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0 * ctx.power})
				ctx.hit(e, d)
		for k in 2:
			var a := randf() * TAU
			FX.burst(c + Vector2.from_angle(a) * R, 1, Pal.school(&"fire"), Vector2(10, 30), Vector2(0.25, 0.45),
				{"dir": Vector2.UP, "spread": 0.8, "gravity": -60.0, "front": false})
		if t >= duration:
			if ctx.upgraded:
				FX.ring(c, R, R + 42.0, 0.35, Pal.school(&"fire"), 3.0, true)
				FX.ring(c, R * 0.5, R + 30.0, 0.3, Pal.school(&"fire"), 1.0, true)
				FX.burst(c, 30, Pal.school(&"fire"), Vector2(100, 220), Vector2(0.2, 0.45), {"drag": 3.0, "glow": true})
				for e: Node2D in SpellEffect.in_circle(c, R + 40.0):
					var d := ctx.dmg(float(ctx.p("burst_mult", 2.5)), Vector2(signf(e.center().x - c.x) * 240.0, -120.0))
					d.statuses.append({"id": &"burn", "duration": 3.0, "power": 4.0 * ctx.power})
					ctx.hit(e, d)
				GameCamera.shake_all(3.0)
				TimeCtl.hitstop(0.04)
				Sfx.play("fire_burst", -1.0)
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var ramp := Pal.school(&"fire")
		var fade := clampf((duration - t) / 0.4, 0.0, 1.0)
		var flick := 1.0 if int(t * 15.0) % 2 == 0 else 0.0
		draw_arc(Vector2.ZERO, R + flick, 0, TAU, 40, Color(ramp[3], 0.5 * fade), 3.0)
		draw_arc(Vector2.ZERO, R, t * 3.0, t * 3.0 + TAU * 0.8, 36, Color(ramp[1], 0.9 * fade), 1.0)
		draw_arc(Vector2.ZERO, R - 3.0, -t * 2.0, -t * 2.0 + TAU * 0.6, 30, Color(ramp[2], 0.7 * fade), 1.0)
		for k in 6:
			var a := t * 2.2 + k * TAU / 6.0
			var p := (Vector2.from_angle(a) * R).round()
			draw_rect(Rect2(p - Vector2(1, 2), Vector2(2, 3)), Color(ramp[0], fade))
