class_name Shieldbearer
extends Companion
## Tamsin, the shieldbearer. Spears enemies she can see near the wizard for
## modest damage, and now and then raises her shield by the wizard (a short
## guard that softens incoming blows).

const ATTACK_DMG := 6.0
const GUARD_CD := 12.0

var _atk_cd := 0.0
var _guard_cd := 4.0


func _init() -> void:
	id = &"tamsin"
	display = "Tamsin"
	sheet = "tamsin"
	max_hp = 90.0
	speed = 5.4


func _act(p: Player, delta: float) -> void:
	_atk_cd -= delta
	_guard_cd -= delta
	_target = _pick_target(p)
	if _target:
		move_to(_target.global_position - SpellEffect.flat_dir(_target.global_position - global_position) * (_target.radius() + 0.9), delta)
	else:
		move_to(follow_spot(p), delta)
	# protective action: a shield wall beside the wizard
	if _guard_cd <= 0.0 and p.is_alive() and (p.health.ratio() < 0.5 or _enemy_winding_up(p)):
		_guard_cd = GUARD_CD
		p.guard_mult = minf(p.guard_mult, 0.6)
		p.guard_t = maxf(p.guard_t, 2.5)
		sprite.play(&"guard", true)
		Sfx.play("block", -2.0)
		FX3.ring(p.global_position + Vector3(0, 0.05, 0), 0.3, 1.4, 0.4, [Color("fff4c8"), Color("f0d890"), Color("a08850")], 2.0)
		FX3.burst(center(), 10, [Color("fff4c8"), Color("f0d890")], Vector2(1.0, 2.5), Vector2(0.3, 0.5), {"gravity": -1.0})
	if _target and SpellEffect.flat(_target.global_position, global_position) < _target.radius() + 1.3 and _atk_cd <= 0.0:
		_atk_cd = 1.1
		face_toward(_target.global_position)
		sprite.play(&"attack", true)
		var dmg := Damage.make(ATTACK_DMG, self, &"", SpellEffect.flat_dir(_target.global_position - global_position) * 2.5)
		dmg.hit_pos = center()
		dmg.stagger = 6.0
		_target.take_hit(dmg)
		Sfx.play("slash", -8.0)
		return
	walk_anim()


## An enemy she can see, close to the wizard.
func _pick_target(p: Player) -> Node3D:
	var best: Node3D = null
	var bd := 7.0
	for e: Node3D in SpellEffect.enemies():
		if e is Bramble or SpellEffect.flat(e.global_position, p.global_position) > 6.5:
			continue
		var dist := SpellEffect.flat(e.global_position, global_position)
		if dist < bd and SpellEffect.has_los(center(), e.center(), self):
			bd = dist
			best = e
	return best


func _enemy_winding_up(p: Player) -> bool:
	for e in SpellEffect.enemies():
		if e is Enemy and String(e.state).ends_with("windup") and SpellEffect.flat(e.global_position, p.global_position) < 4.0:
			return true
	return false
