class_name Journal
extends Control
## Compact quest journal (Q): active quests with their current step, then
## finished ones. Keyboard or click to close.

const FONT := preload("res://assets/fonts/wardhand.tres")
const PANEL := Rect2(150, 50, 340, 250)

var player: Player
var is_open := false


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
	queue_redraw()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	if player:
		player.resume_input()
	Sfx.play("ui_back", -8.0)


func _input(e: InputEvent) -> void:
	if not is_open:
		return
	if e.is_action_pressed(&"journal") or e.is_action_pressed(&"pause") or e.is_action_pressed(&"ui_cancel") \
			or (e is InputEventMouseButton and e.pressed):
		get_viewport().set_input_as_handled()
		close()


func _draw() -> void:
	HUD.frame(self, PANEL)
	var p := PANEL.position
	_t("Journal", p + Vector2(12, 16), Color("f4d890"))
	_t("Q / Esc close", p + Vector2(PANEL.size.x - 90, 16), Color("8a7a60"))
	var y := p.y + 36
	var active: Array = []
	var done: Array = []
	for id in Quests.DATA:
		if GameState.quest_active(id):
			active.append(id)
		elif GameState.quest_done(id):
			done.append(id)
	if active.is_empty() and done.is_empty():
		_t("No entries yet.", Vector2(p.x + 12, y), Color("a89878"))
	for id in active:
		_t(Quests.title(id), Vector2(p.x + 12, y), Color("f0e6d0"))
		y += 12
		for line in Dialogue._wrap(Quests.step_text(id), PANEL.size.x - 36):
			_t(line, Vector2(p.x + 22, y), Color("c8b898"))
			y += 11
		y += 6
	if not done.is_empty():
		_t("Completed", Vector2(p.x + 12, y), Color("8a7a60"))
		y += 12
		for id in done:
			_t(Quests.title(id), Vector2(p.x + 22, y), Color("7a8a6a"))
			y += 11


func _t(s: String, pos: Vector2, col: Color) -> void:
	draw_string(FONT, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.6))
	draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
