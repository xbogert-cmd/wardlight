class_name MeleeBox
extends Node
## An enemy melee swing: hurts the player (and the companion) once per swing
## while `active` if within `reach` and inside `half_angle` of its heading.

var owner_enemy: Enemy
var reach := 1.4
var half_angle := deg_to_rad(60.0)
var damage := 10.0
var push := 6.0
var hop := 3.0
var active := false
var _hit_this_swing := false
var _hit_ally := false


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
	_hit_ally = false


func stop() -> void:
	active = false


func _physics_process(_delta: float) -> void:
	if not active:
		return
	if not _hit_this_swing and _in_arc(owner_enemy.player()):
		_hit_this_swing = true
		_strike(owner_enemy.player())
	if not _hit_ally:
		for c: Node3D in owner_enemy.get_tree().get_nodes_in_group(&"companion"):
			if _in_arc(c):
				_hit_ally = true
				_strike(c)


func _in_arc(t: Node3D) -> bool:
	if t == null or not t.is_alive():
		return false
	var v := t.global_position - owner_enemy.global_position
	v.y = 0.0
	if v.length() > reach + t.radius():
		return false
	return v.length() <= 0.5 or absf(SpellEffect.flat_dir(v).angle_to(owner_enemy.heading)) <= half_angle


func _strike(t: Node3D) -> void:
	var d := Damage.make(damage, owner_enemy, &"", owner_enemy.heading * push + Vector3(0, hop, 0))
	d.hit_pos = owner_enemy.global_position
	t.take_hit(d)
