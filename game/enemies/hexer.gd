class_name Hexer
extends Enemy
## Hollow Hexer — ranged caster. Keeps its distance and backs away when
## crowded. Its hands rise and glow while a dashed line on the ground shows
## where the bolt will fly (the aim locks partway through and the line turns
## solid), then it throws a slow hex bolt and slumps, exhausted — the punish
## window, when it staggers easily.

var _cd := 1.5
var _aim := Vector3.ZERO
var _strafe := 1.0
var _line: MeshInstance3D
var _locked := false


func _setup() -> void:
	_strafe = 1.0 if randf() < 0.5 else -1.0
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func _hand() -> Vector3:
	return global_position + heading * 0.3 + Vector3(0, 1.55, 0)


func take_hit(d: Damage) -> void:
	if state == &"recover":
		d.stagger *= 3.0  # exhausted after casting
	if state == &"windup" and d.stagger >= data.poise * 0.5:
		_flinch_cd = 0.0
	super.take_hit(d)
	if state != &"windup":
		_clear_line()


func _clear_line() -> void:
	if is_instance_valid(_line):
		_line.queue_free()
	_line = null


func _die() -> void:
	_clear_line()
	super._die()


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle", &"move":
			if not alive_p:
				steer(Vector3.ZERO, 16.0, delta)
				anim(&"idle")
				return
			var dist := dist_to(p.global_position)
			if state == &"idle" and dist > data.aggro_range:
				anim(&"idle")
				return
			face_toward(p.global_position)
			var to_p := SpellEffect.flat_dir(p.global_position - global_position)
			var want := Vector3.ZERO
			if dist < _p("too_close"):
				want = -to_p * data.move_speed * 1.2
			elif dist > _p("far"):
				want = to_p * data.move_speed
			else:
				want = to_p.rotated(Vector3.UP, PI / 2 * _strafe) * data.move_speed * 0.5
			steer(want, 20.0, delta)
			if is_on_wall():
				_strafe = -_strafe
			anim(&"move" if Vector2(velocity.x, velocity.z).length() > 0.4 else &"idle")
			if state == &"idle":
				set_state(&"move")
			if _cd <= 0.0 and dist < _p("far") + 2.5 and SpellEffect.has_los(_hand(), p.center(), self):
				set_state(&"windup")
				_aim = p.global_position
				_locked = false
				Sfx.play("hex_gather", -2.0)
				_line = FX3.tele_line(global_position, _aim, _p("windup") + 0.1, Color(0.78, 0.55, 1.0, 0.7), 1.0, true)
		&"windup":
			steer(Vector3.ZERO, 25.0, delta)
			anim(&"windup")
			if alive_p and state_t < _p("windup") * 0.6:
				face_toward(p.global_position)
				_aim = p.global_position
				_place_line()
			elif not _locked:
				_locked = true
				_clear_line()
				var end := global_position + SpellEffect.flat_dir(_aim - global_position) * 12.0
				_line = FX3.tele_line(global_position, end, _p("windup") * 0.4 + 0.1, Color(1.0, 0.48, 0.85, 0.95), 2.0, false)
			if randf() < delta * 40.0:
				FX3.converge(_hand(), 0.5, 1, Pal.school(&"hex"), 0.2, 1.5)
			if state_t >= _p("windup"):
				_clear_line()
				_fire()
				set_state(&"cast")
		&"cast":
			anim(&"cast")
			if state_t >= 0.2:
				set_state(&"recover")
		&"recover":
			anim(&"recover")
			steer(Vector3.ZERO, 25.0, delta)
			if state_t >= _p("recover"):
				_cd = _p("rest")
				_strafe = -_strafe
				set_state(&"move")
		&"flinch":
			steer(Vector3.ZERO, 30.0, delta)
			anim(&"hurt")
			if state_t > 0.4:
				_cd = maxf(_cd, 0.6)
				set_state(&"move")


## Keep the dashed aim line running from the hexer's feet to the aim spot.
func _place_line() -> void:
	if not is_instance_valid(_line):
		return
	var a := global_position
	var d := _aim - a
	var len := Vector2(d.x, d.z).length()
	if len < 0.1:
		return
	(_line.mesh as QuadMesh).size.x = len
	(_line.material_override as ShaderMaterial).set_shader_parameter(&"size_m", (_line.mesh as QuadMesh).size)
	_line.global_position = (a + _aim) * 0.5 + Vector3(0, 0.05, 0)
	_line.rotation = Vector3(-PI / 2, -atan2(d.z, d.x), 0)


func _fire() -> void:
	var from := _hand()
	var target := _aim + Vector3(0, 0.9, 0)
	var p := Projectile.new()
	p.team = &"enemy"
	p.style = &"spectral"
	p.ramp = Pal.school(&"hex")
	var dir := SpellEffect.flat_dir(target - from, heading)
	p.velocity = dir * _p("bolt_speed")
	p.max_dist = 16.0
	p.radius = 0.25
	get_parent().add_child(p)
	p.global_position = Vector3(from.x, global_position.y + 1.0, from.z)
	var dmg := data.damage
	p.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
		var d := Damage.make(dmg, self, &"hex", dir * 5.8 + Vector3(0, 3.5, 0))
		d.hit_pos = pos
		a.take_hit(d)
		FX3.burst(pos, 10, Pal.school(&"hex"), Vector2(1.6, 4.6), Vector2(0.15, 0.35)))
	p.hit_wall.connect(func(pos: Vector3) -> void: FX3.burst(pos, 8, Pal.school(&"hex"), Vector2(0.8, 3.0), Vector2(0.15, 0.3)))
	FX3.flash(from, 0.35, 0.1, Color(0.85, 0.6, 1.0, 0.9), 2.0)
	Sfx.play("hex_release", -3.0)
