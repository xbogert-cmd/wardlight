class_name Hound
extends Enemy
## Gloamhound — fast flanker. Circles the wizard at range (pack members
## spread to different sides), then crouches with a clear tell: eyes flare,
## it snarls and a red ring marks the landing spot. The leap is committed;
## the skidding landing is the punish window. No contact damage outside the leap.
## Hollowed: lands and leaps again at once (a second, quicker marked windup).

var _leap_hit := false
var _land_at := Vector3.ZERO
var _orbit := 1.0
var _rest := 0.8
var _side_t := 0.0
var _mark: MeshInstance3D
var _wind := 0.6             # this windup's length
var _second := false         # hollowed: the follow-up leap is next


func _setup() -> void:
	_orbit = 1.0 if randf() < 0.5 else -1.0
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


## Pack flanking: if another hound is circling on nearly the same bearing,
## the one further away switches direction for a while.
func _spread(p: Node3D) -> void:
	_side_t -= get_physics_process_delta_time()
	if _side_t > 0.0:
		return
	_side_t = 0.8
	var mine := SpellEffect.flat_dir(global_position - p.global_position)
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if e == self or not (e is Hound) or not e.is_alive():
			continue
		var theirs := SpellEffect.flat_dir(e.global_position - p.global_position)
		if mine.angle_to(theirs) < 0.9 and dist_to(p.global_position) > e.dist_to(p.global_position):
			_orbit = -e._orbit
			_side_t = 3.0
			return


func _ai(delta: float) -> void:
	var p := player()
	_rest -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			steer(Vector3.ZERO, 25.0, delta)
			anim(&"idle")
			if alive_p and dist_to(p.global_position) < data.aggro_range:
				Sfx.play("hound_growl", -8.0)
				set_state(&"stalk")
		&"stalk":
			if not alive_p:
				set_state(&"idle")
				return
			_spread(p)
			var out := SpellEffect.flat_dir(global_position - p.global_position)
			var want := p.global_position + out.rotated(Vector3.UP, 0.55 * _orbit) * _p("preferred_dist")
			var d := want - global_position
			d.y = 0.0
			if d.length() > 0.4:
				steer(d.normalized() * data.move_speed, 30.0, delta)
				if absf(velocity.x) > 0.3:
					facing = int(signf(velocity.x))
				heading = SpellEffect.flat_dir(velocity, heading)
				anim(&"run")
			else:
				steer(Vector3.ZERO, 30.0, delta)
				face_toward(p.global_position)
				anim(&"idle")
			var gap := dist_to(p.global_position)
			if _rest <= 0.0 and gap > 2.2 and gap < 7.3 and state_t > 0.3 and is_on_floor():
				_start_windup(p)
		&"windup":
			steer(Vector3.ZERO, 50.0, delta)
			anim(&"windup")
			if alive_p and state_t < _wind * 0.6:
				face_toward(p.global_position)
				_land_at = p.global_position
				if is_instance_valid(_mark):
					_mark.global_position = _land_at + Vector3(0, 0.04, 0)
			if randf() < delta * 20.0:
				FX3.burst(center() + heading * 0.4 + Vector3(0, 0.1, 0), 1, Pal.DANGER, Vector2(0.2, 0.8), Vector2(0.15, 0.3), {"gravity": -1.0})
			if state_t >= _wind:
				_leap()
		&"leap":
			anim(&"leap")
			if not _leap_hit and alive_p and dist_to(p.global_position) < radius() + p.radius() + 0.35:
				_leap_hit = true
				var dmg := Damage.make(data.damage, self, &"", heading * 7.0 + Vector3(0, 4.0, 0))
				dmg.hit_pos = global_position
				p.take_hit(dmg)
			if is_on_floor() and state_t > 0.12:
				armored = false
				set_state(&"land")
				Sfx.play("hound_land", -6.0)
				FX3.burst(global_position + Vector3(0, 0.1, 0), 10, Pal.DUST, Vector2(1.0, 3.0), Vector2(0.2, 0.45), {"dir": Vector3.UP, "spread": 2.4, "gravity": 6.0})
		&"land":
			steer(Vector3.ZERO, 16.0, delta)
			anim(&"land")
			if hollowed and not _second and alive_p and state_t >= 0.2:
				_second = true
				_start_windup(p, 0.7)
			elif state_t >= _p("land_recover"):
				_second = false
				_rest = _p("rest")
				_orbit = -_orbit
				set_state(&"retreat")
		&"retreat":
			if alive_p:
				var away := SpellEffect.flat_dir(global_position - p.global_position)
				steer(away * data.move_speed * 0.8, 40.0, delta)
				if absf(away.x) > 0.2:
					facing = int(signf(away.x))
			anim(&"run")
			if state_t > 0.45:
				set_state(&"stalk")
		&"flinch":
			steer(Vector3.ZERO, 30.0, delta)
			anim(&"hurt")
			if state_t > 0.35:
				_rest = maxf(_rest, 0.5)
				set_state(&"stalk")


func _start_windup(p: Node3D, speed := 1.0) -> void:
	_wind = _p("windup") * speed
	set_state(&"windup")
	face_toward(p.global_position)
	_land_at = p.global_position
	Sfx.play("hound_snarl", -2.0)
	_mark = FX3.tele_ring(_land_at, 0.8, _wind + 0.15, Color(1.0, 0.4, 0.2, 0.9))


func _leap() -> void:
	set_state(&"leap")
	armored = true
	_leap_hit = false
	var T := _p("leap_time")
	var d := _land_at - global_position
	d.y = 0.0
	if d.length() > 8.5:
		d = d.normalized() * 8.5
	velocity = d / T + Vector3(0, 22.0 * T * 0.5, 0)
	heading = SpellEffect.flat_dir(d, heading)
	if absf(d.x) > 0.1:
		facing = int(signf(d.x))
	Sfx.play("hound_leap", -2.0)
