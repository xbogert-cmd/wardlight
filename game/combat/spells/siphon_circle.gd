extends SpellEffect
## Siphon Circle: a hex circle at the wizard's feet that drains enemies inside
## and restores a little health (capped per cast).
## Upgrade (Soul Siphon): also restores mana and drags enemies toward the centre.


func cast(ctx: CastContext) -> void:
	var c := Circle.new()
	c.ctx = ctx
	ctx.spawn(c)
	c.global_position = ctx.caster.global_position + Vector2(0, -2)
	Sfx.play("hex_siphon", -2.0)


class Circle extends Node2D:
	var ctx: CastContext
	var t := 0.0
	var tick := 0.2
	var healed := 0.0
	const R := 54.0

	func _ready() -> void:
		z_index = FX.Z_BACK + 3
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
		FX.ring(global_position, 4.0, R, 0.3, Pal.school(&"hex"), 1.0, false)

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		var dur: float = ctx.p("duration", 3.0)
		if tick <= 0.0:
			tick = 0.5
			var cap: float = ctx.p("heal_cap", 12.0)
			for e: Node2D in SpellEffect.in_circle(global_position + Vector2(0, -10), R):
				var d := ctx.dmg(1.0)
				d.stagger = 2.0
				ctx.hit(e, d)
				var from: Vector2 = e.center()
				var to: Vector2 = ctx.caster.center()
				FX.bolt(from, from.lerp(to, 0.5), 0.12, Pal.SPECTRAL, 3.0)
				if healed < cap:
					var amt := minf(1.5 * ctx.power, cap - healed)
					healed += amt
					ctx.caster.health.heal(amt)
				if ctx.upgraded:
					ctx.caster.mana.gain(1.5)
					e._knock.x += signf(global_position.x - e.global_position.x) * 70.0
		if randf() < delta * 70.0:
			var a := randf() * TAU
			var rr := randf_range(0.3, 1.0) * R
			FX.burst(global_position + Vector2(cos(a) * rr, sin(a) * rr * 0.3 - 2), 1, Pal.SPECTRAL if randf() < 0.6 else Pal.school(&"hex"),
				Vector2(10, 30), Vector2(0.4, 0.8), {"dir": Vector2.UP, "spread": 0.5, "gravity": -30.0, "front": false, "glow": true})
		if t >= dur:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var ramp := Pal.school(&"hex")
		var dur: float = ctx.p("duration", 3.0)
		var fade := clampf((dur - t) / 0.4, 0.0, 1.0) * clampf(t / 0.15, 0.0, 1.0)
		# a flattened magic circle on the ground
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, R, Color(ramp[3], 0.35 * fade))
		draw_arc(Vector2.ZERO, R, 0, TAU, 48, Color(ramp[1], 0.95 * fade), 3.0)
		draw_arc(Vector2.ZERO, R - 7.0, t * 1.5, t * 1.5 + TAU, 40, Color(ramp[1], 0.6 * fade), 1.0)
		for k in 8:
			var a := -t * 1.2 + k * TAU / 8.0
			draw_line(Vector2.from_angle(a) * (R - 7.0), Vector2.from_angle(a + 0.4) * (R - 1.0), Color(Pal.SPECTRAL[1], 0.9 * fade), 2.0)
		draw_arc(Vector2.ZERO, R * 0.45, -t * 2.0, -t * 2.0 + TAU, 32, Color(Pal.SPECTRAL[2], 0.7 * fade), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
