class_name WizardState
extends RefCounted
## Class and spell progression for the wizard: active school, unlocked
## spells, upgrades, foreign-school affinity and one saved loadout per school.

const SCHOOLS := ["fire", "hex", "storm"]
const SCHOOL_NAMES := {"fire": "Pyromancer", "hex": "Hexbinder", "storm": "Stormcaller"}
const BASE := {
	"fire": [&"ember_spear", &"cinder_fan", &"hearth_ward", &"ashfall"],
	"hex": [&"grave_needle", &"binding_roots", &"siphon_circle", &"spirit_lantern"],
	"storm": [&"arc_lance", &"thunder_ring", &"slipstream", &"tempest_orb"],
}
## Chapter 2: the Deepwillow teaches one more spell per school (a fifth
## choice for the loadout; never unlocked by switching schools).
const LAKE := {"fire": &"boiling_spring", "hex": &"drowning_grasp", "storm": &"chain_current"}
const COLS := 5
const BASICS := {"fire": &"flame_pulse", "hex": &"spectral_thrust", "storm": &"storm_gust"}
const AFFINITY := [0.75, 0.85, 0.95, 1.0]

var school := "storm"
var unlocked := {}                                   # spell id -> true
var upgrades := {}                                   # spell id -> true
var affinity := {"fire": 0, "hex": 0, "storm": 0}    # training level 0..3
var loadouts := {}                                   # school -> Array[StringName] (4)


## A school's row in the spellbook: its four base spells, then its lake spell.
static func grid(s: String) -> Array:
	return (BASE[s] as Array) + [LAKE[s]]


func setup(start: String) -> void:
	school = start
	_unlock_school(start)


func switch_school(s: String) -> void:
	if not SCHOOLS.has(s):
		return
	school = s
	# switching makes that school's base spells available
	_unlock_school(s)


func _unlock_school(s: String) -> void:
	for id in BASE[s]:
		unlocked[id] = true
	if not loadouts.has(s):
		loadouts[s] = (BASE[s] as Array).duplicate()


func loadout() -> Array:
	return loadouts[school]


func basic() -> StringName:
	return BASICS[school]


## Positive-effect multiplier for a spell of `spell_school`.
func affinity_mult(spell_school: String) -> float:
	if spell_school == school:
		return 1.0
	return AFFINITY[clampi(affinity.get(spell_school, 0), 0, 3)]


func is_native(spell_school: String) -> bool:
	return spell_school == school


## Equip `id` into `slot` of the active loadout. A spell appears only once:
## if it is already in another slot the two slots swap. Returns false if
## the spell is not unlocked.
func equip(slot: int, id: StringName) -> bool:
	if slot < 0 or slot > 3:
		return false
	if id != &"" and not unlocked.has(id):
		return false
	var lo: Array = loadouts[school]
	var prev := lo.find(id)
	if id != &"" and prev != -1 and prev != slot:
		lo[prev] = lo[slot]
	lo[slot] = id
	return true


func train(s: String) -> bool:
	if s == school or affinity[s] >= 3:
		return false
	affinity[s] += 1
	return true


func to_dict() -> Dictionary:
	var lo := {}
	for k in loadouts:
		lo[k] = (loadouts[k] as Array).map(func(x: StringName) -> String: return String(x))
	return {"school": school, "unlocked": unlocked.keys().map(func(x) -> String: return String(x)),
		"upgrades": upgrades.keys().map(func(x) -> String: return String(x)), "affinity": affinity.duplicate(), "loadouts": lo}


## Rebuilds from saved data, dropping unknown spell ids.
func from_dict(d: Dictionary) -> void:
	school = d.get("school", "storm") if SCHOOLS.has(d.get("school", "")) else "storm"
	unlocked.clear()
	upgrades.clear()
	for id in d.get("unlocked", []):
		if SpellDB.exists(StringName(id)):
			unlocked[StringName(id)] = true
	for id in d.get("upgrades", []):
		if SpellDB.exists(StringName(id)):
			upgrades[StringName(id)] = true
	for s in SCHOOLS:
		affinity[s] = clampi(int(d.get("affinity", {}).get(s, 0)), 0, 3)
	loadouts.clear()
	var lo: Dictionary = d.get("loadouts", {})
	for s in lo:
		if SCHOOLS.has(s):
			var arr: Array = []
			for id in lo[s]:
				var sid := StringName(id)
				arr.append(sid if unlocked.has(sid) and not arr.has(sid) else &"")
			while arr.size() < 4:
				arr.append(&"")
			loadouts[s] = arr.slice(0, 4)
	_unlock_school(school)
