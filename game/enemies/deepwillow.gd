class_name Deepwillow
extends Enemy
## The Deepwillow — the ancient root-being under the lake, hollowed by the
## Herald. Chapter 2's final boss: rooted in place at the north of the Heart
## Isle's clearing, it is to be cleansed, not killed. Three layers:
##   1 hollow bark  — four glowing knots open one at a time; only the open
##                    knot can be hurt. Root lines and arc sweeps meanwhile.
##   2 the flood    — the bark is broken open: the tree itself takes damage.
##                    Water surges sweep the clearing's edges (a pair of rings
##                    marks the band; levitate over it or stay near the
##                    trunk) between root slams in lines.
##   3 hollow core  — at half health the corruption bursts out of the trunk
##                    and every pattern comes faster.
## At no health it is spent (it never dies): `spent` fires, and the region
## offers the cleansing channel that ends the fight.

signal layer_changed(n: int)
signal spent

const KNOT_DATA := preload("res://data/enemies/deep_knot.tres")
## Knot spots on the trunk, relative to the tree's feet (metres).
const KNOT_AT := [Vector3(-1.1, 0.6, 0.7), Vector3(1.2, 1.0, 0.7), Vector3(-0.65, 1.9, 0.8), Vector3(0.8, 2.5, 0.8)]
## Drawn at 80% so its crown stays on screen while fighting at its feet.
const SCALE := 0.8
const HOLLOW := [Color("ffffff"), Color("d8b8ff"), Color("8a5ac8"), Color("3a2458")]
const WATER := [Color("ffffff"), Color("c8f0ff"), Color("5ab8e0"), Color("2a5a8a")]

var engaged := false
var layer := 1
var arena_center := Vector3.ZERO   # set by the region (the surge band is measured from here)
var knots: Array[Enemy] = []
var _open := -1
var _cd := 2.0
var _order := 0
var _is_spent := false


func _setup() -> void:
	is_boss = true
	sprite.scale = Vector3.ONE * SCALE
	set_state(&"idle")
	for k in KNOT_AT.size():
		var n := BarkKnot.new()
		n.data = KNOT_DATA
		n.tree = self
		get_parent().add_child.call_deferred(n)
		n.set_deferred("global_position", global_position + KNOT_AT[k])
		knots.append(n)


func _p(k: String) -> float:
	var v: float = data.params.get(k, 0.0)
	return v * (0.7 if layer == 3 and k.ends_with("windup") else 1.0)


func _flinch() -> void:
	pass


## Bark shrugs everything off in layer 1; it never drops below 1 health.
func block_scale(d: Damage) -> float:
	if layer == 1 or _is_spent or state == &"burst":
		return 0.0
	var raw := d.amount * (Statuses.CURSE_MULT if statuses.has(&"curse") else 1.0)
	var room := health.hp - 1.0
	return clampf(room / raw, 0.0, 1.0) if raw > 0.0 else 1.0


func take_hit(d: Damage) -> void:
	super.take_hit(d)
	if layer == 2 and health.ratio() <= 0.5:
		_to_layer(3)
	if not _is_spent and health.hp <= 1.5 and layer >= 2:
		_is_spent = true
		set_state(&"spent")
		anim(&"spent")
		engaged = false
		for c in get_parent().get_children():
			if c is Enemy and c != self and (c as Enemy).is_alive():
				c.queue_free()
		spent.emit()


func _rewards() -> void:
	pass


func _to_layer(n: int) -> void:
	layer = n
	set_state(&"burst")
	sprite.play(&"core" if n == 3 else &"hurt", true)
	FX3.ring(global_position + Vector3(0, 0.06, 0), 0.5, 8.0, 0.7, HOLLOW if n == 3 else WATER, 3.0)
	FX3.burst(center() + Vector3(0, 1.0, 0), 50, HOLLOW, Vector2(2.0, 7.0), Vector2(0.4, 0.9), {"gravity": 3.0})
	GameCamera3D.shake_all(5.0)
	Sfx.play("sentinel_windup", 3.0)
	layer_changed.emit(n)


## A knot was broken: open the next one, or crack the bark (layer 2).
func knot_broken() -> void:
	_open_next()
	if _open == -1 and layer == 1:
		_to_layer(2)


func _open_next() -> void:
	_open = -1
	for k in knots.size():
		if is_instance_valid(knots[k]) and knots[k].is_alive():
			_open = k
			(knots[k] as BarkKnot).set_open(true)
			return


func _ai(delta: float) -> void:
	var p := player()
	velocity.x = 0.0
	velocity.z = 0.0
	if _is_spent:
		anim(&"spent")
		return
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			anim(&"idle2" if layer == 3 else &"idle")
			if not alive_p:
				return
			if not engaged:
				if dist_to(p.global_position) < data.aggro_range:
					engaged = true
					_open_next()
					Sfx.play("roots", 2.0)
					GameCamera3D.shake_all(3.0)
				return
			if _cd <= 0.0:
				_choose(p)
		&"attack":
			anim(&"attack")
			if state_t >= 0.5:
				_cd = _p("rest")
				set_state(&"idle")
		&"burst":
			if state_t >= 1.6:
				_cd = 1.2
				set_state(&"idle")


func _choose(p: Player) -> void:
	_order += 1
	set_state(&"attack")
	var pick := _order % 3
	if layer >= 2 and pick == 2:
		_surge()
	elif pick == 1 and layer != 2:
		_sweep(p)
	else:
		_lines(p, 1 if layer == 1 else (2 if layer == 2 else 3))


## Root lines: thorns burst along lines from the trunk toward the wizard.
func _lines(p: Player, n: int) -> void:
	var from := global_position + Vector3(0, 0, 1.2)
	var aim := SpellEffect.flat_dir(p.global_position - from, Vector3.BACK)
	var w := _p("line_windup")
	for k in n:
		var dir := aim.rotated(Vector3.UP, (k - (n - 1) * 0.5) * 0.45)
		var to := from + dir * 13.0
		FX3.tele_line(from, to, w, Color(1.0, 0.45, 0.85, 0.95), 3.0, false)
		SpellEffect.later(w, func() -> void: _line_hit(from, to))
	Sfx.play("knot_creak", 2.0)


func _line_hit(a: Vector3, b: Vector3) -> void:
	if not is_alive() or _is_spent:
		return
	for k in 12:
		var q := a.lerp(b, k / 11.0)
		FX3.burst(SpellEffect.ground_at(q, self) + Vector3(0, 0.2, 0), 4, [Color("c8a8e0"), Color("6a4a8a"), Color("3a2a48")], Vector2(1.0, 4.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 0.8, "gravity": 8.0})
	GameCamera3D.shake_all(2.0)
	Sfx.play("roots", -2.0)
	for t: Node3D in _targets():
		var tp := Vector2(t.global_position.x, t.global_position.z)
		var close := Geometry2D.get_closest_point_to_segment(tp, Vector2(a.x, a.z), Vector2(b.x, b.z))
		if close.distance_to(tp) < 0.8 + t.radius():
			var d := Damage.make(data.damage, self, &"", SpellEffect.flat_dir(t.global_position - global_position) * 5.0 + Vector3(0, 4.0, 0))
			d.hit_pos = t.global_position
			t.take_hit(d)


## Arc sweep: a fan of roots lashes across the front of the trunk.
func _sweep(p: Player) -> void:
	var dir := SpellEffect.flat_dir(p.global_position - global_position, Vector3.BACK)
	var w := _p("sweep_windup")
	FX3.arc(global_position + Vector3(0, 0.05, 0), 7.0, 7.0, dir, deg_to_rad(110.0), w, [Color(1.0, 0.5, 0.8, 0.9)], 3.0)
	Sfx.play("raider_grunt", 2.0)
	SpellEffect.later(w, func() -> void:
		if not is_alive() or _is_spent:
			return
		FX3.arc(global_position + Vector3(0, 0.6, 0), 1.0, 7.0, dir, deg_to_rad(110.0), 0.25, HOLLOW, 3.0)
		Sfx.play("slash", 3.0)
		GameCamera3D.shake_all(3.0)
		for t: Node3D in _targets():
			var v := t.global_position - global_position
			v.y = 0.0
			if v.length() < 7.0 + t.radius() and absf(SpellEffect.flat_dir(v).angle_to(dir)) < deg_to_rad(55.0):
				var d := Damage.make(data.damage, self, &"", SpellEffect.flat_dir(v) * 8.0 + Vector3(0, 3.0, 0))
				d.hit_pos = t.global_position
				t.take_hit(d))


## The flood: water surges over the clearing's southern edge. Two rings mark
## the band; inside the inner ring, or levitating, is safe.
func _surge() -> void:
	var w := _p("surge_windup")
	var c := arena_center
	var inner: float = data.params.get("surge_inner", 5.0)
	var outer: float = data.params.get("surge_outer", 9.5)
	FX3.tele_ring(c, inner, w, Color(0.5, 0.85, 1.0, 0.9))
	FX3.tele_ring(c, outer, w, Color(0.5, 0.85, 1.0, 0.9))
	for k in 18:
		var a := k * TAU / 18.0
		FX3.burst(c + Vector3(cos(a), 0.1, sin(a)) * outer, 3, WATER, Vector2(0.5, 1.5), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 0.6, "gravity": 3.0})
	Sfx.play("storm_hum", 0.0)
	SpellEffect.later(w, func() -> void:
		if not is_alive() or _is_spent:
			return
		for k in 36:
			var a := k * TAU / 36.0
			var r := randf_range(inner, outer)
			FX3.burst(c + Vector3(cos(a) * r, 0.2, sin(a) * r), 6, WATER, Vector2(2.0, 6.0), Vector2(0.4, 0.8), {"dir": Vector3.UP, "spread": 0.9, "gravity": 9.0})
		FX3.ring(c + Vector3(0, 0.1, 0), outer, inner, 0.5, WATER, 4.0)
		Sfx.play("fire_rain", 0.0)
		GameCamera3D.shake_all(3.0)
		for t: Node3D in _targets():
			var dist := SpellEffect.flat(t.global_position, c)
			if dist < inner - t.radius() or dist > outer + t.radius() or t.get("levitating") == true:
				continue
			var d := Damage.make(data.damage * 0.8, self, &"", SpellEffect.flat_dir(c - t.global_position) * 7.0 + Vector3(0, 2.0, 0))
			d.hit_pos = t.global_position
			t.take_hit(d))


func _targets() -> Array:
	var out: Array = get_tree().get_nodes_in_group(&"companion").filter(func(c: Node) -> bool: return c.is_alive())
	var p := player()
	if p and p.is_alive():
		out.append(p)
	return out


## A glowing knot in the Deepwillow's bark: closed (untouchable, dark) until
## the tree opens it, then it can be struck. Breaking it opens the next.
class BarkKnot extends Enemy:
	var tree: Deepwillow
	var opened := false

	func _setup() -> void:
		set_open(false)

	func set_open(on: bool) -> void:
		opened = on
		sprite.play(&"open" if on else &"closed")
		if on:
			add_to_group(&"enemy")
			collision_layer = 4
			FX3.burst(center(), 16, [Color("fff0c0"), Color("f0b060"), Color("8a5a30")], Vector2(1.0, 3.0), Vector2(0.3, 0.6))
			Sfx.play("mote", 0.0)
		else:
			remove_from_group(&"enemy")
			collision_layer = 0

	func block_scale(_d: Damage) -> float:
		return 1.0 if opened else 0.0

	func _ai(_delta: float) -> void:
		velocity = Vector3.ZERO
		if opened and randf() < 0.1:
			FX3.burst(center(), 1, [Color("fff0c0"), Color("f0b060")], Vector2(0.2, 0.8), Vector2(0.3, 0.5), {"gravity": -1.0})

	func _physics_process(delta: float) -> void:
		# fixed to the bark: no gravity, no knockback
		state_t += delta
		if state != &"dead":
			_ai(delta)
		_flash = maxf(0.0, _flash - delta * 9.0)
		sprite.set_flash(_flash)

	func _die() -> void:
		super._die()
		FX3.burst(center(), 30, [Color("ffffff"), Color("fff0c0"), Color("f0b060")], Vector2(2.0, 6.0), Vector2(0.3, 0.7), {"gravity": 4.0})
		GameCamera3D.shake_all(3.0)
		Sfx.play("sentinel_slam", -2.0)
		if is_instance_valid(tree):
			tree.knot_broken()

	func _rewards() -> void:
		pass

	func _flinch() -> void:
		pass
