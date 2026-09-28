class_name Enemy3D
extends CharacterBody3D
## Mockup enemy: pixel billboard, health, hit flash, knockback, death.
## Subclasses add behaviour in _ai(delta).

var data: EnemyData
var sprite: PixelBillboard
var health: Health
var facing := -1
var state := &"idle"
var state_t := 0.0
var _flash := 0.0
var _knock := Vector3.ZERO


func _ready() -> void:
	add_to_group(&"enemy3d")
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = maxf(0.3, data.body_size.x * PixelBillboard.PX * 0.5)
	cap.height = maxf(cap.radius * 2.0, data.body_size.y * PixelBillboard.PX)
	cs.shape = cap
	cs.position.y = cap.height * 0.5
	add_child(cs)
	health = Health.new()
	health.max_hp = data.max_hp
	add_child(health)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/%s.json" % data.sheet))
	sprite = PixelBillboard.new()
	sprite.setup(load("res://assets/generated/%s.png" % data.sheet), Vector2i(int(meta.cell[0]), int(meta.cell[1])), int(meta.hframes), meta.anims, data.origin)
	add_child(sprite)
	sprite.play(&"idle")
	add_child(BlobShadow.make(data.body_size.x * PixelBillboard.PX * 1.4))


func center() -> Vector3:
	return global_position + Vector3(0, data.body_size.y * PixelBillboard.PX * 0.5, 0)


func is_alive() -> bool:
	return not health.is_dead()


func player() -> Player3D:
	return get_tree().get_first_node_in_group(&"player") as Player3D


func set_state(s: StringName) -> void:
	state = s
	state_t = 0.0


func take_hit(amount: float, kb: Vector3, school: StringName) -> void:
	if not is_alive():
		return
	health.damage(amount)
	_flash = 1.0
	_knock += Vector3(kb.x, 0, kb.z) * (1.0 - data.knock_resist)
	FX3.burst(center(), 6, Pal.school(school), Vector2(1.5, 4), Vector2(0.12, 0.3), {"gravity": 7.0})
	Sfx.play("hit_flesh", -6.0)
	if not is_alive():
		set_state(&"dead")
		sprite.play(&"death", true)
		Sfx.play("enemy_die", -4.0)
		collision_layer = 0
		for k in data.motes:
			FX3.burst(center(), 6, Pal.MANA, Vector2(1, 3), Vector2(0.4, 0.8), {"gravity": -1.0})
		var tw := create_tween()
		tw.tween_interval(1.6)
		tw.tween_callback(queue_free)
	elif state != &"leap":
		sprite.play(&"hurt", true)


func _physics_process(delta: float) -> void:
	state_t += delta
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	if state != &"dead":
		_ai(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	var saved := velocity
	velocity += _knock
	move_and_slide()
	velocity = Vector3(saved.x, velocity.y, saved.z)
	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	_flash = maxf(0.0, _flash - delta * 9.0)
	sprite.set_flash(_flash)
	sprite.set_flip(facing < 0)


func _ai(_delta: float) -> void:
	if sprite.is_done() or sprite.anim == &"idle":
		sprite.play(&"idle")
	velocity.x = 0.0
	velocity.z = 0.0
	var p := player()
	if p:
		facing = int(signf(p.global_position.x - global_position.x)) if absf(p.global_position.x - global_position.x) > 0.2 else facing
