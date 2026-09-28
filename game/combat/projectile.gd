class_name Projectile
extends Node3D
## Flying spell/attack. Terrain and walls are found by ray each step (no
## tunnelling); actors by flat distance to their body (with a height band).
## Optional homing (seek enemies), guided flight to a node (`homing_point`,
## harmless wisps) or stopping at a point (`stop_at`). Visuals per `style`:
## pixel particles, a glow billboard, 1-pixel lines and a small real light.

signal hit_actor(actor: Node3D, pos: Vector3)
signal hit_wall(pos: Vector3)
signal expired(pos: Vector3)
signal arrived(pos: Vector3)

const PX := 1.0 / 24.0
const NO_STOP := Vector3(INF, INF, INF)

var velocity := Vector3.ZERO
var max_dist := 13.0
var radius := 0.25
var pierce := 0
var team := &"player"        # &"player" hits enemies, &"enemy" hits the player, &"none" nothing
var style := &"arc"
var ramp: Array = Pal.school(&"storm")
var fall_accel := 0.0
var homing := false
var homing_point: Node3D = null
var turn_rate := 6.0
var speed_cap := 0.0
var stop_at := NO_STOP
var ignore_walls := false
var lit := true

var _travel := 0.0
var _hit: Array = []
var _trail: Array[Vector3] = []
var _dead := false
var _age := 0.0
var _seek: Node3D = null
var _seek_t := 0.0
var _glow: MeshInstance3D
var _lamp: OmniLight3D


func _ready() -> void:
	top_level = true
	_build.call_deferred()


## Visuals are built a moment later so spawners can still set style/ramp/lit.
func _build() -> void:
	var tex: Texture2D = FX3.GLOW_L if style == &"orb" else FX3.GLOW_M
	var mat := ShaderMaterial.new()
	mat.shader = FX3.DECAL_SHADER
	mat.set_shader_parameter(&"tex", tex)
	mat.set_shader_parameter(&"billboard", true)
	mat.set_shader_parameter(&"color", Color(ramp[2], 0.9))
	_glow = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tex.get_width(), tex.get_height()) * PX * (0.7 if style in [&"needle", &"ember"] else 1.0)
	_glow.mesh = q
	_glow.material_override = mat
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)
	if lit:
		_lamp = OmniLight3D.new()
		_lamp.light_color = ramp[1]
		_lamp.light_energy = 1.6 if style in [&"arc", &"spear", &"orb", &"fireball"] else 0.8
		_lamp.omni_range = 3.5
		add_child(_lamp)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_age += delta
	velocity.y -= fall_accel * delta
	_steer(delta)
	var from := global_position
	var to := from + velocity * delta
	var stopping := stop_at != NO_STOP
	if stopping and from.distance_to(stop_at) <= velocity.length() * delta + 0.02:
		to = stop_at
	if not ignore_walls:
		var q := PhysicsRayQueryParameters3D.create(from, to, 1)
		var res := get_world_3d().direct_space_state.intersect_ray(q)
		if not res.is_empty():
			global_position = res.position
			if stopping:
				arrived.emit(global_position)
			else:
				hit_wall.emit(global_position)
			_finish()
			return
	if team != &"none" and _check_actors(from, to):
		return
	global_position = to
	_travel += from.distance_to(to)
	_trail.push_front(global_position)
	if _trail.size() > 8:
		_trail.pop_back()
	_trail_fx()
	if stopping and global_position.distance_to(stop_at) < 0.03:
		arrived.emit(global_position)
		_finish()
	elif _travel >= max_dist:
		if stopping:
			arrived.emit(global_position)
		else:
			expired.emit(global_position)
		_finish()


func _targets() -> Array:
	if team == &"enemy":
		return (Engine.get_main_loop() as SceneTree).get_nodes_in_group(&"player")
	return SpellEffect.enemies()


func _check_actors(from: Vector3, to: Vector3) -> bool:
	var a2 := Vector2(from.x, from.z)
	var b2 := Vector2(to.x, to.z)
	for e: Node3D in _targets():
		if _hit.has(e) or not e.is_alive():
			continue
		var p := Vector2(e.global_position.x, e.global_position.z)
		var cp := Geometry2D.get_closest_point_to_segment(p, a2, b2)
		if cp.distance_to(p) > radius + e.radius():
			continue
		var y := lerpf(from.y, to.y, clampf(a2.distance_to(cp) / maxf(a2.distance_to(b2), 0.001), 0.0, 1.0))
		if y < e.global_position.y - 0.4 or y > e.global_position.y + e.height() + 0.9:
			continue
		var at := Vector3(cp.x, y, cp.y)
		_hit.append(e)
		global_position = at
		hit_actor.emit(e, at)
		if pierce <= 0:
			_finish()
			return true
		pierce -= 1
	return false


func _steer(delta: float) -> void:
	var goal := NO_STOP
	if homing_point:
		if not is_instance_valid(homing_point):
			_finish()
			return
		goal = homing_point.center()
		if global_position.distance_to(goal) < 0.35:
			_finish()
			return
	elif homing:
		_seek_t -= delta
		if _seek_t <= 0.0 or not (is_instance_valid(_seek) and _seek.is_alive()):
			_seek_t = 0.2
			_seek = SpellEffect.nearest(global_position, 12.0, _hit, self)
		if _seek and is_instance_valid(_seek):
			goal = _seek.center()
	if goal == NO_STOP:
		return
	var want := (goal - global_position).normalized()
	var cur := velocity.normalized()
	var ang := cur.angle_to(want)
	var sp := velocity.length()
	if speed_cap > 0.0:
		sp = move_toward(sp, speed_cap, 16.0 * delta)
	if ang > 0.001:
		var axis := cur.cross(want)
		if axis.length() < 0.001:
			axis = Vector3.UP
		cur = cur.rotated(axis.normalized(), minf(ang, turn_rate * delta))
	velocity = cur * sp


func _finish() -> void:
	_dead = true
	queue_free()


func _trail_fx() -> void:
	var p := global_position
	var dir := velocity.normalized() if velocity.length() > 0.01 else Vector3.RIGHT
	match style:
		&"arc":
			if _trail.size() > 1:
				FX3.bolt(_trail[0], _trail[_trail.size() - 1], 0.04, ramp, 0.1)
			FX3.burst(p, 2, ramp, Vector2(0.3, 1.5), Vector2(0.12, 0.3), {"drag": 4.0})
		&"spear":
			var tail := p - dir * 0.7
			FX3.seg(tail, p + dir * 0.15, ramp[1])
			FX3.seg(tail + Vector3(0, PX, 0), p + Vector3(0, PX, 0), ramp[2])
			FX3.seg(tail - Vector3(0, PX, 0), p - dir * 0.2 - Vector3(0, PX, 0), ramp[3])
			FX3.burst(p, 2, ramp, Vector2(0.2, 1.2), Vector2(0.2, 0.45), {"gravity": -2.0, "drag": 3.0})
			if randf() < 0.3:
				FX3.burst(p, 1, Pal.SMOKE, Vector2(0.05, 0.4), Vector2(0.4, 0.7), {"gravity": -0.8})
		&"ember", &"fireball":
			FX3.burst(p, 1 if style == &"ember" else 2, ramp, Vector2(0.2, 1.2), Vector2(0.2, 0.45), {"gravity": -2.0, "drag": 3.0, "size": 1.0 if style == &"ember" else 2.0})
			if _trail.size() > 2:
				FX3.seg(_trail[2], p, ramp[2])
		&"needle":
			FX3.seg(p - dir * 0.55, p + dir * 0.1, ramp[0])
			FX3.seg(p - dir * 0.3 + Vector3(0, PX, 0), p + Vector3(0, PX, 0), Pal.SPECTRAL[1])
			if randf() < 0.8:
				FX3.burst(p, 1, Pal.SPECTRAL, Vector2(0.15, 0.6), Vector2(0.2, 0.4), {"drag": 2.0})
		&"spectral":
			FX3.burst(p, 1, ramp, Vector2(0.2, 0.8), Vector2(0.25, 0.5), {"gravity": -1.0, "drag": 2.0, "size": 2.0 if int(_age * 20.0) % 2 == 0 else 1.0})
			if _trail.size() > 3:
				FX3.seg(_trail[3], p, ramp[2])
		&"orb":
			if randf() < 0.5:
				FX3.bolt(p, p + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0.25, 0.5), 0.05, ramp, 0.06)
			FX3.burst(p, 1, ramp, Vector2(0.2, 0.8), Vector2(0.15, 0.3), {"drag": 3.0})
