class_name TitleBackdrop
extends CanvasLayer
## Title screen art: slow parallax woods under the moon, the wizard's
## silhouette on a rise with a glowing staff, and the Wardlight logo.

const FONT := preload("res://assets/fonts/wardhand.tres")

var canvas: Control
var _layers: Array[Texture2D] = []
var _art: Dictionary
var _t := 0.0


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	for k in ["sky", "far", "mid", "near"]:
		_layers.append(load("res://assets/generated/bg_woods_%s.png" % k))
	_art = WizardArt.build(WizardArt.DEFAULT_LOOK)
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_title)
	add_child(canvas)


func _process(delta: float) -> void:
	_t += delta
	canvas.queue_redraw()


func _draw_title() -> void:
	canvas.draw_rect(Rect2(0, 0, 640, 360), Color("0a0812"))
	var speeds := [1.0, 3.0, 8.0, 16.0]
	for k in _layers.size():
		var tex := _layers[k]
		var off := fmod(_t * speeds[k], float(tex.get_width()))
		for x in [-off, tex.get_width() - off]:
			canvas.draw_texture(tex, Vector2(roundf(x), 360 - tex.get_height()))
	canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.35))
	# the wizard, dark against the sky, staff glowing
	var frames: Array = _art.anims.idle.frames
	var f: int = frames[int(_t * 4.0) % frames.size()]
	var cell := Vector2(WizardArt.CELL_W, WizardArt.CELL)
	var src := Rect2(Vector2((f % WizardArt.COLS) * cell.x, (f / WizardArt.COLS) * cell.y), cell)
	var foot := Vector2(470, 300)
	canvas.draw_texture_rect_region(_art.texture, Rect2(foot - Vector2(WizardArt.FOOT) * 2.0, cell * 2.0), src, Color(0.06, 0.05, 0.1))
	var tip: Vector2 = _art.tips[f]
	var pulse := 0.8 + 0.2 * sin(_t * 3.0)
	canvas.draw_texture(SpellEffect.GLOW_M, foot + tip * 2.0 - Vector2(16, 16), Color(0.5, 0.85, 1.0, pulse))
	canvas.draw_texture(SpellEffect.GLOW_L, foot + tip * 2.0 - Vector2(32, 32), Color(0.4, 0.7, 1.0, 0.35 * pulse))
	# logo, drawn at 4x with a soft shadow
	canvas.draw_set_transform(Vector2(40, 70), 0.0, Vector2(4, 4))
	canvas.draw_string(FONT, Vector2(1, 1), "WARDLIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.7))
	canvas.draw_string(FONT, Vector2.ZERO, "WARDLIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f4d890"))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	canvas.draw_string(FONT, Vector2(44, 92), "a wizard of the ward-roads", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a89878"))
