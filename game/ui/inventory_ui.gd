class_name InventoryUI
extends Control
## Inventory (I): four equipment slots on the left, the bag on the right,
## details and a comparison with what is worn at the bottom. Arrows move,
## Enter equips/unequips, I/Esc closes; the mouse works too.

const FONT := preload("res://assets/fonts/wardhand.tres")
const ICONS := preload("res://assets/generated/items.png")
const PANEL := Rect2(60, 26, 520, 304)
const COLS := 8
const ROWS := 5
const CELL := 24
const SLOT_NAMES := {"staff": "Staff", "robe": "Robe", "relic1": "Relic", "relic2": "Relic"}

var player: Player
var is_open := false
var cur := Vector2i(-1, 0)     # x == -1: equipment slot column (y = slot); else bag cell
var _msg := ""
var _msg_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	if is_open or Dialogue.i.is_open:
		return
	is_open = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("ui_open", -6.0)


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player.resume_input()
	Sfx.play("ui_back", -8.0)


func _process(delta: float) -> void:
	if is_open:
		_msg_t -= delta
		queue_redraw()


func _slot_rect(k: int) -> Rect2:
	return Rect2(PANEL.position + Vector2(14, 44 + k * 30), Vector2(CELL, CELL))


func _cell_rect(c: Vector2i) -> Rect2:
	return Rect2(PANEL.position + Vector2(200 + c.x * (CELL + 3), 44 + c.y * (CELL + 3)), Vector2(CELL, CELL))


func _bag() -> Array:
	return GameState.inv.items


func _selected() -> Dictionary:
	if cur.x < 0:
		return GameState.inv.slot_item(Items.SLOTS[cur.y])
	var i := cur.y * COLS + cur.x
	return _bag()[i] if i < _bag().size() else {}


func _input(e: InputEvent) -> void:
	if not is_open:
		return
	if e.is_action_pressed(&"inventory") or e.is_action_pressed(&"pause") or e.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	if e is InputEventMouseMotion or (e is InputEventMouseButton and e.pressed):
		var mp := get_local_mouse_position()
		for k in 4:
			if _slot_rect(k).has_point(mp):
				cur = Vector2i(-1, k)
		for y in ROWS:
			for x in COLS:
				if _cell_rect(Vector2i(x, y)).has_point(mp):
					cur = Vector2i(x, y)
		if e is InputEventMouseButton and (e as InputEventMouseButton).double_click:
			_use()
		return
	var d := Vector2i.ZERO
	if e.is_action_pressed(&"ui_left") or e.is_action_pressed(&"move_left"):
		d.x = -1
	elif e.is_action_pressed(&"ui_right") or e.is_action_pressed(&"move_right"):
		d.x = 1
	elif e.is_action_pressed(&"ui_up") or e.is_action_pressed(&"up"):
		d.y = -1
	elif e.is_action_pressed(&"ui_down") or e.is_action_pressed(&"down"):
		d.y = 1
	elif e.is_action_pressed(&"ui_accept") or e.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		_use()
		return
	if d != Vector2i.ZERO:
		get_viewport().set_input_as_handled()
		if cur.x < 0:
			if d.x > 0:
				cur = Vector2i(0, mini(cur.y, ROWS - 1))
			else:
				cur.y = posmod(cur.y + d.y, 4)
		else:
			var nx := cur.x + d.x
			if nx < 0:
				cur = Vector2i(-1, mini(cur.y, 3))
			else:
				cur = Vector2i(mini(nx, COLS - 1), posmod(cur.y + d.y, ROWS))
		Sfx.play("ui_move", -10.0)


## Enter: equip the bag item (to its slot, or the free/first relic slot);
## on a slot: take it off.
func _use() -> void:
	var inv := GameState.inv
	if cur.x < 0:
		var slot: String = Items.SLOTS[cur.y]
		if inv.slot_item(slot).is_empty():
			return
		if slot in ["staff", "robe"]:
			_say("You'd rather not travel without one.")
			return
		inv.unequip(slot)
		_done()
		return
	var it := _selected()
	if it.is_empty():
		return
	var k := Items.kind(it.id)
	var slot := k
	if k == "relic":
		var worn := inv.is_equipped(int(it.uid))
		if worn != "":
			inv.unequip(worn)
			_done()
			return
		slot = "relic1" if inv.slot_item("relic1").is_empty() or inv.slot_item("relic1").id == it.id else "relic2"
		if not inv.slot_item("relic2").is_empty() and inv.slot_item("relic2").id == it.id:
			slot = "relic2"
	var err := inv.equip(slot, int(it.uid))
	if err != "":
		_say(err)
		return
	_done()


func _done() -> void:
	Sfx.play("ui_select", -6.0)
	player.equipment_changed()
	SaveSystem.autosave()


func _say(s: String) -> void:
	_msg = s
	_msg_t = 2.5
	Sfx.play("fail", -8.0)


func _icon(r: Rect2, id: StringName, dim := false) -> void:
	var icon: int = int(Items.def(id).get("icon", 0))
	draw_texture_rect_region(ICONS, Rect2(r.position + Vector2(4, 4), Vector2(16, 16)), Rect2(icon * 16, 0, 16, 16), Color(1, 1, 1, 0.5) if dim else Color.WHITE)


func _draw() -> void:
	var inv := GameState.inv
	HUD.frame(self, PANEL)
	var p := PANEL.position
	_t("Equipment", p + Vector2(14, 18), Color("f4d890"))
	_t("Bag  %d/%d" % [inv.items.size(), Inventory.MAX_ITEMS], p + Vector2(200, 18), Color("f4d890"))
	_t("Coins %d   Points %d   XP %d/%d" % [inv.coins, inv.points, inv.xp, Inventory.XP_PER_POINT], p + Vector2(330, 18), Color("c8b898"))
	for k in 4:
		var slot: String = Items.SLOTS[k]
		var r := _slot_rect(k)
		var sel := cur == Vector2i(-1, k)
		HUD.frame(self, r, HUD.COL_BG, Color("f4d890") if sel else HUD.COL_FRAME)
		var it := inv.slot_item(slot)
		_t(SLOT_NAMES[slot], r.position + Vector2(CELL + 6, 9), Color("8a7a60"))
		if not it.is_empty():
			_icon(r, it.id)
			_t(Items.display(it), r.position + Vector2(CELL + 6, 20), Color("e8dcc4"))
	for y in ROWS:
		for x in COLS:
			var c := Vector2i(x, y)
			var r := _cell_rect(c)
			var sel := cur == c
			HUD.frame(self, r, HUD.COL_BG, Color("f4d890") if sel else HUD.COL_FRAME_DARK)
			var i := y * COLS + x
			if i < inv.items.size():
				var it: Dictionary = inv.items[i]
				_icon(r, it.id)
				if Items.kind(it.id) == "relic" and int(it.tier) > 1:
					_t(Items.TIER_NAMES[int(it.tier)], r.position + Vector2(2, 22), Color("f4d890"))
				if inv.is_equipped(int(it.uid)) != "":
					draw_rect(Rect2(r.end - Vector2(6, 6), Vector2(4, 4)), Color("9ae8ff"))
	# details
	var dr := Rect2(p + Vector2(14, 190), Vector2(PANEL.size.x - 28, 96))
	HUD.frame(self, dr, Color("120e1a", 0.9), HUD.COL_FRAME_DARK)
	var it := _selected()
	if it.is_empty():
		_t("Arrows or mouse to choose. Enter / double-click to equip.", dr.position + Vector2(8, 14), Color("8a7a60"))
	else:
		var d := Items.def(it.id)
		var worn := inv.is_equipped(int(it.uid))
		_t(Items.display(it) + ("   (worn)" if worn != "" else ""), dr.position + Vector2(8, 14), Color("f4d890"))
		var y := dr.position.y + 28
		for line in Dialogue._wrap(String(d.get("text", "")), dr.size.x - 16):
			_t(line, Vector2(dr.position.x + 8, y), Color("d8ccb4"))
			y += 11
		var b := Items.bonus_text(it)
		if b != "":
			_t(b, Vector2(dr.position.x + 8, y), Color("9ae8ff"))
			y += 11
		var cmp := _compare(it)
		if cmp != "":
			_t(cmp, Vector2(dr.position.x + 8, y + 2), Color("c8b898"))
		_t("Enter: " + ("take off" if worn != "" and worn.begins_with("relic") else ("worn" if worn != "" else "equip")), dr.end - Vector2(96, 8), Color("8a7a60"))
	if _msg_t > 0.0:
		_t(_msg, p + Vector2(14, PANEL.size.y - 6), Color("ff9a8a"))


## "Replaces: Wanderer's Crook (no bonus)" style comparison.
func _compare(it: Dictionary) -> String:
	var inv := GameState.inv
	var k := Items.kind(it.id)
	if inv.is_equipped(int(it.uid)) != "":
		return ""
	var other: Dictionary
	if k == "relic":
		var a := inv.slot_item("relic1")
		var b := inv.slot_item("relic2")
		if (not a.is_empty()) and a.id == it.id:
			other = a
		elif (not b.is_empty()) and b.id == it.id:
			other = b
		elif a.is_empty() or b.is_empty():
			return "Goes into a free relic slot."
		else:
			other = a
	else:
		other = inv.slot_item(k)
	if other.is_empty():
		return ""
	var ob := Items.bonus_text(other)
	return "Replaces: %s%s" % [Items.display(other), (" (" + ob + ")") if ob != "" else ""]


func _t(s: String, pos: Vector2, col: Color) -> void:
	draw_string(FONT, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.6))
	draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
