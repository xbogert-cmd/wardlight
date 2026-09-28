class_name Damage
extends RefCounted
## One hit. Carries enough context for passives and interactions to reason
## about it without recursion (see `is_proc`).

var amount := 0.0
var source: Node = null
var school := &""          # &"fire", &"hex", &"storm" or &"" for physical
var spell_id := &""
var knockback := Vector2.ZERO
var stagger := 0.0         # poise damage
var statuses: Array = []   # [{id, duration, power}]
var is_proc := false       # passive / interaction damage never triggers further procs
var active_attack := true  # enemy hits: came from a real attack (used for perfect-dodge mana)
var hit_pos := Vector2.ZERO


static func make(amt: float, src: Node, sch: StringName = &"", kb: Vector2 = Vector2.ZERO) -> Damage:
	var d := Damage.new()
	d.amount = amt
	d.source = src
	d.school = sch
	d.knockback = kb
	d.stagger = amt
	return d
