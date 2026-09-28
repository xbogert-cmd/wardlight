class_name OcclusionFader
extends Node
## Dithers out tall scenery (trees, big props) standing between the camera
## and the wizard, so the player is never lost behind a pine.

const FADED := 0.6

var target: Node3D
var items: Array[PixelBillboard] = []
var _t := 0.0
var _fade := {}          # billboard -> current fade


func add(b: PixelBillboard) -> void:
	items.append(b)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or target == null or not is_instance_valid(target):
		return
	_t -= delta
	if _t > 0.0:
		_animate(delta)
		return
	_t = 0.1
	var tp := cam.unproject_position(target.global_position + Vector3(0, 0.9, 0))
	for b in items:
		var want := 0.0
		# only things nearer the camera than the wizard can hide him
		if b.global_position.z > target.global_position.z + 0.2 and absf(b.global_position.x - target.global_position.x) < 6.0:
			var base := cam.unproject_position(b.global_position)
			var top := cam.unproject_position(b.global_position + Vector3(0, b.cell.y * PixelBillboard.PX * b.scale.y * 1.5, 0))
			var hw := b.cell.x * 0.5 * b.scale.x * 1.1
			if tp.x > base.x - hw and tp.x < base.x + hw and tp.y > top.y and tp.y < base.y + 4.0:
				want = FADED
		_fade[b] = [_fade.get(b, [0.0, 0.0])[0], want]
	_animate(delta)


func _animate(delta: float) -> void:
	for b: PixelBillboard in _fade:
		var f: Array = _fade[b]
		if f[0] != f[1]:
			f[0] = move_toward(f[0], f[1], delta * 4.0)
			b.set_fade(f[0])
