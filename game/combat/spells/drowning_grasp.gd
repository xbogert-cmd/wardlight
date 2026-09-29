extends SpellEffect
## Drowning Grasp (hex, a gift of the Deepwillow): dark water hands rise at
## the aimed spot and drag every enemy nearby into its centre, then hold
## them there slowed. Sets up Ashfall, Boiling Spring and Thunder Ring.
## Upgrade (Undertow Curse): the dragged are also cursed.

const DARK := [Color("c8e0ff"), Color("5a7ab8"), Color("2a3a6a"), Color("141a30")]


func cast(ctx: CastContext) -> void:
	var at := ground_at(ctx.aim_point, ctx.caster)
	var r: float = ctx.p("radius", 3.0)
	release_fx(ctx, 0.9)
	Sfx.play("hex_release", -2.0)
	FX3.decal(RUNE_L, at + Vector3(0, 0.04, 0), 0.9, Color(Pal.school(&"hex")[2], 0.9), 0.4, r / 1.2, -3.0)
	FX3.ring(at + Vector3(0, 0.05, 0), r, 0.3, 0.4, DARK, 3.0)
	for k in 10:
		var a := k * TAU / 10.0
		var p := at + Vector3(cos(a), 0, sin(a)) * r * randf_range(0.5, 1.0)
		FX3.burst(p, 5, DARK, Vector2(1.0, 3.0), Vector2(0.3, 0.6), {"dir": (at - p).normalized() + Vector3.UP, "spread": 0.5, "gravity": 4.0})
	for e: Node3D in in_circle(at, r):
		var dist := flat(at, e.global_position)
		var v := sqrt(76.0 * maxf(dist - 0.4, 0.0)) * 0.9
		var d := ctx.dmg(1.0, flat_dir(at - e.global_position) * v)
		d.stagger = 20.0
		d.statuses.append({"id": &"slow", "duration": float(ctx.p("slow_time", 2.0)), "power": float(ctx.p("slow", 0.4))})
		if ctx.upgraded:
			d.statuses.append({"id": &"curse", "duration": float(ctx.p("curse_time", 3.0))})
		ctx.hit(e, d)
	later(0.4, func() -> void:
		FX3.burst(at + Vector3(0, 0.1, 0), 24, DARK, Vector2(1.0, 4.0), Vector2(0.4, 0.8), {"dir": Vector3.UP, "spread": 1.0, "gravity": 6.0})
		FX3.ring(at + Vector3(0, 0.06, 0), 0.2, 1.2, 0.4, DARK, 2.0))
