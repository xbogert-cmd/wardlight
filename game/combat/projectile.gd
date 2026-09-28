class_name Projectile
extends Area2D
## Straight-flying projectile. Walls are found by ray each step (no tunnelling);
## actors by overlap. Visuals come from `style`, drawn in _draw and FX.

signal hit_actor(actor: Node2D, pos: Vector2)
signal hit_wall(pos: Vector2)
signal expired(pos: Vector2)

var velocity := Vector2.ZERO
var max_dist := 320.0
var radius := 4.0
var pierce := 0
var team := &"player"
var damage: Damage
var style := &"arc"
var ramp: Array = Pal.school(&"storm")
var fall_accel := 0.0

var _travel := 0.0
var _hit: Array = []
var _trail: Array[Vector2] = []
var _dead := false
var _age := 0.0
const GLOW := preload("res://assets/generated/glow32.png")


func _ready() -> void:
	top_level = true
	z_index = FX.Z_FRONT
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = radius
	cs.shape = sh
	add_child(cs)
	collision_layer = 0
	collision_mask = 4 if team == &"player" else 2
	monitorable = false
	body_entered.connect(_on_body)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_age += delta
	velocity.y += fall_accel * delta
	var from := global_position
	var to := from + velocity * delta
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	var res := get_world_2d().direct_space_state.intersect_ray(q)
	if not res.is_empty():
		global_position = res.position
		if OS.has_feature("debug") and OS.get_cmdline_user_args().has("--trace"):
			print("proj wall hit at ", res.position, " collider=", res.collider, " from=", from, " vel=", velocity)
		hit_wall.emit(res.position)
		_finish()
		return
	global_position = to
	_travel += velocity.length() * delta
	_trail.push_front(global_position)
	if _trail.size() > 9:
		_trail.pop_back()
	_trail_fx()
	if _travel >= max_dist:
		if OS.get_cmdline_user_args().has("--trace"):
			print("proj expired at ", global_position)
		expired.emit(global_position)
		_finish()
	queue_redraw()


func _on_body(body: Node) -> void:
	if _dead or _hit.has(body) or not body.has_method("take_hit"):
		return
	if body.has_method("is_alive") and not body.is_alive():
		return
	_hit.append(body)
	var pos := global_position
	hit_actor.emit(body, pos)
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
				FX.burst(global_position, 1, ramp, Vector2(10, 40), Vector2(0.12, 0.28), {"size": 1, "drag": 4.0})
		&"ember":
			FX.burst(global_position, 1, ramp, Vector2(5, 25), Vector2(0.2, 0.4), {"gravity": -40.0, "drag": 3.0})
		&"hex":
			if randf() < 0.6:
				FX.burst(global_position, 1, ramp, Vector2(4, 16), Vector2(0.25, 0.45), {"drag": 2.0})


func _draw() -> void:
	var dir := velocity.normalized()
	match style:
		&"arc":
			# jagged lightning trail through recent positions + hot core
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
				# second, fainter strand crackling around the first
				var alt := PackedVector2Array()
				for k in pts.size():
					alt.append(pts[k] + dir.orthogonal() * randf_range(-4.0, 4.0))
				draw_polyline(alt, Color(ramp[1], 0.6), 1.0)
			draw_circle(Vector2.ZERO, 4.0, Color(ramp[2], 0.7))
			draw_rect(Rect2(-3, -1, 6, 3), ramp[0])
			draw_rect(Rect2(-1, -3, 3, 7), ramp[0])
		&"ember", &"hex":
			draw_texture(GLOW, -GLOW.get_size() * 0.5, Color(ramp[2], 0.8))
			for k in _trail.size():
				var lp := (_trail[k] - global_position).round()
				var c: Color = ramp[mini(k / 2 + 1, ramp.size() - 1)]
				draw_rect(Rect2(lp.x - 1, lp.y - 1, 3 - k / 3, 3 - k / 3), c)
			draw_circle(Vector2.ZERO, 3.0, Color(ramp[1], 0.7))
			draw_rect(Rect2(-1, -1, 3, 3), ramp[0])
