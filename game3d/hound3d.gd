class_name Hound3D
extends Enemy3D
## Gloamhound on open ground: circles to a flank, crouches with a telegraph
## ring marking the landing spot, leaps, then skids (punish window).

const RING := preload("res://assets/generated/rune40.png")
var _land := Vector3.ZERO
var _hit := false
var _rest := 1.0
var _orbit := 1.0


func _ai(delta: float) -> void:
	var p := player()
	_rest -= delta
	if p == null or not p.is_alive():
		velocity.x = 0.0
		velocity.z = 0.0
		sprite.play(&"idle")
		return
	var to_p := p.global_position - global_position
	to_p.y = 0.0
	match state:
		&"idle":
			sprite.play(&"idle")
			if to_p.length() < 12.0:
				Sfx.play("hound_growl", -8.0)
				_orbit = 1.0 if randf() < 0.5 else -1.0
				set_state(&"stalk")
		&"stalk":
			# circle at ~5 m, drifting toward the wizard's side
			var want := p.global_position - to_p.normalized().rotated(Vector3.UP, 0.6 * _orbit) * 5.0
			var d := want - global_position
			d.y = 0.0
			var v := d.normalized() * 6.0 if d.length() > 0.4 else Vector3.ZERO
			velocity.x = move_toward(velocity.x, v.x, 30.0 * delta)
			velocity.z = move_toward(velocity.z, v.z, 30.0 * delta)
			facing = int(signf(velocity.x)) if absf(velocity.x) > 0.3 else int(signf(to_p.x))
			sprite.play(&"run" if v != Vector3.ZERO else &"idle")
			if _rest <= 0.0 and to_p.length() < 7.0 and to_p.length() > 2.5 and state_t > 0.5:
				set_state(&"windup")
				_land = p.global_position
				facing = int(signf(to_p.x))
				Sfx.play("hound_snarl", -2.0)
				FX3.decal(RING, _land + Vector3(0, 0.05, 0), 0.6, Color(1.0, 0.35, 0.2, 0.9), 0.55, 0.45, -3.0)
		&"windup":
			velocity.x = 0.0
			velocity.z = 0.0
			sprite.play(&"windup")
			if state_t < 0.35:
				_land = p.global_position
			if state_t >= 0.6:
				set_state(&"leap")
				_hit = false
				var d2 := _land - global_position
				d2.y = 0.0
				velocity = d2 / 0.5 + Vector3(0, 5.5, 0)
				Sfx.play("hound_leap", -2.0)
		&"leap":
			sprite.play(&"leap")
			if not _hit and global_position.distance_to(p.global_position) < 1.0:
				_hit = true
				p.take_hit(16.0, global_position)
			if is_on_floor() and state_t > 0.15:
				set_state(&"land")
				Sfx.play("hound_land", -6.0)
				FX3.burst(global_position + Vector3(0, 0.1, 0), 10, Pal.DUST, Vector2(1, 3), Vector2(0.2, 0.45), {"dir": Vector3.UP, "spread": 2.4, "gravity": 6.0})
		&"land":
			velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
			sprite.play(&"land")
			if state_t >= 0.75:
				_rest = 1.2
				_orbit = -_orbit
				set_state(&"stalk")
