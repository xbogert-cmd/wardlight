extends SpellEffect
## Binding Roots: roots burst from the ground at the aimed spot and hold
## enemies in place. Upgrade (Strangling Grove): the roots linger as a thicket
## that re-binds and curses anything that walks in.


func cast(ctx: CastContext) -> void:
	release_fx(ctx, 0.7)
	var ground := ground_below(ctx.aim_point, ctx.caster, 220.0)
	var width: float = ctx.p("width", 72.0)
	var ramp := Pal.school(&"hex")
	FX.tele_mark(ground, width, 0.25, Color(ramp[1], 0.7))
	for k in 8:
		FX.burst(ground + Vector2(randf_range(-width * 0.5, width * 0.5), 0), 2, Pal.DUST, Vector2(10, 40), Vector2(0.2, 0.4),
			{"dir": Vector2.UP, "spread": 1.2, "gravity": 150.0, "add": false})
	Sfx.play("hex_release", -3.0)
	later(0.25, func() -> void:
		var g := Grove.new()
		g.ctx = ctx
		g.width = width
		g.life = ctx.p("linger", 0.9)
		ctx.spawn(g)
		g.global_position = ground
		Sfx.play("roots", -1.0)
		GameCamera.shake_all(2.0))


class Grove extends Node2D:
	var ctx: CastContext
	var width := 72.0
	var life := 0.9
	var t := 0.0
	var _bound := {}
	var _tick := 0.0

	func _ready() -> void:
		z_index = 3
		_bind(true)

	func _bind(first: bool) -> void:
		var r := Rect2(global_position.x - width * 0.5, global_position.y - 30.0, width, 32.0)
		for e: Node2D in SpellEffect.in_rect(r):
			if _bound.has(e) and not first:
				continue
			_bound[e] = true
			var d := ctx.dmg(1.0 if first else 0.4)
			d.stagger = 0.0
			d.statuses.append({"id": &"root", "duration": ctx.p("root_time", 1.8)})
			if ctx.upgraded:
				d.statuses.append({"id": &"curse", "duration": 6.0})
			ctx.hit(e, d)
			FX.burst(e.global_position, 8, Pal.school(&"hex"), Vector2(20, 60), Vector2(0.2, 0.4), {"dir": Vector2.UP, "spread": 1.0})

	func _physics_process(delta: float) -> void:
		t += delta
		_tick -= delta
		if ctx.upgraded and _tick <= 0.0:
			_tick = 0.5
			_bind(false)
		if t > life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var grow := clampf(t / 0.12, 0.0, 1.0)
		var fade := clampf((life - t) / 0.3, 0.0, 1.0)
		var bark := Color("6a4a3a", fade)
		var hi := Color("9a7a5a", fade)
		var glow := Color(Pal.SCHOOL[&"hex"][1], fade)
		var n := int(width / 9.0)
		for k in n:
			var x := -width * 0.5 + (k + 0.5) * width / n
			var h := (14.0 + (k * 7 % 5) * 3.0) * grow
			var lean := (1.0 if k % 2 else -1.0) * (3.0 + k % 3)
			var pts := PackedVector2Array([Vector2(x, 0), Vector2(x + lean * 0.4, -h * 0.5), Vector2(x + lean, -h)])
			draw_polyline(pts, bark, 3.0)
			draw_polyline(pts, hi, 1.0)
			draw_rect(Rect2(Vector2(x + lean, -h).round() - Vector2(1, 1), Vector2(2, 2)), glow)
