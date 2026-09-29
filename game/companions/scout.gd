class_name Scout
extends Companion
## Kess, the scout. Shoots at the wizard's target (or the nearest enemy she
## can see within 10 m) from a step behind. Every MARK_EVERY seconds the shot
## is a gold marking arrow: the marked enemy takes +25% from the wizard's
## next spell hit (Statuses.MARK_MULT). Each shot has a short draw first, the
## tell. When an enemy gets close she hops back out of reach.

const RANGE := 10.0
const SHOT_DMG := 5.0
const SHOT_CD := 1.3
const DRAW_TIME := 0.3
const MARK_EVERY := 6.0
const MARK_TIME := 8.0
const HOP_NEAR := 2.5
const HOP_DIST := 2.5
const HOP_TIME := 0.25
const HOP_CD := 1.5
const REED := [Color("d8f0b0"), Color("8ab860"), Color("4a6a3a")]
const GOLD := [Color("fff0c0"), Color("f0c870"), Color("a07840")]

var _shot_cd := 1.0
var _mark_cd := 2.0
var _draw_t := -1.0          # >= 0 while drawing the bow
var _hop_cd := 0.0
var _hop_t := 0.0
var _hop_v := Vector3.ZERO


func _init() -> void:
	id = &"kess"
	display = "Kess"
	sheet = "kess"
	max_hp = 70.0
	speed = 5.8


func greeting() -> String:
	return "Eyes open, {name}. I've got your back."


## Kess travels as a guest until Reedhollow; after that she can wait at camp.
func can_rest() -> bool:
	return GameState.flag(&"kess_joined")


func rest_refusal() -> String:
	return "Not before Reedhollow, {name}. I'm not leaving you on the marsh road."


func _act(p: Player, delta: float) -> void:
	_shot_cd -= delta
	_mark_cd -= delta
	_hop_cd -= delta
	if _hop_t > 0.0:
		_hop_t -= delta
		velocity.x = _hop_v.x
		velocity.z = _hop_v.z
		return
	_target = _pick_target(p)
	var close := _closest_threat()
	if close and _hop_cd <= 0.0:
		_hop(close)
		return
	move_to(follow_spot(p), delta)
	if _target == null:
		_draw_t = -1.0
		walk_anim()
		return
	face_toward(_target.global_position)
	if _draw_t >= 0.0:
		_draw_t += delta
		if _draw_t >= DRAW_TIME:
			_draw_t = -1.0
			if is_instance_valid(_target):
				_loose(_target)
		return
	if _shot_cd <= 0.0:
		_draw_t = 0.0
		sprite.play(&"draw", true)
		return
	walk_anim()


## The wizard's target if Kess can reach and see it, else the nearest she can.
func _pick_target(p: Player) -> Node3D:
	# the aim can still hold an enemy freed by a region change: check before typing it
	var t: Object = p.aim.target if p.aim else null
	if is_instance_valid(t) and _can_shoot(t as Node3D):
		return t as Node3D
	var best: Node3D = null
	var bd := RANGE
	for e: Node3D in SpellEffect.enemies():
		var dist := SpellEffect.flat(e.global_position, global_position)
		if dist < bd and not (e is Bramble) and SpellEffect.has_los(center(), e.center(), self):
			bd = dist
			best = e
	return best


func _can_shoot(e: Node3D) -> bool:
	return e != null and e.is_alive() and not (e is Bramble) \
		and SpellEffect.flat(e.global_position, global_position) < RANGE and SpellEffect.has_los(center(), e.center(), self)


func _closest_threat() -> Node3D:
	for e: Node3D in SpellEffect.enemies():
		if not (e is Bramble) and SpellEffect.flat(e.global_position, global_position) < HOP_NEAR + e.radius():
			return e
	return null


func _hop(from: Node3D) -> void:
	_hop_cd = HOP_CD
	_hop_t = HOP_TIME
	_draw_t = -1.0
	_hop_v = SpellEffect.flat_dir(global_position - from.global_position) * (HOP_DIST / HOP_TIME)
	face_toward(from.global_position)
	sprite.play(&"hop", true)
	FX3.burst(global_position + Vector3(0, 0.1, 0), 6, Pal.DUST, Vector2(0.5, 1.5), Vector2(0.2, 0.35))


func _loose(t: Node3D) -> void:
	if not _can_shoot(t):
		return
	_shot_cd = SHOT_CD
	var marking := _mark_cd <= 0.0
	if marking:
		_mark_cd = MARK_EVERY
	sprite.play(&"shoot", true)
	Sfx.play("slash", -12.0, 0.4)
	var from := center() + Vector3(0.3 * facing, 0.1, 0)
	var dir := SpellEffect.flat_dir(t.center() - from)
	var pr := Projectile.new()
	pr.team = &"player"
	pr.style = &"arrow"
	pr.ramp = GOLD if marking else REED
	pr.lit = marking
	pr.velocity = dir * 16.0
	pr.max_dist = RANGE + 2.0
	pr.radius = 0.2
	get_parent().add_child(pr)
	pr.global_position = from
	pr.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
		var d := Damage.make(SHOT_DMG, self, &"", dir * 1.5)
		d.hit_pos = pos
		d.stagger = 3.0
		a.take_hit(d)
		if marking and a.is_alive():
			a.statuses.apply(&"mark", MARK_TIME)
			Sfx.play("ui_select", -6.0)
		FX3.burst(pos, 5 if marking else 3, pr.ramp, Vector2(0.6, 2.0), Vector2(0.15, 0.3)))
