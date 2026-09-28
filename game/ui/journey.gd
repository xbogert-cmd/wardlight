class_name Journey
extends CanvasLayer
## Animated journey for distant travel: parallax scenery scrolls past a
## walking wizard silhouette while the destination loads on a background
## thread. The load status is polled every frame (never blocking), with a
## short floor so the trip reads as a trip. A failed load shows a message
## and returns null so the caller can stay put.

signal done

const FONT := preload("res://assets/fonts/wardhand.tres")
const MIN_TIME := 2.4
const TIMEOUT := 20.0

var canvas: Control
var _layers: Array[Texture2D] = []
var _t := 0.0
var _title := ""
var _sub := ""
var _failed := false
var _art: Dictionary
var _frames: Array = []


func _ready() -> void:
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_scene)
	add_child(canvas)
	visible = false


## Returns the loaded resource at `path`, or null if loading failed.
func run(title: String, sub: String, region_look: String, path: String) -> Resource:
	_title = title
	_sub = sub
	_failed = false
	_t = 0.0
	_layers.clear()
	for k in ["sky", "far", "mid", "near"]:
		_layers.append(load("res://assets/generated/bg_%s_%s.png" % [region_look, k]))
	_art = WizardArt.build(GameState.appearance)
	_frames = _art.anims.run.frames
	visible = true
	var err := ResourceLoader.load_threaded_request(path)
	var res: Resource = null
	while true:
		await get_tree().process_frame
		var status := ResourceLoader.load_threaded_get_status(path) if err == OK else ResourceLoader.THREAD_LOAD_FAILED
		if status == ResourceLoader.THREAD_LOAD_LOADED and _t >= MIN_TIME:
			res = ResourceLoader.load_threaded_get(path)
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or _t > TIMEOUT:
			_failed = true
			await _wait_confirm()
			break
	visible = false
	done.emit()
	return res


func _wait_confirm() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed(&"ui_accept") or Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"pause"):
			return


func _process(delta: float) -> void:
	if visible:
		_t += delta
		canvas.queue_redraw()


func _draw_scene() -> void:
	canvas.draw_rect(Rect2(0, 0, 640, 360), Color("0a0812"))
	var speeds := [4.0, 14.0, 40.0, 90.0]
	for k in _layers.size():
		var tex := _layers[k]
		var off := fmod(_t * speeds[k], float(tex.get_width()))
		for x in [-off, tex.get_width() - off]:
			canvas.draw_texture(tex, Vector2(roundf(x), 360 - tex.get_height()))
	# walking wizard silhouette with a faint staff glow
	var f: int = _frames[int(_t * 10.0) % _frames.size()]
	var cell := Vector2(WizardArt.CELL_W, WizardArt.CELL)
	var src := Rect2(Vector2((f % WizardArt.COLS) * cell.x, (f / WizardArt.COLS) * cell.y), cell)
	var at := Vector2(250, 300) - Vector2(WizardArt.FOOT)
	canvas.draw_texture_rect_region(_art.texture, Rect2(at, cell), src, Color(0.05, 0.04, 0.09))
	var tip: Vector2 = _art.tips[f]
	canvas.draw_texture(SpellEffect.GLOW_S, Vector2(250, 300) + tip - Vector2(8, 8), Color(0.5, 0.85, 1.0, 0.8))
	canvas.draw_rect(Rect2(0, 300, 640, 60), Color(0.03, 0.02, 0.05, 0.85))
	var a := clampf(_t * 2.0, 0.0, 1.0)
	_text(_title, Vector2(0, 322), Color(1.0, 0.92, 0.75, a))
	_text(_sub, Vector2(0, 336), Color(0.75, 0.68, 0.55, a))
	if _failed:
		HUD.frame(canvas, Rect2(190, 150, 260, 40))
		_text("The way is lost in the mist.", Vector2(0, 166), Color("ff9a8a"))
		_text("Enter: turn back", Vector2(0, 180), Color("c8b898"))
	else:
		var dots := ".".repeat(1 + int(_t * 2.0) % 3)
		canvas.draw_string(FONT, Vector2(560, 348), dots, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.68, 0.55, a))


func _text(s: String, pos: Vector2, col: Color) -> void:
	canvas.draw_string(FONT, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0, 0, 0, col.a * 0.7))
	canvas.draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_CENTER, 640, 9, col)
