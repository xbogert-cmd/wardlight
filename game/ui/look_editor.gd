class_name LookEditor
extends CanvasLayer
## Character setup (new game: name, starting school, looks) and the
## sanctuary's appearance mirror (looks only). Up/Down pick a row, Left/Right
## change it, typing edits the name, Enter confirms, Esc cancels (mirror only).
## A live preview shows the wizard.

signal finished(result: Dictionary)   # {} when cancelled

const FONT := preload("res://assets/fonts/wardhand.tres")
const PANEL := Rect2(120, 40, 400, 280)

var new_game := false
var canvas: Control
var look := {}
var wiz_name := "Wren"
var school := "storm"
var row := 0
var _rows: Array = []
var _art: Dictionary
var _t := 0.0


func open(is_new: bool) -> void:
	new_game = is_new
	look = WizardArt.DEFAULT_LOOK.duplicate()
	look.merge(GameState.appearance, true)
	wiz_name = GameState.wizard_name
	_rows = (["name", "school"] if new_game else []) + ["robe", "complexion", "hair", "hair_color", "beard", "hat", "staff", "done"]
	row = 0
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_panel)
	add_child(canvas)
	_rebuild()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _options(key: String) -> Array:
	match key:
		"robe":
			return WizardArt.ROBES.keys()
		"complexion":
			return WizardArt.COMPLEXIONS.keys()
		"hair":
			return WizardArt.HAIR_STYLES
		"hair_color":
			return WizardArt.HAIR_COLORS.keys()
		"beard":
			return WizardArt.BEARDS
		"hat":
			return WizardArt.HATS
		"staff":
			return WizardArt.STAFFS.keys()
		"school":
			return WizardState.SCHOOLS
	return []


func _rebuild() -> void:
	_art = WizardArt.build(look)


func _process(delta: float) -> void:
	_t += delta
	canvas.queue_redraw()


func _input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed):
		return
	get_viewport().set_input_as_handled()
	var k := e as InputEventKey
	var key: String = _rows[row]
	if k.keycode == KEY_UP:
		row = posmod(row - 1, _rows.size())
		Sfx.play("ui_move", -10.0)
	elif k.keycode == KEY_DOWN or k.keycode == KEY_TAB:
		row = posmod(row + 1, _rows.size())
		Sfx.play("ui_move", -10.0)
	elif k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT:
		_cycle(key, -1 if k.keycode == KEY_LEFT else 1)
	elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		if key == "done" or new_game == false or row == _rows.size() - 1:
			_finish(true)
		else:
			row = _rows.size() - 1
	elif k.keycode == KEY_ESCAPE and not new_game:
		_finish(false)
	elif key == "name":
		if k.keycode == KEY_BACKSPACE:
			wiz_name = wiz_name.substr(0, wiz_name.length() - 1)
		elif k.unicode >= 32 and k.unicode < 127 and wiz_name.length() < 14:
			var ch := char(k.unicode)
			if ch.is_valid_identifier() or ch == " " or ch == "-" or ch == "'" or ch.is_valid_int():
				wiz_name += ch


func _cycle(key: String, d: int) -> void:
	var opts := _options(key)
	if opts.is_empty():
		return
	Sfx.play("ui_move", -8.0)
	if key == "school":
		school = opts[posmod(opts.find(school) + d, opts.size())]
		return
	look[key] = opts[posmod(opts.find(look.get(key)) + d, opts.size())]
	_rebuild()


func _finish(ok: bool) -> void:
	Sfx.play("ui_select" if ok else "ui_back", -6.0)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var res := {}
	if ok:
		res = {"look": look, "name": wiz_name.strip_edges() if wiz_name.strip_edges() != "" else "Wren", "school": school}
	finished.emit(res)
	queue_free()


func _label(key: String) -> String:
	return {"name": "Name", "school": "School", "robe": "Robe", "complexion": "Complexion", "hair": "Hair", "hair_color": "Hair colour",
		"beard": "Beard", "hat": "Hat", "staff": "Staff", "done": "Begin" if new_game else "Done"}[key]


func _value(key: String) -> String:
	match key:
		"name":
			return wiz_name + ("_" if int(_t * 2.0) % 2 == 0 and _rows[row] == "name" else "")
		"school":
			return WizardState.SCHOOL_NAMES[school]
		"done":
			return ""
	return String(look.get(key, "")).capitalize()


func _draw_panel() -> void:
	canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.06, 0.85))
	HUD.frame(canvas, PANEL)
	var p := PANEL.position
	_t2("Who walks the ward-roads?" if new_game else "Appearance", p + Vector2(14, 18), Color("f4d890"))
	var y := p.y + 40
	for k in _rows.size():
		var key: String = _rows[k]
		var sel := k == row
		var col := Color("f4d890") if sel else Color("c8b898")
		_t2(("> " if sel else "  ") + _label(key), Vector2(p.x + 14, y), col)
		var v := _value(key)
		if v != "":
			_t2(("< " if sel and key != "name" else "  ") + v + (" >" if sel and key != "name" else ""), Vector2(p.x + 110, y), Color("f0e6d0"))
		y += 14
	if new_game and _rows[row] == "school":
		var blurb: String = {"fire": "Fire and heat. Burning ground, wards of flame.",
			"hex": "Curses and spirits. Roots, needles, stolen life.",
			"storm": "Lightning and wind. Fast bolts, thunder, flight."}[school]
		_t2(blurb, p + Vector2(14, PANEL.size.y - 26), Color("a89878"))
	_t2("Arrows change   Enter confirm" + ("" if new_game else "   Esc cancel"), p + Vector2(14, PANEL.size.y - 10), Color("8a7a60"))
	# preview, idle animation at 3x
	var frames: Array = _art.anims.idle.frames
	var f: int = frames[int(_t * 5.0) % frames.size()]
	var cell := Vector2(WizardArt.CELL_W, WizardArt.CELL)
	var src := Rect2(Vector2((f % WizardArt.COLS) * cell.x, (f / WizardArt.COLS) * cell.y), cell)
	var dst := Rect2(Vector2(p.x + 250, p.y + 50), cell * 1.8)
	HUD.frame(canvas, dst.grow(4), Color("1a1426"), HUD.COL_FRAME_DARK)
	canvas.draw_texture_rect_region(_art.texture, dst, src)


func _t2(s: String, pos: Vector2, col: Color) -> void:
	canvas.draw_string(FONT, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.6))
	canvas.draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
