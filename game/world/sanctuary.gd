extends Region
## The Sanctuary: the wizard's hilltop home at dusk. Cottage, class study
## (switch school), appearance mirror, fusion altar (relics: stage 4), the lit
## sanctuary ward, a home plot, and Isolde's tonic table if she settles here.
## The adventure opens here: Pell runs up the path with news, and a bramble
## on the gate path teaches the first spell.

var pell: Npc
var bramble: Bramble
var isolde: Npc


func _layout() -> void:
	id = &"sanctuary"
	display_name = "The Sanctuary"
	music = "home"
	env_preset = &"dusk"
	seed_value = 77
	origin = Vector2(-40, -40)
	grid = Vector2i(80, 80)
	bounds = Rect2(-19, -16, 41, 30)
	paths = [[Vector2(-5, -3.5), Vector2(0, -1), Vector2(6, 1.5), Vector2(14, 2.5), Vector2(23, 3)], [Vector2(0, -1), Vector2(6, -5)]]
	hills = [[-14, 12, 3.5, 7.0], [12, 13, 3.0, 6.0], [-20, -4, 3.0, 7.0], [4, -20, 3.5, 9.0], [20, -10, 2.5, 6.0]]
	pads = [[-5, -7, 5.5, 0.4], [6, -8, 4.0, 0.4], [10, 6, 4.5, 0.3]]
	dirt_spots = [[-5, -3.5, 2.5], [10, 6, 3.8], [0, -2, 2.0]]
	entries = {&"start": [Vector3(-4.2, 0, -3.2), 1.0], &"east": [Vector3(19.5, 0, 3.0), -1.0]}
	exits = [{"rect": Rect2(21.0, -3, 1.5, 12), "to": &"hearthmere", "entry": &"west"}]
	respawn_entry = &"start"


func _build() -> void:
	house(-5, -7, 6.0, 4.5, 2.6, {"roof": "thatch.png", "chimney": true, "windows": [-1.9, 1.8], "door_x": 0.0, "tint": Color(1.0, 0.95, 0.88)})
	house(6, -8.5, 3.6, 3.2, 3.4, {"wall": "bricks.png", "windows": [0.0], "door": false, "roof_h": 1.8, "tint": Color(0.9, 0.9, 1.0)})
	ward_stone(0.5, -2.0, true, true)
	brazier(-1.5, 1.0)
	lantern_post(4.0, 2.8, 1.0)
	lantern_post(13.0, 0.8, -1.0)
	# garden beds by the cottage
	for k in 3:
		var g := _ground(-10.5 + k * 1.6, -3.0)
		box(Vector3(1.3, 0.3, 2.0), g + Vector3(0, 0.1, 0), "wood.png", Vector3.ZERO, false, Color(0.7, 0.6, 0.5))
		for j in 3:
			bill(load("res://assets/generated/props_woods.png"), g + Vector3(randf_range(-0.4, 0.4), 0.2, -0.6 + j * 0.6), 1.0, Rect2(_prop_rect("fern")))
	# the home plot: a ring of small stones marks where things can be built
	for k in 14:
		var a := k * TAU / 14.0
		bill(load("res://assets/generated/props_woods.png"), _ground(10 + cos(a) * 4.0, 6 + sin(a) * 3.2), 0.8, Rect2(_prop_rect("rock_s")))
	_stations()
	_folk()
	var keep := func(p: Vector2) -> bool:
		return path_dist(p) > 2.6 and Vector2(p.x + 5, p.y + 7).length() > 6.0 and Vector2(p.x - 6, p.y + 8).length() > 4.5 \
			and Vector2(p.x - 10, p.y - 6).length() > 5.5 and Vector2(p.x, p.y + 2).length() > 3.5
	trees(Rect2(-34, -30, 70, 52), 110, func(p: Vector2) -> bool: return keep.call(p) and not bounds.grow(-3.0).has_point(p) or (keep.call(p) and rng.randf() < 0.12))
	scenery(Rect2(-20, -16, 42, 30), 160, func(p: Vector2) -> bool: return path_dist(p) > 1.4 and keep.call(p))
	bill(load(D + "signpost.png"), _ground(17.5, 1.2))


func _prop_rect(name: String) -> Rect2:
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
	var r: Array = props[name]
	return Rect2(r[0], r[1], r[2], r[3])


func _stations() -> void:
	# class study: a lectern by the tower door
	var lg := _ground(6.0, -6.4)
	box(Vector3(0.5, 1.0, 0.4), lg + Vector3(0, 0.5, 0), "wood.png", Vector3(0, 0, 0.1))
	var book := bill(load(D + "ward_lit.png"), lg + Vector3(0, 1.05, 0), 0.5)
	book.set_tint(Color(1.0, 0.85, 0.6))
	book.mat.set_shader_parameter(&"emit", 0.8)
	var study := Interactable.make(lg, "Class study (change school)", 1.8, 1.8)
	add_child(study)
	study.activated.connect(func(p: Player) -> void:
		var names := []
		for s in WizardState.SCHOOLS:
			names.append(WizardState.SCHOOL_NAMES[s] + (" (current)" if s == p.wiz.school else ""))
		names.append("Leave the study")
		var k: int = await Dialogue.i.choose("", "The study's old books fall open to three disciplines. Your spells and loadouts are kept for each.", names)
		if k < 3 and WizardState.SCHOOLS[k] != p.wiz.school:
			p.wiz.switch_school(WizardState.SCHOOLS[k])
			p.passives.reset()
			FX3.ring(p.global_position + Vector3(0, 0.05, 0), 0.2, 1.6, 0.4, Pal.school(StringName(p.wiz.school)), 2.0)
			FX3.burst(p.center(), 20, Pal.school(StringName(p.wiz.school)), Vector2(1.0, 3.0), Vector2(0.4, 0.8), {"gravity": -1.5})
			Sfx.play(p.wiz.school + "_gather", 0.0)
			var hud := get_tree().get_first_node_in_group(&"hud") as HUD
			if hud:
				hud.banner(WizardState.SCHOOL_NAMES[p.wiz.school]))
	# appearance mirror beside the cottage
	var mg := _ground(-9.8, -5.6)
	box(Vector3(0.9, 1.9, 0.15), mg + Vector3(0, 0.95, 0), "wood.png", Vector3.ZERO, true, Color(0.8, 0.7, 0.6))
	var glass := bill(load(D + "ward_dark.png"), mg + Vector3(0, 0.6, 0.12), 1.2)
	glass.set_tint(Color(0.7, 0.8, 1.0))
	var mirror := Interactable.make(mg, "Appearance", 1.8, 2.2)
	add_child(mirror)
	mirror.activated.connect(func(p: Player) -> void:
		p.input_enabled = false
		get_tree().paused = true
		var ed := LookEditor.new()
		get_tree().root.add_child(ed)
		ed.open(false)
		var res: Dictionary = await ed.finished
		get_tree().paused = false
		p.resume_input()
		if not res.is_empty():
			GameState.appearance = res.look
			p.set_look(res.look)
			GameState.changed.emit())
	# fusion altar (relic fusion arrives with stage 4 loot)
	var ag := _ground(2.8, -9.0)
	box(Vector3(1.2, 0.8, 0.8), ag + Vector3(0, 0.4, 0), "rune_bricks.png")
	box(Vector3(1.4, 0.15, 1.0), ag + Vector3(0, 0.85, 0), "bricks.png", Vector3.ZERO, false)
	var altar := Interactable.make(ag, "Fusion altar", 1.8, 1.4)
	add_child(altar)
	altar.activated.connect(func(_p: Player) -> void:
		await Dialogue.i.talk([["", "The fusion altar is cold. Two matching relics laid here could be bound into a stronger one."]]))


func _folk() -> void:
	pell = Npc.new()
	pell.sheet = "pell"
	pell.display = "Pell"
	add_child(pell)
	pell.global_position = _ground(7.5, 2.2)
	pell.on_talk = _talk_pell
	bramble = Bramble.new()
	add_child(bramble)
	bramble.global_position = _ground(15.5, 2.6)
	bramble.rotation.y = 0.1
	bramble.cleared.connect(func() -> void:
		GameState.set_flag(&"bramble_cleared")
		if GameState.flag(&"intro_talked"):
			await get_tree().create_timer(0.6).timeout
			await Dialogue.i.talk([["Pell", "Ha! That's the {name} I remember. I'll run ahead and tell Maren you're coming!"]])
			_pell_leaves())
	isolde = Npc.new()
	isolde.sheet = "isolde"
	isolde.display = "Isolde"
	add_child(isolde)
	isolde.global_position = _ground(-1.5, -5.5)
	isolde.on_talk = func() -> void:
		var k: int = await Dialogue.i.choose("Isolde", "Nightbloom tonic, {name}? It keeps the wind in your lungs a while.", ["A tonic, please", "Not now"])
		if k == 0:
			player.health.heal(player.health.max_hp)
			player.mana.refill()
			GameState.set_flag(&"tonic", true)
			FX3.burst(player.center(), 20, Pal.HEAL, Vector2(0.5, 2.0), Vector2(0.4, 0.8), {"gravity": -1.0})
			await Dialogue.i.talk([["Isolde", "There. Bitter, but it works."]])


func _talk_pell() -> void:
	if not GameState.flag(&"intro_talked"):
		await Dialogue.i.talk([
			["Pell", "Master {name}! I ran all the way up. Hearthmere's wardlight has gone dark!"],
			["Pell", "Three nights now. Travellers on the Briarwood road haven't come home, and there are roots creeping up through the cobbles."],
			["Pell", "Elder Maren asked for you. She said you'd know what to do."],
			["Pell", "Only... the gate path's choked with brambles again. Could you clear it?"],
		])
		GameState.set_flag(&"intro_talked")
		GameState.start_quest(Quests.MAIN)
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud and not GameState.flag(&"bramble_cleared"):
			var basic := SpellDB.get_spell(player.wiz.basic())
			var first := SpellDB.get_spell(player.wiz.loadout()[0])
			hud.banner("Point at the brambles: %s %s, or %s %s" % [Settings.key_label("spell_1"), first.display_name, Settings.key_label("attack"), basic.display_name])
		if GameState.flag(&"bramble_cleared"):
			_pell_leaves()
	else:
		await Dialogue.i.talk([["Pell", "Hearthmere's just down the path, past the brambles."]])


func _pell_leaves() -> void:
	pell.enabled = false
	pell.walk_speed = 4.0
	pell.walk_to = _ground(21.0, 3.0)
	var tw := pell.create_tween()
	tw.tween_interval(3.2)
	tw.tween_callback(func() -> void: pell.visible = false)


func apply_state() -> void:
	if GameState.flag(&"bramble_cleared") and is_instance_valid(bramble):
		bramble.queue_free()
	if GameState.flag(&"intro_talked") and GameState.flag(&"bramble_cleared"):
		pell.visible = false
		pell.enabled = false
	var here: bool = GameState.flag(&"isolde_home", "") == "sanctuary"
	isolde.visible = here
	isolde.enabled = here
