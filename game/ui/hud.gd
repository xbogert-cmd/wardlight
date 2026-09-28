class_name HUD
extends CanvasLayer
## In-game overlay drawn directly in 640×360 pixels: health, mana, school
## emblem, the free attack + four spell slots, aim reticle and short prompts.

const FONT := preload("res://assets/fonts/wardhand.tres")
const ICONS := preload("res://assets/generated/icons.png")
const SLOT := 22
const COL_FRAME := Color("8a6e48")
const COL_FRAME_DARK := Color("3a2c24")
const COL_BG := Color("140f1e", 0.88)
const SCHOOL_COL := {"fire": Color("ff8a24"), "hex": Color("b070ff"), "storm": Color("52cfff")}

var player: Player
var canvas: Control
var _fail := {}          # slot -> time left
var _fail_msg := ""
var _fail_msg_t := 0.0
var _banner := ""
var _banner_t := 0.0
var _hp_shown := 1.0
var show_debug := false


func _ready() -> void:
	layer = 10
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)
	add_child(canvas)


func bind(p: Player) -> void:
	player = p
	p.caster.cast_failed.connect(_on_fail)


func banner(text: String) -> void:
	_banner = text
	_banner_t = 3.0


func _on_fail(slot: int, reason: String) -> void:
	_fail[slot] = 0.3
	_fail_msg = {"mana": "Not enough mana", "cooldown": "Recharging", "empty": "No spell in that slot"}.get(reason, "")
	_fail_msg_t = 1.0
	Sfx.play("fail", -8.0)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_F3:
		show_debug = not show_debug


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	for k in _fail.keys():
		_fail[k] -= real
		if _fail[k] <= 0.0:
			_fail.erase(k)
	_fail_msg_t -= real
	_banner_t -= real
	if player:
		_hp_shown = move_toward(_hp_shown, player.health.ratio(), real * 0.8)
		if _hp_shown < player.health.ratio():
			_hp_shown = player.health.ratio()
	canvas.queue_redraw()


func text(s: String, pos: Vector2, col: Color = Color("f0e6d0"), align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, shadow := true) -> void:
	if shadow:
		canvas.draw_string(FONT, pos + Vector2(1, 1), s, align, width, 9, Color(0, 0, 0, 0.7))
	canvas.draw_string(FONT, pos, s, align, width, 9, col)


static func frame(ci: CanvasItem, r: Rect2, bg: Color = COL_BG, edge: Color = COL_FRAME) -> void:
	ci.draw_rect(r, bg)
	ci.draw_rect(Rect2(r.position.x + 1, r.position.y, r.size.x - 2, 1), edge)
	ci.draw_rect(Rect2(r.position.x + 1, r.end.y - 1, r.size.x - 2, 1), edge.darkened(0.3))
	ci.draw_rect(Rect2(r.position.x, r.position.y + 1, 1, r.size.y - 2), edge)
	ci.draw_rect(Rect2(r.end.x - 1, r.position.y + 1, 1, r.size.y - 2), edge.darkened(0.3))


func _bar(r: Rect2, v: float, ghost: float, col: Color, hi: Color) -> void:
	frame(canvas, r.grow(1), Color("0c0812"), COL_FRAME_DARK)
	if ghost > v:
		canvas.draw_rect(Rect2(r.position, Vector2(roundf(r.size.x * ghost), r.size.y)), Color("f0e0c0", 0.8))
	var w := roundf(r.size.x * v)
	canvas.draw_rect(Rect2(r.position, Vector2(w, r.size.y)), col)
	canvas.draw_rect(Rect2(r.position, Vector2(w, 1)), hi)


func _draw_hud() -> void:
	if player == null:
		return
	var school := "storm"
	var basic := player.caster.spell_in(SpellCaster.BASIC_SLOT)
	if basic:
		school = basic.school
	# emblem
	var er := Rect2(6, 6, 20, 20)
	frame(canvas, er)
	var sc: Color = SCHOOL_COL[school]
	canvas.draw_circle(er.get_center(), 6, Color(sc, 0.25))
	canvas.draw_texture_rect_region(ICONS, Rect2(er.position + Vector2(2, 2), Vector2(16, 16)), Rect2(basic.icon * 16 if basic else 15 * 16, 0, 16, 16))
	# bars
	var hp := player.health
	_bar(Rect2(31, 8, 100, 6), hp.ratio(), _hp_shown, Color("c83a3a"), Color("ff8a7a"))
	var mp := player.mana
	_bar(Rect2(31, 18, 100, 4), mp.mp / mp.max_mp, 0.0, Color("3a78f0"), Color("9ad8ff"))
	text("%d" % ceili(hp.hp), Vector2(135, 15), Color("ffc0b0"))
	text("%d" % floori(mp.mp), Vector2(135, 24), Color("a8d8ff"))
	_draw_passive(school)
	# slots
	var n := 5
	var total := n * SLOT + (n - 1) * 4 + 6
	var x0 := roundf((640 - total) * 0.5)
	var y0 := 360 - SLOT - 14
	for k in n:
		var slot := SpellCaster.BASIC_SLOT if k == 0 else k - 1
		var x := x0 + k * (SLOT + 4) + (6 if k > 0 else 0)
		_draw_slot(Rect2(x, y0, SLOT, SLOT), slot)
	if _fail_msg_t > 0.0:
		text(_fail_msg, Vector2(0, y0 - 16), Color("ff9a8a"), HORIZONTAL_ALIGNMENT_CENTER, 640)
	if _banner_t > 0.0:
		var a := clampf(_banner_t, 0.0, 1.0)
		text(_banner, Vector2(0, 60), Color(1, 0.92, 0.75, a), HORIZONTAL_ALIGNMENT_CENTER, 640)
	# reticle
	if player.aim.mouse_active or Settings.aim_mode == "direct":
		var m := canvas.get_local_mouse_position().round()
		var rc := Color("a8f0ff") if player.aim.target else Color("f0e6d0")
		for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var a2 := m + d * 2.0
			var b2 := m + d * 4.0
			canvas.draw_line(a2 + Vector2(1, 1), b2 + Vector2(1, 1), Color(0, 0, 0, 0.6), 1.0)
			canvas.draw_line(a2, b2, rc, 1.0)
		canvas.draw_rect(Rect2(m, Vector2.ONE), rc)
	if show_debug:
		var fx_n := FX.i.total_particles() if FX.i else 0
		text("%d fps  fx %d  enemies %d  ts %.2f" % [Engine.get_frames_per_second(), fx_n, get_tree().get_nodes_in_group(&"enemy").size(), Engine.time_scale], Vector2(6, 350), Color("c0ffc0"))


## Passive state under the bars: Heat charges, Conduction count, Soul Echo ready.
func _draw_passive(school: String) -> void:
	var pas: Passives = player.passives
	var sc: Color = SCHOOL_COL[school]
	match school:
		"fire", "storm":
			var n: int = pas.heat if school == "fire" else pas.storm_count
			for k in 3:
				var r := Rect2(31 + k * 7, 26, 5, 4)
				canvas.draw_rect(r.grow(1), Color("0c0812"))
				if k < n:
					canvas.draw_rect(r, sc)
					canvas.draw_rect(Rect2(r.position, Vector2(5, 1)), sc.lightened(0.5))
				else:
					canvas.draw_rect(r, Color(sc, 0.15))
			text("Heat" if school == "fire" else "Conduction", Vector2(55, 31), Color(sc, 0.8))
		"hex":
			var ready := pas._echo_cd <= 0.0
			canvas.draw_rect(Rect2(31, 25, 5, 6), Color(Pal.SPECTRAL[1], 0.9 if ready else 0.25))
			canvas.draw_rect(Rect2(32, 24, 3, 1), Color(Pal.SPECTRAL[0], 0.9 if ready else 0.25))
			text("Soul Echo", Vector2(40, 31), Color(sc, 0.8 if ready else 0.4))


func _draw_slot(r: Rect2, slot: int) -> void:
	var data := player.caster.spell_in(slot)
	var shake := Vector2(roundf(sin(_fail.get(slot, 0.0) * 80.0) * 2.0), 0) if _fail.has(slot) else Vector2.ZERO
	r.position += shake
	var edge := Color("ff5a4a") if _fail.has(slot) else COL_FRAME
	frame(canvas, r, COL_BG, edge)
	var key := Settings.key_label("attack") if slot == SpellCaster.BASIC_SLOT else Settings.key_label("spell_%d" % (slot + 1))
	text(key, Vector2(r.position.x, r.end.y + 9), Color("c8b898"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if data == null:
		canvas.draw_texture_rect_region(ICONS, Rect2(r.position + Vector2(3, 3), Vector2(16, 16)), Rect2(15 * 16, 0, 16, 16))
		return
	var usable := player.mana.can_spend(data.mana_cost)
	var tint := Color.WHITE if usable else Color(0.5, 0.5, 0.6)
	canvas.draw_texture_rect_region(ICONS, Rect2(r.position + Vector2(3, 3), Vector2(16, 16)), Rect2(data.icon * 16, 0, 16, 16), tint)
	var rem := player.caster.remaining(data.id)
	if rem > 0.0 and data.cooldown > 0.0:
		var f := rem / data.cooldown
		var h := roundf((r.size.y - 2) * f)
		canvas.draw_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, h), Color(0.05, 0.03, 0.1, 0.7))
		if rem > 0.5 and not data.is_basic:
			text("%d" % ceili(rem), Vector2(r.position.x, r.position.y + 15), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if data.mana_cost > 0.0:
		text("%d" % int(data.mana_cost), Vector2(r.position.x, r.position.y - 2), Color("8ac8ff") if usable else Color("ff8a7a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if player.caster.state != SpellCaster.IDLE and player.caster.cur == data:
		canvas.draw_rect(r.grow(1), Color(1, 1, 1, 0.5), false, 1.0)
