extends Node
## Game root. Owns the persistent player, the HUD and the current level.

var player: Player
var level: Crossing
var hud: HUD
var spellbook: Spellbook
var paused_overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player = Player.new()
	hud = HUD.new()
	add_child(hud)
	load_level()
	hud.bind(player)
	spellbook = Spellbook.new()
	spellbook.player = player
	hud.add_child(spellbook)
	player.died.connect(spellbook.close)
	_build_pause()


func load_level() -> void:
	if level:
		level.queue_free()
	level = Crossing.new()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	level.enter(player)
	hud.banner(level.display_name)


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
	if on:
		spellbook.close()
	get_tree().paused = on
	paused_overlay.visible = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_HIDDEN


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed(&"pause"):
		set_paused(not get_tree().paused)
	elif e.is_action_pressed(&"wheel") and not get_tree().paused:
		spellbook.open()
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
