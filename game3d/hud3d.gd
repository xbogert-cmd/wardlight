extends CanvasLayer
## Minimal HUD for the 3D mockup: health, mana, two slots, reticle, hints.

var player: Player3D
var canvas: Control


func _ready() -> void:
	layer = 10
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)
	add_child(canvas)


func _process(_d: float) -> void:
	canvas.queue_redraw()


func _t(s: String, pos: Vector2, col := Color("f0e6d0"), align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	canvas.draw_string(HUD.FONT, pos + Vector2(1, 1), s, align, w, 9, Color(0, 0, 0, 0.7))
	canvas.draw_string(HUD.FONT, pos, s, align, w, 9, col)


func _draw_hud() -> void:
	if player == null:
		return
	HUD.frame(canvas, Rect2(6, 6, 20, 20))
	canvas.draw_texture_rect_region(HUD.ICONS, Rect2(8, 8, 16, 16), Rect2(14 * 16, 0, 16, 16))
	for bar: Array in [[Rect2(31, 8, 100, 6), player.health.ratio(), Color("c83a3a")], [Rect2(31, 18, 100, 4), player.mana.mp / player.mana.max_mp, Color("3a78f0")]]:
		var r: Rect2 = bar[0]
		HUD.frame(canvas, r.grow(1), Color("0c0812"), HUD.COL_FRAME_DARK)
		canvas.draw_rect(Rect2(r.position, Vector2(roundf(r.size.x * bar[1]), r.size.y)), bar[2])
	for k in 2:
		var r := Rect2(292 + k * 30, 360 - 36, 22, 22)
		HUD.frame(canvas, r)
		canvas.draw_texture_rect_region(HUD.ICONS, Rect2(r.position + Vector2(3, 3), Vector2(16, 16)), Rect2((14 if k == 0 else 8) * 16, 0, 16, 16))
		_t("J" if k == 0 else "1", Vector2(r.position.x, r.end.y + 9), Color("c8b898"), HORIZONTAL_ALIGNMENT_CENTER, 22)
	_t("Briarwood Crossing  (3D look mockup)", Vector2(0, 16), Color("f4d890"), HORIZONTAL_ALIGNMENT_CENTER, 640)
	_t("WASD move   Shift dodge   click / J staff   1 Arc Lance", Vector2(0, 352), Color("a89878"), HORIZONTAL_ALIGNMENT_RIGHT, 634)
	var m := canvas.get_local_mouse_position().round()
	for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		canvas.draw_line(m + d * 2.0 + Vector2(1, 1), m + d * 4.0 + Vector2(1, 1), Color(0, 0, 0, 0.6), 1.0)
		canvas.draw_line(m + d * 2.0, m + d * 4.0, Color("a8f0ff"), 1.0)
