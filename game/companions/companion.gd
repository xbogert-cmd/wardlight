class_name Companion
extends CharacterBody3D
## A companion who walks with the wizard (up to GameState.PARTY_MAX at once).
## Follows a step behind (never blocking: own collision layer 16), takes
## enemy blows, and when beaten down kneels until the fight is over, then
## gets up. If stuck or left far behind they slip back to a safe spot near
## the wizard. Never dies. Subclasses pick targets and act in `_act`.

const PX := 1.0 / 24.0

var id := &""
var display := ""
var sheet := ""              # assets/generated/npc_<sheet>.png/.json
var max_hp := 90.0
var speed := 5.4
var slot := 0                # place in the party: 0 walks behind-right, 1 behind-left
var hp := 90.0
var state := &"follow"
var facing := 1
var sprite: PixelBillboard
var _t := 0.0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _calm_t := 0.0
var _flash := 0.0
var _target: Node3D


static func make(cid: StringName) -> Companion:
	match cid:
		&"tamsin":
			return Shieldbearer.new()
		&"kess":
			return Scout.new()
	return null


func _ready() -> void:
	add_to_group(&"companion")
	hp = max_hp
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
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/npc_%s.json" % sheet))
	sprite = PixelBillboard.new()
	sprite.setup(load("res://assets/generated/npc_%s.png" % sheet), Vector2i(48, 48), int(meta.hframes), meta.anims, Vector2(22, 46))
	add_child(sprite)
	sprite.play(&"idle")
	add_child(BlobShadow.make(0.8))
	_last_pos = global_position
	var talk := Interactable.make(Vector3.ZERO, "Talk to " + display, 1.6, 1.9)
	add_child(talk)
	talk.activated.connect(func(_p: Player) -> void:
		var k: int = await Dialogue.i.choose(display, greeting(), ["Keep close", "Wait at the sanctuary"])
		if k == 1 and not can_rest():
			await Dialogue.i.talk([[display, rest_refusal()]])
		elif k == 1:
			GameState.leave_party(id)
			FX3.burst(center(), 12, [Color("d8f8ff"), Color("8ad8f0")], Vector2(0.5, 1.5), Vector2(0.3, 0.6))
			get_tree().root.get_node("Main").sync_party()
			SaveSystem.autosave())
	set_meta(&"talk", talk)


func greeting() -> String:
	return "Right behind you, {name}."


## Whether they'll go and wait at the sanctuary camp right now.
func can_rest() -> bool:
	return true


func rest_refusal() -> String:
	return ""


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


## Enemy attacks that reach them (melee arcs, bolts, thorns) land here.
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
				hp = max_hp * 0.6
				state = &"follow"
				sprite.play(&"rise", true)
		_:
			_act(p, delta)
	Steps.move(self)
	_unstick(p, delta)
	sprite.set_flip(facing < 0)


## Default: just follow.
func _act(p: Player, delta: float) -> void:
	move_to(follow_spot(p), delta)
	walk_anim()


## Where to stand when not fighting: slot 0 a step behind-right of the
## wizard, slot 1 behind-left and a little further back.
func follow_spot(p: Player) -> Vector3:
	var side := p.look_dir.cross(Vector3.UP).normalized()
	var behind := -p.look_dir * (1.6 + slot * 0.8) + side * (0.8 if slot == 0 else -0.9)
	var goal := p.global_position + behind
	if Region.current and Region.current.is_hazard(goal):
		goal = p.global_position - p.look_dir * (0.8 + slot * 0.6)
	return goal


func move_to(goal: Vector3, delta: float) -> void:
	var d := goal - global_position
	d.y = 0.0
	var want := Vector3.ZERO
	if d.length() > 0.35:
		want = d.normalized() * speed * clampf(d.length() / 1.5, 0.4, 1.3)
	velocity.x = move_toward(velocity.x, want.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, want.z, 30.0 * delta)
	if absf(velocity.x) > 0.3:
		facing = int(signf(velocity.x))


## Walk or idle, unless a one-shot animation is still playing.
func walk_anim() -> void:
	if sprite.is_done() or sprite.anim in [&"idle", &"walk"]:
		sprite.play(&"walk" if Vector2(velocity.x, velocity.z).length() > 0.5 else &"idle")


func face_toward(pos: Vector3) -> void:
	if absf(pos.x - global_position.x) > 0.1:
		facing = int(signf(pos.x - global_position.x))


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
		var off := (-p.look_dir).rotated(Vector3.UP, k * 0.7 + slot * 0.35) * (1.6 + slot * 0.6)
		var spot := SpellEffect.ground_at(p.global_position + off, p)
		if Region.current == null or not Region.current.is_hazard(spot):
			global_position = spot
			velocity = Vector3.ZERO
			_stuck_t = 0.0
			FX3.burst(center(), 8, [Color("d8f8ff"), Color("8ad8f0")], Vector2(0.5, 1.5), Vector2(0.2, 0.4))
			return
