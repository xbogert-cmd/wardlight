class_name MenuPanel
extends CanvasLayer
## A framed list of choices (title, optional text, options). Up/Down or the
## mouse choose, Enter/E/click confirm, Esc cancels (returns -1) when allowed.
## `var k: int = await MenuPanel.ask(parent, "Paused", "", ["Resume", "Quit"])`

signal chosen(index: int)

const FONT := preload("res://assets/fonts/wardhand.tres")

var title := ""
var body := ""
var options: Array = []
var sel := 0
var cancel_index := -1        # what Esc returns (-1: Esc disabled)
var dim := true
var canvas: Control
var _rect := Rect2()


static func ask(parent: Node, t: String, b: String, opts: Array, cancel := -1, backdrop := true) -> int:
	var m := MenuPanel.new()
	m.title = t
	m.body = b
	m.options = opts
	m.cancel_index = cancel
	m.dim = backdrop
	parent.add_child(m)
	var k: int = await m.chosen
	m.queue_free()
	return k


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_menu)
	add_child(canvas)
	var lines := Dialogue._wrap(body, 260) if body != "" else PackedStringArray()
	var w := 300.0
	var h := 30.0 + lines.size() * 11.0 + options.size() * 16.0 + 10.0
	_rect = Rect2(320 - w * 0.5, 180 - h * 0.5, w, h)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_d: float) -> void:
	canvas.queue_redraw()


func _opt_rect(k: int) -> Rect2:
	var lines := Dialogue._wrap(body, 260).size() if body != "" else 0
	return Rect2(_rect.position.x + 20, _rect.position.y + 26 + lines * 11 + k * 16, _rect.size.x - 40, 14)


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		for k in options.size():
			if _opt_rect(k).has_point(canvas.get_local_mouse_position()):
				sel = k
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for k in options.size():
			if _opt_rect(k).has_point(canvas.get_local_mouse_position()):
				_pick(k)
		return
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	get_viewport().set_input_as_handled()
	match (e as InputEventKey).keycode:
		KEY_UP, KEY_W:
			sel = posmod(sel - 1, options.size())
			Sfx.play("ui_move", -10.0)
		KEY_DOWN, KEY_S:
			sel = posmod(sel + 1, options.size())
			Sfx.play("ui_move", -10.0)
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			_pick(sel)
		KEY_ESCAPE:
			if cancel_index >= 0:
				_pick(cancel_index)


func _pick(k: int) -> void:
	Sfx.play("ui_select", -6.0)
	chosen.emit(k)


func _draw_menu() -> void:
	if dim:
		canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.06, 0.6))
	HUD.frame(canvas, _rect)
	canvas.draw_string(FONT, _rect.position + Vector2(0, 16), title, HORIZONTAL_ALIGNMENT_CENTER, _rect.size.x, 9, Color("f4d890"))
	var y := _rect.position.y + 30
	if body != "":
		for line in Dialogue._wrap(body, 260):
			canvas.draw_string(FONT, Vector2(_rect.position.x + 20, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("d8ccb4"))
			y += 11
	for k in options.size():
		var r := _opt_rect(k)
		if k == sel:
			canvas.draw_rect(r, Color(1, 1, 1, 0.07))
		canvas.draw_string(FONT, r.position + Vector2(4, 10), ("> " if k == sel else "  ") + String(options[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color("f4d890") if k == sel else Color("c8b898"))
