extends Node
## Scripted input for automated captures and playtest evidence. Only active
## when the game is launched with `-- --demo=<name> [--shots=<abs dir>]`.
## Steps: [seconds, command, arg]. Commands: hold, release, tap, aim ("x,z"
## metres from the player), aim_enemy, clear_aim, shot, burst (name:frames:every),
## freeze / unfreeze (enemies), tp ("x,z"), tp_near (metres west of the nearest
## enemy), pos (print), learn, school, upg, reset, book, key, quit.

## Balance check: one school against the Warden for 25 s (wizard can't die),
## cycling all four spells while holding the staff attack. Prints damage dealt.
static func _dps(sch: String) -> Array:
	var out: Array = [[0.3, "travel", "old_ward:waystone"], [3.5, "learn", ""], [3.55, "school", sch], [3.6, "god", ""],
		[3.6, "tp", "0,-23.5"], [3.8, "aim_enemy", ""], [3.9, "bosshp", "start"], [4.0, "hold", "attack"]]
	var t := 4.0
	var k := 0
	while t < 29.0:
		out.append([t, "tap", "spell_%d" % (k % 4 + 1)])
		k += 1
		t += 0.3
	out.append([29.0, "bosshp", "end_" + sch])
	out.append([29.1, "quit", ""])
	return out


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


## Chapter 2 step 5 look pass: Wenna's request, then each shrine area by boat
## (arrival, its contextual magic, the shrine relit), then Reedhollow with
## all three shrines burning.
static func _shrines() -> Array:
	var out: Array = [[0.2, "god", ""], [0.3, "quest", "dark_ward:-1"], [0.31, "quest", "hollowing:3"], [0.32, "flag", "ward_restored"],
		[0.33, "flag", "kess_joined"], [0.335, "flag", "herald_fled"], [0.34, "recruit", "tamsin"], [0.35, "recruit", "kess"], [0.5, "travel", "reedhollow:square"],
		[2.0, "tp", "2.2,3.3"], [2.3, "tap", "interact"], [2.7, "shot", "s00_wenna"], [2.9, "next", ""], [3.1, "next", ""], [3.3, "shot", "s01_reedhollow_dark"]]
	var t := 3.6
	var nexts := func(at: float, n: int) -> void:
		for k in n:
			out.append([at + k * 0.3, "next", ""])
	# [boat choice, prefix, moment spot, moment look spot, extra shots]
	for area: Array in [["0", "c", "1.0,-1.4", "1.0,1.0", 7.0], ["1", "m", "2.0,1.8", "2.0,1.2", 6.5], ["2", "g", "10.4,0.4", "8.5,0.5", 5.0]]:
		out.append_array([[t, "tp", "19,-10.8"], [t + 0.3, "tap", "interact"], [t + 0.7, "pick", area[0]], [t + 1.7, "shot", area[1] + "0_boat"]])
		t += 6.5
		nexts.call(t, 3)
		out.append_array([[t + 1.0, "shot", area[1] + "1_landing"], [t + 1.2, "tp", "-9,0.5"], [t + 1.8, "shot", area[1] + "2_path"],
			[t + 2.0, "tp", "3,0"], [t + 2.6, "shot", area[1] + "3_middle"], [t + 2.8, "clear", ""], [t + 2.9, "tp", area[2]],
			[t + 3.3, "shot", area[1] + "4_before"], [t + 3.4, "tap", "interact"], [t + 4.6, "burst", area[1] + "5_moment:90:15"]])
		t += 3.4 + float(area[4])
		nexts.call(t, 4)
		out.append_array([[t + 1.2, "tp", area[3]], [t + 1.8, "shot", area[1] + "6_after"], [t + 2.0, "tp", "17,-1"], [t + 2.6, "shot", area[1] + "7_shrine"],
			[t + 2.8, "clear", ""], [t + 2.9, "tp", "21,-1.2"], [t + 3.0, "tap", "interact"], [t + 4.8, "burst", area[1] + "8_lit:60:12"]])
		t += 9.0
		nexts.call(t, 4)
		out.append_array([[t + 1.3, "state", area[1]], [t + 1.4, "tp", "-24.6,0.5"], [t + 1.7, "tap", "interact"]])
		t += 8.0
	t -= 0.5
	out.append_array([[t, "tp", "2.2,3.3"], [t + 0.3, "tap", "interact"]])
	nexts.call(t + 0.7, 3)
	out.append_array([[t + 2.0, "shot", "s10_wenna_pip"], [t + 2.2, "tp", "-6.5,-2.0"], [t + 2.8, "shot", "s11_walkway"],
		[t + 3.0, "tp", "10.5,4.2"], [t + 3.6, "shot", "s12_trader"], [t + 3.8, "tp", "0,1.0"], [t + 4.4, "shot", "s13_village_lit"],
		[t + 4.5, "map", ""], [t + 4.8, "shot", "s14_map"], [t + 5.0, "state", "end"], [t + 5.2, "quit", ""]])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
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
	# real mouse aiming: cursor above / below / left / right of the wizard
	"aimtest": [
		[0.5, "mouse", "320,60"], [0.7, "aimprint", "up"], [0.8, "mouse", "320,340"], [1.0, "aimprint", "down"],
		[1.1, "mouse", "40,200"], [1.3, "aimprint", "left"], [1.4, "mouse", "600,200"], [1.6, "aimprint", "right"],
		[1.7, "tp", "0,11"], [1.9, "mouse", "320,60"], [2.1, "aimprint", "up_near_south_edge"],
		[2.2, "mouse", "600,200"], [2.4, "aimprint", "right_near_south_edge"], [2.5, "quit", ""],
	],
	# walk out of Hearthmere both ways
	"walkexits": [
		[0.3, "travel", "hearthmere:square"], [1.5, "tp", "20,-1"], [1.6, "hold", "move_right"], [3.5, "release", "move_right"],
		[5.0, "state", "after_east"], [5.1, "travel", "hearthmere:square"], [6.3, "tp", "-20,2"], [6.4, "hold", "move_left"],
		[8.3, "release", "move_left"], [9.8, "state", "after_west"], [9.9, "quit", ""],
	],
	# the gorge road behind the southern ridge
	"gorge": [
		[0.1, "flag", "trunk_lifted"], [0.2, "flag", "troll_defeated"], [0.3, "travel", "briarwood:west"], [1.6, "tp", "23,-10"], [2.4, "shot", "g1"],
		[2.5, "tp", "29,-12"], [3.3, "shot", "g2"], [3.4, "tp", "35,-12"], [4.2, "shot", "g3"], [4.4, "quit", ""],
	],
	# the edge walls still hold the wizard in (sanctuary south edge is z=14)
	"edgewalk": [[0.5, "tp", "0,11"], [0.6, "hold", "down"], [3.0, "pos", ""], [3.1, "release", "down"], [3.2, "quit", ""]],
	# walk onto the bridge and up into the Warden's plaza
	"lips": [
		[0.3, "travel", "briarwood:west"], [1.4, "freeze", ""], [1.5, "tp", "-1.5,2.0"], [1.6, "hold", "move_right"], [1.6, "hold", "up:0.45"], [1.7, "pos", "bridge"], [1.9, "pos", "bridge"], [2.2, "pos", "bridge"], [2.5, "pos", "bridge"], [2.7, "pos", "bridge"], [3.0, "pos", "bridge"], [3.2, "pos", "bridge"], [3.5, "pos", "bridge"], [3.7, "pos", "bridge"], [4.0, "pos", "bridge"], [4.2, "release", "move_right"], [4.2, "release", "up"], [4.3, "travel", "old_ward:waystone"], [7.5, "tp", "0,-17"], [7.6, "hold", "up"], [7.7, "pos", "arena"], [8.0, "pos", "arena"], [8.2, "pos", "arena"], [8.4, "pos", "arena"], [8.7, "pos", "arena"], [8.9, "pos", "arena"], [9.2, "pos", "arena"], [9.4, "pos", "arena"], [9.7, "pos", "arena"], [9.9, "pos", "arena"], [10.2, "pos", "arena"], [10.4, "pos", "arena"], [10.5, "release", "up"], [10.6, "quit", ""],
	],
	# steep ground must still stop the wizard (gorge bank, cliff edge)
	"steep": [[0.3, "travel", "briarwood:west"], [1.4, "freeze", ""], [1.5, "tp", "28,-11.5"], [1.6, "hold", "down"], [3.5, "pos", "bank"],
		[3.6, "release", "down"], [3.7, "tp", "12,-10"], [3.8, "hold", "up"], [5.8, "pos", "cliff"], [5.9, "release", "up"], [6.0, "quit", ""]],
	# try to walk round the fallen trunk over the gorge bank (must be blocked)
	"trunkwalk": [[0.3, "travel", "briarwood:west"], [1.4, "freeze", ""], [1.5, "tp", "21.5,-9.8"], [1.6, "hold", "move_right"], [1.6, "hold", "down:0.7"],
		[4.5, "pos", "round_trunk"], [4.6, "release", "move_right"], [4.6, "release", "down"], [4.7, "tp", "20,-7"], [4.8, "hold", "move_right"], [7.0, "pos", "along_bank"], [7.1, "quit", ""]],
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
	# character creation with the school row selected
	"newgame": [[1.0, "key", "4194322"], [1.1, "key", "4194309"], [1.4, "key", "4194322"], [1.5, "key", "4194309"], [2.0, "key", "4194322"], [2.3, "shot", "ng_school"], [2.4, "key", "4194321"], [2.6, "shot", "ng_school2"], [2.7, "quit", ""]],
	"title": [[1.0, "shot", "title"], [1.2, "key", "4194322"], [1.25, "key", "4194322"], [1.3, "key", "4194309"], [1.6, "shot", "settings"],
		[1.7, "key", "4194322"], [1.8, "key", "4194322"], [1.9, "key", "4194321"], [2.1, "shot", "settings2"], [2.2, "key", "4194305"], [2.5, "shot", "title2"], [2.7, "quit", ""]],
	"inv": [
		[0.3, "give", "stormcoil"], [0.32, "give", "stormcoil"], [0.35, "give", "moonstone"], [0.4, "give", "moonstone"], [0.45, "give", "ward_bell"], [0.5, "give", "wardweave"],
		[0.6, "inventory", ""], [0.9, "shot", "i1_staffs"], [1.0, "key", "4194321"], [1.1, "key", "4194309"], [1.4, "shot", "i2_equipped"],
		[1.5, "key", "4194306"], [1.6, "key", "4194306"], [1.8, "shot", "i2b_relics"],
		[2.0, "key", "4194305"], [2.2, "travel", "sanctuary:start"], [3.4, "tp", "3,-7.8"], [3.7, "tap", "interact"], [4.0, "key", "4194309"],
		[4.2, "key", "4194322"], [4.4, "key", "4194309"], [4.7, "shot", "i3_fusion"], [4.9, "key", "4194309"], [5.3, "shot", "i4_fused"],
		[5.5, "key", "4194305"], [5.9, "state", "inv"], [6.0, "quit", ""],
	],
	"tamsin": [
		[0.3, "travel", "briarwood:west"], [1.8, "tp", "-15.5,2.5"], [2.2, "kill", ""], [2.8, "tp", "-18.2,2.2"], [3.2, "shot", "c1_freed"],
		[3.4, "tap", "interact"], [3.8, "next", ""], [4.0, "next", ""], [4.2, "next", ""], [4.5, "pick", "0"], [4.9, "state", "tamsin"],
		[5.0, "hold", "move_right"], [6.5, "shot", "c2_follow"], [7.0, "release", "move_right"],
		[7.2, "tp", "6,0"], [7.4, "aim_enemy", ""], [8.0, "burst", "c3_fight:60:10"], [8.2, "tap", "spell_1"], [9.5, "hold", "attack"],
		[11.5, "release", "attack"], [12.0, "tap", "spell_2"], [14.0, "quit", ""],
	],
	# Chapter 2: Tamsin and Kess together in Briarwood (follow, fight, the mark)
	"party": [
		[0.3, "travel", "briarwood:west"], [1.6, "recruit", "tamsin"], [1.7, "recruit", "kess"], [1.8, "state", "party"],
		[2.0, "hold", "move_right"], [3.6, "shot", "p1_follow"], [4.0, "release", "move_right"],
		[4.2, "tp", "6,0"], [4.4, "aim_enemy", ""], [5.0, "burst", "p2_fight:90:8"], [5.2, "hold", "attack"],
		[8.0, "release", "attack"], [8.2, "tap", "spell_1"], [9.0, "hold", "attack"], [12.0, "release", "attack"], [12.5, "state", "party"], [13.0, "quit", ""],
	],
	# Chapter 2 opening from a finished Chapter 1: Hearthmere -> waystone -> Fenway -> Reedhollow
	"lake": [
		[0.2, "god", ""], [0.3, "quest", "dark_ward:-1"], [0.31, "flag", "ward_restored"], [0.32, "recruit", "tamsin"],
		[0.5, "travel", "hearthmere:square"], [2.0, "shot", "h1_banner"], [2.2, "tp", "0.9,3.6"], [2.5, "tap", "interact"], [2.9, "shot", "h2_opening"],
		[3.1, "next", ""], [3.3, "next", ""], [3.5, "next", ""], [3.7, "next", ""], [3.9, "next", ""], [4.1, "next", ""], [4.3, "next", ""], [4.5, "next", ""], [4.7, "next", ""],
		[5.0, "state", "opening"], [5.3, "shot", "h3_party"], [5.5, "tp", "-17.0,-2.7"], [5.8, "tap", "interact"], [6.1, "pick", "0"], [7.0, "shot", "j1_journey"],
		[10.6, "next", ""], [10.9, "next", ""], [11.2, "shot", "f1_fenway"], [11.4, "tp", "-11,0"], [11.6, "aim_enemy", ""], [11.7, "hold", "attack"],
		[12.0, "burst", "f2_fight:50:10"], [15.0, "release", "attack"], [15.2, "tp", "10,1.5"], [15.6, "shot", "f3_road"], [15.8, "tp", "26.5,-1.2"], [16.0, "hold", "move_right"],
		[17.0, "release", "move_right"], [18.2, "shot", "r1_arrive"], [18.4, "tp", "-1.5,6.0"], [18.7, "tap", "interact"],
		[19.0, "next", ""], [19.2, "next", ""], [19.4, "next", ""], [19.6, "next", ""], [19.8, "next", ""], [20.0, "next", ""], [20.3, "state", "reedhollow"],
		[20.5, "tp", "0,1.0"], [20.9, "shot", "r2_village"], [21.1, "tp", "19,-6"], [21.5, "shot", "r3_dock"], [21.7, "tp", "19,-10.8"], [22.0, "tap", "interact"],
		[22.4, "shot", "r4_boat"], [22.6, "next", ""], [22.8, "tp", "-12,-7.2"], [23.2, "shot", "r5_stilts"], [23.4, "tp", "-1,-4.5"], [23.8, "shot", "r6_water"], [24.4, "pos", "after_water"], [24.6, "quit", ""],
	],
	# Chapter 2 bestiary: one clip per new creature and hollowed variant (feel review)
	"bestiary": [
		[0.3, "travel", "fenway:waystone"], [1.6, "god", ""], [1.8, "clear", ""], [1.85, "tp", "-10,1"], [1.90, "spawn", "husk:-6,1"], [1.90, "spawn", "husk:-5,3.5"], [2.00, "burst", "c1_husk:660:5"], [5.6, "kill", ""], [6.4, "kill", ""], [5.00, "aim_enemy", ""], [5.10, "hold", "attack"], [8.20, "release", "attack"], [8.8, "clear", ""], [8.85, "tp", "-10,1"], [8.90, "spawn", "lurker:-4,1"], [9.00, "burst", "c2_lurker:660:5"], [12.00, "aim_enemy", ""], [12.10, "hold", "attack"], [15.20, "release", "attack"], [15.8, "clear", ""], [15.85, "tp", "-10,1"], [15.90, "spawn", "moth:-3,-2"], [15.90, "spawn", "moth:-4,3.5"], [16.00, "burst", "c3_moth:660:5"], [20.4, "kill", ""], [19.00, "aim_enemy", ""], [19.10, "hold", "attack"], [22.20, "release", "attack"], [22.8, "clear", ""], [22.85, "tp", "-10,1"], [22.90, "spawn", "hound:-4.5,1:h"], [23.00, "burst", "c4_hound_h:660:5"], [29.8, "clear", ""], [29.85, "tp", "-10,1"], [29.90, "spawn", "raider:-8.4,1:h"], [30.00, "burst", "c5_raider_h:660:5"], [36.8, "clear", ""], [36.85, "tp", "-10,1"], [36.90, "spawn", "hexer:-4,1:h"], [37.00, "burst", "c6_hexer_h:660:5"], [43.8, "clear", ""], [43.85, "tp", "-10,1"], [43.90, "spawn", "knot:-6,2:h"], [44.00, "burst", "c7_knot_h:660:5"], [50.8, "clear", ""], [50.85, "tp", "-10,1"], [50.90, "spawn", "sentinel:-7.6,1:h"], [51.00, "burst", "c8_sentinel_h:660:5"], [57.8, "quit", ""],
	],
	"masks": [[0.3, "travel", "fenway:waystone"], [1.6, "clear", ""], [1.7, "tp", "-10,1"], [1.8, "spawn", "hound:-9,1:h"], [1.8, "spawn", "raider:-7,1:h"],
		[1.8, "spawn", "hexer:-5,1:h"], [1.8, "spawn", "knot:-3,1:h"], [1.8, "spawn", "sentinel:-1,1:h"], [1.9, "freeze", ""], [2.3, "shot", "masks"], [2.4, "quit", ""]],
	# look pass: the Fenway's features and Reedhollow's piers
	"lakelook": [[0.2, "god", ""], [0.3, "travel", "fenway:waystone"], [1.6, "freeze", ""], [1.7, "tp", "-6,-2"], [2.0, "shot", "l1_hut"], [2.2, "tp", "6,-4"], [2.5, "shot", "l2_mounds"],
		[2.7, "tp", "4,3"], [3.0, "shot", "l3_boardwalk"], [3.2, "tp", "18,0"], [3.5, "shot", "l4_east"], [3.7, "travel", "reedhollow:west"],
		[5.2, "tp", "-12,1"], [5.5, "shot", "l5_pier_w"], [5.7, "tp", "10,1"], [6.0, "shot", "l6_pier_e"], [6.2, "tp", "19,0.5"], [6.5, "shot", "l7_dock"], [6.7, "quit", ""]],
	"mirelook": [[0.2, "god", ""], [0.3, "travel", "mire:dock"], [1.8, "freeze", ""], [1.9, "next", ""], [2.1, "next", ""], [2.3, "tp", "-9,0.5"],
		[2.8, "shot", "ml1_path"], [2.9, "tp", "2,1.8"], [3.4, "shot", "ml2_bog"], [3.5, "quit", ""]],
	# Chapter 2 step 6: the attack on Reedhollow and the Herald (feel review)
	"herald": [[0.2, "god", ""], [0.3, "quest", "dark_ward:-1"], [0.31, "quest", "hollowing:4"], [0.32, "flag", "shrine_chapel"],
		[0.33, "flag", "shrine_mire"], [0.34, "flag", "kess_joined"], [0.35, "recruit", "tamsin"], [0.36, "recruit", "kess"], [0.5, "travel", "reedhollow:dock"],
		[2.0, "shot", "h0_arrive"], [2.2, "tp", "0,0.6"], [2.9, "next", ""], [3.2, "next", ""], [3.5, "next", ""], [3.8, "next", ""], [4.1, "next", ""],
		[4.3, "learn", ""], [4.4, "aim_enemy", ""], [4.5, "hold", "attack"], [4.6, "burst", "h1_fight:600:5"], [6.0, "tap", "spell_1"], [8.0, "tap", "spell_4"],
		[10.0, "tap", "dodge"], [11.0, "tap", "spell_1"], [13.0, "tap", "spell_2"], [14.5, "wound", "0.52"], [14.6, "burst", "h2_phase2:720:5"], [17.0, "tap", "spell_1"],
		[20.0, "tap", "spell_4"], [23.0, "tap", "spell_1"], [26.5, "wound", "0.33"], [26.6, "burst", "h3_flee:300:6"], [27.0, "tap", "spell_1"], [27.4, "release", "attack"],
		[28.6, "next", ""], [29.0, "next", ""], [29.4, "next", ""], [29.8, "next", ""], [30.2, "next", ""], [32.0, "next", ""], [32.4, "next", ""], [32.8, "next", ""],
		[33.4, "shot", "h4_after"], [33.6, "state", "herald"], [33.7, "quit", ""]],
	# Chapter 2 step 7: Orla's request, the far watchtower and the view east
	"farwatch": [[0.2, "god", ""], [0.3, "quest", "dark_ward:-1"], [0.31, "quest", "hollowing:5"], [0.32, "flag", "herald_fled"], [0.33, "flag", "kess_joined"],
		[0.34, "flag", "shrine_chapel"], [0.35, "flag", "shrine_mire"], [0.36, "recruit", "kess"], [0.5, "travel", "reedhollow:west"],
		[2.0, "tp", "-19.6,4.0"], [2.3, "tap", "interact"], [2.6, "shot", "w0_orla"], [2.8, "next", ""], [3.1, "next", ""], [3.4, "next", ""],
		[3.7, "tp", "19,-10.8"], [4.0, "tap", "interact"], [4.4, "shot", "w1_boats"], [4.5, "pick", "3"], [5.6, "shot", "w2_journey"],
		[10.5, "shot", "w3_landing"], [10.7, "tp", "0,0"], [11.3, "shot", "w4_climb"], [11.5, "tp", "13.6,-4.2"], [12.1, "shot", "w5_tower"],
		[12.3, "tap", "interact"], [12.7, "next", ""], [13.0, "next", ""], [14.0, "shot", "w6_view_a"], [17.0, "shot", "w7_view_b"],
		[19.5, "tap", "interact"], [20.0, "next", ""], [20.3, "next", ""], [20.6, "next", ""], [20.9, "next", ""], [21.2, "state", "watch"],
		[21.4, "tp", "-24.6,0.5"], [21.7, "tap", "interact"], [28.0, "tp", "-19.6,4.0"], [28.3, "tap", "interact"], [28.7, "next", ""], [29.0, "next", ""],
		[29.3, "next", ""], [29.8, "state", "orla"], [30.0, "quit", ""]],
	# the sanctuary camp with both companions resting, then one joins
	"camp": [
		[0.3, "recruit", "tamsin:rest"], [0.35, "recruit", "kess:rest"], [0.4, "travel", "sanctuary:start"],
		[1.8, "tp", "-1.4,-0.5"], [2.3, "shot", "k1_camp"], [2.5, "tp", "-0.3,1.3"], [2.8, "tap", "interact"], [3.1, "next", ""], [3.3, "pick", "0"],
		[3.8, "shot", "k2_joined"], [4.0, "state", "camp"], [4.2, "quit", ""],
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


var _tally := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--demo="):
			var nm := a.trim_prefix("--demo=")
			steps = _all_spells() if nm == "allspells" else _shrines() if nm == "shrines" else _dps(nm.trim_prefix("dps_")) if nm.begins_with("dps_") else DEMOS.get(nm, [])
			if nm.begins_with("dps_"):
				Events.damage_dealt.connect(func(_t: Node3D, d: Damage) -> void:
					_tally[d.spell_id] = roundf(_tally.get(d.spell_id, 0.0) + d.amount))
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
			# "action" or "action:strength"
			var hs: PackedStringArray = (s[2] as String).split(":")
			Input.action_press(hs[0], float(hs[1]) if hs.size() > 1 else 1.0)
		"release":
			Input.action_release((s[2] as String).split(":")[0])
		"tap":
			Input.action_press(s[2])
			_taps.append(s[2])
		"aim":
			var off: PackedStringArray = (s[2] as String).split(",")
			_player().aim.override = _player().global_position + Vector3(float(off[0]), 0, float(off[1]))
		"aim_enemy":
			_player().aim.override_enemy = true
		"mouse":
			# move the real cursor to "x,y" in 640x360 screen pixels
			var mxy: PackedStringArray = (s[2] as String).split(",")
			var mpos := Vector2(float(mxy[0]), float(mxy[1]))
			get_viewport().warp_mouse(mpos)
			var mm := InputEventMouseMotion.new()
			mm.position = mpos
			Input.parse_input_event(mm)
		"aimprint":
			var pa := _player()
			pa.aim.update_aim(pa.cast_origin())
			print("DEMO aim ", s[2], " mouse=", get_viewport().get_mouse_position(), " cursor=", pa.aim.cursor.snappedf(0.1), " player=", pa.global_position.snappedf(0.1), " dir=", pa.aim.dir_from(pa.cast_origin()).snappedf(0.01), " active=", pa.aim.mouse_active)
		"god":
			var pg := _player()
			pg.caster.cast_started.connect(func(dd: SpellData) -> void:
				_tally["cast_" + String(dd.id)] = _tally.get("cast_" + String(dd.id), 0) + 1)
			pg.health.max_hp = 1e6
			pg.health.hp = 1e6
		"bosshp":
			for e in SpellEffect.enemies():
				if e.is_boss:
					print("DEMO bosshp ", s[2], " hp=", roundi(e.health.hp), "/", roundi(e.health.max_hp), " by_spell=", _tally)
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
		"heights":
			# "x:z0:z1": print ground height along a line (debug)
			var hp: PackedStringArray = (s[2] as String).split(":")
			var out := []
			var z := float(hp[1])
			while z <= float(hp[2]):
				out.append("%.1f=%.2f" % [z, Region.current.terrain.height_at(float(hp[0]), z)])
				z += 0.5
			print("DEMO heights x=", hp[0], " ", " ".join(out))
		"spawn":
			# "kind:x:z" or "kind:x:z:h" (hollowed)
			var sp: PackedStringArray = (s[2] as String).split(":")
			var xz2: PackedStringArray = sp[1].split(",")
			Region.current.spawn(StringName(sp[0]), float(xz2[0]), float(xz2[1]), {"hollowed": sp.size() > 2 and sp[2] == "h"})
		"clear":
			# remove every enemy (hidden ones too), spores and patches
			for n in Region.current.get_children():
				if n is Enemy or n is Husk.SporePatch or n is Projectile or n is Knot.ThornPatch:
					n.queue_free()
		"quest":
			# "id:step" (-1 = done)
			var qp: PackedStringArray = (s[2] as String).split(":")
			GameState.quests[StringName(qp[0])] = int(qp[1])
		"recruit":
			# "id" follows, "id:rest" waits at the camp
			var rp: PackedStringArray = (s[2] as String).split(":")
			GameState.recruit(StringName(rp[0]), rp.size() == 1)
			get_tree().root.get_node("Main").sync_party()
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
			print("DEMO state ", s[2], " items=", GameState.inv.items.map(func(it: Dictionary) -> String: return Items.display(it)), " quests=", q, " flags=", GameState.flags.keys(), " unlocks=", GameState.unlocks.keys(), " region=", Region.current.id if Region.current else "", " party=", GameState.party, " recruited=", GameState.recruited.keys(), " placed=", GameState.placed.size(), " coins=", GameState.inv.coins)
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
