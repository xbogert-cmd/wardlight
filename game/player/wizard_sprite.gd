class_name WizardSprite
extends Node2D
## The wizard's body, rebuilt from the appearance whenever it changes.
## Flipping is done with scale.x so the feet stay on the node origin.

var anim: AnimatedSprite2D
var art: Dictionary
var look := {}
var flash_mat: ShaderMaterial


func _ready() -> void:
	anim = AnimatedSprite2D.new()
	anim.centered = false
	anim.offset = -Vector2(WizardArt.FOOT)
	flash_mat = ShaderMaterial.new()
	flash_mat.shader = preload("res://game/combat/flash.gdshader")
	anim.material = flash_mat
	add_child(anim)
	if art.is_empty():
		set_look(look)


func set_look(l: Dictionary) -> void:
	look = l
	art = WizardArt.build(l)
	var sf := SheetFrames.from_texture(art.texture, Vector2i(WizardArt.CELL_W, WizardArt.CELL), WizardArt.COLS, art.anims)
	var cur := anim.animation if anim.sprite_frames else &"idle"
	anim.sprite_frames = sf
	anim.play(cur)


func play(name: StringName) -> void:
	if anim.animation != name or not anim.is_playing():
		anim.play(name)


func restart(name: StringName) -> void:
	anim.play(name)
	anim.frame = 0


func is_done() -> bool:
	return not anim.is_playing()


## Staff gem position relative to the feet, respecting facing.
func tip() -> Vector2:
	var info: Dictionary = art.anims.get(String(anim.animation), {})
	if info.is_empty():
		return Vector2(6, -44)
	var frames: PackedInt32Array = info.frames
	var t: Vector2 = art.tips[frames[clampi(anim.frame, 0, frames.size() - 1)]]
	return Vector2(t.x * scale.x, t.y)


func set_flash(v: float) -> void:
	flash_mat.set_shader_parameter(&"flash", v)
