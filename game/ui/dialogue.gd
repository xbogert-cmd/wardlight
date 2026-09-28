class_name Dialogue
extends CanvasLayer
## Speech box at the bottom of the screen. The world pauses while it is open.
## `await Dialogue.i.talk([[who, text], ...])` or
## `var k: int = await Dialogue.i.choose(who, text, ["A", "B"])`.
## E / Space / Enter / click advances (first press finishes the line);
## Up/Down + Enter picks a choice. "{name}" becomes the wizard's name.

signal _next

static var i: Dialogue

const FONT := preload("res://assets/fonts/wardhand.tres")
const BOX := Rect2(96, 272, 448, 74)
const CPS := 60.0

var is_open := false
var canvas: Control
var _who := ""
var _text := ""
var _shown := 0.0
var _options: Array = []
var _sel := 0
var _opened_at := 0.0


func _enter_tree() -> void:
	i = self


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_box)
	canvas.visible = false
	add_child(canvas)


func _open() -> void:
	if not is_open:
		is_open = true
		_opened_at = Time.get_ticks_msec() / 1000.0
		get_tree().paused = true
		var p := get_tree().get_first_node_in_group(&"player") as Player
		if p:
			p.input_enabled = false
			p.caster.interrupt()
	canvas.visible = true


func _close() -> void:
	is_open = false
	canvas.visible = false
	get_tree().paused = false
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.resume_input()


func _line(who: String, text: String) -> void:
	_who = who.replace("{name}", GameState.wizard_name)
	_text = text.replace("{name}", GameState.wizard_name)
	_shown = 0.0
	_options = []
	Sfx.play("ui_move", -12.0)


func talk(lines: Array) -> void:
	_open()
	for l: Array in lines:
		_line(l[0], l[1])
		await _next
	_close()


func choose(who: String, text: String, options: Array) -> int:
	_open()
	_line(who, text)
	_shown = float(_text.length())
	_options = options
	_sel = 0
	await _next
	var k := _sel
	_close()
	return k


func _process(delta: float) -> void:
	if not is_open:
		return
	_shown = minf(_shown + delta * CPS, float(_text.length()))
	canvas.queue_redraw()


func _input(e: InputEvent) -> void:
	if not is_open or Time.get_ticks_msec() / 1000.0 - _opened_at < 0.15:
		return
	var confirm: bool = e.is_action_pressed(&"interact") or e.is_action_pressed(&"ui_accept") or e.is_action_pressed(&"jump") \
		or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT)
	if not _options.is_empty():
		if e.is_action_pressed(&"up") or e.is_action_pressed(&"ui_up"):
			_sel = posmod(_sel - 1, _options.size())
			Sfx.play("ui_move", -10.0)
		elif e.is_action_pressed(&"down") or e.is_action_pressed(&"ui_down"):
			_sel = posmod(_sel + 1, _options.size())
			Sfx.play("ui_move", -10.0)
		elif e is InputEventMouseMotion:
			var k := _option_at(canvas.get_local_mouse_position())
			if k >= 0:
				_sel = k
		elif confirm:
			if e is InputEventMouseButton and _option_at(canvas.get_local_mouse_position()) < 0:
				return
			get_viewport().set_input_as_handled()
			_next.emit()
		return
	if confirm:
		get_viewport().set_input_as_handled()
		if _shown < _text.length():
			_shown = _text.length()
		else:
			_next.emit()


func _option_rect(k: int) -> Rect2:
	var n := _options.size()
	return Rect2(BOX.position.x + 280, BOX.position.y - 14 - (n - k) * 14, 168, 13)


func _option_at(p: Vector2) -> int:
	for k in _options.size():
		if _option_rect(k).has_point(p):
			return k
	return -1


func _draw_box() -> void:
	HUD.frame(canvas, BOX)
	if _who != "":
		var nr := Rect2(BOX.position + Vector2(8, -9), Vector2(FONT.get_string_size(_who, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 10, 12))
		HUD.frame(canvas, nr)
		canvas.draw_string(FONT, nr.position + Vector2(5, 9), _who, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f4d890"))
	var shown := _text.substr(0, int(_shown))
	var y := BOX.position.y + 16
	for line in _wrap(shown, BOX.size.x - 20):
		canvas.draw_string(FONT, Vector2(BOX.position.x + 10, y) + Vector2(1, 1), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.6))
		canvas.draw_string(FONT, Vector2(BOX.position.x + 10, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f0e6d0"))
		y += 12
	if not _options.is_empty():
		for k in _options.size():
			var r := _option_rect(k)
			HUD.frame(canvas, r, HUD.COL_BG, Color("f4d890") if k == _sel else HUD.COL_FRAME)
			canvas.draw_string(FONT, r.position + Vector2(6, 9), ("> " if k == _sel else "  ") + String(_options[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
				Color("f4d890") if k == _sel else Color("c8b898"))
	elif _shown >= _text.length() and int(Time.get_ticks_msec() / 400) % 2 == 0:
		canvas.draw_string(FONT, BOX.end - Vector2(14, 6), "v", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f4d890"))


static func _wrap(s: String, width: float) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for word in s.split(" "):
		var t := word if cur == "" else cur + " " + word
		if FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x > width and cur != "":
			out.append(cur)
			cur = word
		else:
			cur = t
	if cur != "":
		out.append(cur)
	return out
