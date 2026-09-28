class_name Knot
extends Enemy
## Briar Knot — root creature. It marks a strip of ground under the wizard
## (cracks and rising dust), then thorned roots erupt there and linger as a
## thorn patch, so standing still is dangerous. After each eruption its heart
## lies open (extra damage). If the wizard strays it burrows (untouchable)
## and resurfaces nearer.

var _cd := 1.0
var _casts := 0
var _mark := Vector2.ZERO


func _setup() -> void:
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func block_scale(d: Damage) -> float:
	if state in [&"burrow", &"under"]:
		return 0.0
	return 1.5 if state == &"exposed" else 1.0


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	velocity.x = 0.0
	match state:
		&"idle":
			anim(&"idle")
			if not alive_p:
				return
			var dist := global_position.distance_to(p.global_position)
			if dist > data.aggro_range:
				return
			face_toward(p.global_position.x)
			if (dist > _p("reach") or _casts >= 2) and _cd <= 0.0:
				_casts = 0
				set_state(&"burrow")
				Sfx.play("roots", -6.0)
			elif _cd <= 0.0:
				_mark = SpellEffect.ground_below(p.global_position + Vector2(0, -8), self, 200.0)
				set_state(&"attack")
				FX.tele_mark(_mark, _p("width"), _p("windup"), Color("ffb040"))
				Sfx.play("knot_creak", -3.0)
		&"attack":
			anim(&"attack")
			if randf() < delta * 30.0:
				FX.burst(_mark + Vector2(randf_range(-_p("width") * 0.5, _p("width") * 0.5), 0), 1, Pal.DUST, Vector2(10, 40),
					Vector2(0.2, 0.4), {"dir": Vector2.UP, "spread": 0.6, "gravity": 120.0, "add": false})
			if state_t >= _p("windup"):
				var tp := ThornPatch.new()
				tp.width = _p("width")
				tp.damage = data.damage
				tp.source = self
				get_parent().add_child(tp)
				tp.global_position = _mark
				_casts += 1
				set_state(&"exposed")
		&"exposed":
			anim(&"exposed")
			if state_t >= _p("exposed"):
				_cd = _p("rest")
				set_state(&"idle")
		&"burrow":
			anim(&"burrow")
			if state_t >= 0.4:
				set_state(&"under")
				remove_from_group(&"enemy")
				visual.visible = false
				collision_layer = 0
				FX.burst(global_position, 12, Pal.DUST, Vector2(20, 60), Vector2(0.3, 0.5), {"dir": Vector2.UP, "spread": 2.0, "gravity": 150.0, "add": false})
		&"under":
			if state_t >= 0.8 and alive_p:
				var target := p.global_position + Vector2(-p.facing * 110.0, 0)
				var ground := SpellEffect.ground_below(target + Vector2(0, -60), self, 200.0)
				global_position = ground
				visual.visible = true
				collision_layer = 4
				add_to_group(&"enemy")
				face_toward(p.global_position.x)
				set_state(&"emerge")
				FX.burst(global_position, 14, Pal.DUST, Vector2(20, 80), Vector2(0.3, 0.5), {"dir": Vector2.UP, "spread": 1.6, "gravity": 150.0, "add": false})
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


class ThornPatch extends Node2D:
	## Roots burst up (knock-up hit), then linger as thorns that hurt anyone
	## standing in them. Lingering damage is a hazard, not an attack, so it
	## never grants perfect-dodge mana.
	var width := 48.0
	var damage := 14.0
	var source: Node2D
	var t := 0.0
	var tick := 0.5
	const LIFE := 2.6

	func _ready() -> void:
		z_index = 3
		Sfx.play("roots", -1.0)
		GameCamera.shake_all(2.0)
		for k in 10:
			FX.burst(global_position + Vector2(randf_range(-width * 0.5, width * 0.5), 0), 2, Pal.DUST, Vector2(30, 90), Vector2(0.3, 0.5),
				{"dir": Vector2.UP, "spread": 0.8, "gravity": 200.0, "add": false})
		_hurt(damage, true)

	func _hurt(amount: float, eruption: bool) -> void:
		var p := get_tree().get_first_node_in_group(&"player") as Player
		if p == null or not p.is_alive():
			return
		if absf(p.global_position.x - global_position.x) < width * 0.5 + 4.0 and absf(p.global_position.y - global_position.y) < 26.0:
			var d := Damage.make(amount, source, &"", Vector2(0, -260.0 if eruption else -60.0))
			d.hit_pos = global_position
			d.active_attack = eruption
			p.take_hit(d)

	func _physics_process(delta: float) -> void:
		t += delta
		tick -= delta
		if tick <= 0.0:
			tick = 0.5
			_hurt(5.0, false)
		if t >= LIFE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var grow := clampf(t / 0.1, 0.0, 1.0)
		var fade := clampf((LIFE - t) / 0.4, 0.0, 1.0)
		var bark := Color("6a4a32", fade)
		var tip := Color("c8b890", fade)
		var n := int(width / 7.0)
		for k in n:
			var x := -width * 0.5 + (k + 0.5) * width / n
			var h := (10.0 + (k * 5 % 4) * 4.0) * grow
			var lean := (1.0 if k % 2 else -1.0) * 2.0
			draw_line(Vector2(x, 0), Vector2(x + lean, -h), bark, 2.0)
			draw_rect(Rect2(Vector2(x + lean, -h - 1).round(), Vector2(1, 2)), tip)
			draw_rect(Rect2(Vector2(x + lean * 0.5 + 1, -h * 0.5).round(), Vector2(1, 1)), tip)
