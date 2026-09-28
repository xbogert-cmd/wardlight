class_name Player
extends CharacterBody2D
## The wizard: movement, dodge, damage intake and animation choice.
## Health, mana, aiming and spells live in child components.

signal died
signal perfect_dodge

enum { NORMAL, DODGE, HURT, DEAD, LOCKED, DASH }

@export var tuning: PlayerTuning = preload("res://data/tuning/player.tres")

var health: Health
var mana: Mana
var wiz := WizardState.new()
var passives: Passives
var statuses: Statuses
var caster: SpellCaster
var aim: Aim
var sprite: WizardSprite

var state := NORMAL
var facing := 1
var has_double_jump := false
var has_float := false
## Incoming-damage multiplier from wards, with its remaining time.
var guard_mult := 1.0
var guard_t := 0.0
## Spirit Lantern wards: each absorbs one enemy hit and retaliates.
var spirits: Array = []
var _dash_v := Vector2.ZERO
var _dash_t := 0.0
var _dash_step: Callable
## False while a menu owns the keyboard. After menus close, the staff attack
## waits for its button to be released so a menu click never fires it.
var input_enabled := true
var _attack_needs_release := false
var _input_grace := 0.0

var _coyote := 0.0
var _buffer := 0.0
var _jumping := false
var _air_jump_used := false
var _air_dodge_used := false
var _float_left := 0.0
var _dodge_t := 0.0
var _dodge_cd := 0.0
var _dodge_dir := 1
var _dodge_rewarded := false
var _state_t := 0.0
var _iframes := 0.0
var _flash := 0.0
var _was_on_floor := true
var _land_t := 0.0
var _release_t := 0.0
var _release_pose := 2
var _step_frame := -1


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(47.0)
	floor_constant_speed = true
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(10, 30)
	cs.shape = sh
	cs.position = Vector2(0, -15)
	add_child(cs)

	health = Health.new()
	health.max_hp = tuning.max_hp
	add_child(health)
	mana = Mana.new()
	mana.max_mp = tuning.max_mana
	mana.mp = tuning.max_mana
	mana.regen = tuning.mana_regen
	add_child(mana)
	if wiz.loadouts.is_empty():
		wiz.setup("storm")
	passives = Passives.new()
	passives.player = self
	add_child(passives)
	statuses = Statuses.new()
	statuses.owner_actor = self
	add_child(statuses)
	sprite = WizardSprite.new()
	add_child(sprite)
	aim = Aim.new()
	aim.player = self
	add_child(aim)
	caster = SpellCaster.new()
	caster.player = self
	caster.mana = mana
	caster.aim = aim
	add_child(caster)


func center() -> Vector2:
	return global_position + Vector2(0, -16)


## Staff gem, pulled back if the staff pokes into a wall so spells never
## spawn on the far side of terrain.
func cast_origin() -> Vector2:
	var from := global_position + Vector2(0, -26)
	var tip := global_position + sprite.tip()
	var q := PhysicsRayQueryParameters2D.create(from, tip, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return tip
	return (hit.position as Vector2) - (tip - from).normalized() * 3.0


func is_alive() -> bool:
	return state != DEAD


func can_cast() -> bool:
	return state == NORMAL and input_enabled


func resume_input() -> void:
	input_enabled = true
	_attack_needs_release = true
	_input_grace = 0.08


func _just(a: StringName) -> bool:
	return input_enabled and _input_grace <= 0.0 and Input.is_action_just_pressed(a)


func _held(a: StringName) -> bool:
	return input_enabled and Input.is_action_pressed(a)


func face(dir: int) -> void:
	if dir != 0:
		facing = dir
		sprite.scale.x = facing


# ------------------------------------------------------------------ physics
func _physics_process(delta: float) -> void:
	_state_t += delta
	_iframes = maxf(0.0, _iframes - delta)
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	_release_t = maxf(0.0, _release_t - delta)
	_input_grace -= delta
	if _attack_needs_release and not Input.is_action_pressed(&"attack"):
		_attack_needs_release = false
	_land_t = maxf(0.0, _land_t - delta)
	if guard_t > 0.0:
		guard_t -= delta
		if guard_t <= 0.0:
			guard_mult = 1.0
	match state:
		NORMAL:
			_normal(delta)
		DODGE:
			_dodge(delta)
		DASH:
			_spell_dash(delta)
		HURT:
			velocity.y = minf(velocity.y + tuning.gravity_down * delta, tuning.max_fall)
			velocity.x = move_toward(velocity.x, 0.0, tuning.decel * 0.5 * delta)
			if _state_t >= tuning.hurt_time:
				state = NORMAL
		DEAD:
			velocity.y = minf(velocity.y + tuning.gravity_down * delta, tuning.max_fall)
			velocity.x = move_toward(velocity.x, 0.0, tuning.decel * delta)
		LOCKED:
			velocity.x = move_toward(velocity.x, 0.0, tuning.decel * delta)
			velocity.y = minf(velocity.y + tuning.gravity_down * delta, tuning.max_fall)
	move_and_slide()
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_on_land()
	_was_on_floor = on_floor
	_animate(delta)


func _normal(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		_coyote = tuning.coyote
		_air_jump_used = false
		_air_dodge_used = false
		_float_left = tuning.float_time
		_jumping = false
	else:
		_coyote -= delta
	_buffer -= delta
	if _just(&"jump"):
		_buffer = tuning.jump_buffer

	var ix := Input.get_axis(&"move_left", &"move_right") if input_enabled else 0.0
	var target := ix * tuning.run_speed
	if caster.state == SpellCaster.WINDUP:
		target *= tuning.cast_move_mult
	var a := tuning.accel if on_floor else tuning.air_accel
	if ix == 0.0:
		a = tuning.decel if on_floor else tuning.air_accel * 0.6
	velocity.x = move_toward(velocity.x, target, a * delta)
	if ix != 0.0 and not caster.busy():
		face(int(signf(ix)))

	# jumping (with coyote time, buffer and double jump)
	if _buffer > 0.0:
		if _coyote > 0.0:
			_jump(tuning.jump_height)
		elif has_double_jump and not _air_jump_used:
			_air_jump_used = true
			_jump(tuning.double_jump_height)
			FX.ring(global_position, 3, 14, 0.25, Pal.school(&"storm"), 1.0, false)
			FX.burst(global_position, 8, Pal.MANA, Vector2(30, 70), Vector2(0.2, 0.4), {"dir": Vector2.DOWN, "spread": 2.0})
	if _jumping and velocity.y < 0.0 and not _held(&"jump"):
		velocity.y *= tuning.jump_cut
		_jumping = false

	var g := tuning.gravity_up if velocity.y < 0.0 else tuning.gravity_down
	velocity.y = minf(velocity.y + g * delta, tuning.max_fall)
	if has_float and velocity.y > 0.0 and _held(&"jump") and _float_left > 0.0 and not on_floor:
		_float_left -= delta
		velocity.y = minf(velocity.y, tuning.float_fall_speed)
		if randf() < 0.4:
			FX.burst(global_position + Vector2(randf_range(-6, 6), -2), 1, Pal.HEAL, Vector2(5, 15), Vector2(0.3, 0.5), {"dir": Vector2.DOWN, "spread": 1.0})

	if _just(&"dodge") and _dodge_cd <= 0.0 and (on_floor or not _air_dodge_used):
		_start_dodge(ix)
		return

	if _just(&"spell_1"):
		caster.request(0)
	elif _just(&"spell_2"):
		caster.request(1)
	elif _just(&"spell_3"):
		caster.request(2)
	elif _just(&"spell_4"):
		caster.request(3)
	elif _held(&"attack") and not _attack_needs_release:
		caster.request(SpellCaster.BASIC_SLOT, true)


func _jump(h: float) -> void:
	var g := tuning.gravity_up
	velocity.y = -sqrt(2.0 * g * h)
	_jumping = true
	_coyote = 0.0
	_buffer = 0.0
	Sfx.play("jump", -8.0)
	FX.burst(global_position, 5, Pal.DUST, Vector2(10, 40), Vector2(0.2, 0.35), {"dir": Vector2.UP, "spread": 2.4, "add": false, "front": false, "gravity": 60.0})


func _start_dodge(ix: float) -> void:
	caster.interrupt()
	state = DODGE
	_state_t = 0.0
	_dodge_t = tuning.dodge_time
	_dodge_dir = int(signf(ix)) if ix != 0.0 else facing
	face(_dodge_dir)
	_dodge_rewarded = false
	_iframes = maxf(_iframes, tuning.dodge_iframes)
	if not is_on_floor():
		_air_dodge_used = true
	velocity = Vector2(_dodge_dir * tuning.dodge_speed, 0)
	sprite.restart(&"dodge")
	Sfx.play("dodge", -4.0)
	FX.burst(global_position + Vector2(-_dodge_dir * 4, -2), 6, Pal.DUST, Vector2(20, 60), Vector2(0.2, 0.4),
		{"dir": Vector2(-_dodge_dir, -0.3), "spread": 0.8, "add": false, "front": false, "drag": 3.0})


func _dodge(delta: float) -> void:
	_dodge_t -= delta
	velocity.x = _dodge_dir * tuning.dodge_speed * (0.55 + 0.45 * _dodge_t / tuning.dodge_time)
	velocity.y = minf(velocity.y + tuning.gravity_down * 0.25 * delta, 60.0)
	if int(_state_t * 60.0) % 3 == 0:
		_afterimage()
	if _dodge_t <= 0.0:
		state = NORMAL
		_dodge_cd = tuning.dodge_cooldown
		velocity.x *= 0.5


## Spell-driven dash (Slipstream): fixed velocity, invulnerable, calls
## `on_step` every physics frame so the spell can hit things it passes.
func spell_dash(v: Vector2, time: float, on_step: Callable) -> void:
	state = DASH
	_state_t = 0.0
	_dash_v = v
	_dash_t = time
	_dash_step = on_step
	_iframes = maxf(_iframes, time + 0.05)
	if absf(v.x) > 1.0:
		face(int(signf(v.x)))


func _spell_dash(delta: float) -> void:
	_dash_t -= delta
	velocity = _dash_v
	if _dash_step.is_valid():
		_dash_step.call()
	if int(_state_t * 60.0) % 2 == 0:
		_afterimage()
	if _dash_t <= 0.0:
		state = NORMAL
		velocity = _dash_v * 0.35


func _afterimage() -> void:
	var tex := sprite.anim.sprite_frames.get_frame_texture(sprite.anim.animation, sprite.anim.frame)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = -Vector2(WizardArt.FOOT)
	s.scale.x = facing
	s.global_position = global_position
	s.modulate = Color(0.5, 0.85, 1.0, 0.45)
	s.z_index = -1
	get_parent().add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.18)
	tw.tween_callback(s.queue_free)


func _on_land() -> void:
	_land_t = 0.1
	Sfx.play("land", -10.0)
	FX.burst(global_position, 4, Pal.DUST, Vector2(10, 35), Vector2(0.15, 0.3), {"dir": Vector2.UP, "spread": 2.8, "add": false, "front": false, "gravity": 80.0})


# ------------------------------------------------------------------ damage
func take_hit(d: Damage) -> void:
	if state == DEAD:
		return
	if _iframes > 0.0:
		if state == DODGE and d.active_attack and not _dodge_rewarded:
			_dodge_rewarded = true
			mana.gain(tuning.perfect_dodge_mana)
			perfect_dodge.emit()
			Sfx.play("perfect_dodge", -4.0)
			FX.ring(center(), 4, 18, 0.3, Pal.MANA, 1.0, true)
			FX.burst(center(), 10, Pal.MANA, Vector2(30, 80), Vector2(0.2, 0.4), {"glow": true})
		return
	if not spirits.is_empty() and d.active_attack:
		var sp: Node = spirits.pop_front()
		sp.intercept(d)
		_iframes = 0.3
		return
	caster.interrupt()
	health.damage(d.amount * guard_mult)
	_flash = 0.75
	_iframes = tuning.hurt_iframes
	var kb := d.knockback if d.knockback != Vector2.ZERO else Vector2(signf(global_position.x - d.hit_pos.x) * 120.0, -120.0)
	velocity = kb
	TimeCtl.hitstop(0.06)
	GameCamera.shake_all(4.0)
	FX.burst(center(), 10, Pal.DANGER, Vector2(40, 120), Vector2(0.15, 0.35), {"gravity": 200.0})
	if health.is_dead():
		_die()
	else:
		state = HURT
		_state_t = 0.0
		sprite.restart(&"hurt")
		Sfx.play("hurt", -2.0)


func _die() -> void:
	state = DEAD
	_state_t = 0.0
	sprite.restart(&"death")
	Sfx.play("player_death")
	died.emit()


func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	state = NORMAL
	_state_t = 0.0
	health.reset()
	mana.refill()
	statuses.clear()
	guard_mult = 1.0
	guard_t = 0.0
	for s in spirits:
		s.queue_free()
	spirits.clear()
	passives.reset()
	_iframes = tuning.respawn_iframes
	sprite.restart(&"idle")


func lock(on: bool) -> void:
	if state == DEAD:
		return
	state = LOCKED if on else NORMAL
	if on:
		caster.interrupt()


# ------------------------------------------------------------------ animation
func on_cast_release(_data: SpellData, _ctx: CastContext) -> void:
	_release_t = 0.14
	_release_pose = caster.pose_index()
	sprite.restart(StringName("release_%d" % _release_pose))


func _animate(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 8.0)
	sprite.set_flash(_flash)
	sprite.visible = true
	if _iframes > 0.0 and state != DODGE and state != DEAD and state != HURT:
		sprite.modulate.a = 0.45 if int(_iframes * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0
	match state:
		DEAD:
			sprite.play(&"death")
			return
		HURT:
			sprite.play(&"hurt")
			return
		DODGE, DASH:
			sprite.play(&"dodge")
			return
	if caster.state == SpellCaster.WINDUP:
		sprite.play(&"raise" if caster.t < caster.cur.windup * 0.35 else &"gather")
		return
	if _release_t > 0.0:
		sprite.play(StringName("release_%d" % _release_pose))
		return
	if caster.state == SpellCaster.RECOVER:
		sprite.play(&"recover")
		return
	if not is_on_floor():
		sprite.play(&"jump" if velocity.y < 0.0 else &"fall")
	elif _land_t > 0.0:
		sprite.play(&"land")
	elif absf(velocity.x) > 12.0:
		sprite.play(&"run")
		var f := sprite.anim.frame
		if (f == 1 or f == 5) and f != _step_frame:
			Sfx.play("step", -14.0, 0.15)
		_step_frame = f
	else:
		sprite.play(&"idle")
