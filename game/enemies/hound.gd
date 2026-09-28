class_name Hound
extends Enemy
## Gloamhound — fast flanker. Stalks at range on one side of the wizard
## (pack members take opposite sides), then crouches with a clear tell:
## eyes flare, it growls and a marker shows the landing spot. The leap is
## committed; the skidding landing is the punish window. No contact damage
## outside the leap.

var attack_box: Area2D
var _leap_hit := false
var _land_at := Vector2.ZERO
var _side := 0
var _rest := 0.8
var _side_t := 0.0


func _setup() -> void:
	attack_box = Area2D.new()
	attack_box.collision_layer = 0
	attack_box.collision_mask = 2
	attack_box.monitorable = false
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(30, 16)
	cs.shape = sh
	cs.position = Vector2(4, -10)
	attack_box.add_child(cs)
	visual.add_child(attack_box)
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


## Pack flanking: the first hound keeps its side; a second hound on the
## same side (the one further away) commits to the other side for a while.
func _pick_side(p: Node2D) -> void:
	_side_t -= get_physics_process_delta_time()
	if _side == 0:
		_side = 1 if global_position.x > p.global_position.x else -1
	if _side_t > 0.0:
		return
	_side_t = 1.0
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if e != self and e is Hound and e.is_alive() and e._side == _side:
			if e.global_position.distance_to(p.global_position) < global_position.distance_to(p.global_position):
				_side = -_side
				_side_t = 5.0
			break


func _ai(delta: float) -> void:
	var p := player()
	_rest -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			anim(&"idle")
			if alive_p and global_position.distance_to(p.global_position) < data.aggro_range:
				Sfx.play("hound_growl", -8.0)
				set_state(&"stalk")
		&"stalk":
			if not alive_p:
				set_state(&"idle")
				return
			_pick_side(p)
			var want_x := p.global_position.x + _side * _p("preferred_dist")
			var dx := want_x - global_position.x
			if absf(dx) > 12.0:
				velocity.x = move_toward(velocity.x, signf(dx) * data.move_speed, 900.0 * delta)
				facing = int(signf(dx))
				anim(&"run")
				if is_on_wall() and is_on_floor():
					velocity.y = -280.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
				face_toward(p.global_position.x)
				anim(&"idle")
			var gap := absf(p.global_position.x - global_position.x)
			if _rest <= 0.0 and is_on_floor() and gap > 50.0 and gap < 175.0 \
					and absf(p.global_position.y - global_position.y) < 90.0 and state_t > 0.3:
				_start_windup(p)
		&"windup":
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			anim(&"windup")
			if alive_p and state_t < _p("windup") * 0.6:
				face_toward(p.global_position.x)
				_land_at = p.global_position
			if state_t >= _p("windup"):
				_leap()
		&"leap":
			anim(&"leap")
			if not _leap_hit:
				for b in attack_box.get_overlapping_bodies():
					if b is Player:
						_leap_hit = true
						var d := Damage.make(data.damage, self, &"", Vector2(facing * 170.0, -150.0))
						d.hit_pos = global_position
						b.take_hit(d)
			if is_on_floor() and state_t > 0.12:
				armored = false
				set_state(&"land")
				Sfx.play("hound_land", -6.0)
				FX.burst(global_position, 8, Pal.DUST, Vector2(20, 70), Vector2(0.2, 0.45), {"dir": Vector2.UP, "spread": 2.6, "add": false, "front": false, "gravity": 120.0})
		&"land":
			velocity.x = move_toward(velocity.x, 0.0, 380.0 * delta)
			anim(&"land")
			if state_t >= _p("land_recover"):
				_rest = _p("rest")
				set_state(&"retreat")
		&"retreat":
			if alive_p:
				var away := signf(global_position.x - p.global_position.x)
				velocity.x = away * data.move_speed * 0.8
				facing = int(away) if away != 0.0 else facing
			anim(&"run")
			if state_t > 0.45:
				set_state(&"stalk")
		&"flinch":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			anim(&"hurt")
			if state_t > 0.35:
				_rest = maxf(_rest, 0.5)
				set_state(&"stalk")


func _start_windup(p: Node2D) -> void:
	set_state(&"windup")
	face_toward(p.global_position.x)
	_land_at = p.global_position
	Sfx.play("hound_snarl", -2.0)
	FX.tele_mark(p.global_position, 30.0, _p("windup"), Color("ff6a3a"))
	FX.burst(center() + Vector2(facing * 14, -6), 4, Pal.DANGER, Vector2(10, 30), Vector2(0.2, 0.3), {"front": true})


func _leap() -> void:
	set_state(&"leap")
	armored = true
	_leap_hit = false
	var T := _p("leap_time")
	var dx := clampf(_land_at.x - global_position.x, -200.0, 200.0)
	var dy := clampf(_land_at.y - global_position.y, -90.0, 60.0)
	velocity.x = dx / T
	velocity.y = (dy - 0.5 * gravity * T * T) / T
	facing = int(signf(dx)) if dx != 0.0 else facing
	Sfx.play("hound_leap", -2.0)


func _flinch() -> void:
	set_state(&"flinch")
	sprite.play(&"hurt")
