extends Node
## Game root. Owns the persistent player, the HUD, menus and the current
## region, and moves the wizard between regions (short fades for walk-off
## exits, an animated journey for distant travel).

const REGIONS := {
	&"sanctuary": "res://game/world/sanctuary.gd",
	&"hearthmere": "res://game/world/hearthmere.gd",
	&"briarwood": "res://game/world/briarwood.gd",
	&"old_ward": "res://game/world/old_ward.gd",
	&"fenway": "res://game/world/fenway.gd",
	&"reedhollow": "res://game/world/reedhollow.gd",
	&"sunken_chapel": "res://game/world/sunken_chapel.gd",
	&"mire": "res://game/world/mire.gd",
	&"stilled_grove": "res://game/world/stilled_grove.gd",
	&"far_watch": "res://game/world/far_watch.gd",
	&"heart_isle": "res://game/world/heart_isle.gd",
}
const NAMES := {&"sanctuary": "The Sanctuary", &"hearthmere": "Hearthmere", &"briarwood": "Briarwood Road", &"old_ward": "The Old Ward",
	&"fenway": "The Fenway", &"reedhollow": "Reedhollow", &"sunken_chapel": "The Sunken Chapel", &"mire": "The Mire",
	&"stilled_grove": "The Stilled Grove", &"far_watch": "The Far Watch", &"heart_isle": "The Heart Isle"}
## Pairs joined by a waystone journey rather than a walk.
const DISTANT := [[&"briarwood", &"old_ward"], [&"hearthmere", &"fenway"], [&"briarwood", &"fenway"]]
## Places Reedhollow's boats sail to (a boat journey, not a waystone).
const LAKE := [&"sunken_chapel", &"mire", &"stilled_grove", &"far_watch", &"heart_isle"]

var player: Player
var level: Region
var hud: HUD
var spellbook: Spellbook
var journal: Journal
var world_map: WorldMap
var inventory: InventoryUI
var dialogue: Dialogue
var journey: Journey
var _fade: ColorRect
var _traveling := false
var companions := {}         # party member id -> Companion


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player = Player.new()
	hud = HUD.new()
	add_child(hud)
	dialogue = Dialogue.new()
	add_child(dialogue)
	journey = Journey.new()
	add_child(journey)
	var fl := CanvasLayer.new()
	fl.layer = 26
	add_child(fl)
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.015, 0.04, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(_fade)
	spellbook = Spellbook.new()
	spellbook.player = player
	hud.add_child(spellbook)
	journal = Journal.new()
	journal.player = player
	hud.add_child(journal)
	world_map = WorldMap.new()
	hud.add_child(world_map)
	inventory = InventoryUI.new()
	inventory.player = player
	hud.add_child(inventory)
	player.died.connect(spellbook.close)
	GameState.quest_updated.connect(func(_id: StringName) -> void: SaveSystem.autosave())
	if _scripted() and OS.get_cmdline_user_args().has("--continue"):
		_continue()
	elif _scripted() and not OS.get_cmdline_user_args().has("--title"):
		_new_game(false)
	else:
		_title()


static func _scripted() -> bool:
	return " ".join(OS.get_cmdline_user_args()).contains("--demo")


# ------------------------------------------------------------------ title
func _title() -> void:
	hud.visible = false
	SaveSystem.enabled = false
	var bg := TitleBackdrop.new()
	add_child(bg)
	Sfx.music("home")
	while true:
		var opts: Array = (["Continue"] if SaveSystem.has_save() else []) + ["New game", "Settings", "Quit"]
		var k: int = await MenuPanel.ask(self, "", "", opts, -1, false)
		var pick: String = opts[k]
		if pick == "Continue":
			if await _continue():
				break
		elif pick == "New game":
			if SaveSystem.has_save():
				var c: int = await MenuPanel.ask(self, "Start a new journey?", "Your saved journey will be replaced when the new one first saves.", ["Keep my save", "Start new"], 0)
				if c == 0:
					continue
			bg.queue_free()
			_new_game(true)
			return
		elif pick == "Settings":
			var st := SettingsUI.new()
			add_child(st)
			st.open()
			await st.finished
		else:
			get_tree().quit()
			return
	bg.queue_free()


## Load the save (or its backup). Returns false to stay on the title.
func _continue() -> bool:
	var r := SaveSystem.load_main()
	if r.error != "":
		var opts: Array = ["Load the backup"] if SaveSystem.has_backup() and SaveSystem.load_backup().error == "" else []
		opts += ["Back to the title"]
		var k: int = await MenuPanel.ask(self, "Your save couldn't be read", String(r.error) + " It has not been changed or deleted.", opts, opts.size() - 1)
		if opts[k] != "Load the backup":
			return false
		r = SaveSystem.load_backup()
	var d: Dictionary = r.data
	SaveSystem.apply(d)
	player.wiz = WizardState.new()
	player.wiz.from_dict(d.wizard)
	if player.wiz.loadouts.is_empty():
		player.wiz.setup("storm")
	_begin(GameState.region, GameState.entry)
	return true


func _new_game(ask_setup: bool) -> void:
	GameState.reset()
	GameState.new_game_kit()
	player.wiz = WizardState.new()
	player.wiz.setup("storm")
	_begin(&"sanctuary", &"start")
	if ask_setup:
		get_tree().paused = true
		var ed := LookEditor.new()
		add_child(ed)
		ed.open(true)
		var res: Dictionary = await ed.finished
		get_tree().paused = false
		GameState.wizard_name = res.name
		GameState.appearance = res.look
		player.wiz = WizardState.new()
		player.wiz.setup(res.school)
		player.set_look(res.look)
	GameState.set_flag(&"created")
	SaveSystem.enabled = true
	SaveSystem.autosave()
	hud.banner("%s %s %s %s move    %s talk" % [Settings.key_label("up"), Settings.key_label("move_left"), Settings.key_label("down"),
		Settings.key_label("move_right"), Settings.key_label("interact")])


func _begin(region: StringName, entry: StringName) -> void:
	hud.visible = true
	_load_region(region, entry)
	if hud.player == null:
		hud.bind(player)
	player.apply_bonuses()
	player.health.reset()
	player.mana.refill()
	player.set_look(GameState.appearance)
	SaveSystem.enabled = true


func _load_region(id: StringName, entry: StringName, script: Script = null) -> void:
	if level:
		level.leave()
		player.reparent(self)
		for c: Companion in companions.values():
			c.reparent(self)
		level.queue_free()
	var s: Script = script if script else load(REGIONS[id])
	level = s.new()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	level.exit_requested.connect(travel)
	level.enter(player, entry)
	sync_party()
	GameState.learn_place(id)
	GameState.region = id
	GameState.entry = entry
	hud.banner(level.display_name)


## Party members walk with the wizard; everyone else waits at the sanctuary
## camp (as NPCs there) or hasn't been met yet.
func sync_party() -> void:
	for cid: StringName in companions.keys():
		if level == null or not GameState.in_party(cid):
			(companions[cid] as Companion).queue_free()
			companions.erase(cid)
	if level == null:
		return
	for k in GameState.party.size():
		var cid := GameState.party[k]
		var c: Companion = companions.get(cid)
		if c == null:
			c = Companion.make(cid)
			if c == null:
				continue
			companions[cid] = c
			c.slot = k
			level.add_child(c)
			c.warp_near(player)
		elif c.get_parent() != level:
			c.slot = k
			c.reparent(level)
			c.warp_near(player)
		c.slot = k


static func _distant(a: StringName, b: StringName) -> bool:
	if _boat(a, b):
		return true
	for pair: Array in DISTANT:
		if pair.has(a) and pair.has(b):
			return true
	return false


static func _boat(a: StringName, b: StringName) -> bool:
	return (a == &"reedhollow" and LAKE.has(b)) or (b == &"reedhollow" and LAKE.has(a))


## Move to another region. Walks between neighbours fade briefly; distant
## trips play the journey while the destination loads.
func travel(to: StringName, entry: StringName) -> void:
	if _traveling or not REGIONS.has(to):
		return
	_traveling = true
	player.lock(true)
	spellbook.close()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.25)
	await tw.finished
	var script: Script = null
	if _distant(level.id, to):
		get_tree().paused = true
		var boat := _boat(level.id, to)
		var look := "lake" if boat or to == &"fenway" or level.id == &"fenway" else ("ruins" if to == &"old_ward" else "woods")
		var sub := "The boat glides over the still lake" if boat else "The waystone's road hums underfoot"
		script = await journey.run("To " + NAMES[to], sub, look, REGIONS[to], boat)
		get_tree().paused = false
		if script == null:
			tw = create_tween()
			tw.tween_property(_fade, "color:a", 0.0, 0.25)
			player.lock(false)
			_traveling = false
			return
	_load_region(to, entry, script)
	TimeCtl.clear_all()
	SaveSystem.autosave()
	tw = create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.3)
	player.lock(false)
	_traveling = false


var _pause_open := false


func set_paused(on: bool) -> void:
	if dialogue.is_open or journal.is_open or world_map.is_open or inventory.is_open or _traveling or not hud.visible:
		return
	if on and not _pause_open:
		_pause_menu()


func _pause_menu() -> void:
	_pause_open = true
	spellbook.close()
	get_tree().paused = true
	player.input_enabled = false
	while true:
		var k: int = await MenuPanel.ask(self, "Paused", "", ["Resume", "Settings", "Save and return to title", "Quit"], 0)
		if k == 1:
			var st := SettingsUI.new()
			add_child(st)
			st.open()
			await st.finished
			continue
		if k == 2:
			SaveSystem.save_now()
			get_tree().paused = false
			get_tree().reload_current_scene()
			return
		if k == 3:
			SaveSystem.save_now()
			get_tree().quit()
			return
		break
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player.resume_input()
	_pause_open = false


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed(&"pause"):
		set_paused(true)
	elif e.is_action_pressed(&"wheel") and not get_tree().paused and not _traveling:
		spellbook.open()
	elif e.is_action_pressed(&"journal") and not get_tree().paused and not _traveling:
		player.input_enabled = false
		journal.open()
	elif e.is_action_pressed(&"inventory") and not get_tree().paused and not _traveling:
		player.input_enabled = false
		inventory.open()
	elif e.is_action_pressed(&"build") and not get_tree().paused and not _traveling and level and level.id == &"sanctuary":
		var bm := BuildMode.new()
		add_child(bm)
		bm.open(level, player)
	elif e.is_action_pressed(&"build") and not get_tree().paused and not _traveling:
		hud.toast("You can build at your sanctuary")
	elif e.is_action_pressed(&"map") and not get_tree().paused and not _traveling:
		player.input_enabled = false
		world_map.open()
	elif OS.is_debug_build() and e is InputEventKey and e.pressed and not e.echo:
		_dev_key((e as InputEventKey).physical_keycode)


## Development shortcuts (debug builds only) for testing the combat toolkit
## before the sanctuary study exists: F5 next school, F6 toggle all upgrades,
## F7 raise foreign affinity, F8 unlock all base spells.
func _dev_key(k: int) -> void:
	var wiz := player.wiz
	match k:
		KEY_F5:
			var i := WizardState.SCHOOLS.find(wiz.school)
			wiz.switch_school(WizardState.SCHOOLS[(i + 1) % 3])
			player.passives.reset()
			hud.banner(WizardState.SCHOOL_NAMES[wiz.school])
		KEY_F6:
			var on := wiz.upgrades.is_empty()
			wiz.upgrades.clear()
			if on:
				for id in SpellDB.all():
					wiz.upgrades[id] = true
			hud.banner("Upgrades " + ("on" if on else "off"))
		KEY_F7:
			for s in WizardState.SCHOOLS:
				wiz.train(s)
			hud.banner("Affinity trained")
		KEY_F8:
			for s in WizardState.SCHOOLS:
				for id in WizardState.BASE[s]:
					wiz.unlocked[id] = true
			hud.banner("All spells learned")


func _notification(what: int) -> void:
	var scripted := " ".join(OS.get_cmdline_user_args()).contains("--demo")
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree() and not get_tree().paused and not scripted:
		set_paused(true)
