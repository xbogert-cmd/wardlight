class_name SettingsUI
extends CanvasLayer
## Settings: audio levels, aim mode, fullscreen, comfort options and key
## remapping. Left/Right change a value; Enter on a key row waits for the
## new key (Esc cancels). Changes apply and save immediately.

signal finished

const FONT := preload("res://assets/fonts/wardhand.tres")
const PANEL := Rect2(120, 22, 400, 316)

var canvas: Control
var row := 0
var _rows: Array = []
var _waiting := ""
var _scroll := 0


func open() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_panel)
	add_child(canvas)
	_rows = ["master", "music", "sfx", "aim", "fullscreen", "shake", "flash"]
	for a in Settings.REMAPPABLE:
		_rows.append("key:" + a)
	_rows.append("reset_keys")
	_rows.append("back")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_d: float) -> void:
	canvas.queue_redraw()


func _input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	get_viewport().set_input_as_handled()
	var k := e as InputEventKey
	if _waiting != "":
		if k.physical_keycode != KEY_ESCAPE:
			Settings.rebind(_waiting, k.physical_keycode)
			Sfx.play("ui_select", -6.0)
		_waiting = ""
		return
	match k.keycode:
		KEY_UP:
			row = posmod(row - 1, _rows.size())
			Sfx.play("ui_move", -10.0)
		KEY_DOWN:
			row = posmod(row + 1, _rows.size())
			Sfx.play("ui_move", -10.0)
		KEY_LEFT:
			_change(-1)
		KEY_RIGHT:
			_change(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			var r: String = _rows[row]
			if r.begins_with("key:"):
				_waiting = r.trim_prefix("key:")
			elif r == "reset_keys":
				Settings.reset_keys()
				Sfx.play("ui_select", -6.0)
			elif r == "back":
				_close()
			else:
				_change(1)
		KEY_ESCAPE:
			_close()
	_scroll = clampi(row - 16, 0, maxi(0, _rows.size() - 20))


func _change(d: int) -> void:
	match _rows[row]:
		"master":
			Settings.master_vol = clampf(Settings.master_vol + d * 0.1, 0.0, 1.0)
		"music":
			Settings.music_vol = clampf(Settings.music_vol + d * 0.1, 0.0, 1.0)
		"sfx":
			Settings.sfx_vol = clampf(Settings.sfx_vol + d * 0.1, 0.0, 1.0)
		"aim":
			Settings.aim_mode = "direct" if Settings.aim_mode == "assisted" else "assisted"
		"fullscreen":
			Settings.fullscreen = not Settings.fullscreen
		"shake":
			Settings.reduce_shake = not Settings.reduce_shake
		"flash":
			Settings.reduce_flash = not Settings.reduce_flash
		_:
			return
	Settings.save_settings()
	Settings.apply()
	Sfx.play("ui_move", -6.0)


func _close() -> void:
	Sfx.play("ui_back", -8.0)
	finished.emit()
	queue_free()


func _label(r: String) -> Array:
	match r:
		"master":
			return ["Master volume", "%d%%" % roundi(Settings.master_vol * 100)]
		"music":
			return ["Music", "%d%%" % roundi(Settings.music_vol * 100)]
		"sfx":
			return ["Sound effects", "%d%%" % roundi(Settings.sfx_vol * 100)]
		"aim":
			return ["Aim", "Assisted (locks near the cursor)" if Settings.aim_mode == "assisted" else "Direct (exactly the cursor)"]
		"fullscreen":
			return ["Fullscreen", "On" if Settings.fullscreen else "Off"]
		"shake":
			return ["Reduce screen shake", "On" if Settings.reduce_shake else "Off"]
		"flash":
			return ["Reduce flashes", "On" if Settings.reduce_flash else "Off"]
		"reset_keys":
			return ["Reset all keys", ""]
		"back":
			return ["Back", ""]
	var a := r.trim_prefix("key:")
	return [Settings.ACTION_NAMES.get(a, a), "press a key..." if _waiting == a else Settings.key_label(a)]


func _draw_panel() -> void:
	canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.06, 0.75))
	HUD.frame(canvas, PANEL)
	var p := PANEL.position
	canvas.draw_string(FONT, p + Vector2(14, 16), "Settings", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f4d890"))
	var y := p.y + 32
	for k in range(_scroll, mini(_rows.size(), _scroll + 21)):
		var r: String = _rows[k]
		var l := _label(r)
		var sel := k == row
		if sel:
			canvas.draw_rect(Rect2(p.x + 10, y - 9, PANEL.size.x - 20, 12), Color(1, 1, 1, 0.07))
		canvas.draw_string(FONT, Vector2(p.x + 16, y), ("> " if sel else "  ") + String(l[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color("f4d890") if sel else Color("c8b898"))
		canvas.draw_string(FONT, Vector2(p.x + 190, y), String(l[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f0e6d0"))
		y += 13
	canvas.draw_string(FONT, p + Vector2(14, PANEL.size.y - 6), "Up/Down choose   Left/Right change   Enter set key   Esc back", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("8a7a60"))
