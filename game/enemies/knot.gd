class_name Knot
extends Enemy
## Briar Knot — root creature. It marks a circle of ground under the wizard
## (a pulsing ring and rising dust), then thorned roots erupt there and linger
## as a thorn patch, so standing still is dangerous. After each eruption its
## heart lies open (extra damage). If the wizard strays it burrows
## (untouchable) and resurfaces nearer.

var _cd := 1.0
var _casts := 0
var _mark := Vector3.ZERO


func _setup() -> void:
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func block_scale(_d: Damage) -> float:
	if state in [&"burrow", &"under"]:
		return 0.0
	return 1.5 if state == &"exposed" else 1.0


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	steer(Vector3.ZERO, 60.0, delta)
	var r := _p("width") * 0.5
	match state:
		&"idle":
			anim(&"idle")
			if not alive_p:
				return
			var dist := dist_to(p.global_position)
			if dist > data.aggro_range:
				return
			face_toward(p.global_position)
			if (dist > _p("reach") or _casts >= 2) and _cd <= 0.0:
				_casts = 0
				set_state(&"burrow")
				Sfx.play("roots", -6.0)
			elif _cd <= 0.0:
				_mark = SpellEffect.ground_at(p.global_position, self)
				set_state(&"attack")
				FX3.tele_ring(_mark, r, _p("windup"), Color(1.0, 0.69, 0.25, 0.9))
				Sfx.play("knot_creak", -3.0)
		&"attack":
			anim(&"attack")
			if randf() < delta * 30.0:
				var a := randf() * TAU
				FX3.burst(_mark + Vector3(cos(a), 0.05, sin(a)) * randf() * r, 1, Pal.DUST, Vector2(0.4, 1.6),
					Vector2(0.2, 0.4), {"dir": Vector3.UP, "spread": 0.6, "gravity": 5.0})
			if state_t >= _p("windup"):
				var tp := ThornPatch.new()
				tp.radius = r
				tp.damage = data.damage
				tp.source = self
				get_parent().add_child(tp)
				tp.global_position = _mark
				_casts += 1
				set_state(&"exposed")
		&"exposed":
			anim(&"exposed")
			if randf() < delta * 10.0:
				FX3.burst(center(), 1, Pal.DANGER, Vector2(0.2, 0.6), Vector2(0.3, 0.5), {"gravity": -0.6})
			if state_t >= _p("exposed"):
				_cd = _p("rest")
				set_state(&"idle")
		&"burrow":
			anim(&"burrow")
			if state_t >= 0.4:
				set_state(&"under")
				remove_from_group(&"enemy")
				sprite.visible = false
				collision_layer = 0
				FX3.burst(global_position, 12, Pal.DUST, Vector2(0.8, 2.5), Vector2(0.3, 0.5), {"dir": Vector3.UP, "spread": 2.0, "gravity": 6.0})
		&"under":
			if state_t >= 0.8 and alive_p:
				var back := -p.look_dir.rotated(Vector3.UP, randf_range(-0.8, 0.8))
				var target := p.global_position + back * 4.5
				global_position = SpellEffect.ground_at(target, self)
				sprite.visible = true
				collision_layer = 4
				add_to_group(&"enemy")
				face_toward(p.global_position)
				set_state(&"emerge")
				FX3.burst(global_position, 14, Pal.DUST, Vector2(0.8, 3.3), Vector2(0.3, 0.5), {"dir": Vector3.UP, "spread": 1.6, "gravity": 6.0})
				FX3.ring(global_position + Vector3(0, 0.05, 0), 0.2, 1.2, 0.3, Pal.DUST, 2.0)
				Sfx.play("roots", -3.0)
		&"emerge":
			anim(&"emerge")
			if state_t >= 0.4:
				_cd = 0.6
				set_state(&"idle")
		&"flinch":
			anim(&"hurt")
			if state_t > 0.3:
				set_state(&"idle")


class ThornPatch extends Node3D:
	## Roots burst up (knock-up hit), then linger as thorns that hurt anyone
	## standing in them. Lingering damage is a hazard, not an attack, so it
	## never grants perfect-dodge mana.
	const LIFE := 2.6
	const THORN := preload("res://assets/generated/w3d/thorns.png")
	var radius := 1.0
	var damage := 14.0
	var source: Node3D
	var t := 0.0
	var tick := 0.5
	var _thorns: Array[PixelBillboard] = []

	func _ready() -> void:
		Sfx.play("roots", -1.0)
		GameCamera3D.shake_all(2.0)
		var n := int(radius * 7.0)
		for k in n:
			var a := TAU * k / n + randf_range(-0.2, 0.2)
			var rr := sqrt(randf()) * radius * 0.9
			var b := PixelBillboard.still(THORN)
			b.set_flip(randf() < 0.5)
			add_child(b)
			b.position = Vector3(cos(a) * rr, -0.6, sin(a) * rr)
			_thorns.append(b)
			FX3.burst(global_position + b.position + Vector3(0, 0.6, 0), 2, Pal.DUST, Vector2(1.2, 3.7), Vector2(0.3, 0.5),
				{"dir": Vector3.UP, "spread": 0.8, "gravity": 8.0})
		FX3.ring(global_position + Vector3(0, 0.05, 0), radius * 0.3, radius * 1.1, 0.3, Pal.DUST, 2.0)
		_hurt(damage, true)

	func _hurt(amount: float, eruption: bool) -> void:
		var targets: Array = get_tree().get_nodes_in_group(&"player") + get_tree().get_nodes_in_group(&"companion")
		for p: Node3D in targets:
			if not p.is_alive():
				continue
			if SpellEffect.flat(p.global_position, global_position) < radius + p.radius() and absf(p.global_position.y - global_position.y) < 1.2:
				var d := Damage.make(amount, source, &"", Vector3(0, 7.0 if eruption else 2.0, 0))
				d.hit_pos = global_position
				d.active_attack = eruption
				p.take_hit(d)

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		if tick <= 0.0:
			tick = 0.5
			_hurt(5.0, false)
		var grow := clampf(t / 0.1, 0.0, 1.0)
		var sink := clampf((LIFE - t) / 0.4, 0.0, 1.0)
		for b in _thorns:
			b.position.y = lerpf(-0.6, 0.0, grow * sink)
		if t >= LIFE:
			queue_free()
