class_name SpellData
extends Resource
## One spell or basic attack. Balance numbers live here, behaviour lives in
## `effect` (a SpellEffect script). `upgrade_params` override `params`
## when the spell's upgrade is owned.

@export var id: StringName
@export var display_name := ""
@export_enum("fire", "hex", "storm") var school: String = "storm"
@export var is_basic := false
@export var mana_cost := 10.0
@export var cooldown := 1.0
## Committed, interruptible time before the spell releases.
@export var windup := 0.12
## Short recovery after release (movement stays allowed).
@export var recovery := 0.12
@export var damage := 10.0
@export var icon := 0
@export_multiline var description := ""
@export var upgrade_name := ""
@export_multiline var upgrade_description := ""
@export var effect: Script
@export var params: Dictionary = {}
@export var upgrade_params: Dictionary = {}


func p(key: String, upgraded: bool, default: Variant = 0.0) -> Variant:
	if upgraded and upgrade_params.has(key):
		return upgrade_params[key]
	return params.get(key, default)


func school_name() -> StringName:
	return StringName(school)
