extends Node
## Scripted input for automated captures and playtest evidence. Only active
## when the game is launched with `-- --demo=<name> [--shots=<abs dir>]`.
## Steps: [seconds, command, arg]. Commands: hold, release, tap, aim ("x,z"
## metres from the player), aim_enemy, clear_aim, shot, burst (name:frames:every),
## freeze / unfreeze (enemies), tp ("x,z"), tp_near (metres west of the nearest
## enemy), pos (print), learn, school, upg, reset, book, key, quit.

static func _all_spells() -> Array:
	var out: Array = [[0.1, "freeze", ""], [0.15, "learn", ""], [0.2, "tp_near", "3.5"], [0.3, "aim_enemy", ""]]
	var t := 0.5
	for upg in [0, 1]:
		out.append([t, "upg", str(upg)])
		for sch in ["fire", "hex", "storm"]:
			out.append([t, "school", sch])
			for k in 4:
				out.append([t, "reset", ""])
				out.append([t + 0.02, "tap", "spell_%d" % (k + 1)])
				out.append([t + 0.02, "burst", "%s%d_%s:48:4" % [sch, k + 1, "up" if upg else "base"]])
				t += 1.3
	out.append([t, "hold", "attack"])
	for sch in ["fire", "hex", "storm"]:
		out.append([t, "school", sch])
		out.append([t + 0.02, "burst", "basic_%s:30:3" % sch])
		t += 0.8
	out.append([t, "release", "attack"])
	out.append([t + 0.2, "quit", ""])
	return out


const DEMOS := {
	# first look: walk in, lance a hound, gust, dodge
	"look": [
		[0.6, "shot", "l01_start"],
		[0.7, "hold", "move_right"], [1.6, "shot", "l02_walk"], [1.9, "release", "move_right"],
		[2.0, "aim_enemy", ""], [2.1, "tap", "spell_1"], [2.1, "burst", "l03_lance:36:3"],
		[3.4, "hold", "attack"], [3.5, "burst", "l04_gust:20:4"], [4.4, "release", "attack"],
		[4.6, "tap", "dodge"], [4.62, "shot", "l05_dodge"],
		[5.5, "shot", "l06"], [6.5, "shot", "l07"], [7.5, "quit", ""],
	],
	# every enemy role: stand near each and let it attack
	"enemies": [
		[0.3, "tp", "10,2"], [1.5, "shot", "e01_hounds"], [2.3, "shot", "e02_hounds"], [3.0, "shot", "e03_hounds"],
		[3.2, "tp", "17,-3"], [4.4, "shot", "e04_raider_hexer"], [5.0, "shot", "e05"], [5.6, "shot", "e06"],
		[5.8, "tp", "-12,2"], [7.0, "shot", "e07_knot"], [7.6, "shot", "e08_knot"], [8.2, "shot", "e09_knot"],
		[8.4, "tp", "21,-9"], [9.6, "shot", "e10_sentinel"], [10.3, "shot", "e11_sentinel"], [11.0, "shot", "e12_sentinel"],
		[11.2, "quit", ""],
	],
	"idle_die": [
		[0.1, "hold", "move_right"], [0.8, "release", "move_right"], [40.0, "quit", ""],
	],
	"book": [
		[0.5, "learn", ""], [0.7, "book", ""], [1.0, "shot", "book1"], [1.2, "key", "4194321"], [1.4, "shot", "book2"],
		[2.0, "key", "4194322"], [2.2, "shot", "book3"], [2.4, "key", "4194306"], [2.6, "shot", "book4"], [2.8, "quit", ""],
	],
}

var steps: Array = []
var idx := 0
var t := 0.0
var shot_dir := ""
var _taps: Array = []
var _burst_name := ""
var _burst_left := 0
var _burst_i := 0
var _burst_every := 1
var _burst_frame := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--demo="):
			var nm := a.trim_prefix("--demo=")
			steps = _all_spells() if nm == "allspells" else DEMOS.get(nm, [])
		elif a.begins_with("--shots="):
			shot_dir = a.trim_prefix("--shots=")
	if steps.is_empty():
		queue_free()
	elif shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)


func _process(delta: float) -> void:
	t += delta / maxf(Engine.time_scale, 0.0001) if Engine.time_scale > 0.0 else delta
	for a in _taps:
		Input.action_release(a)
	_taps.clear()
	if _burst_left > 0:
		_burst_left -= 1
		_burst_frame += 1
		if _burst_frame % _burst_every == 0:
			_burst_i += 1
			_shot("%s_%02d" % [_burst_name, _burst_i])
	while idx < steps.size() and t >= steps[idx][0]:
		_run(steps[idx])
		idx += 1


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _run(s: Array) -> void:
	var cmd: String = s[1]
	match cmd:
		"hold":
			Input.action_press(s[2])
		"release":
			Input.action_release(s[2])
		"tap":
			Input.action_press(s[2])
			_taps.append(s[2])
		"aim":
			var off: PackedStringArray = (s[2] as String).split(",")
			_player().aim.override = _player().global_position + Vector3(float(off[0]), 0, float(off[1]))
		"aim_enemy":
			_player().aim.override_enemy = true
		"clear_aim":
			_player().aim.override = null
			_player().aim.override_enemy = false
		"shot":
			_shot(s[2])
		"burst":
			var parts: PackedStringArray = (s[2] as String).split(":")
			_burst_name = parts[0]
			_burst_left = int(parts[1])
			_burst_every = int(parts[2]) if parts.size() > 2 else 1
			_burst_i = 0
			_burst_frame = 0
		"freeze", "unfreeze":
			for e in get_tree().get_nodes_in_group(&"enemy"):
				e.set_physics_process(cmd == "unfreeze")
				if cmd == "freeze":
					e.sprite.play(&"idle")
		"quit":
			print("DEMO fps=%d" % Engine.get_frames_per_second())
			get_tree().quit()
		"learn":
			for sc in WizardState.SCHOOLS:
				for id in WizardState.BASE[sc]:
					_player().wiz.unlocked[id] = true
		"school":
			_player().wiz.switch_school(s[2])
		"upg":
			_player().wiz.upgrades.clear()
			if s[2] == "1":
				for id in SpellDB.all():
					_player().wiz.upgrades[id] = true
		"reset":
			var pl := _player()
			pl.caster.ready_at.clear()
			pl.mana.refill()
			pl.health.reset()
			for e in get_tree().get_nodes_in_group(&"enemy"):
				e.health.reset()
				e.statuses.clear()
		"book":
			get_tree().root.get_node("Main").spellbook.open()
		"key":
			var ev := InputEventKey.new()
			ev.physical_keycode = int(s[2])
			ev.pressed = true
			Input.parse_input_event(ev)
			var up := ev.duplicate()
			up.pressed = false
			Input.parse_input_event.call_deferred(up)
		"tp":
			# "x,z": stand on the ground there
			var pl3 := _player()
			var xz: PackedStringArray = (s[2] as String).split(",")
			pl3.global_position = SpellEffect.ground_at(Vector3(float(xz[0]), pl3.global_position.y, float(xz[1])), pl3)
			pl3.velocity = Vector3.ZERO
		"pos":
			print("DEMO pos ", s[2], " ", _player().global_position)
		"tp_near":
			# stand `arg` metres west of the nearest enemy, facing it
			var pl2 := _player()
			var e2: Node3D = null
			for e in SpellEffect.enemies():
				if e2 == null or pl2.global_position.distance_to(e.global_position) < pl2.global_position.distance_to(e2.global_position):
					e2 = e
			if e2:
				pl2.global_position = SpellEffect.ground_at(e2.global_position - Vector3(float(s[2]), 0, 0), pl2)
				pl2.velocity = Vector3.ZERO
				pl2.face(1)
				pl2.look_dir = Vector3.RIGHT


func _shot(name: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(name + ".png"))
