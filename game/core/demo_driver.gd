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
	# tree fading + ground rings on the ruins hill
	"check": [
		[0.1, "freeze", ""], [0.2, "learn", ""], [0.3, "tp", "-12,2"], [1.0, "shot", "k01_behind_tree"],
		[1.1, "school", "hex"], [1.2, "tp", "-16.5,1"], [1.8, "tap", "spell_3"], [2.3, "shot", "k02_siphon_slope"],
		[3.6, "school", "fire"], [3.7, "tap", "spell_3"], [4.1, "shot", "k03_ward_slope"], [4.3, "quit", ""],
	],
	# every region on arrival, plus a few landmarks
	"regions": [
		[0.8, "shot", "r01_sanctuary"], [0.9, "tp", "8,-2"], [1.5, "shot", "r02_sanctuary_study"],
		[1.6, "tp", "12,4"], [2.2, "shot", "r03_bramble"],
		[2.4, "travel", "hearthmere:west"], [3.6, "tp", "-2,5"], [4.3, "shot", "r04_square"], [4.4, "tp", "12,-2"], [5.0, "shot", "r05_smithy"],
		[5.2, "travel", "briarwood:west"], [6.4, "tp", "-12,12"], [7.0, "shot", "r06_roadward"], [7.1, "tp", "20,-11"], [7.8, "shot", "r07_trunk"],
		[7.9, "tp", "12,9"], [8.5, "shot", "r08_fawn"], [8.6, "tp", "36,-10"], [9.3, "shot", "r09_gate"],
		[9.4, "travel", "old_ward:waystone"], [13.0, "shot", "r10_oldward"], [13.1, "tp", "0,-9"], [13.8, "shot", "r11_climb"],
		[13.9, "tp", "0,-22"], [14.6, "shot", "r12_arena"], [14.8, "quit", ""],
	],
	# the whole first adventure, driven by script (checks quest/flag order)
	"story": [
		[0.5, "tp", "6.3,2.2"], [0.9, "tap", "interact"], [1.3, "next", ""], [1.5, "next", ""], [1.7, "next", ""], [1.9, "next", ""],
		[2.2, "state", "pell"], [2.4, "aim_enemy", ""], [2.5, "tap", "spell_1"], [3.6, "next", ""], [3.8, "clear_aim", ""], [4.0, "state", "bramble"],
		[4.4, "travel", "hearthmere:west"], [6.0, "tp", "-3.2,1.6"], [6.4, "tap", "interact"], [6.8, "next", ""], [7.0, "next", ""],
		[7.2, "next", ""], [7.4, "next", ""], [7.6, "state", "maren"], [7.8, "shot", "s01_village_dark"],
		[8.2, "travel", "briarwood:west"], [9.8, "tp", "-9.6,10.6"], [10.2, "tap", "interact"], [12.4, "next", ""], [12.6, "next", ""],
		[12.8, "shot", "s02_ward_lit"], [13.0, "state", "ward"],
		[13.4, "tp", "22.4,-12"], [13.9, "tap", "interact"], [17.0, "shot", "s03_trunk_moved"], [17.2, "state", "trunk"],
		[17.6, "tp", "12.2,11.5"], [18.0, "tap", "interact"], [21.4, "next", ""], [21.6, "next", ""], [22.0, "state", "fawn"],
		[22.4, "tp", "30,-11"], [23.0, "kill", ""], [24.0, "tp", "37.4,-14.2"], [24.5, "tap", "interact"], [24.9, "next", ""],
		[25.1, "next", ""], [25.3, "next", ""], [25.6, "pick", "1"], [26.0, "next", ""], [26.4, "state", "isolde"],
		[27.0, "tp", "40,-11.4"], [27.4, "tap", "interact"],
		[29.0, "shot", "s04_journey"], [32.0, "tp", "0,-26.5"], [32.6, "shot", "s05_arena"], [33.0, "kill", ""], [33.5, "kill", ""],
		[38.0, "next", ""], [38.3, "next", ""], [38.6, "next", ""], [39.0, "shot", "s06_cleansed"], [39.2, "state", "guardian"],
		[39.6, "travel", "briarwood:waystone"], [44.0, "travel", "hearthmere:east"], [45.5, "tp", "-3.2,1.6"], [46.0, "shot", "s07_village_restored"],
		[46.2, "tap", "interact"], [46.6, "next", ""], [46.8, "next", ""], [47.0, "next", ""], [47.4, "state", "done"], [47.6, "shot", "s08_after"], [48.0, "quit", ""],
	],
	# levitate across the chasm to the ledge, then step off it on foot
	"levitate": [
		[0.3, "travel", "briarwood:west"], [1.8, "unlock", "levitate"], [1.9, "tp", "-3,-15.2"], [2.4, "pos", "cliff"],
		[2.5, "hold", "jump"], [2.6, "hold", "up"], [2.9, "shot", "v01_float"], [3.3, "shot", "v02_over_gap"], [3.55, "release", "up"],
		[3.6, "release", "jump"], [3.9, "pos", "ledge"], [4.0, "shot", "v03_ledge"], [4.1, "tap", "interact"], [4.6, "next", ""],
		[5.0, "hold", "up"], [5.6, "release", "up"], [6.0, "pos", "after_fall"], [6.1, "shot", "v04_back"], [6.3, "quit", ""],
	],
	# fight the Gatebreaker for real (storm school, all spells), sampling frames
	"troll": [
		[0.3, "travel", "briarwood:west"], [1.8, "learn", ""], [1.9, "tp", "27,-11.5"], [2.0, "aim_enemy", ""],
		[2.4, "tap", "spell_1"], [2.6, "burst", "t_fight:240:10"], [3.4, "tap", "spell_4"], [4.4, "tap", "spell_1"],
		[5.0, "hold", "attack"], [6.0, "release", "attack"], [6.2, "tap", "dodge"], [6.8, "tap", "spell_1"], [7.6, "tap", "spell_2"],
		[8.4, "tap", "spell_1"], [9.2, "hold", "move_left"], [9.8, "release", "move_left"], [10.0, "tap", "spell_1"],
		[11.0, "tap", "spell_4"], [12.0, "tap", "spell_1"], [13.0, "hold", "attack"], [14.5, "release", "attack"], [15.5, "quit", ""],
	],
	"warden": [
		[0.3, "travel", "old_ward:waystone"], [3.5, "learn", ""], [3.6, "tp", "0,-23.5"], [3.8, "aim_enemy", ""],
		[4.0, "burst", "w_a:120:10"], [4.2, "tap", "spell_1"], [5.2, "tap", "spell_1"], [6.4, "tap", "dodge"], [7.0, "tap", "spell_4"],
		[8.0, "tap", "spell_1"], [9.0, "hold", "attack"], [10.5, "release", "attack"], [11.0, "wound", "0.5"],
		[11.2, "burst", "w_b:150:10"], [13.5, "tap", "spell_1"], [14.5, "tap", "dodge"], [15.5, "tap", "spell_1"], [16.5, "tap", "spell_2"],
		[18.0, "tap", "spell_1"], [20.0, "quit", ""],
	],
	"menus": [
		[0.3, "flag", "ward_restored"], [0.4, "travel", "hearthmere:west"], [1.8, "map", ""], [2.1, "shot", "m1_map"],
		[2.3, "key", "4194305"], [2.6, "journal", ""], [2.9, "shot", "m2_journal"], [3.2, "quit", ""],
	],
	"title": [[1.0, "shot", "title"], [1.2, "key", "4194322"], [1.25, "key", "4194322"], [1.3, "key", "4194309"], [1.6, "shot", "settings"],
		[1.7, "key", "4194322"], [1.8, "key", "4194322"], [1.9, "key", "4194321"], [2.1, "shot", "settings2"], [2.2, "key", "4194305"], [2.5, "shot", "title2"], [2.7, "quit", ""]],
	"inv": [
		[0.3, "give", "stormcoil"], [0.35, "give", "moonstone"], [0.4, "give", "moonstone"], [0.45, "give", "ward_bell"], [0.5, "give", "wardweave"],
		[0.6, "inventory", ""], [0.9, "shot", "i1_inventory"], [1.0, "key", "4194321"], [1.1, "key", "4194309"], [1.4, "shot", "i2_equipped"],
		[1.6, "key", "4194305"], [1.8, "travel", "sanctuary:start"], [3.0, "tp", "3,-7.8"], [3.3, "tap", "interact"], [3.6, "key", "4194309"],
		[3.8, "key", "4194322"], [4.0, "key", "4194309"], [4.3, "shot", "i3_fusion"], [4.5, "key", "4194309"], [4.9, "shot", "i4_fused"],
		[5.1, "key", "4194305"], [5.5, "state", "inv"], [5.6, "quit", ""],
	],
	"tamsin": [
		[0.3, "travel", "briarwood:west"], [1.8, "tp", "-15.5,2.5"], [2.2, "kill", ""], [2.8, "tp", "-18.2,2.2"], [3.2, "shot", "c1_freed"],
		[3.4, "tap", "interact"], [3.8, "next", ""], [4.0, "next", ""], [4.2, "next", ""], [4.5, "pick", "0"], [4.9, "state", "tamsin"],
		[5.0, "hold", "move_right"], [6.5, "shot", "c2_follow"], [7.0, "release", "move_right"],
		[7.2, "tp", "6,0"], [7.4, "aim_enemy", ""], [8.0, "burst", "c3_fight:60:10"], [8.2, "tap", "spell_1"], [9.5, "hold", "attack"],
		[11.5, "release", "attack"], [12.0, "tap", "spell_2"], [14.0, "quit", ""],
	],
	# B at home: place a lantern, bench, tent and hut on the plot
	"build": [
		[0.3, "coins", "200"], [0.35, "decor_all", ""], [0.5, "tp", "6,6"], [1.0, "key", "66"], [1.3, "key", "4194321"], [1.4, "key", "4194321"],
		[1.5, "key", "4194322"], [1.7, "key", "4194309"], [1.9, "key", "50"], [2.0, "key", "4194321"], [2.1, "key", "4194321"], [2.2, "key", "4194321"],
		[2.3, "key", "4194309"], [2.5, "key", "52"], [2.6, "key", "4194322"], [2.7, "key", "4194322"], [2.8, "key", "4194322"], [2.9, "key", "4194322"],
		[3.0, "key", "4194321"], [3.1, "key", "4194321"], [3.2, "key", "4194309"], [3.4, "key", "54"], [3.5, "key", "4194321"], [3.6, "key", "4194321"],
		[3.7, "key", "4194321"], [3.8, "key", "4194321"], [3.9, "key", "4194321"], [4.0, "key", "4194321"], [4.1, "key", "4194322"], [4.2, "key", "4194322"],
		[4.4, "shot", "b1_ghost"], [4.5, "key", "4194309"], [4.8, "shot", "b2_placed"], [5.0, "key", "4194305"], [5.2, "tp", "4,2"], [5.8, "shot", "b3_home"],
		[6.0, "state", "build"], [6.2, "quit", ""],
	],
	"resume": [[1.5, "state", "resumed"], [1.6, "shot", "resume"], [1.8, "quit", ""]],
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
				if cmd == "freeze" and e is Enemy:
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
		"map":
			get_tree().root.get_node("Main").world_map.open()
		"journal":
			get_tree().root.get_node("Main").journal.open()
		"inventory":
			get_tree().root.get_node("Main").inventory.open()
		"give":
			GameState.inv.add(StringName(s[2]))
		"coins":
			GameState.inv.earn(int(s[2]))
		"decor_all":
			for d in Placeables.ORDER:
				GameState.inv.decor[d] = true
		"key":
			var ev := InputEventKey.new()
			ev.physical_keycode = int(s[2])
			ev.keycode = int(s[2])
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
		"travel":
			# "region:entry"
			var re: PackedStringArray = (s[2] as String).split(":")
			get_tree().root.get_node("Main").travel(StringName(re[0]), StringName(re[1]))
		"flag":
			GameState.set_flag(StringName(s[2]))
		"unlock":
			GameState.unlock(StringName(s[2]))
		"next":
			if Dialogue.i and Dialogue.i.is_open:
				Dialogue.i._shown = Dialogue.i._text.length()
				Dialogue.i._next.emit()
		"pick":
			if Dialogue.i and Dialogue.i.is_open:
				Dialogue.i._sel = int(s[2])
				Dialogue.i._next.emit()
		"kill":
			var pk := _player()
			var victim: Node3D = null
			for e in SpellEffect.enemies():
				if victim == null or pk.global_position.distance_to(e.global_position) < pk.global_position.distance_to(victim.global_position):
					victim = e
			if victim:
				var d := Damage.make(99999.0, pk, &"storm")
				victim.take_hit(d)
				if victim.is_alive():
					victim.take_hit(d)
		"wound":
			# nearest enemy down to `arg` of its max health
			var pw := _player()
			var tgt: Node3D = null
			for e in SpellEffect.enemies():
				if tgt == null or pw.global_position.distance_to(e.global_position) < pw.global_position.distance_to(tgt.global_position):
					tgt = e
			if tgt and tgt is Enemy:
				tgt.take_hit(Damage.make(tgt.health.hp - tgt.health.max_hp * float(s[2]), pw, &"hex"))
		"state":
			var q := {}
			for k in GameState.quests:
				q[k] = GameState.quests[k]
			print("DEMO state ", s[2], " items=", GameState.inv.items.map(func(it: Dictionary) -> String: return Items.display(it)), " quests=", q, " flags=", GameState.flags.keys(), " unlocks=", GameState.unlocks.keys(), " region=", Region.current.id if Region.current else "", " companion=", GameState.companion, " placed=", GameState.placed.size(), " coins=", GameState.inv.coins)
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
