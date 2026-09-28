class_name GameCamera
extends Camera2D
## Follows the player with a little look-ahead; owns screen shake.

static var current_cam: GameCamera

var target: Node2D
var look_ahead := 26.0
var _shake := 0.0
var _look := 0.0


func _enter_tree() -> void:
	current_cam = self


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	make_current()


static func shake_all(amount: float) -> void:
	if current_cam:
		current_cam.shake(amount)


func shake(amount: float) -> void:
	if Settings.reduce_shake:
		amount *= 0.25
	_shake = maxf(_shake, amount)


func snap_to_target() -> void:
	if target:
		global_position = target.global_position + Vector2(0, -28)
		reset_smoothing()


func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		var f: float = target.get("facing") if target.get("facing") != null else 1.0
		_look = move_toward(_look, f * look_ahead, 60.0 * delta)
		global_position = target.global_position + Vector2(_look, -28)
	if _shake > 0.0:
		offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)).round()
		_shake = move_toward(_shake, 0.0, 40.0 * delta)
	else:
		offset = Vector2.ZERO
