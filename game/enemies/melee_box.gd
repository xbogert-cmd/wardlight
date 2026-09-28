class_name MeleeBox
extends Area2D
## An enemy attack hitbox that only hurts while `active`, once per swing.

var owner_enemy: Node2D
var damage := 10.0
var knockback := Vector2(160, -140)
var active := false
var _hit_this_swing := false


static func make(parent: Node2D, owner_e: Node2D, size: Vector2, offset: Vector2) -> MeleeBox:
	var b := MeleeBox.new()
	b.owner_enemy = owner_e
	b.collision_layer = 0
	b.collision_mask = 2
	b.monitorable = false
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = offset
	b.add_child(cs)
	parent.add_child(b)
	return b


func swing(dmg: float, kb: Vector2) -> void:
	damage = dmg
	knockback = kb
	active = true
	_hit_this_swing = false


func stop() -> void:
	active = false


func _physics_process(_delta: float) -> void:
	if not active or _hit_this_swing:
		return
	for b in get_overlapping_bodies():
		if b is Player and b.is_alive():
			_hit_this_swing = true
			var d := Damage.make(damage, owner_enemy, &"", Vector2(knockback.x * owner_enemy.facing, knockback.y))
			d.hit_pos = owner_enemy.global_position
			b.take_hit(d)
