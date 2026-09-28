class_name MeleeBox
extends Node
## An enemy melee swing: hurts the player once per swing while `active` if
## they are within `reach` of the enemy and inside `half_angle` of its heading.

var owner_enemy: Enemy
var reach := 1.4
var half_angle := deg_to_rad(60.0)
var damage := 10.0
var push := 6.0
var hop := 3.0
var active := false
var _hit_this_swing := false


static func make(owner_e: Enemy, reach_m: float, half_deg: float) -> MeleeBox:
	var b := MeleeBox.new()
	b.owner_enemy = owner_e
	b.reach = reach_m
	b.half_angle = deg_to_rad(half_deg)
	owner_e.add_child(b)
	return b


func swing(dmg: float, push_speed: float, hop_speed: float = 3.0) -> void:
	damage = dmg
	push = push_speed
	hop = hop_speed
	active = true
	_hit_this_swing = false


func stop() -> void:
	active = false


func _physics_process(_delta: float) -> void:
	if not active or _hit_this_swing:
		return
	var p := owner_enemy.player()
	if p == null or not p.is_alive():
		return
	var v := p.global_position - owner_enemy.global_position
	v.y = 0.0
	if v.length() > reach + p.radius():
		return
	if v.length() > 0.5 and absf(SpellEffect.flat_dir(v).angle_to(owner_enemy.heading)) > half_angle:
		return
	_hit_this_swing = true
	var d := Damage.make(damage, owner_enemy, &"", owner_enemy.heading * push + Vector3(0, hop, 0))
	d.hit_pos = owner_enemy.global_position
	p.take_hit(d)
