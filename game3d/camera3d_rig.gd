class_name GameCamera3D
extends Camera3D
## Diagonal-down follow camera (fixed angle, narrow field of view so the
## world reads like a diorama). Owns screen shake.

static var cur: GameCamera3D

var target: Node3D
var pitch_deg := 50.0
var dist := 25.0
var _shake := 0.0
var _focus := Vector3.ZERO


func _enter_tree() -> void:
	cur = self


func _ready() -> void:
	fov = 30.0
	near = 0.5
	far = 400.0
	make_current()
	if target:
		_focus = target.global_position
		_place(0.0)


## Shake strength in screen pixels (converted to metres at the focus).
static func shake_all(amount_px: float) -> void:
	if cur:
		cur._shake = maxf(cur._shake, amount_px / 24.0 * (0.25 if Settings.reduce_shake else 1.0))


## Jump straight to the target (level entry, respawn).
func snap() -> void:
	if target and is_instance_valid(target):
		_focus = target.global_position + Vector3(0, 1.0, 0)
		_place(0.0)


func _physics_process(delta: float) -> void:
	_place(delta)


var _boss_w := 0.0


## An engaged boss within reach pulls the frame toward itself and widens it.
func _boss() -> Node3D:
	if target == null:
		return null
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if e.is_boss and e.is_alive() and e.get("engaged") and e.global_position.distance_to(target.global_position) < 18.0:
			return e
	return null


func _place(delta: float) -> void:
	if target and is_instance_valid(target):
		var goal := target.global_position + Vector3(0, 1.0, 0)
		var boss := _boss()
		_boss_w = move_toward(_boss_w, 1.0 if boss else 0.0, delta * 1.5)
		if boss:
			var mid := boss.global_position + Vector3(0, float(boss.call("height")) * 0.5, 0)
			goal = goal.lerp(mid, 0.4 * _boss_w)
		_focus = goal if delta == 0.0 else _focus.lerp(goal, 1.0 - exp(-7.0 * delta))
	var p := deg_to_rad(pitch_deg)
	var off := Vector3(0, sin(p), cos(p)) * (dist + 5.0 * smoothstep(0.0, 1.0, _boss_w))
	var sh := Vector3.ZERO
	if _shake > 0.0:
		sh = Vector3(randf_range(-_shake, _shake), randf_range(-_shake, _shake), 0)
		_shake = move_toward(_shake, 0.0, delta * 1.5)
	global_position = _focus + off + sh
	look_at(_focus + sh, Vector3.UP)
