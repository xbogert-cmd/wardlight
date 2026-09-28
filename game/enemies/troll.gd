class_name Troll
extends Enemy
## Gatebreaker — a troll wearing planks of the broken gate, swinging its
## crossbeam. Three attacks, each with long anticipation and a recovery to
## punish: a wide heavy sweep, an overhead ground slam (the beam sticks in the
## ground), and thrown rubble (chunks of gate-stone) at range. Below half
## health it throws three chunks at once. Never flinches; bosses shrug off
## most knockback.

var box: MeleeBox
var _cd := 1.4
var _next := 0
var _target := Vector3.ZERO
var engaged := false


func _setup() -> void:
	is_boss = true
	box = MeleeBox.make(self, 3.2, 95.0)
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func _flinch() -> void:
	pass


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle", &"walk":
			if not alive_p or (not engaged and dist_to(p.global_position) > data.aggro_range):
				steer(Vector3.ZERO, 10.0, delta)
				anim(&"idle")
				return
			if not engaged:
				engaged = true
				Sfx.play("sentinel_windup", 2.0)
				GameCamera3D.shake_all(3.0)
			face_toward(p.global_position)
			var gap := dist_to(p.global_position)
			if gap > 2.6:
				steer(heading * data.move_speed, 8.0, delta)
				anim(&"walk")
			else:
				steer(Vector3.ZERO, 14.0, delta)
				anim(&"idle")
			if _cd <= 0.0:
				_choose(p, gap)
		&"sweep_windup":
			steer(Vector3.ZERO, 14.0, delta)
			anim(&"sweep_windup")
			if state_t >= _p("sweep_windup"):
				set_state(&"sweep")
				box.swing(data.damage, 11.0, 4.0)
				FX3.arc(global_position + Vector3(0, 0.6, 0), 0.8, 3.3, heading, deg_to_rad(190.0), 0.2, [Color("ffffff"), Color("d8c8a8"), Color("8a7a60")], 3.0)
				FX3.burst(global_position + heading * 2.0 + Vector3(0, 0.3, 0), 16, Pal.DUST, Vector2(2.0, 6.0), Vector2(0.3, 0.5), {"dir": heading, "spread": 2.0, "gravity": 6.0})
				Sfx.play("slash", 2.0)
				GameCamera3D.shake_all(2.5)
		&"slam_windup":
			steer(Vector3.ZERO, 14.0, delta)
			anim(&"slam_windup")
			if state_t >= _p("slam_windup"):
				set_state(&"slam")
				_slam(p)
		&"throw_windup":
			steer(Vector3.ZERO, 14.0, delta)
			anim(&"throw_windup")
			if alive_p and state_t < _p("throw_windup") * 0.5:
				face_toward(p.global_position)
			if state_t >= _p("throw_windup"):
				set_state(&"throw")
				_throw(p)
		&"sweep", &"slam", &"throw":
			anim(state)
			if state_t >= 0.18:
				box.stop()
				set_state(&"recover")
		&"recover":
			anim(&"recover")
			steer(Vector3.ZERO, 14.0, delta)
			if state_t >= (1.3 if _next == 1 else 0.8):
				_cd = _p("rest")
				set_state(&"walk")


func _choose(p: Player, gap: float) -> void:
	face_toward(p.global_position)
	if gap > 5.0:
		_next = 2
	else:
		_next = 0 if _next != 0 else 1
	match _next:
		0:
			set_state(&"sweep_windup")
			FX3.arc(global_position + Vector3(0, 0.05, 0), 3.3, 3.3, heading, deg_to_rad(190.0), _p("sweep_windup"), [Color(1.0, 0.6, 0.3, 0.9)], 3.0)
			Sfx.play("raider_grunt", 2.0)
		1:
			set_state(&"slam_windup")
			_target = global_position + heading * 2.2
			FX3.tele_ring(_target, 1.9, _p("slam_windup"), Color(1.0, 0.35, 0.23, 0.9))
			Sfx.play("sentinel_windup", 0.0)
		2:
			set_state(&"throw_windup")
			Sfx.play("raider_grunt", 0.0)


func _slam(p: Player) -> void:
	GameCamera3D.shake_all(6.0)
	TimeCtl.hitstop(0.06)
	Sfx.play("sentinel_slam", 3.0)
	var g := SpellEffect.ground_at(_target, self)
	FX3.burst(g + Vector3(0, 0.1, 0), 30, Pal.DUST, Vector2(2.0, 7.0), Vector2(0.3, 0.7), {"dir": Vector3.UP, "spread": 2.6, "gravity": 10.0})
	FX3.ring(g + Vector3(0, 0.06, 0), 0.3, 2.6, 0.35, [Color("ffffff"), Color("c8b8a0"), Color("8a7a60")], 3.0)
	for k in 6:
		var a := k * TAU / 6.0
		FX3.burst(g + Vector3(cos(a), 0.2, sin(a)) * 1.2, 3, [Color("9a9490"), Color("7a7470"), Color("5a5450")], Vector2(2.0, 4.0), Vector2(0.5, 0.8), {"dir": Vector3(cos(a), 1.5, sin(a)), "spread": 0.5, "gravity": 14.0, "size": 2.0})
	if p and p.is_alive() and SpellEffect.flat(p.global_position, g) < 1.9 + p.radius():
		var d := Damage.make(_p("slam_damage"), self, &"", SpellEffect.push(g, p.global_position, 9.0, 6.0))
		d.hit_pos = g
		p.take_hit(d)


func _throw(p: Player) -> void:
	if p == null:
		return
	var n := 3 if health.hp < data.max_hp * 0.5 else 1
	for k in n:
		var spot := p.global_position + (Vector3.ZERO if k == 0 else Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)))
		spot = SpellEffect.ground_at(spot, self)
		var rock := Rubble.new()
		rock.from = global_position + Vector3(0, 3.0, 0)
		rock.to = spot
		rock.damage = _p("throw_damage")
		rock.source = self
		get_parent().add_child(rock)
	Sfx.play("dodge", 2.0)


class Rubble extends Node3D:
	## A chunk of gate-stone thrown in an arc. Its landing spot is marked from
	## the moment it leaves the troll's hand.
	const FLIGHT := 0.95
	const R := 1.3
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var damage := 16.0
	var source: Node3D
	var t := 0.0
	var _rock: PixelBillboard
	var _mark: MeshInstance3D

	func _ready() -> void:
		var img := Image.create_empty(12, 10, false, Image.FORMAT_RGBA8)
		for y in 10:
			for x in 12:
				var d := Vector2((x - 5.5) / 6.0, (y - 4.5) / 5.0).length()
				if d < 1.0:
					img.set_pixel(x, y, Color("8a8480") if d < 0.6 and x < 7 else Color("5a5450"))
		_rock = PixelBillboard.still(ImageTexture.create_from_image(img), Vector2(6, 5))
		add_child(_rock)
		_mark = FX3.tele_ring(to, R, FLIGHT + 0.05, Color(1.0, 0.6, 0.3, 0.9))
		global_position = from

	func _physics_process(delta: float) -> void:
		t += delta
		var k := clampf(t / FLIGHT, 0.0, 1.0)
		global_position = from.lerp(to, k) + Vector3(0, sin(k * PI) * 3.5, 0)
		if randf() < 0.5:
			FX3.burst(global_position, 1, Pal.DUST, Vector2(0.1, 0.4), Vector2(0.3, 0.5), {"gravity": 3.0})
		if k >= 1.0:
			FX3.burst(to + Vector3(0, 0.2, 0), 18, [Color("9a9490"), Color("7a7470"), Color("5a5450")], Vector2(2.0, 5.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 2.4, "gravity": 12.0, "size": 2.0})
			FX3.ring(to + Vector3(0, 0.06, 0), 0.2, R, 0.25, Pal.DUST, 2.0)
			GameCamera3D.shake_all(2.5)
			Sfx.play("hound_land", 0.0)
			var p := get_tree().get_first_node_in_group(&"player") as Player
			if p and p.is_alive() and SpellEffect.flat(p.global_position, to) < R + p.radius():
				var d := Damage.make(damage, source, &"", SpellEffect.push(to, p.global_position, 6.0, 4.0))
				d.hit_pos = to
				p.take_hit(d)
			queue_free()
