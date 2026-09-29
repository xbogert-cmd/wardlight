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


## The equipped staff's signature on staff attacks, scaled by its tier.
func _staff_identity(target_actor: Node3D, d: Damage) -> void:
	var m := GameState.inv.tier_mult("staff")
	match GameState.inv.staff_id():
		&"cinderbrand":
			d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0 * m})
		&"gravewood":
			d.statuses.append({"id": &"curse", "duration": 2.5 * m})
		&"reedwhistle":
			d.statuses.append({"id": &"slow", "duration": 1.5, "power": 0.2 * m})
		&"stormcoil":
			if bonus.has("coil"):
				return
			bonus["coil"] = true
			var e := SpellEffect.nearest(target_actor.center(), 3.5, [target_actor], target_actor)
			if e:
				FX3.bolt(target_actor.center(), e.center(), 0.15, Pal.school(&"storm"), 0.12)
				var pd := proc_dmg(d.amount * 0.5 * m, &"storm", &"stormcoil")
				pd.hit_pos = e.center()
				SpellEffect.later(0.05, func() -> void: hit(e, pd))


## Proc damage (passives / interactions): cannot trigger further procs.
func proc_dmg(amount: float, school: StringName, id: StringName) -> Damage:
	var d := Damage.make(amount, caster, school)
	d.spell_id = id
	d.is_proc = true
	d.stagger = amount * 0.5
	return d


## Add `n` to the world, placed at `at` (global) *before* it enters the tree,
## so its _ready already sees where it is.
func spawn(n: Node, at: Variant = null) -> void:
	if at != null:
		(n as Node3D).position = (world as Node3D).to_local(at)
	world.add_child(n)


func hit(target_actor: Node3D, d: Damage) -> void:
	if not is_instance_valid(target_actor) or not target_actor.is_alive():
		return
	if d.hit_pos == Vector3.ZERO:
		d.hit_pos = target_actor.center()
	if bonus.has("heat") and not d.is_proc:
		d.statuses.append({"id": &"burn", "duration": 2.5, "power": 4.0})
	if data.is_basic and not d.is_proc:
		_staff_identity(target_actor, d)
	for s: Dictionary in d.statuses:
		target_actor.statuses.apply(s.id, s.duration, s.get("power", 0.0), caster)
	if not d.is_proc and not data.is_basic and target_actor.statuses.has(&"mark"):
		target_actor.statuses.remove(&"mark")
		d.amount *= Statuses.MARK_MULT
		FX3.ring(target_actor.center(), 0.1, 0.9, 0.25, [Color("fff0c0"), Color("f0c870"), Color("a07840")], 1.0, false)
	target_actor.take_hit(d)
	Events.damage_dealt.emit(target_actor, d)
	if d.is_proc:
		return
	hits += 1
	if caster.passives:
		caster.passives.on_cast_hit(self, target_actor, d)
	Interactions.on_spell_hit(self, target_actor, d)
