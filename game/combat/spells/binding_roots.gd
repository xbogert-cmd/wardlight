extends SpellEffect
## Binding Roots: roots burst from the ground at the aimed spot and hold
## enemies in place. Upgrade (Strangling Grove): the roots linger as a thicket
## that re-binds and curses anything that walks in.

const ROOTS := preload("res://assets/generated/w3d/roots.png")


func cast(ctx: CastContext) -> void:
	release_fx(ctx, 0.7)
	var ground := ground_at(ctx.aim_point, ctx.caster)
	var r: float = float(ctx.p("width", 3.0)) * 0.5
	var ramp := Pal.school(&"hex")
	FX3.tele_ring(ground, r, 0.25, Color(ramp[1], 0.7))
	FX3.decal(RUNE_L, ground + Vector3(0, 0.04, 0), 0.5, Color(ramp[1], 0.8), r / 1.33 * 0.6, r / 1.33, -2.0)
	for k in 10:
		var a := randf() * TAU
		FX3.burst(ground + Vector3(cos(a), 0.05, sin(a)) * randf() * r, 2, Pal.DUST, Vector2(0.4, 1.6), Vector2(0.2, 0.4),
			{"dir": Vector3.UP, "spread": 1.2, "gravity": 6.0})
	Sfx.play("hex_release", -3.0)
	later(0.25, func() -> void:
		var g := Grove.new()
		g.ctx = ctx
		g.radius = r
		g.life = ctx.p("linger", 0.9)
		ctx.spawn(g)
		g.global_position = ground
		Sfx.play("roots", -1.0)
		GameCamera3D.shake_all(2.0))


class Grove extends Node3D:
	var ctx: CastContext
	var radius := 1.5
	var life := 0.9
	var t := 0.0
	var _bound := {}
	var _tick := 0.0
	var _roots: Array[PixelBillboard] = []

	func _ready() -> void:
		var n := int(radius * 6.0)
		for k in n:
			var a := TAU * k / n + randf_range(-0.25, 0.25)
			var rr := sqrt(randf_range(0.1, 1.0)) * radius * 0.9
			var b := PixelBillboard.still(ROOTS)
			b.set_flip(randf() < 0.5)
			add_child(b)
			b.position = Vector3(cos(a) * rr, -0.9, sin(a) * rr)
			_roots.append(b)
		FX3.ring(global_position + Vector3(0, 0.05, 0), 0.3, radius, 0.3, Pal.school(&"hex"), 2.0)
		_bind(true)

	func _bind(first: bool) -> void:
		for e: Node3D in SpellEffect.in_circle(global_position, radius):
			if _bound.has(e) and not first:
				continue
			_bound[e] = true
			var d := ctx.dmg(1.0 if first else 0.4)
			d.stagger = 0.0
			d.statuses.append({"id": &"root", "duration": ctx.p("root_time", 1.8)})
			if ctx.upgraded:
				d.statuses.append({"id": &"curse", "duration": 6.0})
			ctx.hit(e, d)
			FX3.burst(e.global_position + Vector3(0, 0.2, 0), 8, Pal.school(&"hex"), Vector2(0.8, 2.5), Vector2(0.2, 0.4), {"dir": Vector3.UP, "spread": 1.0})

	func _physics_process(delta: float) -> void:
		t += delta
		_tick -= delta
		if ctx.upgraded and _tick <= 0.0:
			_tick = 0.5
			_bind(false)
		var grow := clampf(t / 0.12, 0.0, 1.0)
		var sink := clampf((life - t) / 0.3, 0.0, 1.0)
		for b in _roots:
			b.position.y = lerpf(-0.9, 0.0, grow * sink)
		if t > life:
			queue_free()
