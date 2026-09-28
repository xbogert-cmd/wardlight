extends Node
## Game root. Owns the persistent player, the HUD, menus and the current
## region, and moves the wizard between regions (short fades for walk-off
## exits, an animated journey for distant travel).

const REGIONS := {
	&"sanctuary": "res://game/world/sanctuary.gd",
	&"hearthmere": "res://game/world/hearthmere.gd",
	&"briarwood": "res://game/world/briarwood.gd",
	&"old_ward": "res://game/world/old_ward.gd",
}
const NAMES := {&"sanctuary": "The Sanctuary", &"hearthmere": "Hearthmere", &"briarwood": "Briarwood Road", &"old_ward": "The Old Ward"}
## Pairs joined by a waystone journey rather than a walk.
const DISTANT := [[&"briarwood", &"old_ward"]]

var player: Player
var level: Region
var hud: HUD
var spellbook: Spellbook
var journal: Journal
var world_map: WorldMap
var dialogue: Dialogue
var journey: Journey
var paused_overlay: Control
var _fade: ColorRect
var _traveling := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player = Player.new()
	player.wiz.setup("storm")
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
	_load_region(GameState.region, GameState.entry)
	hud.bind(player)
	spellbook = Spellbook.new()
	spellbook.player = player
	hud.add_child(spellbook)
	journal = Journal.new()
	journal.player = player
	hud.add_child(journal)
	world_map = WorldMap.new()
	hud.add_child(world_map)
	player.died.connect(spellbook.close)
	_build_pause()
	if not GameState.flag(&"created"):
		_character_setup()


## New game: name, starting school and looks, then a movement hint.
func _character_setup() -> void:
	var scripted := " ".join(OS.get_cmdline_user_args()).contains("--demo")
	if not scripted:
		get_tree().paused = true
		var ed := LookEditor.new()
		add_child(ed)
		ed.open(true)
		var res: Dictionary = await ed.finished
		get_tree().paused = false
		GameState.wizard_name = res.name
		GameState.appearance = res.look
		player.set_look(res.look)
		player.wiz = WizardState.new()
		player.wiz.setup(res.school)
	GameState.set_flag(&"created")
	hud.banner("%s %s %s %s move    %s talk" % [Settings.key_label("up"), Settings.key_label("move_left"), Settings.key_label("down"),
		Settings.key_label("move_right"), Settings.key_label("interact")])


func _load_region(id: StringName, entry: StringName, script: Script = null) -> void:
	if level:
		level.leave()
		player.reparent(self)
		level.queue_free()
	var s: Script = script if script else load(REGIONS[id])
	level = s.new()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	level.exit_requested.connect(travel)
	level.enter(player, entry)
	GameState.learn_place(id)
	hud.banner(level.display_name)


static func _distant(a: StringName, b: StringName) -> bool:
	for pair: Array in DISTANT:
		if pair.has(a) and pair.has(b):
			return true
	return false


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
		script = await journey.run("To " + NAMES[to], "The waystone's road hums underfoot", "ruins" if to == &"old_ward" else "woods", REGIONS[to])
		get_tree().paused = false
		if script == null:
			tw = create_tween()
			tw.tween_property(_fade, "color:a", 0.0, 0.25)
			player.lock(false)
			_traveling = false
			return
	_load_region(to, entry, script)
	TimeCtl.clear_all()
	tw = create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.3)
	player.lock(false)
	_traveling = false


func _build_pause() -> void:
	paused_overlay = Control.new()
	paused_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	paused_overlay.visible = false
	paused_overlay.draw.connect(func() -> void:
		paused_overlay.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.06, 0.6))
		HUD.frame(paused_overlay, Rect2(250, 150, 140, 44))
		paused_overlay.draw_string(HUD.FONT, Vector2(250, 168), "Paused", HORIZONTAL_ALIGNMENT_CENTER, 140, 9, Color("f0e6d0"))
		paused_overlay.draw_string(HUD.FONT, Vector2(250, 184), "Esc to resume", HORIZONTAL_ALIGNMENT_CENTER, 140, 9, Color("a89878")))
	hud.add_child(paused_overlay)


func set_paused(on: bool) -> void:
	if dialogue.is_open or journal.is_open or world_map.is_open or _traveling:
		return
	if on:
		spellbook.close()
	get_tree().paused = on
	paused_overlay.visible = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_HIDDEN


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed(&"pause"):
		set_paused(not get_tree().paused)
	elif e.is_action_pressed(&"wheel") and not get_tree().paused and not _traveling:
		spellbook.open()
	elif e.is_action_pressed(&"journal") and not get_tree().paused and not _traveling:
		player.input_enabled = false
		journal.open()
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
