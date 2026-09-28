class_name Enemy
extends CharacterBody2D
## Shared enemy behaviour: health, hit reactions, knockback, flinch limits,
## death and mana-mote drops. Subclasses implement `_ai(delta)`.

signal died(enemy: Enemy)
signal hurt(enemy: Enemy, d: Damage)

const MOTE := preload("res://game/items/mote.gd")

@export var data: EnemyData

var health: Health
var sprite: AnimatedSprite2D
var visual: Node2D
var flash_mat: ShaderMaterial
var facing := -1
var state := &"idle"
var state_t := 0.0
var gravity := 900.0
var home := Vector2.ZERO
var armored := false       # true during committed attacks: no flinch, reduced knockback
var _flinch_cd := 0.0
var _poise_dmg := 0.0
var _flash := 0.0
var _knock := Vector2.ZERO


func _ready() -> void:
	add_to_group(&"enemy")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(47.0)
	floor_constant_speed = true
	home = global_position
	health = Health.new()
	health.max_hp = data.max_hp
	add_child(health)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = data.body_size
	cs.shape = sh
	cs.position = Vector2(0, -data.body_size.y * 0.5)
	add_child(cs)
	visual = Node2D.new()
	add_child(visual)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SheetFrames.load_sheet(data.sheet)
	sprite.centered = false
	sprite.offset = -data.origin
	flash_mat = ShaderMaterial.new()
	flash_mat.shader = preload("res://game/combat/flash.gdshader")
	sprite.material = flash_mat
	visual.add_child(sprite)
	sprite.play(&"idle")
	_setup()


## Subclass hook for extra nodes.
func _setup() -> void:
	pass


func player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func center() -> Vector2:
	return global_position + Vector2(0, -data.body_size.y * 0.5)


func hurt_rect() -> Rect2:
	return Rect2(global_position - Vector2(data.body_size.x * 0.5, data.body_size.y), data.body_size)


func is_alive() -> bool:
	return not health.is_dead()


func set_state(s: StringName) -> void:
	state = s
	state_t = 0.0


func face_toward(x: float) -> void:
	var d := signf(x - global_position.x)
	if d != 0.0:
		facing = int(d)


func take_hit(d: Damage) -> void:
	if not is_alive():
		return
	health.damage(d.amount)
	_flash = 1.0
	var kb := d.knockback * (1.0 - data.knock_resist) * (0.3 if armored else 1.0)
	_knock.x += kb.x
	if kb.y < 0.0 and not armored:
		velocity.y = minf(velocity.y, kb.y)
	_poise_dmg += d.stagger
	FX.burst(center(), 5, Pal.school(d.school), Vector2(30, 90), Vector2(0.12, 0.3), {"gravity": 150.0})
	hurt.emit(self, d)
	if not is_alive():
		_die()
		return
	Sfx.play("hit_flesh", -6.0)
	if _poise_dmg >= data.poise and _flinch_cd <= 0.0 and not armored:
		_poise_dmg = 0.0
		_flinch_cd = data.flinch_cooldown
		_flinch()


## Default flinch: short interrupt. Subclasses may override.
func _flinch() -> void:
	set_state(&"flinch")
	sprite.play(&"hurt")


func _die() -> void:
	set_state(&"dead")
	armored = false
	collision_layer = 0
	sprite.play(&"death")
	Sfx.play("enemy_die", -4.0)
	FX.burst(center(), 14, Pal.SMOKE, Vector2(10, 40), Vector2(0.4, 0.8), {"add": false, "gravity": -30.0, "front": false, "jitter": 6.0})
	for k in data.motes:
		var m := MOTE.new()
		m.position = center()
		m.velocity = Vector2(randf_range(-70, 70), randf_range(-150, -80))
		get_parent().add_child.call_deferred(m)
	died.emit(self)
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	state_t += delta
	_flinch_cd = maxf(0.0, _flinch_cd - delta)
	_poise_dmg = maxf(0.0, _poise_dmg - delta * data.poise * 0.35)
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 420.0)
	if state != &"dead":
		_ai(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	var ai_vx := velocity.x
	velocity.x = ai_vx + _knock.x
	move_and_slide()
	velocity.x = ai_vx
	_knock.x = move_toward(_knock.x, 0.0, 900.0 * delta)
	_flash = maxf(0.0, _flash - delta * 9.0)
	flash_mat.set_shader_parameter(&"flash", _flash)
	visual.scale.x = facing


func _ai(_delta: float) -> void:
	pass


func anim(name: StringName) -> void:
	if sprite.animation != name:
		sprite.play(name)
