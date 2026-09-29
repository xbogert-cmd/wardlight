class_name Herald
extends Enemy
## The Herald — the Hollowing's masked gardener, Chapter 2's mid-boss in
## Reedhollow. A mobile duellist-caster:
##   blink          — melts into shadow; a ring marks the pool it will rise
##                    from for BLINK_MARK seconds (the tell), then it steps out
##   sweeping slash — an arc marked on the ground, then the sickle sweeps it
##                    (below half health: two sweeps back to back)
##   hollow seeds   — plants 2 (then 3) seeds near the wizard; each sprouts
##                    into a Husk after 6 s unless it is destroyed first
##   tether         — below half health, binds Tamsin or Kess in place with a
##                    dark cord; hitting the knot in the cord breaks it
## It never dies here: at 30% health it stops, speaks, and flees (`fled`).

signal fled

const FLEE_AT := 0.3
const PHASE2_AT := 0.5
const BLINK_MARK := 0.8
const SEED_DATA := preload("res://data/enemies/hollow_seed.tres")
const KNOT_DATA := preload("res://data/enemies/tether_knot.tres")
const VIOLET := [Color("ffffff"), Color("d8b8ff"), Color("8a5ac8"), Color("3a2458")]

var pools: Array[Vector3] = []   # shadow pools it blinks between (set by the region)
var engaged := false
var fleeing := false
var box: MeleeBox
var _cd := 1.2
var _order := 0
var _sweeps_left := 0
var _to := Vector3.ZERO
var _tether_cd := 3.0
var _hurt_since_blink := 0.0


func _setup() -> void:
	is_boss = true
	box = MeleeBox.make(self, 3.4, 62.0)
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func phase2() -> bool:
	return health.ratio() <= PHASE2_AT


func _flinch() -> void:
	pass


## Untouchable while dissolved or fleeing; never takes the last 30% here.
func block_scale(d: Damage) -> float:
	if fleeing or state in [&"blink_out", &"hidden"]:
		return 0.0
	var raw := d.amount * (Statuses.CURSE_MULT if statuses.has(&"curse") else 1.0)
	var room := health.hp - health.max_hp * FLEE_AT
	return clampf(room / raw, 0.0, 1.0) if raw > 0.0 else 1.0


func take_hit(d: Damage) -> void:
	var before := health.hp
	super.take_hit(d)
	_hurt_since_blink += before - health.hp
	if not fleeing and health.hp <= health.max_hp * FLEE_AT + 0.5:
		_flee()


func _rewards() -> void:
	pass


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	_tether_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			if not alive_p or fleeing:
				steer(Vector3.ZERO, 10.0, delta)
				anim(&"idle")
				return
			if not engaged:
				anim(&"idle")
				if dist_to(p.global_position) < data.aggro_range:
					engaged = true
				return
			face_toward(p.global_position)
			var gap := dist_to(p.global_position)
			if gap > 2.6:
				steer(heading * data.move_speed, 8.0, delta)
				anim(&"walk")
			else:
				steer(Vector3.ZERO, 10.0, delta)
				anim(&"idle")
			if _cd <= 0.0:
				_choose(p, gap)
		&"slash_windup":
			anim(&"slash_windup")
			steer(Vector3.ZERO, 12.0, delta)
			if state_t >= _p("slash_windup") * (0.75 if _sweeps_left == 1 and phase2() else 1.0):
				set_state(&"slash")
				box.swing(data.damage, 9.0, 3.5)
				FX3.arc(global_position + Vector3(0, 0.8, 0), 1.0, 3.5, heading, deg_to_rad(124.0), 0.22, VIOLET, 3.0)
				Sfx.play("slash", 2.0)
				GameCamera3D.shake_all(2.0)
		&"slash":
			anim(&"slash")
			if state_t >= 0.22:
				box.stop()
				_sweeps_left -= 1
				if _sweeps_left > 0 and alive_p:
					face_toward(p.global_position)
					_tele_slash()
					set_state(&"slash_windup")
				else:
					set_state(&"recover")
		&"recover":
			anim(&"recover")
			steer(Vector3.ZERO, 10.0, delta)
			if state_t >= _p("recover"):
				_cd = 0.7 if phase2() else 1.0
				set_state(&"idle")
		&"cast_seeds":
			anim(&"cast")
			steer(Vector3.ZERO, 10.0, delta)
			if state_t >= _p("seed_windup"):
				_plant(p)
				set_state(&"recover")
		&"cast_tether":
			anim(&"cast")
			steer(Vector3.ZERO, 10.0, delta)
			if state_t >= 0.6:
				_tether()
				set_state(&"recover")
		&"blink_out":
			anim(&"blink_out")
			steer(Vector3.ZERO, 20.0, delta)
			if state_t >= 0.4:
				_vanish(true)
				set_state(&"hidden")
		&"hidden":
			if state_t >= BLINK_MARK:
				global_position = _to
				_vanish(false)
				set_state(&"blink_in")
				sprite.play(&"blink_in", true)
				FX3.burst(center(), 16, VIOLET, Vector2(1.0, 3.0), Vector2(0.3, 0.6), {"gravity": -1.0})
				Sfx.play("hex_release", -2.0)
				if alive_p:
					face_toward(p.global_position)
		&"blink_in":
			if state_t >= 0.4:
				_cd = 0.5
				set_state(&"recover")
		&"flee":
			steer(Vector3.ZERO, 20.0, delta)
			anim(&"idle")


func _choose(p: Player, gap: float) -> void:
	_order += 1
	if phase2() and _tether_cd <= 0.0 and _free_companion():
		_tether_cd = 14.0
		set_state(&"cast_tether")
		FX3.converge(center() + Vector3(0, 0.6, 0), 1.0, 14, VIOLET, 0.6, 1.2)
		Sfx.play("hex_gather", 0.0)
		return
	if gap > 7.5 or _hurt_since_blink > health.max_hp * 0.12:
		_blink(p)
		return
	match _order % 4:
		1:
			if _seeds_alive() < 3:
				set_state(&"cast_seeds")
				FX3.converge(center() + Vector3(0, 0.8, 0), 1.2, 16, [Color("e8ffc0"), Color("a8d860"), Color("5a7a3a")], _p("seed_windup"), 1.3)
				Sfx.play("hex_gather", 0.0)
				return
			_slash()
		3:
			_blink(p)
		_:
			if gap < 4.5:
				_slash()
			else:
				_blink(p)


func _slash() -> void:
	_sweeps_left = 2 if phase2() else 1
	_tele_slash()
	set_state(&"slash_windup")
	Sfx.play("raider_grunt", 0.0)


func _tele_slash() -> void:
	FX3.arc(global_position + Vector3(0, 0.05, 0), 3.5, 3.5, heading, deg_to_rad(124.0), _p("slash_windup"), [Color(0.85, 0.55, 1.0, 0.9)], 3.0)


## Dissolve and rise from another shadow pool, near the wizard but not on
## top of them. The destination ring is the tell.
func _blink(p: Player) -> void:
	_hurt_since_blink = 0.0
	var best := global_position
	var best_score := INF
	for q in pools:
		var dp := SpellEffect.flat(q, p.global_position)
		if SpellEffect.flat(q, global_position) < 1.5 or dp < 2.5:
			continue
		var score := absf(dp - 4.0) + randf() * 1.5
		if score < best_score:
			best_score = score
			best = q
	_to = best
	set_state(&"blink_out")
	sprite.play(&"blink_out", true)
	FX3.burst(center(), 16, VIOLET, Vector2(1.0, 3.0), Vector2(0.3, 0.6), {"gravity": -1.0})
	FX3.tele_ring(_to, 1.1, 0.4 + BLINK_MARK, Color(0.8, 0.5, 1.0, 0.95))
	Sfx.play("dodge", -2.0)


func _vanish(on: bool) -> void:
	sprite.visible = not on
	collision_layer = 0 if on else 4
	if on:
		remove_from_group(&"enemy")
	else:
		add_to_group(&"enemy")


func _seeds_alive() -> int:
	var n := 0
	for c in get_parent().get_children():
		if c is Seed and (c as Enemy).is_alive():
			n += 1
	return n


func _plant(p: Player) -> void:
	if p == null:
		return
	var n := 3 if phase2() else 2
	var off := randf() * TAU
	for k in n:
		var a := off + k * TAU / n
		var at := SpellEffect.ground_at(p.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 4.5), self)
		var s := Seed.new()
		s.data = SEED_DATA
		get_parent().add_child(s)
		s.global_position = at
		FX3.burst(at + Vector3(0, 0.3, 0), 10, [Color("e8ffc0"), Color("a8d860"), Color("5a7a3a")], Vector2(1.0, 3.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 1.0, "gravity": 6.0})
	Sfx.play("roots", -2.0)


func _free_companion() -> Node3D:
	for c: Node3D in get_tree().get_nodes_in_group(&"companion"):
		if c.is_alive() and c.get("held_t") != null and float(c.get("held_t")) <= 0.0 and dist_to(c.global_position) < 14.0:
			return c
	return null


func _tether() -> void:
	var c := _free_companion()
	if c == null:
		return
	var k := TetherKnot.new()
	k.data = KNOT_DATA
	k.herald = self
	k.bound = c
	get_parent().add_child(k)
	k.global_position = (global_position + c.global_position) * 0.5
	Sfx.play("hex_release", 0.0)
	var hud := get_tree().get_first_node_in_group(&"hud") as HUD
	if hud and c.get("display") != null:
		hud.toast("%s is bound! Strike the knot in the cord." % c.get("display"))


func _flee() -> void:
	fleeing = true
	armored = true
	box.stop()
	if state in [&"blink_out", &"hidden"]:
		_vanish(false)
	set_state(&"flee")
	sprite.play(&"hurt", true)
	for c in get_parent().get_children():
		if c is TetherKnot or c is Seed:
			(c as Enemy).health.damage(99.0)
			(c as Enemy)._die()
	FX3.ring(global_position + Vector3(0, 0.06, 0), 0.5, 5.0, 0.6, VIOLET, 2.0)
	GameCamera3D.shake_all(3.0)
	fled.emit()


## After the parting words: dissolve for good.
func depart() -> void:
	sprite.play(&"blink_out", true)
	FX3.burst(center(), 30, VIOLET, Vector2(1.0, 4.0), Vector2(0.4, 0.9), {"gravity": -1.5})
	Sfx.play("hex_release", 0.0)
	engaged = false
	await get_tree().create_timer(0.45).timeout
	queue_free()


# ---------------------------------------------------------------- seeds and the tether
## A hollow seed: sprouts into a Husk after SPROUT seconds unless destroyed.
class Seed extends Enemy:
	const SPROUT := 6.0

	func _setup() -> void:
		FX3.tele_ring(global_position, 0.9, SPROUT, Color(0.66, 0.85, 0.35, 0.85))

	func _ai(delta: float) -> void:
		velocity.x = 0.0
		velocity.z = 0.0
		anim(&"idle")
		if randf() < delta * 6.0:
			FX3.burst(center(), 1, [Color("e8ffc0"), Color("a8d860")], Vector2(0.2, 0.8), Vector2(0.3, 0.5), {"gravity": -1.0})
		if state_t >= SPROUT:
			var r := Region.current
			if r:
				var h := r.spawn(&"husk", global_position.x, global_position.z)
				FX3.burst(h.center(), 20, [Color("e8ffc0"), Color("a8d860"), Color("5a7a3a")], Vector2(1.0, 3.5), Vector2(0.3, 0.7), {"gravity": 5.0})
			Sfx.play("knot_creak", 0.0)
			queue_free()

	func _rewards() -> void:
		pass

	func _flinch() -> void:
		pass


## The knot in the Herald's cord: holds a companion in place until it is
## struck (or the cord frays after LIFE seconds). Rides the cord's middle.
class TetherKnot extends Enemy:
	const LIFE := 7.0
	var herald: Node3D
	var bound: Node3D
	var _spark := 0.0

	func _ai(delta: float) -> void:
		if state_t >= LIFE or not is_instance_valid(herald) or not is_instance_valid(bound):
			health.damage(99.0)
			_die()
			return
		anim(&"idle")
		var a: Vector3 = (herald as Enemy).center()
		var b: Vector3 = bound.call("center")
		global_position = (a + b) * 0.5 - Vector3(0, 0.3, 0)
		velocity = Vector3.ZERO
		bound.set("held_t", 0.25)
		_spark -= delta
		if _spark <= 0.0:
			_spark = 0.07
			FX3.bolt(a, b, 0.09, [Color("d8b8ff"), Color("8a5ac8"), Color("3a2458")], 0.12)

	func _die() -> void:
		if is_instance_valid(bound):
			bound.set("held_t", 0.0)
		FX3.burst(center(), 16, [Color("ffffff"), Color("d8b8ff"), Color("8a5ac8")], Vector2(1.0, 4.0), Vector2(0.3, 0.6))
		super._die()

	func _rewards() -> void:
		pass

	func _flinch() -> void:
		pass
