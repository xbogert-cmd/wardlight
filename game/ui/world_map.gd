class_name WorldMap
extends Control
## The world map (M): places the wizard has learned, the roads between them,
## and waystone journeys (dashed) once both ends are known. Shows where the
## wizard is and the current objective.

const FONT := preload("res://assets/fonts/wardhand.tres")
const PANEL := Rect2(110, 40, 420, 270)
## place -> [position in the panel, label]
const PLACES := {
	&"sanctuary": [Vector2(70, 150), "The Sanctuary"],
	&"hearthmere": [Vector2(165, 170), "Hearthmere"],
	&"briarwood": [Vector2(265, 140), "Briarwood Road"],
	&"old_ward": [Vector2(345, 70), "The Old Ward"],
}
const ROADS := [[&"sanctuary", &"hearthmere"], [&"hearthmere", &"briarwood"]]
const JOURNEYS := [[&"briarwood", &"old_ward"]]

var is_open := false
var _t := 0.0


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
	Sfx.play("ui_open", -6.0)


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.resume_input()
	Sfx.play("ui_back", -8.0)


func _process(delta: float) -> void:
	if is_open:
		_t += delta
		queue_redraw()


func _input(e: InputEvent) -> void:
	if is_open and (e.is_action_pressed(&"map") or e.is_action_pressed(&"pause") or e.is_action_pressed(&"ui_cancel") \
			or (e is InputEventMouseButton and e.pressed)):
		get_viewport().set_input_as_handled()
		close()


func _draw() -> void:
	HUD.frame(self, PANEL, Color("1a1622", 0.96))
	var o := PANEL.position
	_t2("World map", o + Vector2(12, 16), Color("f4d890"))
	_t2("M / Esc close", o + Vector2(PANEL.size.x - 84, 16), Color("8a7a60"))
	# a little terrain: forest dots and the misty rise of the Old Ward
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for k in 90:
		var p := o + Vector2(r.randf_range(20, 400), r.randf_range(40, 250))
		draw_rect(Rect2(p.round(), Vector2(2, 3)), Color("2a4a34", 0.6))
	for pair: Array in ROADS:
		if GameState.known.has(pair[0]) and GameState.known.has(pair[1]):
			_line(o + PLACES[pair[0]][0], o + PLACES[pair[1]][0], Color("c8a878"), false)
	for pair: Array in JOURNEYS:
		if GameState.known.has(pair[0]) and GameState.known.has(pair[1]):
			_line(o + PLACES[pair[0]][0], o + PLACES[pair[1]][0], Color("b8a0f0"), true)
	var here: StringName = Region.current.id if Region.current else &""
	for id in PLACES:
		if not GameState.known.has(id):
			continue
		var p: Vector2 = o + PLACES[id][0]
		var lit: bool = id == &"hearthmere" and GameState.flag(&"ward_restored") or id == &"sanctuary" or id == &"old_ward" and GameState.flag(&"ward_restored")
		draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color("0c0812"))
		draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color("9ae8ff") if lit else Color("8a7a60"))
		_t2(PLACES[id][1], p + Vector2(-30, 16), Color("f0e6d0") if id == here else Color("b8aa94"))
		if id == here:
			var bob := roundf(sin(_t * 5.0) * 1.5)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -12 + bob), p + Vector2(4, -12 + bob), p + Vector2(0, -6 + bob)]), Color("f4d890"))
	var step := Quests.step_text(Quests.MAIN)
	if step != "":
		_t2("Objective: " + step, o + Vector2(12, PANEL.size.y - 12), Color("d8c8a0"))


func _line(a: Vector2, b: Vector2, col: Color, dashed: bool) -> void:
	var n := int(a.distance_to(b) / 3.0)
	for k in n:
		if dashed and (k / 2) % 2 == 1:
			continue
		draw_rect(Rect2(a.lerp(b, float(k) / n).round(), Vector2(2, 2)), col)


func _t2(s: String, pos: Vector2, col: Color) -> void:
	draw_string(FONT, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.6))
	draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
