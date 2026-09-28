extends Node
## Scripted input for automated captures and playtest evidence. Only active
## when the game is launched with `-- --demo=<name> [--shots=<abs dir>]`.
## Steps: [seconds, command, arg]. Commands: hold, release, tap, aim (world
## offset from the player), aim_enemy, clear_aim, shot, burst (N consecutive
## frames), freeze / unfreeze (enemies), quit.

const DEMOS := {
	"spells": [
		[0.2, "freeze", ""], [0.3, "shot", "a01_idle"],
		[0.5, "hold", "move_right"], [0.8, "shot", "a02_run"], [1.0, "release", "move_right"],
		[1.3, "aim_enemy", ""], [1.5, "tap", "spell_1"], [1.5, "burst", "b_lance:40"],
		[2.8, "hold", "move_right"], [4.2, "release", "move_right"],
		[4.4, "tap", "attack"], [4.4, "burst", "c_gust:16"],
		[5.2, "unfreeze", ""], [5.3, "hold", "attack"], [6.0, "release", "attack"],
		[6.2, "hold", "move_left"], [6.8, "release", "move_left"],
		[7.0, "shot", "d01"], [7.4, "shot", "d02"], [7.8, "shot", "d03"], [8.2, "shot", "d04"],
		[8.6, "shot", "d05"], [9.0, "shot", "d06"], [9.4, "tap", "dodge"], [9.45, "shot", "d07"],
		[9.8, "shot", "d08"], [10.2, "tap", "spell_1"], [10.5, "shot", "d09"], [11.0, "shot", "d10"],
		[11.5, "quit", ""],
	],
	"tour": [
		[0.1, "freeze", ""], [0.3, "shot", "t01"], [0.4, "hold", "move_left"], [1.0, "shot", "t02_slope"],
		[1.3, "tap", "jump"], [1.8, "tap", "jump"], [2.4, "shot", "t03_climb"], [2.8, "release", "move_left"], [3.0, "shot", "t04_plateau"],
		[3.2, "hold", "move_right"], [4.0, "shot", "t05"], [5.0, "shot", "t06_hill"], [6.0, "shot", "t07"],
		[6.9, "tap", "jump"], [7.2, "shot", "t08_jump"], [7.6, "shot", "t09_outcrop"], [8.5, "shot", "t10"],
		[9.5, "shot", "t11"], [10.5, "shot", "t12"], [11.2, "tap", "jump"], [11.8, "shot", "t13_hill"], [12.5, "shot", "t14"],
		[13.0, "quit", ""],
	],
	"idle_die": [
		[0.1, "hold", "move_right"], [0.8, "release", "move_right"], [40.0, "quit", ""],
	],
	"combat": [
		[0.7, "hold", "move_right"], [1.9, "release", "move_right"], [2.0, "aim_enemy", ""],
		[2.2, "tap", "spell_1"], [3.3, "tap", "spell_1"], [4.0, "hold", "attack"], [5.4, "release", "attack"],
		[6.5, "tap", "dodge"], [7.6, "tap", "spell_1"], [8.2, "hold", "attack"], [9.7, "release", "attack"],
		[10.5, "tap", "spell_1"], [12.0, "quit", ""],
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--demo="):
			steps = DEMOS.get(a.trim_prefix("--demo="), [])
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
			_player().aim.override = _player().global_position + (s[2] as Vector2)
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
			_burst_i = 0
		"freeze", "unfreeze":
			for e in get_tree().get_nodes_in_group(&"enemy"):
				e.set_physics_process(cmd == "unfreeze")
				if cmd == "freeze":
					e.sprite.play(&"idle")
		"quit":
			get_tree().quit()


func _shot(name: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(name + ".png"))
