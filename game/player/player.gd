class_name Player
extends CharacterBody3D
## The wizard: movement on the ground plane (no jumping — hills are walked),
## dodge, damage intake and animation choice. Health, mana, aiming and spells
## live in child components. Side-facing sprite, flipped by `facing`.

signal died
signal perfect_dodge

enum { NORMAL, DODGE, HURT, DEAD, LOCKED, DASH }

const PX := 1.0 / 24.0

@export var tuning: PlayerTuning = preload("res://data/tuning/player.tres")

var health: Health
var mana: Mana
var wiz := WizardState.new()
var passives: Passives
var statuses: Statuses
var caster: SpellCaster
var aim: Aim
var sprite: PixelBillboard
var art: Dictionary

var state := NORMAL
var facing := 1
var look_dir := Vector3.RIGHT      # horizontal: last move / aim direction
var focus: Interactable = null      # nearest usable thing (E)
var levitating := false
var float_left := 0.0
var _float_base := 0.0
var _bell_cd := 0.0
var _ward_t := 0.0      # Wardweave: window after a dodge
var _last_safe := Vector3.ZERO
var _shadow: BlobShadow
## Incoming-damage multiplier from wards, with its remaining time.
var guard_mult := 1.0
var guard_t := 0.0
## Spirit Lantern wards: each absorbs one enemy hit and retaliates.
var spirits: Array = []
var _dash_v := Vector3.ZERO
var _dash_t := 0.0
var _dash_step: Callable
## False while a menu owns the keyboard. After menus close, the staff attack
## waits for its button to be released so a menu click never fires it.
var input_enabled := true
var _attack_needs_release := false
var _input_grace := 0.0

var _dodge_t := 0.0
var _dodge_cd := 0.0
var _dodge_dir := Vector3.RIGHT
var _dodge_rewarded := false
var _state_t := 0.0
var _iframes := 0.0
var _flash := 0.0
var _release_t := 0.0
var _release_pose := 2
var _step_frame := -1
var _ghost_t := 0.0


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 2
	collision_mask = 1 | 64 | Region.INVISIBLE   # world + solid spell targets (brambles) + invisible walls
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	floor_constant_speed = true
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.4
	cs.shape = cap
	cs.position.y = 0.7
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
	apply_bonuses()
	health.hp = health.max_hp
	mana.mp = mana.max_mp
	passives = Passives.new()
	passives.player = self
	add_child(passives)
	statuses = Statuses.new()
	statuses.owner_actor = self
	add_child(statuses)
	sprite = PixelBillboard.new()
	add_child(sprite)
	set_look(GameState.appearance)
	_shadow = BlobShadow.make(0.9)
	add_child(_shadow)
	aim = Aim.new()
	aim.player = self
	add_child(aim)
	caster = SpellCaster.new()
	caster.player = self
	caster.mana = mana
	caster.aim = aim
	add_child(caster)


## Rebuild the body from an appearance ({robe, hat, beard...}; see WizardArt).
func set_look(l: Dictionary) -> void:
	art = WizardArt.build(l)
	var cur := sprite.anim if sprite.anim != &"" else &"idle"
	sprite.setup(art.texture, Vector2i(WizardArt.CELL_W, WizardArt.CELL), WizardArt.COLS, art.anims, Vector2(WizardArt.FOOT))
	sprite.play(cur, true)


## Permanent rewards stored in GameState (max health / mana charms).
func apply_bonuses() -> void:
	var inv := GameState.inv
	health.max_hp = tuning.max_hp + float(GameState.flag(&"hp_bonus", 0.0)) + inv.hp_bonus()
	health.hp = minf(health.hp, health.max_hp)
	mana.max_mp = tuning.max_mana + float(GameState.flag(&"mana_bonus", 0.0))
	mana.regen = tuning.mana_regen * (1.0 + inv.relic(&"moonstone"))


## Put on equipment: stats follow, and the wizard's silhouette takes the
## item's look (the appearance mirror can change it back).
func equipment_changed() -> void:
	apply_bonuses()
	var look := GameState.appearance.duplicate()
	look.merge(GameState.inv.look(), true)
	GameState.appearance = look
	set_look(look)


func float_time() -> float:
	var inv := GameState.inv
	return tuning.float_time * ((1.0 + 0.5 * inv.tier_mult("robe")) if inv.robe_id() == &"mistcloak" else 1.0)


func center() -> Vector3:
	return global_position + Vector3(0, 0.9, 0)


func radius() -> float:
	return 0.32


func height() -> float:
	return 1.7


## Staff gem in world space (matches sprite_lit: upright quad, Y stretched by 1/cos(pitch)).
func staff_tip() -> Vector3:
	var info: Dictionary = art.anims.get(String(sprite.anim), {})
	var t := Vector2(6, -44)
	if not info.is_empty():
		t = art.tips[info.frames[clampi(sprite.frame, 0, info.frames.size() - 1)]]
	if sprite.flip:
		t.x = -t.x
	var cam := get_viewport().get_camera_3d()
	var right := Vector3.RIGHT
	var stretch := 1.0 / cos(deg_to_rad(50.0))
	if cam:
		var b := cam.global_transform.basis
		right = Vector3(b.x.x, 0.0, b.x.z).normalized()
		stretch = 1.0 / maxf(Vector2(b.z.x, b.z.z).length(), 0.2)
	return global_position + right * t.x * PX + Vector3.UP * -t.y * PX * stretch


## Staff gem, pulled back if the staff pokes into a wall so spells never
## spawn on the far side of scenery.
func cast_origin() -> Vector3:
	var from := global_position + Vector3(0, 1.2, 0)
	var tip := staff_tip()
	var q := PhysicsRayQueryParameters3D.create(from, tip, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return tip
	return (hit.position as Vector3) - (tip - from).normalized() * 0.12


func is_alive() -> bool:
	return state != DEAD


func has_float() -> bool:
	return GameState.has_unlock(&"levitate")


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


func move_input() -> Vector3:
	if not input_enabled:
		return Vector3.ZERO
	var v := Vector3(Input.get_axis(&"move_left", &"move_right"), 0, Input.get_axis(&"up", &"down"))
	return v.normalized() if v.length() > 1.0 else v


# ------------------------------------------------------------------ physics
func _physics_process(delta: float) -> void:
	_state_t += delta
	_iframes = maxf(0.0, _iframes - delta)
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	_bell_cd = maxf(0.0, _bell_cd - delta)
	_ward_t = maxf(0.0, _ward_t - delta)
	_release_t = maxf(0.0, _release_t - delta)
	_input_grace -= delta
	if _attack_needs_release and not Input.is_action_pressed(&"attack"):
		_attack_needs_release = false
	if guard_t > 0.0:
		guard_t -= delta
		if guard_t <= 0.0:
			guard_mult = 1.0
	if levitating:
		_levitate(delta)
	elif is_on_floor() and state != DASH:
		velocity.y = -0.5
		float_left = float_time()
	else:
		velocity.y -= tuning.gravity * delta
	match state:
		NORMAL:
			_normal(delta)
		DODGE:
			_dodge(delta)
		DASH:
			_spell_dash(delta)
		HURT:
			_brake(tuning.decel * 0.3, delta)
			if _state_t >= tuning.hurt_time:
				state = NORMAL
		DEAD, LOCKED:
			_brake(tuning.decel, delta)
	Steps.move(self)
	_check_ground()
	_find_focus()
	_animate(delta)


func _brake(rate: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)
	velocity.z = move_toward(velocity.z, 0.0, rate * delta)


func _normal(delta: float) -> void:
	var input := move_input()
	var speed := tuning.run_speed * statuses.move_scale()
	if caster.state == SpellCaster.WINDUP:
		speed *= tuning.cast_move_mult
	var target := input * speed
	var rate := tuning.accel if input != Vector3.ZERO else tuning.decel
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	if input.length() > 0.1 and not caster.busy() and _release_t <= 0.0:
		look_dir = input.normalized()
		if absf(input.x) > 0.1:
			face(int(signf(input.x)))

	if _just(&"dodge") and _dodge_cd <= 0.0:
		_end_levitate()
		_start_dodge(input)
		return
	if has_float() and not levitating and _just(&"jump") and float_left > 0.2:
		_start_levitate()
	elif levitating and not _held(&"jump"):
		_end_levitate()
	if _just(&"interact") and focus and not levitating:
		focus.activate(self)
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


# ------------------------------------------------------------------ levitate
func _start_levitate() -> void:
	levitating = true
	_float_base = global_position.y
	floor_snap_length = 0.0
	Sfx.play("levitate", -6.0)
	FX3.ring(global_position + Vector3(0, 0.05, 0), 0.2, 0.9, 0.3, Pal.HEAL, 1.0)


func _end_levitate() -> void:
	if levitating:
		levitating = false
		floor_snap_length = 0.4


func _levitate(delta: float) -> void:
	float_left -= delta
	var ground := SpellEffect.ground_at(global_position + Vector3(0, 0.5, 0), self).y
	# hold altitude over drops (chasms), rise over bumps
	var want := maxf(ground, _float_base) + tuning.float_height + sin(_state_t * 5.0) * 0.05
	velocity.y = (want - global_position.y) * 8.0
	if randf() < delta * 30.0:
		FX3.burst(global_position + Vector3(randf_range(-0.3, 0.3), 0.1, randf_range(-0.2, 0.2)), 1, Pal.HEAL, Vector2(0.2, 0.6), Vector2(0.3, 0.5), {"dir": Vector3.DOWN, "spread": 1.0})
	if float_left <= 0.0:
		_end_levitate()


## Chasms (Region.hazards) swallow anyone walking in: back to the last safe
## ground with a little damage. Levitating crosses them.
func _check_ground() -> void:
	var r := Region.current
	if r == null or state == DEAD:
		return
	var over := r.is_hazard(global_position)
	if levitating or state == DASH:
		return
	if over:
		health.damage(5.0)
		_flash = 0.6
		FX3.burst(global_position + Vector3(0, 0.3, 0), 12, Pal.DUST, Vector2(1.0, 3.0), Vector2(0.3, 0.5), {"gravity": 6.0})
		Sfx.play("hurt", -6.0)
		global_position = _last_safe
		velocity = Vector3.ZERO
		_iframes = maxf(_iframes, 0.6)
		if health.is_dead():
			_die()
	elif is_on_floor():
		_last_safe = global_position


func _find_focus() -> void:
	focus = null
	if state != NORMAL or not input_enabled:
		return
	var bd := INF
	for it: Interactable in get_tree().get_nodes_in_group(&"interactable"):
		if not it.enabled or not it.is_visible_in_tree():
			continue
		var d := SpellEffect.flat(global_position, it.global_position)
		if d < it.radius and d < bd:
			bd = d
			focus = it


func _start_dodge(input: Vector3) -> void:
	caster.interrupt()
	state = DODGE
	_state_t = 0.0
	_dodge_t = tuning.dodge_time
	_dodge_dir = input.normalized() if input.length() > 0.1 else look_dir
	if absf(_dodge_dir.x) > 0.1:
		face(int(signf(_dodge_dir.x)))
	_dodge_rewarded = false
	_iframes = maxf(_iframes, tuning.dodge_iframes)
	sprite.play(&"dodge", true)
	Sfx.play("dodge", -4.0)
	FX3.burst(global_position + Vector3(0, 0.1, 0), 8, Pal.DUST, Vector2(1.0, 3.0), Vector2(0.2, 0.4), {"dir": -_dodge_dir + Vector3(0, 0.3, 0), "spread": 1.2, "gravity": 4.0})


func _dodge(delta: float) -> void:
	_dodge_t -= delta
	var inv := GameState.inv
	var sp := tuning.dodge_speed * ((1.0 + 0.12 * inv.tier_mult("robe")) if inv.robe_id() == &"mistcloak" else 1.0) * (0.55 + 0.45 * _dodge_t / tuning.dodge_time)
	velocity.x = _dodge_dir.x * sp
	velocity.z = _dodge_dir.z * sp
	_trail_ghosts(delta, Color(0.5, 0.85, 1.0))
	if _dodge_t <= 0.0:
		state = NORMAL
		_dodge_cd = maxf(0.1, tuning.dodge_cooldown - GameState.inv.relic(&"gale_feather"))
		if inv.robe_id() == &"wardweave":
			_ward_t = 1.5
			FX3.ring(global_position + Vector3(0, 0.05, 0), 0.2, 0.8, 0.25, Pal.MANA, 1.0)
		velocity.x *= 0.4
		velocity.z *= 0.4


func _trail_ghosts(delta: float, col: Color) -> void:
	_ghost_t -= delta
	if _ghost_t <= 0.0:
		_ghost_t = 0.04
		sprite.afterimage(col, 0.2)


## Spell-driven dash (Slipstream): fixed velocity, invulnerable, calls
## `on_step` every physics frame so the spell can hit things it passes.
func spell_dash(v: Vector3, time: float, on_step: Callable) -> void:
	state = DASH
	_state_t = 0.0
	_dash_v = Vector3(v.x, 0.0, v.z)
	_dash_t = time
	_dash_step = on_step
	_iframes = maxf(_iframes, time + 0.05)
	if absf(v.x) > 0.1:
		face(int(signf(v.x)))
	look_dir = SpellEffect.flat_dir(v, look_dir)


func _spell_dash(delta: float) -> void:
	_dash_t -= delta
	velocity.x = _dash_v.x
	velocity.z = _dash_v.z
	if _dash_step.is_valid():
		_dash_step.call()
	_trail_ghosts(delta, Color(0.7, 0.95, 1.0))
	if _dash_t <= 0.0:
		state = NORMAL
		velocity.x = _dash_v.x * 0.3
		velocity.z = _dash_v.z * 0.3


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
			FX3.ring(center(), 0.2, 0.9, 0.3, Pal.MANA, 1.0, false)
			FX3.burst(center(), 10, Pal.MANA, Vector2(1.2, 3.3), Vector2(0.2, 0.4))
		return
	if not spirits.is_empty() and d.active_attack:
		var sp: Node = spirits.pop_front()
		sp.intercept(d)
		_iframes = 0.3
		return
	var bell := GameState.inv.relic(&"ward_bell")
	if bell > 0.0 and _bell_cd <= 0.0 and randf() < bell:
		_bell_cd = 6.0
		_iframes = 0.4
		Sfx.play("hex_block", 0.0)
		FX3.ring(center(), 0.1, 1.2, 0.35, [Color("fff4c8"), Color("f0d890"), Color("a08850")], 2.0, false)
		FX3.burst(center(), 12, [Color("fff4c8"), Color("f0d890")], Vector2(1.0, 3.0), Vector2(0.2, 0.4))
		return
	caster.interrupt()
	_end_levitate()
	var amount := d.amount * guard_mult
	if _ward_t > 0.0:
		_ward_t = 0.0
		amount *= 1.0 - 0.4 * GameState.inv.tier_mult("robe")
		FX3.ring(center(), 0.1, 0.8, 0.2, Pal.MANA, 1.0, false)
	health.damage(amount)
	_flash = 0.75
	_iframes = tuning.hurt_iframes
	var kb := d.knockback
	if kb == Vector3.ZERO:
		kb = SpellEffect.push(d.hit_pos, global_position, 5.0, 3.0)
	velocity = kb
	TimeCtl.hitstop(0.06)
	GameCamera3D.shake_all(4.0)
	FX3.burst(center(), 10, Pal.DANGER, Vector2(1.6, 5.0), Vector2(0.15, 0.35), {"gravity": 8.0})
	if health.is_dead():
		_die()
	else:
		state = HURT
		_state_t = 0.0
		sprite.play(&"hurt", true)
		Sfx.play("hurt", -2.0)


func _die() -> void:
	state = DEAD
	_state_t = 0.0
	sprite.play(&"death", true)
	Sfx.play("player_death")
	died.emit()


func respawn_at(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
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
	_last_safe = pos
	_end_levitate()
	sprite.play(&"idle", true)


func lock(on: bool) -> void:
	if state == DEAD:
		return
	_end_levitate()
	state = LOCKED if on else NORMAL
	if on:
		caster.interrupt()


# ------------------------------------------------------------------ animation
func on_cast_release(_data: SpellData, ctx: CastContext) -> void:
	_release_t = 0.14
	_release_pose = caster.pose_index()
	look_dir = ctx.dir
	sprite.play(StringName("release_%d" % _release_pose), true)


func _animate(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 8.0)
	sprite.set_flash(_flash)
	sprite.set_flip(facing < 0)
	var blink := _iframes > 0.0 and state != DODGE and state != DEAD and state != HURT and state != DASH
	sprite.set_fade(0.5 if blink and int(_iframes * 20.0) % 2 == 0 else 0.0)
	if _shadow:
		_shadow.global_position.y = (SpellEffect.ground_at(global_position + Vector3(0, 0.3, 0), self).y + 0.04) if levitating else global_position.y + 0.04
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
	if levitating:
		sprite.play(&"fall")
	elif Vector2(velocity.x, velocity.z).length() > 0.5:
		sprite.play(&"run")
		var f := sprite.frame
		if (f == 1 or f == 5) and f != _step_frame:
			Sfx.play("step", -14.0, 0.15)
		_step_frame = f
	else:
		sprite.play(&"idle")
