class_name PixelBillboard
extends MeshInstance3D
## A camera-facing pixel sprite in 3D (1 texel = 1/24 m), lit with banded
## lighting. Plays animations from our generated sheets (same anim tables
## as the 2D game): {name: {frames: [...], fps, loop}}.

const PX := 1.0 / 24.0
const SHADER := preload("res://game3d/sprite_lit.gdshader")

var sheet: Texture2D
var cell := Vector2i(16, 16)
var hframes := 1
var anims := {}
var foot := Vector2(8, 16)       # pixel in the cell that sits on the node origin
var flip := false
var anim := &""
var frame := 0
var _t := 0.0
var _playing := false
var mat: ShaderMaterial


func setup(tex: Texture2D, cell_size: Vector2i, cols: int, anim_table: Dictionary, foot_px: Vector2) -> PixelBillboard:
	sheet = tex
	cell = cell_size
	hframes = cols
	anims = anim_table
	foot = foot_px
	var q := QuadMesh.new()
	q.size = Vector2(cell.x, cell.y) * PX
	mesh = q
	_place_origin()
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"tex", tex)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if anims.is_empty():
		_apply(0)
	return self


## Single still image (props, trees).
static func still(tex: Texture2D, foot_px: Vector2 = Vector2(-1, -1)) -> PixelBillboard:
	var b := PixelBillboard.new()
	var sz := Vector2i(tex.get_width(), tex.get_height())
	var f := foot_px if foot_px.x >= 0.0 else Vector2(sz.x * 0.5, sz.y)
	b.setup(tex, sz, 1, {}, f)
	return b


func play(n: StringName, restart: bool = false) -> void:
	if n == anim and _playing and not restart:
		return
	anim = n
	frame = 0
	_t = 0.0
	_playing = true
	_apply_anim()


func is_done() -> bool:
	return not _playing


func _process(delta: float) -> void:
	if not _playing or anims.is_empty():
		return
	var a: Dictionary = anims.get(String(anim), {})
	if a.is_empty():
		return
	_t += delta
	var spf := 1.0 / float(a.fps)
	while _t >= spf:
		_t -= spf
		frame += 1
		if frame >= (a.frames as Array).size():
			if a.loop:
				frame = 0
			else:
				frame = (a.frames as Array).size() - 1
				_playing = false
	_apply_anim()


func global_frame() -> int:
	var a: Dictionary = anims.get(String(anim), {})
	return int(a.frames[frame]) if not a.is_empty() else 0


func _apply_anim() -> void:
	_apply(global_frame())


func _apply(f: int) -> void:
	var tw := float(sheet.get_width())
	var th := float(sheet.get_height())
	var x := float((f % hframes) * cell.x) / tw
	var y := float((f / hframes) * cell.y) / th
	var w := float(cell.x) / tw
	var h := float(cell.y) / th
	if flip:
		mat.set_shader_parameter(&"region", Vector4(x + w, y, -w, h))
	else:
		mat.set_shader_parameter(&"region", Vector4(x, y, w, h))


func set_flip(v: bool) -> void:
	if v != flip:
		flip = v
		_place_origin()
		_apply_anim()


## Put the foot pixel on the node origin (mirrored when flipped).
func _place_origin() -> void:
	var fx := cell.x - foot.x if flip else foot.x
	(mesh as QuadMesh).center_offset = Vector3((cell.x * 0.5 - fx) * PX, (foot.y - cell.y * 0.5) * PX, 0)


func set_flash(v: float) -> void:
	mat.set_shader_parameter(&"flash", v)
