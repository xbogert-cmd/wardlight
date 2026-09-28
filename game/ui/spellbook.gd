class_name Spellbook
extends Control
## Tab spellbook. The world slows to 15% while it is open; the book itself
## runs at full speed. Choose a slot (1–4, or click), choose an unlocked spell
## (arrows / WASD, or hover), confirm (Enter / Space / E / click).
## Tab or Esc closes it. Game actions never fire from book input.

signal closed

const FONT := preload("res://assets/fonts/wardhand.tres")
const ICONS := preload("res://assets/generated/icons.png")
const SLOW := 0.15
const PANEL := Rect2(92, 44, 456, 262)
const SCHOOL_COL := {"fire": Color("ff9a3a"), "hex": Color("b67cff"), "storm": Color("5ad4ff")}
const PASSIVE_TEXT := {
	"fire": ["Heat", "Each native fire spell that lands adds a charge (max 3). At 3, your next damaging fire spell spends them: +45% power and its hits spread burn."],
	"hex": ["Soul Echo", "Killing a cursed enemy restores 5 health and 6 mana (once per second)."],
	"storm": ["Conduction", "Every third native lightning spell that lands arcs to one more nearby enemy for 50% damage."],
}

var player: Player
var is_open := false
var sel_slot := 0
var cur := Vector2i(0, 0)   # x = column 0..3, y = school row 0..2
var _hover_slot := -1
var _msg := ""
var _msg_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	if is_open or not player.is_alive():
		return
	is_open = true
	visible = true
	player.input_enabled = false
	player.caster.interrupt()
	TimeCtl.set_factor("wheel", SLOW)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var s: int = WizardState.SCHOOLS.find(player.wiz.school)
	cur = Vector2i(0, maxi(s, 0))
	Sfx.play("ui_open", -4.0)
	queue_redraw()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	TimeCtl.clear("wheel")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player.resume_input()
	Sfx.play("ui_back", -6.0)
	closed.emit()


func _process(delta: float) -> void:
	if is_open:
		_msg_t -= delta / maxf(Engine.time_scale, 0.001)
		queue_redraw()


func _spell_at(c: Vector2i) -> StringName:
	return WizardState.BASE[WizardState.SCHOOLS[c.y]][c.x]


func _cell_rect(c: Vector2i) -> Rect2:
	return Rect2(PANEL.position + Vector2(118 + c.x * 26, 58 + c.y * 30), Vector2(22, 22))


func _slot_rect(k: int) -> Rect2:
	return Rect2(PANEL.position + Vector2(14, 58 + k * 30), Vector2(22, 22))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		for y in 3:
			for x in 4:
				if _cell_rect(Vector2i(x, y)).has_point(e.position):
					if cur != Vector2i(x, y):
						cur = Vector2i(x, y)
						Sfx.play("ui_move", -12.0)
		_hover_slot = -1
		for k in 4:
			if _slot_rect(k).has_point(e.position):
				_hover_slot = k
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for k in 4:
			if _slot_rect(k).has_point(e.position):
				sel_slot = k
				Sfx.play("ui_move", -8.0)
				return
		for y in 3:
			for x in 4:
				if _cell_rect(Vector2i(x, y)).has_point(e.position):
					cur = Vector2i(x, y)
					_confirm()
					return
		if not PANEL.has_point(e.position):
			close()
	accept_event()


func _unhandled_key_input(e: InputEvent) -> void:
	if not is_open or not e.is_pressed() or e.is_echo() and not _is_nav(e):
		return
	var k := e as InputEventKey
	var pk := k.physical_keycode
	get_viewport().set_input_as_handled()
	if e.is_action(&"wheel") or pk == KEY_ESCAPE:
		close()
	elif pk in [KEY_1, KEY_2, KEY_3, KEY_4]:
		sel_slot = pk - KEY_1
		Sfx.play("ui_move", -8.0)
	elif pk in [KEY_LEFT, KEY_A]:
		_move(Vector2i(-1, 0))
	elif pk in [KEY_RIGHT, KEY_D]:
		_move(Vector2i(1, 0))
	elif pk in [KEY_UP, KEY_W]:
		_move(Vector2i(0, -1))
	elif pk in [KEY_DOWN, KEY_S]:
		_move(Vector2i(0, 1))
	elif pk in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
		_confirm()
	elif pk == KEY_U:
		_buy_upgrade()
	elif pk == KEY_T:
		_train()


## Spend a progression point on the selected spell's upgrade.
func _buy_upgrade() -> void:
	var id := _spell_at(cur)
	var wiz: WizardState = player.wiz
	var d := SpellDB.get_spell(id)
	var inv := GameState.inv
	if not wiz.unlocked.has(id):
		_say("Learn the spell first")
	elif d.upgrade_name == "" or wiz.upgrades.has(id):
		_say("Nothing more to learn here")
	elif inv.points < 1:
		_say("Needs 1 progression point")
	else:
		inv.points -= 1
		wiz.upgrades[id] = true
		inv.changed.emit()
		Sfx.play("ward_light", -4.0)
		_say("Learned: " + d.upgrade_name)
		SaveSystem.autosave()
		return
	Sfx.play("fail", -6.0)


## Spend a progression point on affinity with the selected spell's school.
func _train() -> void:
	var school: String = WizardState.SCHOOLS[cur.y]
	var wiz: WizardState = player.wiz
	var inv := GameState.inv
	if wiz.is_native(school):
		_say("Your own school needs no training")
	elif inv.points < 1:
		_say("Needs 1 progression point")
	elif not wiz.train(school):
		_say("Fully trained")
	else:
		inv.points -= 1
		inv.changed.emit()
		Sfx.play("ward_light", -4.0)
		_say("%s affinity %d%%" % [WizardState.SCHOOL_NAMES[school], roundi(wiz.affinity_mult(school) * 100.0)])
		SaveSystem.autosave()
		return
	Sfx.play("fail", -6.0)


func _is_nav(e: InputEvent) -> bool:
	var pk := (e as InputEventKey).physical_keycode
	return pk in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_A, KEY_D, KEY_W, KEY_S]


func _move(d: Vector2i) -> void:
	cur = Vector2i(posmod(cur.x + d.x, 4), posmod(cur.y + d.y, 3))
	Sfx.play("ui_move", -12.0)


func _confirm() -> void:
	var id := _spell_at(cur)
	var wiz: WizardState = player.wiz
	if not wiz.unlocked.has(id):
		_say("Not learned yet")
		Sfx.play("fail", -6.0)
		return
	if wiz.equip(sel_slot, id):
		Sfx.play("ui_select", -4.0)
		_say("%s -> slot %d" % [SpellDB.get_spell(id).display_name, sel_slot + 1])
		sel_slot = (sel_slot + 1) % 4


func _say(s: String) -> void:
	_msg = s
	_msg_t = 1.6


# ---------------------------------------------------------------- drawing
func _t(s: String, pos: Vector2, col: Color = Color("f0e6d0"), align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(FONT, pos + Vector2(1, 1), s, align, width, 9, Color(0, 0, 0, 0.6))
	draw_string(FONT, pos, s, align, width, 9, col)


func _wrap(s: String, pos: Vector2, width: float, col: Color, max_lines: int = 6) -> float:
	var words := s.split(" ")
	var line := ""
	var y := pos.y
	var lines := 0
	for w in words:
		var test := w if line == "" else line + " " + w
		if FONT.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x > width and line != "":
			_t(line, Vector2(pos.x, y), col)
			y += 11
			lines += 1
			line = w
			if lines >= max_lines:
				return y
		else:
			line = test
	if line != "":
		_t(line, Vector2(pos.x, y), col)
		y += 11
	return y


func _draw() -> void:
	if not is_open:
		return
	var wiz: WizardState = player.wiz
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.55))
	HUD.frame(self, PANEL, Color("150f22", 0.96))
	HUD.frame(self, PANEL.grow(-3), Color(0, 0, 0, 0), Color("4a3a2e"))
	var p := PANEL.position
	var sc: Color = SCHOOL_COL[wiz.school]
	_t("Spellbook", p + Vector2(14, 18), Color("f4d890"))
	_t(WizardState.SCHOOL_NAMES[wiz.school], p + Vector2(80, 18), sc)
	var pas: Array = PASSIVE_TEXT[wiz.school]
	_t("Passive: " + pas[0], p + Vector2(230, 18), sc)
	_t("Points %d" % GameState.inv.points, p + Vector2(PANEL.size.x - 62, 18), Color("f4d890"))
	_wrap(pas[1], p + Vector2(14, 31), 428, Color("b8aa94"), 2)
	# slots
	_t("Loadout", p + Vector2(10, 50), Color("c8b898"))
	for k in 4:
		var r := _slot_rect(k)
		var id: StringName = wiz.loadout()[k]
		var edge := Color("f4d890") if k == sel_slot else (Color("a88a60") if k == _hover_slot else HUD.COL_FRAME)
		HUD.frame(self, r, HUD.COL_BG, edge)
		if k == sel_slot:
			draw_rect(r.grow(2), Color("f4d890", 0.6), false, 1.0)
		_t(str(k + 1), r.position + Vector2(-8, 15), Color("c8b898"))
		if id != &"":
			var d := SpellDB.get_spell(id)
			draw_texture_rect_region(ICONS, Rect2(r.position + Vector2(3, 3), Vector2(16, 16)), Rect2(d.icon * 16, 0, 16, 16))
			_t(d.display_name, r.position + Vector2(26, 15), Color("e8dcc4"))
	var basic := SpellDB.get_spell(wiz.basic())
	var br := Rect2(p + Vector2(14, 58 + 4 * 30 + 4), Vector2(22, 22))
	HUD.frame(self, br, HUD.COL_BG, Color("5a4a3a"))
	draw_texture_rect_region(ICONS, Rect2(br.position + Vector2(3, 3), Vector2(16, 16)), Rect2(basic.icon * 16, 0, 16, 16))
	_t("J / click: " + basic.display_name, br.position + Vector2(26, 15), Color("a89878"))
	# spell grid
	_t("Spells", p + Vector2(114, 50), Color("c8b898"))
	for y in 3:
		var school: String = WizardState.SCHOOLS[y]
		draw_rect(Rect2(p + Vector2(114, 56 + y * 30), Vector2(108, 26)), Color(SCHOOL_COL[school], 0.07))
		for x in 4:
			var c := Vector2i(x, y)
			var r := _cell_rect(c)
			var id := _spell_at(c)
			var d := SpellDB.get_spell(id)
			var known := wiz.unlocked.has(id)
			var equipped := wiz.loadout().has(id)
			HUD.frame(self, r, HUD.COL_BG, Color("f4d890") if c == cur else (Color(SCHOOL_COL[school], 0.8) if equipped else HUD.COL_FRAME_DARK))
			draw_texture_rect_region(ICONS, Rect2(r.position + Vector2(3, 3), Vector2(16, 16)), Rect2(d.icon * 16, 0, 16, 16),
				Color.WHITE if known else Color(0.25, 0.22, 0.3))
			if not known:
				draw_rect(Rect2(r.position + Vector2(8, 9), Vector2(6, 5)), Color("5a5070"))
				draw_arc(r.position + Vector2(11, 9), 2.0, PI, TAU, 6, Color("5a5070"), 1.0)
			if equipped:
				_t(str(wiz.loadout().find(id) + 1), r.position + Vector2(16, 21), Color("f4d890"))
			if wiz.upgrades.has(id):
				draw_rect(Rect2(r.position + Vector2(18, 2), Vector2(2, 2)), Color("f4d890"))
	# details
	_details(SpellDB.get_spell(_spell_at(cur)), Rect2(p + Vector2(232, 50), Vector2(214, 200)))
	# footer
	_t("1-4 slot   Arrows choose   Enter equip   U upgrade   T train   Tab close", p + Vector2(0, PANEL.size.y - 8), Color("8a7a64"), HORIZONTAL_ALIGNMENT_CENTER, PANEL.size.x)
	if _msg_t > 0.0:
		_t(_msg, p + Vector2(0, PANEL.size.y - 20), Color("f4d890"), HORIZONTAL_ALIGNMENT_CENTER, PANEL.size.x)


func _details(d: SpellData, r: Rect2) -> void:
	var wiz: WizardState = player.wiz
	var known := wiz.unlocked.has(d.id)
	var sc: Color = SCHOOL_COL[d.school]
	var x := r.position.x
	var y := r.position.y + 8
	_t(d.display_name, Vector2(x, y), sc)
	var mult := wiz.affinity_mult(d.school)
	var native := wiz.is_native(d.school)
	_t("native" if native else "foreign  %d%% affinity" % roundi(mult * 100.0), Vector2(x + 100, y), Color("c8b898") if native else Color("e0a070"))
	y += 14
	_t("Mana %d   Cooldown %.1fs" % [roundi(d.mana_cost), d.cooldown], Vector2(x, y), Color("8ac8ff"))
	y += 11
	var eff := d.damage * mult
	_t("Damage %s%s" % [_num(eff), "" if native else "  (base %s)" % _num(d.damage)], Vector2(x, y), Color("ffb0a0"))
	y += 14
	y = _wrap(d.description, Vector2(x, y), r.size.x, Color("e8dcc4"), 4) + 4
	if d.upgrade_name != "":
		var owned := wiz.upgrades.has(d.id)
		_t(("Upgrade: " if owned else "Upgrade (U, 1 point): ") + d.upgrade_name, Vector2(x, y), Color("f4d890") if owned else Color("a89070"))
		y += 11
		y = _wrap(d.upgrade_description, Vector2(x, y), r.size.x, Color("c8bca4") if owned else Color("8a8070"), 3)
	if not known:
		_t("Switch to this school at the sanctuary study to learn it.", Vector2(x, r.end.y - 6), Color("8a8070"))


static func _num(v: float) -> String:
	return str(roundi(v)) if absf(v - roundf(v)) < 0.05 else "%.1f" % v
