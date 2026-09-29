class_name ShrineArea
extends Region
## A lake shrine area (Chapter 2), reached by boat from Reedhollow: a landing
## at the west end (pier, moored boat home), a path east to the shrine in its
## clearing. Hollowed things guard the shrine: they spawn only while it is
## dark, and it can't be relit while one of them is still near. Relighting
## it is a contextual-magic channel; the reward comes once. Each area adds
## its own ground, props, enemies and one contextual-magic moment through
## _area_layout() / _area_build().

const PROPS := "res://assets/generated/props_woods.png"
const GUARD_R := 10.0
const SHRINE_RAMP := [Color("ffffff"), Color("d8fff0"), Color("80e0d0"), Color("2a8878")]

var shrine_flag := &""
var relic := &""
var shrine_at := Vector2(21, -2.5)
var landing := Vector2(-21, 0.5)      # where the pier meets the land
var guards: Array = []                 # spawn rows guarding the shrine
var arrive_lines: Array = []           # said on the first visit (Kess, if she's along)
var lit_lines: Array = []
var shrine: Dictionary
var shrine_it: Interactable
var tex: Texture2D
var props: Dictionary


func _layout() -> void:
	music = "lake"
	enemy_scale = 1.25
	origin = Vector2(-40, -40)
	grid = Vector2i(80, 80)
	bounds = Rect2(-28, -12, 56, 22)
	_area_layout()
	landing_layout(landing)
	pads.append([shrine_at.x, shrine_at.y, 3.2, 0.25])
	dirt_spots.append([shrine_at.x, shrine_at.y, 4.0])
	if not GameState.flag(shrine_flag):
		spawns.append_array(guards)


func _build() -> void:
	tex = load(PROPS)
	props = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
	landing_build(landing)
	_shrine()
	_area_build()


func _area_layout() -> void:
	pass


func _area_build() -> void:
	pass


## Subclass hook: the shrine has just been relit (after the reward).
func _on_lit() -> void:
	pass


## The shrine: a ward stone in a ring of low standing stones (all under a
## metre, so nothing hides the fight around it).
func _shrine() -> void:
	shrine = ward_stone(shrine_at.x, shrine_at.y, GameState.flag(shrine_flag))
	for k in 8:
		var a := k * TAU / 8.0 + 0.2
		var p := shrine_at + Vector2(cos(a), sin(a)) * 3.4
		var h := rng.randf_range(0.5, 0.95)
		box(Vector3(0.5, h, 0.4), _ground(p.x, p.y) + Vector3(0, h * 0.5 - 0.1, 0), "rune_bricks.png", Vector3(0, -a, rng.randf_range(-0.08, 0.08)))
	FX3.decal(FX3.RUNE_L, _ground(shrine_at.x, shrine_at.y) + Vector3(0, 0.04, 0), 1e9, Color(0.5, 0.9, 0.85, 0.35), 2.6, 2.6, 0.2)
	shrine_it = Interactable.make(shrine.pos - Vector3(0, 1.2, 0) + Vector3(0, 0, 0.6), "Relight the shrine", 2.2, 1.9)
	add_child(shrine_it)
	shrine_it.activated.connect(_relight)


## Live guards still near the shrine.
func guards_left() -> int:
	var at := _ground(shrine_at.x, shrine_at.y)
	var n := 0
	for c in get_children():
		if c is Enemy and not c is Spore and (c as Enemy).is_alive() and SpellEffect.flat(c.global_position, at) < GUARD_R:
			n += 1
	return n


## Light a shrine's flag and grant its reward once. Returns the reward item
## (empty if it was already given). Any order: each shrine is independent.
static func light_shrine(flag: StringName, item: StringName) -> Dictionary:
	GameState.set_flag(flag)
	var got := {}
	GameState.once(StringName(String(flag) + "_reward"), func() -> void:
		got.merge(GameState.inv.add(item))
		GameState.inv.points += 1)
	return got


func _relight(p: Player) -> void:
	if guards_left() > 0:
		await Dialogue.i.talk([["", "Hollowed things still circle the shrine. Drive them off first."]])
		return
	shrine_it.enabled = false
	Sfx.play("ward_light", -8.0)
	await channel(p, shrine.pos, SHRINE_RAMP, 2.0)
	var got := light_shrine(shrine_flag, relic)
	set_ward(shrine, true)
	ward_flare(shrine)
	for k in 4:
		SpellEffect.later(0.3 * k, func() -> void:
			FX3.ring(_ground(shrine_at.x, shrine_at.y) + Vector3(0, 0.1, 0), 0.5, 6.0 + k * 3.0, 0.9, SHRINE_RAMP, 2.0))
	if not got.is_empty():
		reward(["Received: " + Items.display(got), "+1 progression point"])
		GameState.inv.changed.emit()
		var hud0 := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud0:
			hud0.fusion_hint()
	SaveSystem.autosave()
	var hud := get_tree().get_first_node_in_group(&"hud") as HUD
	if hud:
		hud.banner("Shrine relit (%d of 3)" % Quests.shrines_lit())
	_on_lit()
	var lit := Quests.shrines_lit()
	var step := GameState.quest_step(Quests.HOLLOWING)
	await get_tree().create_timer(1.0).timeout
	if lit == 2 and not GameState.flag(&"herald_fled"):
		# the second shrine draws the Herald to Reedhollow (step 6's attack)
		GameState.advance(Quests.HOLLOWING, 4)
		SaveSystem.autosave()
		var alarm := ["Kess", "{name}... that's Reedhollow. Something's attacking the village. To the boat, now!"] if GameState.in_party(&"kess") \
			else ["", "Something is attacking Reedhollow. Back to the boat."]
		await Dialogue.i.talk(lit_lines + [["", "Far across the water, a red glow blooms where Reedhollow stands. Smoke rises over the lake."], alarm])
		return
	if lit == 3 and step in [3, 5]:
		GameState.advance(Quests.HOLLOWING, 6)
		SaveSystem.autosave()
	var last := "The shrines are all burning. The Heart Isle's seal must be open." if lit == 3 \
		else "%s more to relight." % ("One" if lit == 2 else "Two")
	await Dialogue.i.talk(lit_lines + [["", last]])


func enter(p: Player, entry: StringName) -> void:
	super.enter(p, entry)
	if GameState.in_party(&"kess") and not arrive_lines.is_empty() and GameState.once(StringName("arrive_" + String(id))):
		await get_tree().create_timer(0.8).timeout
		await Dialogue.i.talk(arrive_lines)


func apply_state() -> void:
	var lit: bool = GameState.flag(shrine_flag)
	set_ward(shrine, lit)
	shrine_it.enabled = not lit
