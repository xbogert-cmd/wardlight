class_name Husk
extends Enemy
## Husk — a villager the Hollowing has emptied out. Shambles slowly toward
## the wizard; in reach it rears back with raised arms and glowing eyes while
## a red line marks the lunge (the tell), then lunges a few metres and stands
## spent for a moment (the punish window). Dying, it bursts into a spore
## patch that slows anyone walking through it.

var _cd := 1.0
var _dir := Vector3.RIGHT
var _hit := false


func _setup() -> void:
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle":
			steer(Vector3.ZERO, 20.0, delta)
			anim(&"idle")
			if alive_p and dist_to(p.global_position) < data.aggro_range:
				set_state(&"walk")
		&"walk":
			if not alive_p:
				set_state(&"idle")
				return
			face_toward(p.global_position)
			steer(heading * data.move_speed, 12.0, delta)
			anim(&"walk")
			if _cd <= 0.0 and state_t > 0.3 and dist_to(p.global_position) < _p("reach"):
				_dir = heading
				set_state(&"windup")
				Sfx.play("hound_growl", -6.0, 0.3)
				FX3.tele_line(global_position, global_position + _dir * (_p("reach") + 0.9), _p("windup"), Color(1.0, 0.45, 0.3, 0.9), 3.0, false)
		&"windup":
			steer(Vector3.ZERO, 30.0, delta)
			anim(&"windup")
			if randf() < delta * 16.0:
				FX3.burst(center() + Vector3(0, 0.3, 0), 1, [Color("e8ffb0"), Color("a8d860"), Color("5a7a3a")], Vector2(0.2, 0.8), Vector2(0.2, 0.4), {"gravity": -1.0})
			if state_t >= _p("windup"):
				set_state(&"lunge")
				armored = true
				_hit = false
				Sfx.play("dodge", -4.0)
		&"lunge":
			anim(&"lunge")
			velocity.x = _dir.x * _p("lunge_speed")
			velocity.z = _dir.z * _p("lunge_speed")
			if not _hit and alive_p and dist_to(p.global_position) < radius() + p.radius() + 0.45:
				_hit = true
				var d := Damage.make(data.damage, self, &"", _dir * 6.0 + Vector3(0, 3.0, 0))
				d.hit_pos = center()
				p.take_hit(d)
			if state_t >= _p("lunge_time"):
				armored = false
				set_state(&"recover")
		&"recover":
			steer(Vector3.ZERO, 22.0, delta)
			anim(&"recover")
			if state_t >= _p("recover"):
				_cd = _p("rest")
				set_state(&"walk")
		&"flinch":
			steer(Vector3.ZERO, 30.0, delta)
			anim(&"hurt")
			if state_t > 0.35:
				set_state(&"walk")


func _die() -> void:
	super._die()
	var sp := SporePatch.new()
	sp.radius = _p("spore_radius")
	sp.life = _p("spore_time")
	sp.position = (get_parent() as Node3D).to_local(global_position)
	get_parent().add_child.call_deferred(sp)


class SporePatch extends Node3D:
	## Spores hanging over the ground where a Husk fell: anyone walking in it
	## is slowed (Statuses &"slow", 40%). A ring marks its edge for its whole
	## life; it fades out after `life` seconds. A hazard, not an attack.
	const SLOW := 0.4
	const SPORE := [Color("e8ffb0", 0.8), Color("a8d860", 0.7), Color("5a7a3a", 0.6)]
	var radius := 1.6
	var life := 3.0
	var t := 0.0

	func _ready() -> void:
		FX3.tele_ring(global_position, radius, life, Color(0.66, 0.85, 0.35, 0.8))
		FX3.burst(global_position + Vector3(0, 0.3, 0), 24, SPORE, Vector2(0.4, 1.6), Vector2(0.6, 1.2), {"gravity": -0.4, "size": 2.0})
		Sfx.play("roots", -10.0, 0.4)

	func _physics_process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		if randf() < delta * 14.0:
			var a := randf() * TAU
			var rr := sqrt(randf()) * radius
			FX3.burst(global_position + Vector3(cos(a) * rr, 0.15, sin(a) * rr), 1, SPORE, Vector2(0.05, 0.3), Vector2(0.6, 1.0), {"dir": Vector3.UP, "spread": 0.4, "gravity": -0.3})
		var walkers: Array = get_tree().get_nodes_in_group(&"player") + get_tree().get_nodes_in_group(&"enemy")
		for w: Node3D in walkers:
			if not w.is_alive() or w is Spore or not ("statuses" in w):
				continue
			if SpellEffect.flat(w.global_position, global_position) < radius and absf(w.global_position.y - global_position.y) < 1.2:
				(w.statuses as Statuses).apply(&"slow", 0.2, SLOW)
