class_name Spore
extends Enemy
## A Hollow Moth's spore: drifts after the wizard, turning slowly (sidestep
## it), bursts on contact, and pops to any hit (1 HP). No rewards.

var speed := 3.2
var target: Node3D
var _dir := Vector3.ZERO
var _life := 7.0


func _setup() -> void:
	_life = data.params.get("life", 7.0)
	set_state(&"drift")
	if target:
		_dir = (target.center() - global_position).normalized()


func _ai(delta: float) -> void:
	_life -= delta
	anim(&"idle")
	if _life <= 0.0 or not is_instance_valid(target) or not target.is_alive():
		health.damage(99.0)
		_die()
		return
	var want: Vector3 = (target.center() - global_position).normalized()
	_dir = _dir.slerp(want, clampf(float(data.params.get("turn", 1.6)) * delta, 0.0, 1.0)).normalized() if _dir != Vector3.ZERO else want
	velocity = _dir * speed
	if global_position.distance_to(target.center()) < 0.55:
		var d := Damage.make(data.damage, self, &"", _dir * 3.0 + Vector3(0, 2.0, 0))
		d.hit_pos = global_position
		target.take_hit(d)
		health.damage(99.0)
		_die()


func _rewards() -> void:
	pass


func _flinch() -> void:
	pass
