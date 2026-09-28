class_name BuildMode
extends CanvasLayer
## Home building at the sanctuary (B). Choose an object (1-6 or Q/E), move
## its ghost on a half-metre grid (arrows or mouse), R rotates, Enter places.
## Tab cycles placed objects: Enter picks one up to move (free), X removes it
## (refunding what was paid). The ghost turns red and explains when a spot
## isn't allowed. Esc leaves.

signal finished

const FONT := preload("res://assets/fonts/wardhand.tres")
const GRID := 0.5

var region: Region
var player: Player
var canvas: Control
var pick := 0
var rot := 0
var pos := Vector3.ZERO
var ghost: Node3D
var moving := -1          # index in GameState.placed being moved (-1: new object)
var editing := -1         # index of the placed object selected with Tab
var _reason := ""
var _msg := ""
var _msg_t := 0.0
var _mouse_used := false


func open(r: Region, p: Player) -> void:
	region = r
	player = p
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_ui)
	add_child(canvas)
	p.input_enabled = false
	pos = _snap(p.global_position + p.look_dir * 3.0)
	_make_ghost()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("ui_open", -6.0)


func _id() -> StringName:
	return Placeables.ORDER[pick]


func _unlocked(id: StringName) -> bool:
	return GameState.inv.decor.has(id)


func _snap(p: Vector3) -> Vector3:
	return Vector3(snappedf(p.x, GRID), 0.0, snappedf(p.z, GRID))


func _make_ghost() -> void:
	if ghost:
		ghost.queue_free()
	var id: StringName = GameState.placed[moving].id if moving >= 0 else _id()
	ghost = Placeables.build(id, rot, false)
	region.add_child(ghost)
	_update_ghost()


func _update_ghost() -> void:
	var id: StringName = GameState.placed[moving].id if moving >= 0 else _id()
	ghost.global_position = region._ground(pos.x, pos.z)
	_reason = region.call("can_place", id, pos, rot, moving) as String
	if moving < 0 and _reason == "":
		if not _unlocked(id):
			_reason = "Not yet earned"
		elif GameState.inv.coins < int(Placeables.DEFS[id].cost):
			_reason = "Needs %d coins" % Placeables.DEFS[id].cost
	Placeables.tint(ghost, Color(0.6, 1.0, 0.6) if _reason == "" else Color(1.0, 0.45, 0.4))
	ghost.visible = editing < 0


func _process(delta: float) -> void:
	_msg_t -= delta
	canvas.queue_redraw()


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and editing < 0:
		_mouse_used = true
		var cam := player.get_viewport().get_camera_3d()
		var mp := player.get_viewport().get_mouse_position()
		var from := cam.project_ray_origin(mp)
		var dir := cam.project_ray_normal(mp)
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0, 1)
		var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			pos = _snap(hit.position)
			_update_ghost()
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and editing < 0:
		_place()
		return
	if not (e is InputEventKey and e.pressed):
		return
	get_viewport().set_input_as_handled()
	var k := (e as InputEventKey).keycode
	var step := Vector3.ZERO
	match k:
		KEY_LEFT, KEY_A:
			step.x = -GRID
		KEY_RIGHT, KEY_D:
			step.x = GRID
		KEY_UP, KEY_W:
			step.z = -GRID
		KEY_DOWN, KEY_S:
			step.z = GRID
		KEY_R:
			rot = (rot + 1) % 4
			_make_ghost()
		KEY_Q:
			_choose(pick - 1)
		KEY_E:
			_choose(pick + 1)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			_choose(k - KEY_1)
		KEY_TAB:
			_cycle_placed()
		KEY_X, KEY_DELETE, KEY_BACKSPACE:
			_remove()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if editing >= 0:
				_pick_up()
			else:
				_place()
		KEY_ESCAPE:
			if editing >= 0 or moving >= 0:
				_cancel_edit()
			else:
				_close()
	if step != Vector3.ZERO and editing < 0:
		pos += step
		_update_ghost()
		Sfx.play("ui_move", -12.0)


func _choose(i: int) -> void:
	if moving >= 0:
		return
	editing = -1
	pick = posmod(i, Placeables.ORDER.size())
	_make_ghost()
	Sfx.play("ui_move", -8.0)


func _place() -> void:
	if _reason != "":
		_say(_reason)
		return
	var id: StringName = GameState.placed[moving].id if moving >= 0 else _id()
	if moving >= 0:
		var entry: Dictionary = GameState.placed[moving]
		entry.x = pos.x
		entry.z = pos.z
		entry.rot = rot
		moving = -1
		_say("Moved")
	else:
		var cost := int(Placeables.DEFS[id].cost)
		if not GameState.inv.spend(cost):
			_say("Needs %d coins" % cost)
			return
		GameState.placed.append({"id": id, "x": pos.x, "z": pos.z, "rot": rot, "paid": cost})
		_say("Placed: %s (-%d coins)" % [Placeables.DEFS[id].name, cost])
	region.call("rebuild_placed")
	FX3.burst(region._ground(pos.x, pos.z) + Vector3(0, 0.3, 0), 16, Pal.DUST, Vector2(0.5, 2.0), Vector2(0.3, 0.6), {"gravity": 4.0})
	Sfx.play("ui_select", -4.0)
	SaveSystem.autosave()
	_make_ghost()


func _cycle_placed() -> void:
	if GameState.placed.is_empty() or moving >= 0:
		return
	editing = (editing + 1) % GameState.placed.size()
	var e: Dictionary = GameState.placed[editing]
	pos = Vector3(e.x, 0, e.z)
	_update_ghost()
	Sfx.play("ui_move", -8.0)


func _pick_up() -> void:
	moving = editing
	editing = -1
	rot = int(GameState.placed[moving].rot)
	region.call("rebuild_placed", moving)
	_make_ghost()
	_say("Moving: Enter to set it down")


func _remove() -> void:
	var i := editing if editing >= 0 else moving
	if i < 0:
		return
	var e: Dictionary = GameState.placed[i]
	GameState.inv.earn(int(e.get("paid", 0)))
	_say("Removed %s (+%d coins)" % [Placeables.DEFS[e.id].name, int(e.get("paid", 0))])
	GameState.placed.remove_at(i)
	editing = -1
	moving = -1
	region.call("rebuild_placed")
	SaveSystem.autosave()
	_make_ghost()


func _cancel_edit() -> void:
	editing = -1
	moving = -1
	region.call("rebuild_placed")
	_make_ghost()


func _say(s: String) -> void:
	_msg = s
	_msg_t = 2.5


func _close() -> void:
	if ghost:
		ghost.queue_free()
	if moving >= 0:
		region.call("rebuild_placed")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player.resume_input()
	Sfx.play("ui_back", -8.0)
	finished.emit()
	queue_free()


func _draw_ui() -> void:
	var bar := Rect2(20, 6, 600, 44)
	HUD.frame(canvas, bar, Color("140f1e", 0.92))
	var x := 30.0
	for k in Placeables.ORDER.size():
		var id: StringName = Placeables.ORDER[k]
		var d: Dictionary = Placeables.DEFS[id]
		var sel: bool = k == pick and moving < 0 and editing < 0
		var ok := _unlocked(id)
		var label := "%d %s" % [k + 1, d.name]
		var col := Color("f4d890") if sel else (Color("d8ccb4") if ok else Color("5a5060"))
		canvas.draw_string(FONT, Vector2(x, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
		canvas.draw_string(FONT, Vector2(x, 32), ("%d coins" % d.cost) if ok else "locked", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a89060") if ok else Color("5a5060"))
		x += FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 18
	canvas.draw_string(FONT, Vector2(30, 45), "Coins %d    Q/E or 1-6 choose   Arrows/mouse move   R rotate   Enter place   Tab pick placed   X remove   Esc done" % GameState.inv.coins,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("8a7a60"))
	if editing >= 0:
		var e: Dictionary = GameState.placed[editing]
		_banner("Selected: %s   Enter move   X remove (+%d)" % [Placeables.DEFS[e.id].name, int(e.get("paid", 0))], Color("9ae8ff"))
	elif _reason != "":
		_banner(_reason, Color("ff9a8a"))
	if _msg_t > 0.0:
		canvas.draw_string(FONT, Vector2(0, 330), _msg, HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color("f4d890"))


func _banner(s: String, col: Color) -> void:
	var w := FONT.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 16
	HUD.frame(canvas, Rect2(320 - w * 0.5, 56, w, 14), Color("140f1e", 0.9))
	canvas.draw_string(FONT, Vector2(0, 66), s, HORIZONTAL_ALIGNMENT_CENTER, 640, 9, col)
