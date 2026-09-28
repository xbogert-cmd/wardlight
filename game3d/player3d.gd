class_name Player3D
extends CharacterBody3D
## Mockup wizard in the 3D world: WASD in eight directions, Shift dodge,
## cursor aim on the ground, J / click staff gust, 1 = Arc Lance.

signal died

const PX := PixelBillboard.PX
const SPEED := 4.8
const DODGE_SPEED := 12.5
const DODGE_TIME := 0.2
const RUNE := preload("res://assets/generated/rune64.png")
const GLOW := preload("res://assets/generated/glow32.png")

var sprite: PixelBillboard
var art: Dictionary
var health: Health
var mana: Mana
var cam: Camera3D
var aim_point := Vector3.ZERO
var facing := 1
var state := &"move"
var _t := 0.0
var _dodge_dir := Vector3.RIGHT
var _iframes := 0.0
var _cd := {}
var _flash := 0.0
var _cast_rune: MeshInstance3D
var _release_t := 0.0
var _release_pose := 2
var _cast_dir := Vector3.RIGHT
var aim_override: Variant = null   # demo driver: world point to aim at


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.4
	cs.shape = cap
	cs.position.y = 0.7
	add_child(cs)
	health = Health.new()
	add_child(health)
	mana = Mana.new()
	add_child(mana)
	art = WizardArt.build({})
	sprite = PixelBillboard.new()
	sprite.setup(art.texture, Vector2i(WizardArt.CELL_W, WizardArt.CELL), WizardArt.COLS, art.anims, Vector2(WizardArt.FOOT))
	add_child(sprite)
	sprite.play(&"idle")
	add_child(BlobShadow.make(0.9))


func center() -> Vector3:
	return global_position + Vector3(0, 0.9, 0)


func is_alive() -> bool:
	return state != &"dead"


## Staff gem in world space (billboards face the camera, so offset along the camera's axes).
func staff_tip() -> Vector3:
	var info: Dictionary = art.anims.get(String(sprite.anim), {})
	var t := Vector2(6, -44)
	if not info.is_empty():
		t = art.tips[info.frames[clampi(sprite.frame, 0, info.frames.size() - 1)]]
	if sprite.flip:
		t.x = -t.x
	var b := cam.global_transform.basis
	return global_position + b.x * t.x * PX + b.y * -t.y * PX


func _physics_process(delta: float) -> void:
	_t += delta
	_iframes = maxf(0.0, _iframes - delta)
	_release_t = maxf(0.0, _release_t - delta)
	for k in _cd.keys():
		_cd[k] -= delta
	_update_aim()
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.5
	var input := Vector3(Input.get_axis(&"move_left", &"move_right"), 0, Input.get_axis(&"up", &"down"))
	if input.length() > 1.0:
		input = input.normalized()
	match state:
		&"move":
			var sp := SPEED * (0.7 if _t < 0.0 else 1.0)
			var target := input * sp
			velocity.x = move_toward(velocity.x, target.x, 40.0 * delta)
			velocity.z = move_toward(velocity.z, target.z, 40.0 * delta)
			if absf(input.x) > 0.1 and _release_t <= 0.0:
				facing = int(signf(input.x))
			if Input.is_action_just_pressed(&"dodge"):
				_dodge_dir = input.normalized() if input.length() > 0.1 else Vector3(facing, 0, 0)
				state = &"dodge"
				_t = 0.0
				_iframes = 0.17
				sprite.play(&"dodge", true)
				Sfx.play("dodge", -4.0)
				FX3.burst(global_position + Vector3(0, 0.1, 0), 8, Pal.DUST, Vector2(1, 3), Vector2(0.2, 0.4), {"dir": -_dodge_dir, "spread": 1.2, "gravity": 4.0})
			elif Input.is_action_just_pressed(&"spell_1"):
				_begin_cast()
			elif Input.is_action_pressed(&"attack") and _cd.get(&"gust", 0.0) <= 0.0:
				_gust()
		&"dodge":
			velocity.x = _dodge_dir.x * DODGE_SPEED * (0.5 + 0.5 * (1.0 - _t / DODGE_TIME))
			velocity.z = _dodge_dir.z * DODGE_SPEED * (0.5 + 0.5 * (1.0 - _t / DODGE_TIME))
			if _t >= DODGE_TIME:
				state = &"move"
		&"cast":
			velocity.x = move_toward(velocity.x, input.x * SPEED * 0.6, 40.0 * delta)
			velocity.z = move_toward(velocity.z, input.z * SPEED * 0.6, 40.0 * delta)
			_face_aim()
			var tip := staff_tip()
			if randf() < delta * 140.0:
				FX3.converge(tip, 0.9 - _t * 3.0, 2, Pal.school(&"storm"), 0.14, 1.5)
			if randf() < delta * 30.0:
				FX3.bolt(tip + Vector3(randf_range(-0.5, 0.5), randf_range(-0.4, 0.4), randf_range(-0.5, 0.5)), tip, 0.06, Pal.school(&"storm"), 0.06)
			if is_instance_valid(_cast_rune):
				_cast_rune.global_position = global_position + Vector3(0, 0.03, 0)
			if _t >= 0.16:
				_release_lance()
				state = &"move"
		&"hurt":
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
			if _t >= 0.28:
				state = &"move"
		&"dead":
			velocity.x = 0.0
			velocity.z = 0.0
	move_and_slide()
	_animate(delta)


func _update_aim() -> void:
	if aim_override != null:
		aim_point = aim_override
		return
	if cam == null:
		return
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var dir := cam.project_ray_normal(mp)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		aim_point = hit.position
	else:
		var t := (global_position.y - from.y) / dir.y if dir.y != 0.0 else 0.0
		aim_point = from + dir * t


func _aim_dir() -> Vector3:
	var enemy := _target()
	var goal: Vector3 = enemy.center() if enemy else aim_point + Vector3(0, 0.9, 0)
	var d := goal - center()
	d.y = 0.0
	return d.normalized() if d.length() > 0.2 else Vector3(facing, 0, 0)


## Assisted aim: an enemy near the cursor.
func _target() -> Node3D:
	var best: Node3D = null
	var bd := 1.6
	for e in get_tree().get_nodes_in_group(&"enemy3d"):
		if e.is_alive():
			var d: float = Vector2(e.global_position.x - aim_point.x, e.global_position.z - aim_point.z).length()
			if d < bd:
				bd = d
				best = e
	return best


func _face_aim() -> void:
	var d := _aim_dir()
	if absf(d.x) > 0.05:
		facing = int(signf(d.x))


func _pose_for(d: Vector3) -> int:
	# screen-space angle of the aim: "up the screen" (away from camera) points the staff up
	var ang := rad_to_deg(atan2(d.z * 0.7, absf(d.x)))
	var best := 2
	var bd := 999.0
	for k in WizardArt.AIM_ANGLES.size():
		var diff := absf(ang - WizardArt.AIM_ANGLES[k])
		if diff < bd:
			bd = diff
			best = k
	return best


# ------------------------------------------------------------------ spells
func _begin_cast() -> void:
	if _cd.get(&"lance", 0.0) > 0.0 or not mana.can_spend(16.0):
		Sfx.play("fail", -8.0)
		return
	mana.spend(16.0)
	_cd[&"lance"] = 0.9
	state = &"cast"
	_t = 0.0
	Sfx.play("storm_gather", -6.0)
	_cast_rune = FX3.decal(RUNE, global_position + Vector3(0, 0.03, 0), 0.55, Color(0.4, 0.85, 1.0, 0.9), 0.3, 1.1, 2.5)


func _release_lance() -> void:
	var d := _aim_dir()
	_cast_dir = d
	facing = int(signf(d.x)) if absf(d.x) > 0.05 else facing
	_release_pose = _pose_for(d)
	_release_t = 0.14
	sprite.play(StringName("release_%d" % _release_pose), true)
	var o := staff_tip()
	var ramp := Pal.school(&"storm")
	FX3.decal(GLOW, o, 0.2, Color(ramp[2], 0.9), 0.8, 1.4, 0.0, false)
	FX3.decal(RUNE, o, 0.3, Color(ramp[1], 1.0), 0.25, 0.6, 0.0, false)
	FX3.burst(o, 16, ramp, Vector2(2, 6), Vector2(0.1, 0.25), {"dir": d, "spread": 1.0, "drag": 5.0})
	FX3.light(o, Color(0.5, 0.85, 1.0), 3.0, 5.0, 0.15)
	Sfx.play("storm_release", -1.0)
	var b := Bolt3D.new()
	var tgt := _target()
	var goal: Vector3 = tgt.center() if tgt else aim_point + Vector3(0, 1.0, 0)
	var start := Vector3(o.x, global_position.y + 1.0, o.z)
	b.dir = (goal - start).normalized() if goal.distance_to(start) > 0.5 else d
	b.ramp = ramp
	get_parent().add_child(b)
	b.global_position = start


func _gust() -> void:
	_cd[&"gust"] = 0.32
	_face_aim()
	var d := _aim_dir()
	_release_pose = _pose_for(d)
	_release_t = 0.12
	sprite.play(StringName("release_%d" % _release_pose), true)
	var o := staff_tip()
	var ramp := Pal.school(&"storm")
	for a in [-0.35, 0.0, 0.35]:
		FX3.bolt(o, o + d.rotated(Vector3.UP, a) * randf_range(1.6, 2.2), 0.1, ramp, 0.12)
	FX3.burst(o, 14, [Color("ffffff"), Color("d8f8ff"), Color("8ad8f0")], Vector2(6, 10), Vector2(0.08, 0.18), {"dir": d, "spread": 0.9, "drag": 7.0})
	FX3.light(o, Color(0.5, 0.85, 1.0), 1.5, 3.0, 0.1)
	Sfx.play("storm_gust", -5.0)
	var hit_any := false
	for e in get_tree().get_nodes_in_group(&"enemy3d"):
		if not e.is_alive():
			continue
		var v: Vector3 = e.global_position - global_position
		v.y = 0.0
		if v.length() < 2.6 and (v.length() < 0.8 or v.normalized().angle_to(d) < 0.7):
			e.take_hit(7.0, d * 5.0, &"storm")
			hit_any = true
	if hit_any:
		mana.gain(3.0)
		Sfx.play("storm_zap", -6.0)
		TimeCtl.hitstop(0.025)


func take_hit(amount: float, from: Vector3) -> void:
	if state == &"dead" or _iframes > 0.0:
		return
	health.damage(amount)
	_flash = 0.75
	_iframes = 0.8
	var kb := (global_position - from)
	kb.y = 0.0
	velocity = kb.normalized() * 6.0 + Vector3(0, 3, 0)
	TimeCtl.hitstop(0.06)
	FX3.burst(center(), 12, Pal.DANGER, Vector2(2, 5), Vector2(0.15, 0.35), {"gravity": 8.0})
	if health.is_dead():
		state = &"dead"
		sprite.play(&"death", true)
		Sfx.play("player_death")
		died.emit()
	else:
		state = &"hurt"
		_t = 0.0
		sprite.play(&"hurt", true)
		Sfx.play("hurt", -2.0)


func _animate(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 8.0)
	sprite.set_flash(_flash)
	sprite.set_flip(facing < 0)
	sprite.visible = not (_iframes > 0.0 and state == &"move" and int(_iframes * 20.0) % 2 == 0)
	match state:
		&"dead":
			return
		&"hurt":
			sprite.play(&"hurt")
			return
		&"dodge":
			sprite.play(&"dodge")
			return
		&"cast":
			sprite.play(&"raise" if _t < 0.05 else &"gather")
			return
	if _release_t > 0.0:
		sprite.play(StringName("release_%d" % _release_pose))
	elif Vector2(velocity.x, velocity.z).length() > 0.5:
		sprite.play(&"run")
	else:
		sprite.play(&"idle")


class Bolt3D extends Node3D:
	## Arc Lance bolt: a crackling lightning trail carrying a real light.
	var dir := Vector3.RIGHT
	var ramp: Array
	var speed := 19.0
	var travel := 0.0
	var trail: Array = []
	var lamp: OmniLight3D

	func _ready() -> void:
		lamp = OmniLight3D.new()
		lamp.light_color = Color(0.45, 0.85, 1.0)
		lamp.light_energy = 2.2
		lamp.omni_range = 4.5
		add_child(lamp)

	func _physics_process(delta: float) -> void:
		var from := global_position
		var to := from + dir * speed * delta
		var q := PhysicsRayQueryParameters3D.create(from, to, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			_impact(hit.position, null)
			return
		for e in get_tree().get_nodes_in_group(&"enemy3d"):
			if e.is_alive() and Geometry3D.get_closest_point_to_segment(e.center(), from, to).distance_to(e.center()) < 0.6:
				_impact(e.center(), e)
				return
		global_position = to
		travel += speed * delta
		trail.push_front(to)
		if trail.size() > 7:
			trail.pop_back()
		if trail.size() > 1:
			FX3.bolt(trail[0], trail[trail.size() - 1], 0.04, ramp, 0.1)
		FX3.burst(to, 2, ramp, Vector2(0.3, 1.5), Vector2(0.12, 0.3), {"drag": 4.0})
		FX3.decal(GLOW, to, 0.05, Color(ramp[2], 0.9), 0.7, 0.7, 0.0, false)
		if travel > 14.0:
			FX3.burst(to, 10, ramp, Vector2(1, 3), Vector2(0.15, 0.3), {"drag": 3.0})
			queue_free()

	func _impact(pos: Vector3, e: Node3D) -> void:
		FX3.decal(GLOW, pos, 0.3, Color(ramp[2], 1.0), 1.2, 2.2, 0.0, false)
		FX3.decal(RUNE, Vector3(pos.x, pos.y - 0.9 if e else pos.y + 0.03, pos.z), 0.4, Color(ramp[1], 0.9), 0.3, 0.9, 3.0)
		for k in 6:
			FX3.bolt(pos, pos + Vector3(randf_range(-1, 1), randf_range(-0.6, 0.8), randf_range(-1, 1)).normalized() * randf_range(0.5, 1.1), 0.14, ramp, 0.12)
		FX3.burst(pos, 26, ramp, Vector2(2, 7), Vector2(0.15, 0.5), {"gravity": 9.0, "drag": 1.0})
		FX3.light(pos, Color(0.55, 0.9, 1.0), 4.0, 7.0, 0.3)
		GameCamera3D.shake_all(0.12)
		if e:
			e.take_hit(24.0, dir * 4.0, &"storm")
			TimeCtl.hitstop(0.05)
			Sfx.play("storm_impact", -1.0)
		else:
			Sfx.play("storm_fizzle", -4.0)
		queue_free()
