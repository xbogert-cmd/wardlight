class_name Lurker
extends Enemy
## Mire Lurker — hunts hidden, as a ripple through mud and shallow water
## (untargetable and untouchable while under). Near the wizard it stops and
## a ring marks the spot for WARN seconds (the tell), then it bursts up
## there and bites whoever stayed, and lies exposed on land for a while (the
## punish window) before diving again. It only hunts within its aggro range,
## so it never comes up from off-screen.

var _cd := 0.6
var _spot := Vector3.ZERO
var _ripple_t := 0.0


func _setup() -> void:
	_hide()
	set_state(&"lurk")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func _hide() -> void:
	remove_from_group(&"enemy")
	sprite.visible = false
	collision_layer = 0


func _show() -> void:
	add_to_group(&"enemy")
	sprite.visible = true
	collision_layer = 4


func block_scale(_d: Damage) -> float:
	return 0.0 if state in [&"lurk", &"hunt", &"warn"] else 1.0


## Knocked about but never interrupted: its windows are fixed by design.
func _flinch() -> void:
	sprite.play(&"hurt", true)


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"lurk":
			steer(Vector3.ZERO, 20.0, delta)
			if alive_p and _cd <= 0.0 and dist_to(p.global_position) < data.aggro_range:
				set_state(&"hunt")
		&"hunt":
			if not alive_p or dist_to(p.global_position) > data.aggro_range * 1.5:
				set_state(&"lurk")
				return
			face_toward(p.global_position)
			steer(heading * data.move_speed, 20.0, delta)
			_ripple(delta, 1.0)
			if dist_to(p.global_position) < 0.7 or state_t > 4.0:
				_spot = p.global_position
				set_state(&"warn")
				FX3.tele_ring(_spot, _p("bite_reach"), _p("warn"), Color(1.0, 0.5, 0.25, 0.95))
				Sfx.play("knot_creak", -4.0, 0.3)
		&"warn":
			velocity.x = 0.0
			velocity.z = 0.0
			global_position = Vector3(_spot.x, global_position.y, _spot.z)
			_ripple(delta, 2.5)
			if state_t >= _p("warn"):
				_surface(p)
		&"surface":
			steer(Vector3.ZERO, 30.0, delta)
			anim(&"surface")
			if state_t >= 0.25:
				set_state(&"exposed")
		&"exposed":
			steer(Vector3.ZERO, 30.0, delta)
			if alive_p:
				face_toward(p.global_position)
			if sprite.anim != &"hurt" or sprite.is_done():
				anim(&"idle")
			if state_t >= _p("exposed"):
				set_state(&"dive")
				Sfx.play("roots", -8.0)
		&"dive":
			anim(&"dive")
			if state_t >= 0.3:
				_hide()
				_cd = _p("rest")
				set_state(&"lurk")


func _surface(p: Player) -> void:
	_show()
	set_state(&"surface")
	sprite.play(&"surface", true)
	Sfx.play("hound_snarl", -2.0, 0.2)
	FX3.burst(_spot + Vector3(0, 0.2, 0), 22, [Color("a89878"), Color("7a6a4a"), Color("54482f")], Vector2(1.5, 4.5), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 1.4, "gravity": 9.0})
	GameCamera3D.shake_all(2.5)
	if p and p.is_alive() and SpellEffect.flat(p.global_position, _spot) < _p("bite_reach") + p.radius():
		var d := Damage.make(data.damage, self, &"", SpellEffect.push(_spot, p.global_position, 5.0, 6.0))
		d.hit_pos = _spot
		p.take_hit(d)


## The hidden lurker's wake: churned mud and a widening ripple.
func _ripple(delta: float, rate: float) -> void:
	_ripple_t -= delta * rate
	if _ripple_t > 0.0:
		return
	_ripple_t = 0.12
	var g := global_position + Vector3(0, 0.06, 0)
	FX3.burst(g, 2, [Color("a89878"), Color("7a6a4a"), Color("54482f")], Vector2(0.4, 1.4), Vector2(0.2, 0.4), {"dir": Vector3.UP, "spread": 1.2, "gravity": 7.0})
	FX3.ring(g, 0.15, 0.7, 0.4, [Color(0.75, 0.7, 0.55, 0.7), Color(0.55, 0.5, 0.38, 0.6), Color(0.35, 0.3, 0.22, 0.5)], 1.0)
