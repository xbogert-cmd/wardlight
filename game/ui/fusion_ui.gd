class_name FusionUI
extends CanvasLayer
## The sanctuary's fusion altar. Pick two alike items (staffs, robes or
## relics of the same tier); the preview shows both (and whether each is
## worn), the exact result and its effect, or why they can't be fused. Enter
## confirms; the fusion commits in one step and saves.

signal finished

const FONT := preload("res://assets/fonts/wardhand.tres")
const ICONS := preload("res://assets/generated/items.png")
const PANEL := Rect2(90, 34, 460, 290)
const VISIBLE := 12           # list rows on screen; the list scrolls past that

var canvas: Control
var sel := 0
var picks: Array[int] = []    # chosen uids (0-2)
var _msg := ""
var _msg_t := 0.0
var _flash := 0.0
var _top := 0                 # first list row on screen
var _bad := false             # the message is an error


func open() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_panel)
	add_child(canvas)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("ui_open", -6.0)


## Every fusable item: staffs, then robes, then relics, each tier-then-name.
func _items() -> Array:
	var out: Array = []
	for k: String in InventoryUI.TABS:
		out.append_array(InventoryUI.tab_items(GameState.inv, k).filter(func(it: Dictionary) -> bool: return Items.fusable(it.id)))
	return out


func _process(delta: float) -> void:
	_msg_t -= delta
	_flash = maxf(0.0, _flash - delta * 2.0)
	var n := _items().size()
	_top = clampi(clampi(_top, sel - VISIBLE + 1, sel), 0, maxi(0, n - VISIBLE))
	canvas.queue_redraw()


func _input(e: InputEvent) -> void:
	var items := _items()
	if e is InputEventMouseMotion or (e is InputEventMouseButton and e.pressed):
		var mp := canvas.get_local_mouse_position()
		for k in range(_top, mini(items.size(), _top + VISIBLE)):
			if _row(k - _top).has_point(mp):
				sel = k
				if e is InputEventMouseButton:
					_pick(items)
		return
	if not (e is InputEventKey and e.pressed):
		return
	get_viewport().set_input_as_handled()
	match (e as InputEventKey).keycode:
		KEY_UP, KEY_W:
			sel = posmod(sel - 1, maxi(items.size(), 1))
			Sfx.play("ui_move", -10.0)
		KEY_DOWN, KEY_S:
			sel = posmod(sel + 1, maxi(items.size(), 1))
			Sfx.play("ui_move", -10.0)
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			if picks.size() == 2:
				_confirm()
			else:
				_pick(items)
		KEY_BACKSPACE:
			if not picks.is_empty():
				picks.pop_back()
		KEY_ESCAPE:
			if not picks.is_empty():
				picks.clear()
			else:
				_close()


func _pick(items: Array) -> void:
	if items.is_empty():
		return
	var uid := int(items[sel].uid)
	if picks.has(uid):
		picks.erase(uid)
	elif picks.size() < 2:
		picks.append(uid)
	Sfx.play("ui_select", -8.0)


func _confirm() -> void:
	var out := GameState.inv.fuse(picks[0], picks[1])
	if out.has("error"):
		_msg = out.error
		_bad = true
		_msg_t = 3.0
		Sfx.play("fail", -6.0)
		return
	picks.clear()
	_msg = "Fused: " + Items.display(out)
	_bad = false
	_msg_t = 3.0
	_flash = 1.0
	Sfx.play("ward_light", 0.0)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.equipment_changed()
		FX3.ring(p.global_position + Vector3(0, 0.05, 0), 0.2, 2.0, 0.5, [Color("fff0c0"), Color("f0c870"), Color("a07840")], 2.0)
	SaveSystem.autosave()


func _close() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Sfx.play("ui_back", -8.0)
	finished.emit()
	queue_free()


func _row(k: int) -> Rect2:
	return Rect2(PANEL.position + Vector2(12, 40 + k * 18), Vector2(200, 16))


func _draw_panel() -> void:
	canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.06, 0.7))
	HUD.frame(canvas, PANEL)
	var p := PANEL.position
	_t("Fusion altar", p + Vector2(12, 16), Color("f4d890"))
	_t("Two alike items of the same tier become one of the next tier (up to III).", p + Vector2(12, 30), Color("a89878"))
	var items := _items()
	if items.is_empty():
		_t("You carry nothing that can be fused.", p + Vector2(12, 56), Color("8a7a60"))
	for k in range(_top, mini(items.size(), _top + VISIBLE)):
		var it: Dictionary = items[k]
		var r := _row(k - _top)
		var chosen := picks.has(int(it.uid))
		if k == sel:
			canvas.draw_rect(r, Color(1, 1, 1, 0.06))
		canvas.draw_texture_rect_region(ICONS, Rect2(r.position + Vector2(2, 0), Vector2(16, 16)), Rect2(int(Items.def(it.id).icon) * 16, 0, 16, 16))
		if GameState.inv.has_partner(int(it.uid)):
			canvas.draw_rect(Rect2(r.position + Vector2(2, 1), Vector2(3, 3)), Color("f4d890"))
		var worn := GameState.inv.is_equipped(int(it.uid)) != ""
		_t(("> " if k == sel else "  ") + Items.display(it) + ("  (worn)" if worn else ""), r.position + Vector2(20, 11),
			Color("9ae8ff") if chosen else (Color("f4d890") if k == sel else Color("d8ccb4")))
	# preview
	var pr := Rect2(p + Vector2(228, 40), Vector2(220, 200))
	HUD.frame(canvas, pr, Color("120e1a", 0.9), HUD.COL_FRAME_DARK)
	var y := pr.position.y + 14
	for k in 2:
		var label := "First" if k == 0 else "Second"
		if k < picks.size():
			var it := GameState.inv.find(picks[k])
			var worn := GameState.inv.is_equipped(picks[k])
			_t("%s: %s%s" % [label, Items.display(it), ("" if worn == "" else (" (worn: comes off)" if worn.begins_with("relic") else " (worn)"))], Vector2(pr.position.x + 8, y), Color("e8dcc4"))
		else:
			_t("%s: choose an item" % label, Vector2(pr.position.x + 8, y), Color("8a7a60"))
		y += 14
	y += 6
	if picks.size() == 2:
		var pv := GameState.inv.fusion_preview(picks[0], picks[1])
		if pv.has("error"):
			for line in Dialogue._wrap(String(pv.error), pr.size.x - 16):
				_t(line, Vector2(pr.position.x + 8, y), Color("ff9a8a"))
				y += 11
		else:
			var out := {"id": pv.id, "tier": pv.tier}
			_t("Becomes: " + Items.display(out), Vector2(pr.position.x + 8, y), Color("f4d890"))
			y += 14
			for line in Dialogue._wrap(String(Items.def(pv.id).text), pr.size.x - 16):
				_t(line, Vector2(pr.position.x + 8, y), Color("d8ccb4"))
				y += 11
			y += 4
			var worn_note := "The result starts unworn." if Items.kind(pv.id) == "relic" else "If one was worn, the result is worn."
			for line in Dialogue._wrap("Both are consumed. " + worn_note, pr.size.x - 16):
				_t(line, Vector2(pr.position.x + 8, y), Color("a89878"))
				y += 11
			_t("Enter: fuse", pr.end - Vector2(70, 8), Color("9ae8ff"))
	if _flash > 0.0:
		canvas.draw_rect(pr, Color(1.0, 0.9, 0.6, _flash * 0.3))
	_t("Enter pick / fuse   Backspace undo   Esc back", p + Vector2(12, PANEL.size.y - 8), Color("8a7a60"))
	if _msg_t > 0.0:
		_t(_msg, p + Vector2(228, PANEL.size.y - 22), Color("ff9a8a") if _bad else Color("f4d890"))


func _t(s: String, pos: Vector2, col: Color) -> void:
	canvas.draw_string(FONT, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.6))
	canvas.draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
