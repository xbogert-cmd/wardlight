class_name Raider
extends Enemy
## Briar Raider — shield bearer. With a Hexer nearby it plants itself between
## the Hexer and the wizard, shield raised: hits from the front are mostly
## blocked. Get behind or above it, root it, or knock it out of position with
## a strong push (guard break). Up close it shield-bashes or slashes, each
## with a clear windup.

const BLOCK := 0.2
var box: MeleeBox
var ward: Node2D = null
var _cd := 1.2
var _next_bash := true


func _setup() -> void:
	box = MeleeBox.make(visual, self, Vector2(24, 26), Vector2(12, -16))
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func guarding() -> bool:
	return state in [&"idle", &"advance", &"guard"]


func block_scale(d: Damage) -> float:
	if d.is_proc and d.spell_id == &"":
		return 1.0  # burning goes around a shield
	var from_front := signf(d.hit_pos.x - global_position.x) == facing
	var from_above := d.hit_pos.y < global_position.y - data.body_size.y + 6.0
	if guarding() and from_front and not from_above:
		FX.burst(global_position + Vector2(facing * 10, -18), 6, [Color("ffffff"), Color("f0e0a0"), Color("a09060")], Vector2(40, 120), Vector2(0.1, 0.25), {"dir": Vector2(facing, -0.4), "spread": 1.2, "gravity": 200.0})
		Sfx.play("block", -4.0)
		return BLOCK
	return 1.0


func take_hit(d: Damage) -> void:
	var strong := absf(d.knockback.x) >= 200.0 or d.stagger >= 28.0
	super.take_hit(d)
	if is_alive() and strong and state != &"stagger":
		box.stop()
		set_state(&"stagger")
		Sfx.play("guard_break", -2.0)
		FX.burst(global_position + Vector2(facing * 10, -18), 10, [Color("ffffff"), Color("f0e0a0"), Color("a09060")], Vector2(60, 160), Vector2(0.2, 0.4), {"gravity": 250.0})


func _find_ward() -> void:
	ward = null
	var best := 220.0
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if e is Hexer and e.is_alive():
			var d := global_position.distance_to(e.global_position)
			if d < best:
				best = d
				ward = e


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			anim(&"guard" if alive_p else &"idle")
			if alive_p and global_position.distance_to(p.global_position) < data.aggro_range:
				set_state(&"advance")
		&"advance", &"guard":
			if not alive_p:
				set_state(&"idle")
				return
			if int(state_t * 10.0) % 10 == 0:
				_find_ward()
			var want_x: float
			if ward and is_instance_valid(ward):
				want_x = ward.global_position.x + signf(p.global_position.x - ward.global_position.x) * 34.0
			else:
				want_x = p.global_position.x - signf(p.global_position.x - global_position.x) * 34.0
			var dx := want_x - global_position.x
			face_toward(p.global_position.x)
			if absf(dx) > 6.0:
				velocity.x = move_toward(velocity.x, signf(dx) * data.move_speed, 500.0 * delta)
				anim(&"walk")
				if is_on_wall() and is_on_floor():
					velocity.y = -240.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
				anim(&"guard")
			var gap := absf(p.global_position.x - global_position.x)
			if _cd <= 0.0 and gap < 48.0 and absf(p.global_position.y - global_position.y) < 32.0:
				face_toward(p.global_position.x)
				_next_bash = not _next_bash
				set_state(&"bash_windup" if _next_bash else &"slash_windup")
				Sfx.play("raider_grunt", -4.0)
				FX.flash(global_position + Vector2(facing * 12, -26), 3.0, 0.15, Color(1.0, 0.9, 0.5, 0.9))
		&"bash_windup", &"slash_windup":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			anim(state)
			if state_t >= _p("windup"):
				if state == &"bash_windup":
					set_state(&"bash")
					velocity.x = facing * 230.0
					box.swing(_p("bash_damage"), Vector2(230, -120))
					Sfx.play("dodge", -4.0)
				else:
					set_state(&"slash")
					box.swing(data.damage, Vector2(140, -120))
					Sfx.play("slash", -3.0)
		&"bash", &"slash":
			anim(state)
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_t >= 0.16:
				box.stop()
				set_state(&"recover")
		&"recover":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			anim(&"idle")
			if state_t >= _p("recover"):
				_cd = _p("rest")
				set_state(&"advance")
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			anim(&"stagger")
			if state_t >= _p("stagger_time"):
				_cd = 0.4
				set_state(&"advance")
		&"flinch":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			anim(&"hurt")
			if state_t > 0.3:
				set_state(&"advance")
