extends Node
## Permanent adventure progress (everything a save file keeps, apart from the
## wizard's spells/loadouts in WizardState): story flags, one-time events,
## quest steps, unlocks, the local choice, known places and the checkpoint.
## Temporary encounter state (enemy health, projectiles) never lives here.

signal changed
signal quest_updated(id: StringName)

var wizard_name := "Wren"
var appearance := {}
var flags := {}            # StringName -> Variant (world consequences, choices)
var events := {}           # StringName -> true: rewards/recruits granted exactly once
var quests := {}           # quest id -> step index (Quests.DATA); -1 = done
var unlocks := {}          # &"levitate" ...
var known := {&"sanctuary": true}   # places the world map shows
var inv := Inventory.new()
var placed: Array = []     # home building: [{id, x, z, rot}]
const PARTY_MAX := 2
var recruited := {}                  # companion id -> true
var party: Array[StringName] = []    # who walks with the wizard, in order
var region := &"sanctuary"
var entry := &"start"      # checkpoint entry id inside `region`


func reset() -> void:
	wizard_name = "Wren"
	appearance = {}
	flags.clear()
	events.clear()
	quests.clear()
	unlocks.clear()
	known = {&"sanctuary": true}
	inv = Inventory.new()
	placed = []
	recruited = {}
	party = []
	region = &"sanctuary"
	entry = &"start"
	changed.emit()


## A fresh game's starting kit: the crook and the wanderer's robe, worn.
func new_game_kit() -> void:
	var st := inv.add(&"crook")
	var rb := inv.add(&"wanderer")
	st.bonus = {}
	rb.bonus = {}
	inv.equip("staff", int(st.uid))
	inv.equip("robe", int(rb.uid))
	for d in [&"lantern", &"bench", &"planter"]:
		inv.decor[d] = true


func flag(id: StringName, default: Variant = false) -> Variant:
	return flags.get(id, default)


func set_flag(id: StringName, v: Variant = true) -> void:
	if flags.get(id) != v:
		flags[id] = v
		changed.emit()


## Runs `grant` only the first time `id` is claimed. Returns whether it ran.
func once(id: StringName, grant: Callable = Callable()) -> bool:
	if events.has(id):
		return false
	events[id] = true
	if grant.is_valid():
		grant.call()
	changed.emit()
	return true


func in_party(id: StringName) -> bool:
	return party.has(id)


## Recruit a companion; they follow straight away if asked and there's room.
func recruit(id: StringName, follow: bool) -> void:
	recruited[id] = true
	if follow:
		join_party(id)
	changed.emit()


## Bring a recruited companion along. Returns "" or why they can't come.
func join_party(id: StringName) -> String:
	if not recruited.has(id):
		return "They haven't joined you yet."
	if party.has(id):
		return ""
	if party.size() >= PARTY_MAX:
		return "Two already walk with you. Ask one to rest at the camp first."
	party.append(id)
	changed.emit()
	return ""


func leave_party(id: StringName) -> void:
	if party.has(id):
		party.erase(id)
		changed.emit()


func has_unlock(id: StringName) -> bool:
	return unlocks.has(id)


func unlock(id: StringName) -> void:
	unlocks[id] = true
	changed.emit()


func learn_place(id: StringName) -> void:
	if not known.has(id):
		known[id] = true
		changed.emit()


# ------------------------------------------------------------------ quests
func quest_step(id: StringName) -> int:
	return quests.get(id, -2)   # -2 = not started


func quest_active(id: StringName) -> bool:
	return quests.get(id, -2) >= 0


func quest_done(id: StringName) -> bool:
	return quests.get(id, -2) == -1


func start_quest(id: StringName) -> void:
	if not quests.has(id):
		quests[id] = 0
		quest_updated.emit(id)
		changed.emit()


## Move a quest to `step` (only forward), or finish it with -1.
func advance(id: StringName, step: int) -> void:
	var cur: int = quests.get(id, -2)
	if cur == -1 or (step != -1 and step <= cur):
		return
	quests[id] = step
	quest_updated.emit(id)
	changed.emit()


func to_dict() -> Dictionary:
	return {"name": wizard_name, "appearance": appearance, "flags": flags, "events": events.keys(),
		"quests": quests, "unlocks": unlocks.keys(), "known": known.keys(), "region": region, "entry": entry,
		"inv": inv.to_dict(), "placed": placed, "recruited": recruited.keys(), "party": party}


func from_dict(d: Dictionary) -> void:
	reset()
	wizard_name = d.get("name", "Wren")
	appearance = d.get("appearance", {})
	for k in d.get("flags", {}):
		flags[StringName(k)] = d.flags[k]
	for k in d.get("events", []):
		events[StringName(k)] = true
	for k in d.get("quests", {}):
		quests[StringName(k)] = int(d.quests[k])
	for k in d.get("unlocks", []):
		unlocks[StringName(k)] = true
	for k in d.get("known", []):
		known[StringName(k)] = true
	region = StringName(d.get("region", "sanctuary"))
	entry = StringName(d.get("entry", "start"))
	inv.from_dict(d.get("inv", {}))
	placed = []
	for pl in d.get("placed", []):
		if pl is Dictionary and pl.has("id"):
			placed.append({"id": StringName(pl.id), "x": float(pl.get("x", 0)), "z": float(pl.get("z", 0)), "rot": int(pl.get("rot", 0)),
				"paid": int(pl.get("paid", 0))})
	var c: Dictionary = d.get("companion", {})      # version 1 (Chapter 1)
	if c.get("recruited", false):
		recruited[&"tamsin"] = true
		if c.get("following", false):
			party.append(&"tamsin")
	for k in d.get("recruited", []):
		recruited[StringName(k)] = true
	for k in d.get("party", []):
		var id := StringName(k)
		if recruited.has(id) and not party.has(id) and party.size() < PARTY_MAX:
			party.append(id)
