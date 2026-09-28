class_name CastContext
extends RefCounted
## Everything a spell effect needs at the moment of release. Spells report
## damage through hit() so passives and interactions see every real hit.

var caster: Node3D
var data: SpellData
var upgraded := false
var power := 1.0          # affinity × passive multiplier on positive effects
var native := true
var origin := Vector3.ZERO  # staff gem, global
var dir := Vector3.RIGHT   # horizontal unit vector
var target: Node3D = null
var aim_point := Vector3.ZERO  # on the ground (or a target centre)
var world: Node = null
var bonus := {}           # per-cast flags (heat spent, scattered embers...)
var hits := 0


func p(key: String, default: Variant = 0.0) -> Variant:
	return data.p(key, upgraded, default)


func dmg(mult: float = 1.0, kb: Vector3 = Vector3.ZERO) -> Damage:
	var d := Damage.make(data.damage * power * mult, caster, data.school_name(), kb)
	d.spell_id = data.id
	return d


## Proc damage (passives / interactions): cannot trigger further procs.
func proc_dmg(amount: float, school: StringName, id: StringName) -> Damage:
	var d := Damage.make(amount, caster, school)
	d.spell_id = id
	d.is_proc = true
	d.stagger = amount * 0.5
	return d


func spawn(n: Node) -> void:
	world.add_child(n)


func hit(target_actor: Node3D, d: Damage) -> void:
	if not is_instance_valid(target_actor) or not target_actor.is_alive():
		return
	if d.hit_pos == Vector3.ZERO:
		d.hit_pos = target_actor.center()
	if bonus.has("heat") and not d.is_proc:
		d.statuses.append({"id": &"burn", "duration": 2.5, "power": 4.0})
	for s: Dictionary in d.statuses:
		target_actor.statuses.apply(s.id, s.duration, s.get("power", 0.0), caster)
	target_actor.take_hit(d)
	Events.damage_dealt.emit(target_actor, d)
	if d.is_proc:
		return
	hits += 1
	if caster.passives:
		caster.passives.on_cast_hit(self, target_actor, d)
	Interactions.on_spell_hit(self, target_actor, d)
