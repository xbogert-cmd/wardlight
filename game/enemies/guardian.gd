class_name Guardian
extends Enemy
## The Hollowed Warden — the Old Ward's forest guardian, corrupted by the
## roots choking the ward. Rooted near the ward stone, it turns to face the
## wizard and shuffles closer when far. Three patterns:
##   sweeping limb   — a wide arc in front (phase 2: two sweeps back to back)
##   root eruptions  — rings marked on the ground, then thorns burst up
##                     (phase 1: three around the wizard; phase 2: a line
##                     of rings marching toward the wizard)
##   seed burst      — a pod swells and spits corrupted seeds (phase 1: a fan
##                     at the wizard; phase 2: two radial volleys)
## At 55% health it transforms (untouchable for a moment, no damage burst):
## ward-stones crack violet and the patterns change. Telegraphs are drawn over
## everything else.

signal phase_changed(p: int)

const PHASE2_AT := 0.55
var box: MeleeBox
var phase := 1
var engaged := false
var _cd := 1.6
var _order := 0
var _sweeps_left := 0


func _setup() -> void:
	is_boss = true
	box = MeleeBox.make(self, 4.0, 85.0)
	set_state(&"idle")


func _p(k: String) -> float:
	var v: float = data.params.get(k, 0.0)
	return v * (0.8 if phase == 2 and k.ends_with("windup") else 1.0)


func _flinch() -> void:
	pass


func block_scale(_d: Damage) -> float:
	return 0.0 if state == &"transform" else 1.0


func take_hit(d: Damage) -> void:
	super.take_hit(d)
	if is_alive() and phase == 1 and health.ratio() <= PHASE2_AT and state != &"transform":
		box.stop()
		set_state(&"transform")
		armored = true
		Sfx.play("sentinel_windup", 3.0)
		GameCamera3D.shake_all(4.0)


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	var idle_anim := &"idle2" if phase == 2 else &"idle"
	match state:
		&"idle":
			anim(idle_anim)
			steer(Vector3.ZERO, 10.0, delta)
			if not alive_p:
				return
			if not engaged:
				if dist_to(p.global_position) < data.aggro_range:
					engaged = true
					Sfx.play("roots", 2.0)
					GameCamera3D.shake_all(3.0)
				return
			face_toward(p.global_position)
			var gap := dist_to(p.global_position)
			if gap > 5.5:
				steer(heading * data.move_speed, 6.0, delta)
			if _cd <= 0.0:
				_choose(p, gap)
		&"sweep_windup":
			anim(&"sweep_windup")
			steer(Vector3.ZERO, 10.0, delta)
			if state_t >= _p("sweep_windup"):
				set_state(&"sweep")
				box.swing(_p("sweep_damage"), 10.0, 4.0)
				FX3.arc(global_position + Vector3(0, 0.8, 0), 1.0, 4.1, heading, deg_to_rad(170.0), 0.22, [Color("ffffff"), Color("c8a0f0"), Color("6a4a8a")], 3.0)
				FX3.burst(global_position + heading * 2.5 + Vector3(0, 0.3, 0), 18, Pal.DUST, Vector2(2.0, 6.0), Vector2(0.3, 0.6), {"dir": heading, "spread": 2.2, "gravity": 6.0})
				Sfx.play("slash", 3.0)
				GameCamera3D.shake_all(3.0)
		&"sweep":
			anim(&"sweep")
			if state_t >= 0.2:
				box.stop()
				_sweeps_left -= 1
				if _sweeps_left > 0 and alive_p:
					face_toward(p.global_position)
					_tele_sweep()
					set_state(&"sweep_windup")
				else:
					set_state(&"recover")
		&"roots_windup":
			anim(&"roots_windup" if state_t < 0.6 else &"roots")
			if state_t >= _p("roots_windup"):
				set_state(&"recover")
		&"seed_windup":
			anim(&"seed_windup")
			if alive_p and state_t < _p("seed_windup") * 0.5:
				face_toward(p.global_position)
			if state_t >= _p("seed_windup"):
				set_state(&"seed")
				_seeds(p)
		&"seed":
			anim(&"seed")
			if state_t >= 0.25:
				if phase == 2 and _order % 2 == 1 and alive_p:
					_order += 1
					set_state(&"seed_windup")
				else:
					set_state(&"recover")
		&"recover":
			anim(&"recover")
			steer(Vector3.ZERO, 10.0, delta)
			if state_t >= (0.9 if phase == 1 else 0.7):
				_cd = 0.6 if phase == 2 else 1.0
				set_state(&"idle")
		&"transform":
			anim(&"transform")
			if randf() < 0.5:
				var a := randf() * TAU
				FX3.burst(global_position + Vector3(cos(a) * 1.5, 0.2, sin(a) * 1.5), 1, Pal.school(&"hex"), Vector2(1.0, 4.0), Vector2(0.5, 1.0), {"dir": Vector3.UP, "spread": 0.5})
			if state_t >= 1.4:
				phase = 2
				armored = false
				phase_changed.emit(2)
				FX3.ring(global_position + Vector3(0, 0.06, 0), 0.5, 6.0, 0.6, Pal.school(&"hex"), 2.0)
				FX3.flash(center(), 1.5, 0.3, Color(0.7, 0.4, 1.0), 6.0)
				Sfx.play("storm_thunder", 0.0)
				_cd = 1.0
				set_state(&"idle")


func _choose(p: Player, gap: float) -> void:
	_order += 1
	var pick := _order % 3
	if gap > 6.0 and pick == 0:
		pick = 2
	match pick:
		0:
			_sweeps_left = 2 if phase == 2 else 1
			_tele_sweep()
			set_state(&"sweep_windup")
			Sfx.play("raider_grunt", 3.0)
		1:
			set_state(&"roots_windup")
			_roots(p)
			Sfx.play("knot_creak", 2.0)
		2:
			set_state(&"seed_windup")
			if phase == 2:
				_order = _order | 1   # odd: a second volley follows
			var pod := center() + heading * 0.5 + Vector3(0, 1.4, 0)
			FX3.converge(pod, 1.2, 20, Pal.school(&"hex"), _p("seed_windup"), 1.5)
			Sfx.play("hex_gather", 2.0)


func _tele_sweep() -> void:
	FX3.arc(global_position + Vector3(0, 0.05, 0), 4.1, 4.1, heading, deg_to_rad(170.0), _p("sweep_windup"), [Color(1.0, 0.5, 0.8, 0.9)], 3.0)


func _roots(p: Player) -> void:
	var spots: Array[Vector3] = []
	if phase == 1:
		spots.append(p.global_position)
		for k in 2:
			var a := randf() * TAU
			spots.append(p.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(2.5, 4.0))
	else:
		var from := global_position
		var dir := SpellEffect.flat_dir(p.global_position - from, heading)
		for k in 5:
			spots.append(from + dir * (2.5 + k * 1.8))
	for k in spots.size():
		var at := SpellEffect.ground_at(spots[k], self)
		var delay := _p("roots_windup") + (k * 0.2 if phase == 2 else 0.0)
		FX3.tele_ring(at, 1.2, delay, Color(1.0, 0.45, 0.85, 0.9))
		SpellEffect.later(delay, func() -> void:
			if not is_alive():
				return
			var tp := Knot.ThornPatch.new()
			tp.radius = 1.2
			tp.damage = data.damage * 0.75
			tp.source = self
			get_parent().add_child(tp)
			tp.global_position = at)


func _seeds(p: Player) -> void:
	var from := center() + heading * 0.6 + Vector3(0, 1.3, 0)
	var dirs: Array[Vector3] = []
	if phase == 1:
		var aim := SpellEffect.flat_dir(p.global_position - from, heading)
		for k in 5:
			dirs.append(aim.rotated(Vector3.UP, (k - 2) * 0.22))
	else:
		var off := randf() * TAU
		for k in 10:
			dirs.append(Vector3.RIGHT.rotated(Vector3.UP, off + k * TAU / 10.0))
	for d in dirs:
		var pr := Projectile.new()
		pr.team = &"enemy"
		pr.style = &"spectral"
		pr.ramp = Pal.school(&"hex")
		pr.velocity = d * 7.5
		pr.max_dist = 14.0
		pr.radius = 0.3
		pr.lit = false
		get_parent().add_child(pr)
		pr.global_position = Vector3(from.x, global_position.y + 1.0, from.z)
		var dmg := _p("seed_damage")
		pr.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
			var dd := Damage.make(dmg, self, &"hex", d * 5.0 + Vector3(0, 3.0, 0))
			dd.hit_pos = pos
			a.take_hit(dd)
			FX3.burst(pos, 10, Pal.school(&"hex"), Vector2(1.6, 4.6), Vector2(0.15, 0.35)))
	FX3.flash(from, 0.6, 0.1, Color(0.8, 0.5, 1.0), 3.0)
	Sfx.play("hex_release", 2.0)
