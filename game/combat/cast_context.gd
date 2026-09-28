class_name CastContext
extends RefCounted
## Everything a spell effect needs at the moment of release.

var caster: Node2D
var data: SpellData
var upgraded := false
var power := 1.0          # affinity × passive multiplier on positive effects
var native := true
var origin := Vector2.ZERO  # staff gem, global
var dir := Vector2.RIGHT
var target: Node2D = null
var aim_point := Vector2.ZERO
var world: Node = null
var bonus := {}           # passive extras (e.g. heat charges spent)


func p(key: String, default: Variant = 0.0) -> Variant:
	return data.p(key, upgraded, default)


func dmg(mult: float = 1.0, kb: Vector2 = Vector2.ZERO) -> Damage:
	var d := Damage.make(data.damage * power * mult, caster, data.school_name(), kb)
	d.spell_id = data.id
	return d


func spawn(n: Node) -> void:
	world.add_child(n)
