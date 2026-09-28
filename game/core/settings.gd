extends Node
## Player settings and the remappable input map. Persisted to user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

## action -> [primary physical key, optional secondary]
const DEFAULT_KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"up": [KEY_W, KEY_UP],
	"down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE],
	"dodge": [KEY_SHIFT],
	"attack": [KEY_J],
	"spell_1": [KEY_1],
	"spell_2": [KEY_2],
	"spell_3": [KEY_3],
	"spell_4": [KEY_4],
	"interact": [KEY_E],
	"wheel": [KEY_TAB],
	"inventory": [KEY_I],
	"journal": [KEY_Q],
	"build": [KEY_B],
	"pause": [KEY_ESCAPE],
}
const REMAPPABLE := ["move_left", "move_right", "up", "down", "jump", "dodge", "attack",
	"spell_1", "spell_2", "spell_3", "spell_4", "interact", "wheel", "inventory", "journal", "build"]
const ACTION_NAMES := {
	"move_left": "Move left", "move_right": "Move right", "up": "Climb / up", "down": "Drop / down",
	"jump": "Jump / float", "dodge": "Dodge", "attack": "Staff attack", "spell_1": "Spell 1",
	"spell_2": "Spell 2", "spell_3": "Spell 3", "spell_4": "Spell 4", "interact": "Interact / magic",
	"wheel": "Spellbook", "inventory": "Inventory", "journal": "Journal", "build": "Build mode", "pause": "Pause",
}

var aim_mode := "assisted"  # or "direct"
var master_vol := 0.8
var music_vol := 0.7
var sfx_vol := 0.8
var fullscreen := false
var reduce_shake := false
var reduce_flash := false
var keys := {}  # action -> primary physical keycode (remapped)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	aim_mode = cf.get_value("game", "aim_mode", aim_mode)
	master_vol = cf.get_value("audio", "master", master_vol)
	music_vol = cf.get_value("audio", "music", music_vol)
	sfx_vol = cf.get_value("audio", "sfx", sfx_vol)
	fullscreen = cf.get_value("video", "fullscreen", fullscreen)
	reduce_shake = cf.get_value("comfort", "reduce_shake", reduce_shake)
	reduce_flash = cf.get_value("comfort", "reduce_flash", reduce_flash)
	var saved: Dictionary = cf.get_value("input", "keys", {})
	for a in saved:
		if DEFAULT_KEYS.has(a) and saved[a] is int:
			keys[a] = saved[a]


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("game", "aim_mode", aim_mode)
	cf.set_value("audio", "master", master_vol)
	cf.set_value("audio", "music", music_vol)
	cf.set_value("audio", "sfx", sfx_vol)
	cf.set_value("video", "fullscreen", fullscreen)
	cf.set_value("comfort", "reduce_shake", reduce_shake)
	cf.set_value("comfort", "reduce_flash", reduce_flash)
	cf.set_value("input", "keys", keys)
	cf.save(PATH)


func apply() -> void:
	_build_input_map()
	_apply_audio()
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	changed.emit()


func _apply_audio() -> void:
	for pair in [["Master", master_vol], ["Music", music_vol], ["SFX", sfx_vol]]:
		var idx := AudioServer.get_bus_index(pair[0])
		if idx == -1:
			AudioServer.add_bus()
			idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, pair[0])
			AudioServer.set_bus_send(idx, "Master")
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(pair[1], 0.0001)))


func _build_input_map() -> void:
	for a in DEFAULT_KEYS:
		if InputMap.has_action(a):
			InputMap.action_erase_events(a)
		else:
			InputMap.add_action(a, 0.2)
		var list: Array = DEFAULT_KEYS[a].duplicate()
		if keys.has(a):
			list[0] = keys[a]
		for k in list:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)
	# Trackpad tap / left click is an alternate staff attack (never required).
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", click)


func primary_key(action: String) -> int:
	return keys.get(action, DEFAULT_KEYS[action][0])


func key_label(action: String) -> String:
	if not DEFAULT_KEYS.has(action):
		return "?"
	var k := primary_key(action)
	var shown := DisplayServer.keyboard_get_keycode_from_physical(k) if DisplayServer.get_name() != "headless" else k
	var s := OS.get_keycode_string(shown)
	return "Space" if s == "Space" else s


## Returns the action currently using this key (or "").
func action_for_key(k: int) -> String:
	for a in REMAPPABLE:
		if primary_key(a) == k:
			return a
	return ""


## Rebinds; if another action had this key they swap, so nothing is left unbound.
func rebind(action: String, k: int) -> void:
	var other := action_for_key(k)
	if other != "" and other != action:
		keys[other] = primary_key(action)
	keys[action] = k
	save_settings()
	apply()


func reset_keys() -> void:
	keys.clear()
	save_settings()
	apply()
