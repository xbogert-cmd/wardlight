extends SpellEffect
## Spirit Lantern: a spirit circles the wizard for a while, loosing a weak
## cursing bolt at the nearest enemy every few seconds. The next enemy attack
## that would land is caught by the spirit, which answers with a full-strength
## bolt. Upgrade (Twin Lanterns): two spirits.

const VOLLEY_EVERY := 2.0
const VOLLEY_RANGE := 9.0
const VOLLEY_MULT := 0.5

const SPIRIT := preload("res://assets/generated/w3d/spirit.png")


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


class Spirit extends Node3D:
	var ctx: CastContext
	var phase := 0.0
	var life := 12.0
	var t := 0.0
	var _volley := 1.0
	var _body: PixelBillboard
	var _lamp: OmniLight3D

	func _ready() -> void:
		top_level = true
		_body = PixelBillboard.still(SPIRIT, Vector2(8, 12))
		_body.mat.set_shader_parameter(&"emit", 1.2)
		add_child(_body)
		add_child(FX3.make_glow(GLOW_M, Color(Pal.SPECTRAL[2], 0.8), 0.9))
		_lamp = OmniLight3D.new()
		_lamp.light_color = Color(0.6, 1.0, 0.8)
		_lamp.light_energy = 1.2
		_lamp.omni_range = 3.0
		add_child(_lamp)

	func _physics_process(delta: float) -> void:
		t += delta
		var c: Vector3 = ctx.caster.global_position
		var a := t * 2.6 + phase
		global_position = c + Vector3(cos(a) * 0.9, 1.5 + roundf(sin(t * 8.0)) * FX3.PX, sin(a) * 0.9)
		_body.set_flip(cos(a + PI / 2) < 0.0)
		if randf() < delta * 20.0:
			FX3.burst(global_position, 1, Pal.SPECTRAL, Vector2(0.15, 0.5), Vector2(0.3, 0.5), {"gravity": -1.2})
		_volley -= delta
		if _volley <= 0.0:
			_volley = VOLLEY_EVERY
			var e := SpellEffect.nearest(global_position, VOLLEY_RANGE, [], ctx.caster)
			if e:
				_bolt(e, VOLLEY_MULT)
				Sfx.play("hex_release", -10.0)
		if t >= life:
			ctx.caster.spirits.erase(self)
			FX3.burst(global_position, 8, Pal.SPECTRAL, Vector2(0.4, 1.6), Vector2(0.2, 0.4))
			queue_free()

	## Called by the player when this spirit absorbs a hit.
	func intercept(d: Damage) -> void:
		FX3.flash(global_position, 0.6, 0.12, Color(0.7, 1.0, 0.85), 3.0)
		FX3.ring(global_position, 0.1, 0.8, 0.3, Pal.SPECTRAL, 1.0, false)
		Sfx.play("hex_block", -1.0)
		var attacker: Node3D = d.source as Node3D
		if is_instance_valid(attacker) and attacker.has_method("is_alive") and attacker.is_alive():
			_bolt(attacker, 1.0)
		queue_free()

	func _bolt(target: Node3D, mult: float) -> void:
		var p := Projectile.new()
		p.style = &"spectral"
		p.ramp = Pal.SPECTRAL
		p.velocity = (target.center() - global_position).normalized() * 8.3
		p.homing = true
		p.turn_rate = 10.0
		p.speed_cap = 13.3
		p.max_dist = 16.0
		p.ignore_walls = true
		ctx.spawn(p, global_position)
		p.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
			var rd := ctx.dmg(mult, SpellEffect.push(pos, a.global_position, 4.0 * mult, 2.5 * mult))
			rd.hit_pos = pos
			rd.statuses.append({"id": &"curse", "duration": 6.0})
			ctx.hit(a, rd)
			FX3.burst(pos, 12, Pal.SPECTRAL, Vector2(1.6, 5.0), Vector2(0.15, 0.35), {"gravity": 5.0}))
