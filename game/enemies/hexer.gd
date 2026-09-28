class_name Hexer
extends Enemy
## Hollow Hexer — ranged caster. Keeps its distance and backs away when
## crowded. Its hands rise and glow while a dotted line shows where the bolt
## will fly (the aim locks partway through), then it throws a slow hex bolt
## and slumps, exhausted — the punish window, when it staggers easily.

var _cd := 1.5
var _aim := Vector2.ZERO
var tele: Node2D


func _setup() -> void:
	tele = Node2D.new()
	tele.z_index = FX.Z_TELE
	tele.z_as_relative = false
	tele.top_level = true
	tele.draw.connect(_draw_tele)
	add_child(tele)
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func _hand() -> Vector2:
	return global_position + Vector2(facing * 7, -38)


func take_hit(d: Damage) -> void:
	if state == &"recover":
		d.stagger *= 3.0  # exhausted after casting
	if state == &"windup" and d.stagger >= data.poise * 0.5:
		_flinch_cd = 0.0
	super.take_hit(d)


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	tele.queue_redraw()
	match state:
		&"idle", &"move":
			if not alive_p:
				velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
				anim(&"idle")
				return
			var dist := global_position.distance_to(p.global_position)
			if state == &"idle" and dist > data.aggro_range:
				anim(&"idle")
				return
			face_toward(p.global_position.x)
			var dx := p.global_position.x - global_position.x
			var want := 0.0
			if absf(dx) < _p("too_close"):
				want = -signf(dx) * data.move_speed * 1.2
			elif absf(dx) > _p("far"):
				want = signf(dx) * data.move_speed
			velocity.x = move_toward(velocity.x, want, 500.0 * delta)
			if is_on_wall() and want != 0.0:
				velocity.x = 0.0
			anim(&"move" if absf(velocity.x) > 10.0 else &"idle")
			if state == &"idle":
				set_state(&"move")
			if _cd <= 0.0 and dist < _p("far") + 60.0 and SpellEffect.has_los(_hand(), p.center(), self):
				set_state(&"windup")
				_aim = p.center()
				Sfx.play("hex_gather", -2.0)
		&"windup":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			anim(&"windup")
			if alive_p and state_t < _p("windup") * 0.6:
				face_toward(p.global_position.x)
				_aim = p.center()
			if randf() < delta * 40.0:
				FX.converge(_hand(), 12.0, 1, Pal.school(&"hex"), 0.2, {"swirl": 1.5})
			if state_t >= _p("windup"):
				_fire()
				set_state(&"cast")
		&"cast":
			anim(&"cast")
			if state_t >= 0.2:
				set_state(&"recover")
		&"recover":
			anim(&"recover")
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_t >= _p("recover"):
				_cd = _p("rest")
				set_state(&"move")
		&"flinch":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			anim(&"hurt")
			if state_t > 0.4:
				_cd = maxf(_cd, 0.6)
				set_state(&"move")


func _fire() -> void:
	var from := _hand()
	var p := Projectile.new()
	p.team = &"enemy"
	p.style = &"spectral"
	p.ramp = Pal.school(&"hex")
	p.velocity = (_aim - from).normalized() * _p("bolt_speed")
	p.max_dist = 380.0
	p.radius = 4.0
	get_parent().add_child(p)
	p.global_position = from
	var dmg := data.damage
	p.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void:
		var d := Damage.make(dmg, self, &"hex", Vector2(signf(p.velocity.x) * 140.0, -110.0))
		d.hit_pos = pos
		a.take_hit(d)
		FX.burst(pos, 10, Pal.school(&"hex"), Vector2(40, 110), Vector2(0.15, 0.35)))
	p.hit_wall.connect(func(pos: Vector2) -> void: FX.burst(pos, 8, Pal.school(&"hex"), Vector2(20, 70), Vector2(0.15, 0.3)))
	FX.flash(from, 5.0, 0.08, Color(0.85, 0.6, 1.0, 0.9))
	Sfx.play("hex_release", -3.0)


func _draw_tele() -> void:
	if state != &"windup" or not is_alive():
		return
	var from := _hand()
	var locked := state_t >= _p("windup") * 0.6
	var col := Color("ff7ad8") if locked else Color("c88cff", 0.7)
	var d := (_aim - from)
	var n := int(d.length() / 8.0)
	for k in range(1, n):
		if (k + int(state_t * 20.0)) % 2 == 0 or locked:
			var q := (from + d.normalized() * k * 8.0).round()
			tele.draw_rect(Rect2(q, Vector2(2, 2) if locked else Vector2(1, 1)), col)
