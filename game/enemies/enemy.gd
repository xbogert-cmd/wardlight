class_name Enemy
extends CharacterBody3D
## Shared enemy behaviour: health, hit reactions, knockback, flinch limits,
## death and mana-mote drops. Subclasses implement `_ai(delta)`.
## `heading` is the horizontal direction the enemy attacks toward; the side
## view sprite flips with `facing` (sign of heading.x).

signal died(enemy: Enemy)
signal hurt(enemy: Enemy, d: Damage)

const PX := 1.0 / 24.0
const MOTE := preload("res://game/items/mote.gd")

@export var data: EnemyData

var health: Health
var statuses: Statuses
var last_hit: Damage
var is_boss := false
var sprite: PixelBillboard
var facing := -1
var heading := Vector3.LEFT
var state := &"idle"
var state_t := 0.0
var home := Vector3.ZERO
var armored := false       # true during committed attacks: no flinch, reduced knockback
var _flinch_cd := 0.0
var _poise_dmg := 0.0
var _flash := 0.0
var _knock := Vector3.ZERO


func _ready() -> void:
	add_to_group(&"enemy")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	home = global_position
	health = Health.new()
	health.max_hp = data.max_hp
	add_child(health)
	statuses = Statuses.new()
	statuses.owner_actor = self
	statuses.root_resist = data.params.get("root_resist", 0.0)
	add_child(statuses)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius()
	cap.height = maxf(cap.radius * 2.0, height())
	cs.shape = cap
	cs.position.y = cap.height * 0.5
	add_child(cs)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/%s.json" % data.sheet))
	sprite = PixelBillboard.new()
	sprite.setup(load("res://assets/generated/%s.png" % data.sheet), Vector2i(int(meta.cell[0]), int(meta.cell[1])), int(meta.hframes), meta.anims, data.origin)
	add_child(sprite)
	sprite.play(&"idle")
	add_child(BlobShadow.make(maxf(0.7, data.body_size.x * PX * 1.4)))
	var ov := StatusOverlay.new()
	ov.actor = self
	add_child(ov)
	_setup()


## Subclass hook for extra nodes.
func _setup() -> void:
	pass


func player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func center() -> Vector3:
	return global_position + Vector3(0, height() * 0.5, 0)


func radius() -> float:
	return maxf(0.3, data.body_size.x * PX * 0.5)


func height() -> float:
	return data.body_size.y * PX


func is_alive() -> bool:
	return not health.is_dead()


func set_state(s: StringName) -> void:
	state = s
	state_t = 0.0


func face_toward(p: Vector3) -> void:
	heading = SpellEffect.flat_dir(p - global_position, heading)
	if absf(heading.x) > 0.15:
		facing = int(signf(heading.x))


## Horizontal distance to a point.
func dist_to(p: Vector3) -> float:
	return SpellEffect.flat(global_position, p)


## Steer toward a horizontal velocity.
func steer(v: Vector3, rate: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, v.x, rate * delta)
	velocity.z = move_toward(velocity.z, v.z, rate * delta)


func take_hit(d: Damage) -> void:
	if not is_alive():
		return
	last_hit = d
	health.damage(block_scale(d) * d.amount)
	_flash = 1.0 if not d.is_proc else 0.5
	var kb := d.knockback * (1.0 - data.knock_resist) * (0.3 if armored else 1.0)
	_knock += Vector3(kb.x, 0.0, kb.z)
	if kb.y > 0.0 and not armored:
		velocity.y = maxf(velocity.y, kb.y)
	_poise_dmg += d.stagger
	if not d.is_proc or d.spell_id != &"":
		FX3.burst(center(), 5, Pal.school(d.school), Vector2(1.2, 3.8), Vector2(0.12, 0.3), {"gravity": 6.0})
	hurt.emit(self, d)
	if not is_alive():
		_die()
		return
	if not (d.is_proc and d.spell_id == &""):
		Sfx.play("hit_flesh", -6.0 if not d.is_proc else -12.0)
	if _poise_dmg >= data.poise and _flinch_cd <= 0.0 and not armored:
		_poise_dmg = 0.0
		_flinch_cd = data.flinch_cooldown
		_flinch()


## Damage multiplier for incoming hits (shields/armour override this).
func block_scale(_d: Damage) -> float:
	return 1.0


## Default flinch: short interrupt. Subclasses may override.
func _flinch() -> void:
	set_state(&"flinch")
	sprite.play(&"hurt", true)


func _die() -> void:
	set_state(&"dead")
	armored = false
	collision_layer = 0
	sprite.play(&"death", true)
	Sfx.play("enemy_die", -4.0)
	FX3.burst(center(), 14, Pal.SMOKE, Vector2(0.4, 1.6), Vector2(0.4, 0.8), {"gravity": -1.2, "jitter": 0.25})
	for k in data.motes:
		var m: Node3D = MOTE.new()
		m.set("velocity", Vector3(randf_range(-2.8, 2.8), randf_range(3.5, 6.0), randf_range(-2.8, 2.8)))
		get_parent().add_child.call_deferred(m)
		m.set_deferred("global_position", center())
	died.emit(self)
	Interactions.on_enemy_died(self, last_hit)
	Events.enemy_killed.emit(self, last_hit)
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_method(sprite.set_fade, 0.0, 1.0, 0.5)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	state_t += delta
	_flinch_cd = maxf(0.0, _flinch_cd - delta)
	_poise_dmg = maxf(0.0, _poise_dmg - delta * data.poise * 0.35)
	if is_on_floor() and velocity.y <= 0.0:
		velocity.y = -0.5
	else:
		velocity.y -= 22.0 * delta
	if state != &"dead":
		_ai(delta)
		var ms := statuses.move_scale()
		velocity.x *= ms
		velocity.z *= ms
		_separate()
	else:
		steer(Vector3.ZERO, 25.0, delta)
	var ai_v := velocity
	velocity += _knock
	move_and_slide()
	velocity = Vector3(ai_v.x, velocity.y, ai_v.z)
	_knock = _knock.move_toward(Vector3.ZERO, 38.0 * delta)
	_flash = maxf(0.0, _flash - delta * 9.0)
	sprite.set_flash(_flash)
	sprite.set_flip(facing < 0)


## Soft push apart so packs don't stack on one spot.
## ponytail: O(n²) over live enemies; fine for encounters under ~30.
func _separate() -> void:
	for e: Node3D in SpellEffect.enemies():
		if e == self:
			continue
		var v := global_position - e.global_position
		v.y = 0.0
		var min_d: float = radius() + e.radius()
		var d := v.length()
		if d < min_d and d > 0.001:
			var push := v / d * (min_d - d) * 6.0
			velocity.x += push.x
			velocity.z += push.z


func _ai(_delta: float) -> void:
	pass


func anim(n: StringName) -> void:
	sprite.play(n)
