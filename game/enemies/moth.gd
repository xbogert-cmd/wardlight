class_name Moth
extends Enemy
## Hollow Moth — a flyer hanging about HOVER metres up that keeps 6-9 m from
## the wizard, drifting sideways. Every few seconds its wing-spots flare (the
## tell) and it looses a slow homing spore: dodge it, or pop it with any
## spell. Fragile; shot down, it drops to the ground.

var _cd := 1.5
var _orbit := 1.0
var _t := 0.0


func _setup() -> void:
	_orbit = 1.0 if randf() < 0.5 else -1.0
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func _ai(delta: float) -> void:
	_t += delta
	_cd -= delta
	# hold altitude over the ground below, with a slow bob
	var ground := Region.current.terrain.height_at(global_position.x, global_position.z) if Region.current and Region.current.terrain else 0.0
	velocity.y = (ground + _p("hover") + sin(_t * 2.2) * 0.15 - global_position.y) * 5.0
	var p := player()
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			steer(Vector3.ZERO, 10.0, delta)
			anim(&"idle")
			if alive_p and dist_to(p.global_position) < data.aggro_range:
				set_state(&"fly")
		&"fly":
			if not alive_p:
				set_state(&"idle")
				return
			anim(&"idle")
			face_toward(p.global_position)
			var d := dist_to(p.global_position)
			var to_p := SpellEffect.flat_dir(p.global_position - global_position)
			var want := to_p.rotated(Vector3.UP, PI / 2 * _orbit) * data.move_speed * 0.6
			if d < _p("near"):
				want = -to_p * data.move_speed
			elif d > _p("far"):
				want = to_p * data.move_speed
			steer(want, 8.0, delta)
			if is_on_wall():
				_orbit = -_orbit
			if _cd <= 0.0 and d < _p("far") + 2.0:
				set_state(&"windup")
				Sfx.play("hex_gather", -8.0, 0.4)
		&"windup":
			steer(Vector3.ZERO, 12.0, delta)
			anim(&"windup")
			if randf() < delta * 30.0:
				FX3.converge(center(), 0.5, 1, [Color("e8ffb0"), Color("a8d860"), Color("5a7a3a")], 0.2, 1.5)
			if state_t >= _p("windup"):
				_loose(p)
				set_state(&"shoot")
		&"shoot":
			anim(&"shoot")
			if state_t >= 0.25:
				_cd = _p("fire_cd")
				_orbit = -_orbit
				set_state(&"fly")
		&"flinch":
			anim(&"hurt")
			steer(Vector3.ZERO, 10.0, delta)
			if state_t > 0.3:
				set_state(&"fly")


func _loose(p: Player) -> void:
	if p == null:
		return
	var s: Enemy = Spore.new()
	s.data = preload("res://data/enemies/spore.tres")
	s.set("speed", _p("spore_speed"))
	s.set("target", p)
	s.position = (get_parent() as Node3D).to_local(center())
	get_parent().add_child(s)
	Sfx.play("hex_release", -8.0, 0.3)
