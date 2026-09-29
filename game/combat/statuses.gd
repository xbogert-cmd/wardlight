class_name Statuses
extends Node
## Timed status effects on an actor. Durations tick on scaled time.
##   burn  — fire damage over time (proc damage: never triggers passives)
##   curse — hex mark: the bearer takes CURSE_MULT damage; enables Soul Echo,
##           Grave Current and Haunted Embers
##   root  — cannot move (bosses shrug it off faster via `root_resist`)
##   slow  — walks slower by `power` (0.4 = 40% slower): Husk spores
##   mark  — Kess's arrow: the wizard's next spell hit deals MARK_MULT and
##           uses it up (CastContext.hit)

signal changed

const BURN_TICK := 0.5
const CURSE_MULT := 1.2
const MARK_MULT := 1.25

var owner_actor: Node3D
var root_resist := 0.0
var _s := {}  # id -> {t, power, src}
var _burn_acc := 0.0


func apply(id: StringName, duration: float, power: float = 0.0, src: Node = null) -> void:
	if id == &"root":
		duration *= 1.0 - root_resist
	if id == &"slow" and owner_actor is Player:
		power *= 1.0 - GameState.inv.relic(&"bogheart")
	if src is Player:
		if id == &"burn":
			power *= 1.0 + GameState.inv.relic(&"ember_seed")
		elif id == &"curse":
			duration += GameState.inv.relic(&"whisper_bone")
	var cur: Dictionary = _s.get(id, {})
	_s[id] = {"t": maxf(duration, cur.get("t", 0.0)), "power": maxf(power, cur.get("power", 0.0)), "src": src}
	changed.emit()


func has(id: StringName) -> bool:
	return _s.has(id)


func remaining(id: StringName) -> float:
	return _s.get(id, {}).get("t", 0.0)


func remove(id: StringName) -> void:
	if _s.erase(id):
		changed.emit()


func clear() -> void:
	_s.clear()
	changed.emit()


func move_scale() -> float:
	if _s.has(&"root"):
		return 0.0
	return 1.0 - clampf(float(_s[&"slow"].power), 0.0, 0.9) if _s.has(&"slow") else 1.0


func _physics_process(delta: float) -> void:
	if _s.is_empty():
		return
	var gone := []
	for id in _s:
		_s[id].t -= delta
		if _s[id].t <= 0.0:
			gone.append(id)
	if _s.has(&"burn"):
		_burn_acc += delta
		if _burn_acc >= BURN_TICK:
			_burn_acc -= BURN_TICK
			var b: Dictionary = _s[&"burn"]
			var d := Damage.make(b.power, b.src, &"fire")
			d.is_proc = true
			d.stagger = 0.0
			d.hit_pos = owner_actor.center()
			owner_actor.take_hit(d)
	for id in gone:
		_s.erase(id)
	if not gone.is_empty():
		changed.emit()
