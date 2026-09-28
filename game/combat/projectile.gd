class_name Projectile
extends Area2D
## Flying spell/attack. Walls are found by ray each step (no tunnelling);
## actors by overlap. Optional homing (seek enemies), guided flight to a
## node (`homing_point`, harmless wisps) or stopping at a point (`stop_at`).
## Visuals are drawn per `style`.

signal hit_actor(actor: Node2D, pos: Vector2)
signal hit_wall(pos: Vector2)
signal expired(pos: Vector2)
signal arrived(pos: Vector2)

const GLOW := preload("res://assets/generated/glow32.png")

var velocity := Vector2.ZERO
var max_dist := 320.0
var radius := 4.0
var pierce := 0
var team := &"player"        # &"player" hits enemies, &"enemy" hits the player, &"none" nothing
var style := &"arc"
var ramp: Array = Pal.school(&"storm")
var fall_accel := 0.0
var homing := false
var homing_point: Node2D = null
var turn_rate := 6.0
var speed_cap := 0.0
var stop_at := Vector2.INF
var ignore_walls := false

var _travel := 0.0
var _hit: Array = []
var _trail: Array[Vector2] = []
var _dead := false
var _age := 0.0
var _seek: Node2D = null
var _seek_t := 0.0


func _ready() -> void:
	top_level = true
	z_index = FX.Z_FRONT
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = radius
	cs.shape = sh
	# deferred: projectiles are often spawned from inside physics callbacks
	add_child.call_deferred(cs)
	collision_layer = 0
	collision_mask = {&"player": 4, &"enemy": 2}.get(team, 0)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_age += delta
	velocity.y += fall_accel * delta
	_steer(delta)
	var from := global_position
	var to := from + velocity * delta
	if stop_at != Vector2.INF and from.distance_to(stop_at) <= velocity.length() * delta + 0.5:
		to = stop_at
	if not ignore_walls:
		var q := PhysicsRayQueryParameters2D.create(from, to, 1)
		var res := get_world_2d().direct_space_state.intersect_ray(q)
		if not res.is_empty():
			global_position = res.position
			if stop_at != Vector2.INF:
				arrived.emit(res.position)
			else:
				hit_wall.emit(res.position)
			_finish()
			return
	global_position = to
	_travel += from.distance_to(to)
	_trail.push_front(global_position)
	if _trail.size() > 9:
		_trail.pop_back()
	_trail_fx()
	if stop_at != Vector2.INF and global_position.distance_to(stop_at) < 0.6:
		arrived.emit(global_position)
		_finish()
	elif _travel >= max_dist:
		if stop_at != Vector2.INF:
			arrived.emit(global_position)
		else:
			expired.emit(global_position)
		_finish()
	queue_redraw()


func _steer(delta: float) -> void:
	var goal := Vector2.INF
	if homing_point:
		if not is_instance_valid(homing_point):
			_finish()
			return
		goal = homing_point.center()
		if global_position.distance_to(goal) < 8.0:
			_finish()
			return
	elif homing:
		_seek_t -= delta
		if _seek_t <= 0.0 or not (is_instance_valid(_seek) and _seek.is_alive()):
			_seek_t = 0.2
			_seek = SpellEffect.nearest(global_position, 300.0, _hit, self)
		if _seek and is_instance_valid(_seek):
			goal = _seek.center()
	if goal == Vector2.INF:
		return
	var want := (goal - global_position).angle()
	var ang := rotate_toward(velocity.angle(), want, turn_rate * delta)
	var sp := velocity.length()
	if speed_cap > 0.0:
		sp = move_toward(sp, speed_cap, 400.0 * delta)
	velocity = Vector2.from_angle(ang) * sp


func _on_body(body: Node) -> void:
	if _dead or _hit.has(body) or not body.has_method("take_hit"):
		return
	if body.has_method("is_alive") and not body.is_alive():
		return
	_hit.append(body)
	hit_actor.emit(body, global_position)
	if pierce <= 0:
		_finish()
	else:
		pierce -= 1


func _finish() -> void:
	_dead = true
	set_deferred("monitoring", false)
	queue_free()


func _trail_fx() -> void:
	match style:
		&"arc":
			if randf() < 0.7:
				FX.burst(global_position, 1, ramp, Vector2(10, 40), Vector2(0.12, 0.28), {"drag": 4.0})
		&"ember", &"spear", &"fireball":
			FX.burst(global_position, 2 if style == &"spear" else 1, ramp, Vector2(5, 30), Vector2(0.2, 0.45), {"gravity": -50.0, "drag": 3.0})
			if randf() < 0.3:
				FX.burst(global_position, 1, Pal.SMOKE, Vector2(2, 10), Vector2(0.4, 0.7), {"gravity": -20.0, "add": false, "front": false})
		&"needle":
			if randf() < 0.8:
				FX.burst(global_position, 1, Pal.SPECTRAL, Vector2(4, 14), Vector2(0.2, 0.4), {"drag": 2.0})
		&"spectral":
			FX.burst(global_position, 1, ramp, Vector2(5, 20), Vector2(0.25, 0.5), {"gravity": -25.0, "drag": 2.0})
		&"orb":
			if randf() < 0.5:
				FX.bolt(global_position, global_position + Vector2.from_angle(randf() * TAU) * randf_range(6, 12), 0.05, ramp, 1.5)


func _draw() -> void:
	var dir := velocity.normalized() if velocity != Vector2.ZERO else Vector2.RIGHT
	match style:
		&"arc":
			var pts := PackedVector2Array()
			for k in _trail.size():
				var lp := _trail[k] - global_position
				if k > 0 and k < _trail.size() - 1:
					lp += dir.orthogonal() * randf_range(-2.5, 2.5)
				pts.append(lp.round())
			draw_texture(GLOW, -GLOW.get_size() * 0.5, Color(ramp[2], 0.9))
			if pts.size() > 1:
				draw_polyline(pts, Color(ramp[3], 0.45), 5.0)
				draw_polyline(pts, Color(ramp[2], 0.8), 3.0)
				draw_polyline(pts, ramp[0], 1.0)
				var alt := PackedVector2Array()
				for k in pts.size():
					alt.append(pts[k] + dir.orthogonal() * randf_range(-4.0, 4.0))
				draw_polyline(alt, Color(ramp[1], 0.6), 1.0)
			draw_circle(Vector2.ZERO, 4.0, Color(ramp[2], 0.7))
			draw_rect(Rect2(-3, -1, 6, 3), ramp[0])
			draw_rect(Rect2(-1, -3, 3, 7), ramp[0])
		&"spear":
			draw_texture(GLOW, -GLOW.get_size() * 0.5, Color(ramp[2], 0.8))
			_trail_line(4.0, 2.0)
			draw_set_transform(Vector2.ZERO, dir.angle())
			draw_rect(Rect2(-12, -2, 16, 4), Color(ramp[3], 0.9))
			draw_rect(Rect2(-10, -1, 16, 2), ramp[2])
			draw_rect(Rect2(-4, -1, 10, 2), ramp[1])
			draw_rect(Rect2(3, -2, 3, 4), ramp[0])
			draw_rect(Rect2(6, -1, 2, 2), ramp[0])
			draw_set_transform(Vector2.ZERO, 0.0)
		&"ember", &"fireball":
			draw_texture(GLOW, -GLOW.get_size() * 0.5, Color(ramp[2], 0.7 if style == &"ember" else 0.9))
			_trail_line(3.0 if style == &"fireball" else 2.0, 1.0)
			var r := 3.0 if style == &"fireball" else 2.0
			draw_circle(Vector2.ZERO, r + 1.0, Color(ramp[2], 0.8))
			draw_rect(Rect2(-1, -1, 3, 3) if style == &"fireball" else Rect2(-1, -1, 2, 2), ramp[0])
		&"needle":
			draw_texture(GLOW, -GLOW.get_size() * 0.5, Color(ramp[2], 0.6))
			_trail_line(1.0, 1.0)
			draw_set_transform(Vector2.ZERO, dir.angle())
			draw_rect(Rect2(-10, 0, 14, 1), ramp[1])
			draw_rect(Rect2(-6, -1, 6, 3), Color(ramp[2], 0.8))
			draw_rect(Rect2(4, 0, 3, 1), ramp[0])
			draw_rect(Rect2(-12, -1, 2, 3), Pal.SPECTRAL[1])
			draw_set_transform(Vector2.ZERO, 0.0)
		&"spectral":
			draw_texture(GLOW, -GLOW.get_size() * 0.5, Color(ramp[2], 0.8))
			_trail_line(2.0, 1.0)
			var f := 1.0 if int(_age * 20.0) % 2 == 0 else 0.0
			draw_circle(Vector2.ZERO, 3.0 + f, Color(ramp[2], 0.8))
			draw_rect(Rect2(-1, -2, 3, 4), ramp[0])
		&"orb":
			var pulse := 1.0 + 0.5 * sin(_age * 18.0)
			draw_texture(GLOW, -GLOW.get_size() * 0.5 * 1.0, Color(ramp[2], 0.9))
			draw_circle(Vector2.ZERO, 6.0 + pulse, Color(ramp[3], 0.5))
			draw_circle(Vector2.ZERO, 4.0, Color(ramp[2], 0.9))
			draw_circle(Vector2(-1, -1), 2.0, ramp[0])
			draw_arc(Vector2.ZERO, 8.0 + pulse, _age * 6.0, _age * 6.0 + 2.0, 8, ramp[1], 1.0)
			draw_arc(Vector2.ZERO, 8.0 + pulse, _age * 6.0 + PI, _age * 6.0 + PI + 2.0, 8, ramp[1], 1.0)


func _trail_line(w_outer: float, w_inner: float) -> void:
	if _trail.size() < 2:
		return
	var pts := PackedVector2Array()
	for k in _trail.size():
		pts.append((_trail[k] - global_position).round())
	draw_polyline(pts, Color(ramp[3], 0.5), w_outer + 2.0)
	draw_polyline(pts, Color(ramp[2], 0.8), w_outer)
	draw_polyline(pts, ramp[1], w_inner)
