class_name Raider
extends Enemy
## Briar Raider — shield bearer. With a Hexer nearby it plants itself between
## the Hexer and the wizard, shield raised toward the wizard: hits from the
## front are mostly blocked. Circle around it, root it, or knock it out of
## position with a strong push (guard break). Up close it shield-bashes or
## slashes, each with a clear windup.

const BLOCK := 0.2
const SHIELD_ARC := deg_to_rad(75.0)
var box: MeleeBox
var ward: Node3D = null
var _cd := 1.2
var _next_bash := true
var _ward_t := 0.0


func _setup() -> void:
	box = MeleeBox.make(self, 1.5, 70.0)
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func guarding() -> bool:
	return state in [&"idle", &"advance", &"guard"]


func block_scale(d: Damage) -> float:
	if d.is_proc and d.spell_id == &"":
		return 1.0  # burning goes around a shield
	var from := SpellEffect.flat_dir(d.hit_pos - global_position, -heading)
	if guarding() and from.angle_to(heading) < SHIELD_ARC:
		var at := center() + heading * 0.4
		FX3.burst(at, 6, [Color("ffffff"), Color("f0e0a0"), Color("a09060")], Vector2(1.6, 5.0), Vector2(0.1, 0.25), {"dir": heading + Vector3(0, 0.4, 0), "spread": 1.2, "gravity": 8.0})
		FX3.ring(at, 0.1, 0.5, 0.15, [Color("ffffff"), Color("f0e0a0"), Color("a09060")], 1.0, false)
		Sfx.play("block", -4.0)
		return BLOCK
	return 1.0


func take_hit(d: Damage) -> void:
	var strong := Vector2(d.knockback.x, d.knockback.z).length() >= 8.3 or d.stagger >= 28.0
	super.take_hit(d)
	if is_alive() and strong and state != &"stagger":
		box.stop()
		set_state(&"stagger")
		Sfx.play("guard_break", -2.0)
		FX3.burst(center() + heading * 0.4, 10, [Color("ffffff"), Color("f0e0a0"), Color("a09060")], Vector2(2.5, 6.5), Vector2(0.2, 0.4), {"gravity": 10.0})


func _find_ward() -> void:
	ward = null
	var best := 9.0
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if e is Hexer and e.is_alive():
			var d := dist_to(e.global_position)
			if d < best:
				best = d
				ward = e


const SPIN_R := 1.8
const SPIN_WINDUP := 0.45


## Hollowed follow-up: one cut all the way round.
func _spin(p: Player) -> void:
	Sfx.play("slash", -2.0)
	FX3.ring(global_position + Vector3(0, 0.6, 0), 0.4, SPIN_R, 0.2, [Color("ffffff"), Color("e0d8c8"), Color("a09888")], 2.0, false)
	if p and p.is_alive() and dist_to(p.global_position) < SPIN_R + p.radius():
		var d := Damage.make(data.damage * 0.8, self, &"", SpellEffect.push(global_position, p.global_position, 6.0, 3.0))
		d.hit_pos = center()
		p.take_hit(d)


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			steer(Vector3.ZERO, 25.0, delta)
			anim(&"guard" if alive_p else &"idle")
			if alive_p and dist_to(p.global_position) < data.aggro_range:
				set_state(&"advance")
		&"advance", &"guard":
			if not alive_p:
				set_state(&"idle")
				return
			_ward_t -= delta
			if _ward_t <= 0.0:
				_ward_t = 1.0
				_find_ward()
			var want: Vector3
			if ward and is_instance_valid(ward) and ward.is_alive():
				want = ward.global_position + SpellEffect.flat_dir(p.global_position - ward.global_position) * 1.5
			else:
				want = p.global_position - SpellEffect.flat_dir(p.global_position - global_position) * 1.3
			var d := want - global_position
			d.y = 0.0
			face_toward(p.global_position)
			if d.length() > 0.25:
				steer(d.normalized() * data.move_speed, 20.0, delta)
				anim(&"walk")
			else:
				steer(Vector3.ZERO, 25.0, delta)
				anim(&"guard")
			var gap := dist_to(p.global_position)
			if _cd <= 0.0 and gap < 1.9:
				face_toward(p.global_position)
				_next_bash = not _next_bash
				set_state(&"bash_windup" if _next_bash else &"slash_windup")
				Sfx.play("raider_grunt", -4.0)
				FX3.flash(center() + heading * 0.5 + Vector3(0, 0.3, 0), 0.25, 0.15, Color(1.0, 0.9, 0.5, 0.9), 0.0)
				if _next_bash:
					FX3.tele_line(global_position, global_position + heading * 2.2, _p("windup"), Color(1.0, 0.55, 0.3, 0.9), 3.0, false)
				else:
					FX3.arc(global_position + Vector3(0, 0.05, 0), 1.5, 1.5, heading, deg_to_rad(140.0), _p("windup"), [Color(1.0, 0.55, 0.3, 0.9)], 2.0)
		&"bash_windup", &"slash_windup":
			steer(Vector3.ZERO, 35.0, delta)
			anim(state)
			if state_t >= _p("windup"):
				if state == &"bash_windup":
					set_state(&"bash")
					velocity.x = heading.x * 9.5
					velocity.z = heading.z * 9.5
					box.swing(_p("bash_damage"), 9.5, 4.0)
					Sfx.play("dodge", -4.0)
				else:
					set_state(&"slash")
					box.swing(data.damage, 6.0, 4.0)
					Sfx.play("slash", -3.0)
					FX3.arc(global_position + Vector3(0, 0.6, 0), 0.5, 1.6, heading, deg_to_rad(140.0), 0.15, [Color("ffffff"), Color("e0d8c8"), Color("a09888")], 2.0)
		&"bash", &"slash":
			anim(state)
			steer(Vector3.ZERO, 38.0, delta)
			if state_t >= 0.16:
				box.stop()
				if hollowed and state == &"slash":
					set_state(&"spin_windup")
					FX3.tele_ring(global_position, SPIN_R, SPIN_WINDUP, Color(1.0, 0.45, 0.3, 0.9))
					Sfx.play("raider_grunt", -6.0, 0.2)
				else:
					set_state(&"recover")
		&"spin_windup":
			steer(Vector3.ZERO, 35.0, delta)
			anim(&"slash_windup")
			if state_t >= SPIN_WINDUP:
				set_state(&"spin")
				_spin(p)
		&"spin":
			anim(&"slash")
			facing = -facing if int(state_t * 20.0) % 2 == 0 else facing
			if state_t >= 0.25:
				set_state(&"recover")
		&"recover":
			steer(Vector3.ZERO, 33.0, delta)
			anim(&"idle")
			if state_t >= _p("recover"):
				_cd = _p("rest")
				set_state(&"advance")
		&"stagger":
			steer(Vector3.ZERO, 16.0, delta)
			anim(&"stagger")
			if state_t >= _p("stagger_time"):
				_cd = 0.4
				set_state(&"advance")
		&"flinch":
			steer(Vector3.ZERO, 30.0, delta)
			anim(&"hurt")
			if state_t > 0.3:
				set_state(&"advance")
