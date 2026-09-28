class_name Shieldbearer
extends CharacterBody3D
## Tamsin, the shieldbearer companion. Follows a step behind the wizard (never
## blocking: she is on her own collision layer), spears enemies she can see
## near the wizard for modest damage, and now and then raises her shield by
## the wizard (a short guard that softens incoming blows). When beaten down
## she kneels until the fight is over, then gets up. If stuck or left far
## behind she slips back to a safe spot near the wizard. Never dies.

const PX := 1.0 / 24.0
const SPEED := 5.4
const MAX_HP := 90.0
const ATTACK_DMG := 6.0
const GUARD_CD := 12.0

var hp := MAX_HP
var state := &"follow"
var facing := 1
var sprite: PixelBillboard
var _t := 0.0
var _atk_cd := 0.0
var _guard_cd := 4.0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _calm_t := 0.0
var _flash := 0.0
var _target: Node3D


func _ready() -> void:
	add_to_group(&"companion")
	collision_layer = 16
	collision_mask = 1 | Region.INVISIBLE
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.4
	cs.shape = cap
	cs.position.y = 0.7
	add_child(cs)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/npc_tamsin.json"))
	sprite = PixelBillboard.new()
	sprite.setup(load("res://assets/generated/npc_tamsin.png"), Vector2i(48, 48), int(meta.hframes), meta.anims, Vector2(22, 46))
	add_child(sprite)
	sprite.play(&"idle")
	add_child(BlobShadow.make(0.8))
	_last_pos = global_position
	var talk := Interactable.make(Vector3.ZERO, "Talk to Tamsin", 1.6, 1.9)
	add_child(talk)
	talk.activated.connect(func(_p: Player) -> void:
		var k: int = await Dialogue.i.choose("Tamsin", "Right behind you, {name}.", ["Keep close", "Wait at the sanctuary"])
		if k == 1:
			GameState.companion.following = false
			FX3.burst(center(), 12, [Color("d8f8ff"), Color("8ad8f0")], Vector2(0.5, 1.5), Vector2(0.3, 0.6))
			get_tree().root.get_node("Main").sync_companion()
			SaveSystem.autosave())
	set_meta(&"talk", talk)


func player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func center() -> Vector3:
	return global_position + Vector3(0, 0.8, 0)


func radius() -> float:
	return 0.3


func height() -> float:
	return 1.6


func is_alive() -> bool:
	return state != &"downed"


## Enemy attacks that reach her (melee arcs, bolts, thorns) land here.
func take_hit(d: Damage) -> void:
	if state == &"downed":
		return
	hp -= d.amount
	_flash = 0.8
	velocity += Vector3(d.knockback.x, 0, d.knockback.z) * 0.5
	if hp <= 0.0:
		hp = 0.0
		state = &"downed"
		_calm_t = 0.0
		sprite.play(&"downed")
		Sfx.play("hurt", -4.0)
	else:
		sprite.play(&"hurt", true)


func _physics_process(delta: float) -> void:
	_t += delta
	_atk_cd -= delta
	_guard_cd -= delta
	_flash = maxf(0.0, _flash - delta * 6.0)
	sprite.set_flash(_flash)
	var p := player()
	if p == null:
		return
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= 22.0 * delta
	(get_meta(&"talk") as Interactable).enabled = state != &"downed" and _target == null
	match state:
		&"downed":
			velocity.x = 0.0
			velocity.z = 0.0
			sprite.play(&"downed")
			# up again once nothing is fighting nearby
			var danger := false
			for e: Node3D in SpellEffect.enemies():
				if SpellEffect.flat(e.global_position, global_position) < 10.0:
					danger = true
			_calm_t = 0.0 if danger else _calm_t + delta
			if _calm_t > 3.0:
				hp = MAX_HP * 0.6
				state = &"follow"
				sprite.play(&"rise", true)
		_:
			_act(p, delta)
	Steps.move(self)
	_unstick(p, delta)
	sprite.set_flip(facing < 0)


func _act(p: Player, delta: float) -> void:
	_target = _pick_target(p)
	var goal: Vector3
	if _target:
		goal = _target.global_position - SpellEffect.flat_dir(_target.global_position - global_position) * (_target.radius() + 0.9)
	else:
		var behind := -p.look_dir * 1.6 + p.look_dir.cross(Vector3.UP).normalized() * 0.8
		goal = p.global_position + behind
		if Region.current and Region.current.is_hazard(goal):
			goal = p.global_position - p.look_dir * 0.8
	var d := goal - global_position
	d.y = 0.0
	var want := Vector3.ZERO
	if d.length() > 0.35:
		want = d.normalized() * SPEED * clampf(d.length() / 1.5, 0.4, 1.3)
	velocity.x = move_toward(velocity.x, want.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, want.z, 30.0 * delta)
	if absf(velocity.x) > 0.3:
		facing = int(signf(velocity.x))
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
		facing = int(signf(_target.global_position.x - global_position.x)) if absf(_target.global_position.x - global_position.x) > 0.1 else facing
		sprite.play(&"attack", true)
		var dmg := Damage.make(ATTACK_DMG, self, &"", SpellEffect.flat_dir(_target.global_position - global_position) * 2.5)
		dmg.hit_pos = center()
		dmg.stagger = 6.0
		_target.take_hit(dmg)
		Sfx.play("slash", -8.0)
		return
	if sprite.is_done() or sprite.anim in [&"idle", &"walk"]:
		sprite.play(&"walk" if Vector2(velocity.x, velocity.z).length() > 0.5 else &"idle")


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


## Too far behind, or not moving while trying to: reappear near the wizard.
func _unstick(p: Player, delta: float) -> void:
	var far := SpellEffect.flat(p.global_position, global_position) > 16.0
	var trying := Vector2(velocity.x, velocity.z).length() > 1.0
	_stuck_t = _stuck_t + delta if trying and global_position.distance_to(_last_pos) < 0.02 else 0.0
	_last_pos = global_position
	if far or _stuck_t > 1.5 or global_position.y < p.global_position.y - 6.0:
		warp_near(p)


func warp_near(p: Player) -> void:
	for k in 8:
		var off := (-p.look_dir).rotated(Vector3.UP, k * 0.7) * 1.6
		var spot := SpellEffect.ground_at(p.global_position + off, p)
		if Region.current == null or not Region.current.is_hazard(spot):
			global_position = spot
			velocity = Vector3.ZERO
			_stuck_t = 0.0
			FX3.burst(center(), 8, [Color("d8f8ff"), Color("8ad8f0")], Vector2(0.5, 1.5), Vector2(0.2, 0.4))
			return
