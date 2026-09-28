class_name Aim
extends Node
## Chooses where spells go. Assisted (default): an enemy near the cursor on
## screen, else toward the cursor's spot on the ground. With the mouse idle
## (keyboard play) it uses the nearest visible enemy in the direction the
## wizard is moving/looking, else straight that way. Direct: always the
## cursor. Never targets through walls.

const ASSIST_PX := 26.0          # screen pixels from the cursor to an enemy's body
const FACING_RANGE := 10.5
const FACING_CONE := deg_to_rad(55.0)
const MAX_RANGE := 15.0
const MOUSE_IDLE := 4.0

var player: Node3D
var target: Node3D = null
var cursor := Vector3.ZERO       # ground point under the mouse
var mouse_active := false
var _last_move := -100.0
var override: Variant = null     # demo driver: fixed world cursor
var override_enemy := false      # demo driver: cursor follows nearest enemy


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion or e is InputEventMouseButton:
		_last_move = Time.get_ticks_msec() / 1000.0


func camera() -> Camera3D:
	return player.get_viewport().get_camera_3d()


func update_aim(origin: Vector3) -> void:
	mouse_active = Time.get_ticks_msec() / 1000.0 - _last_move < MOUSE_IDLE
	var cam := camera()
	if cam:
		var mp := player.get_viewport().get_mouse_position()
		var from := cam.project_ray_origin(mp)
		var dir := cam.project_ray_normal(mp)
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 300.0, 1)
		var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			cursor = hit.position
		elif absf(dir.y) > 0.001:
			cursor = from + dir * ((player.global_position.y - from.y) / dir.y)
	if override_enemy:
		var e := SpellEffect.nearest(origin, 25.0, [], player)
		override = e.global_position if e else null
	if override != null:
		cursor = override
		mouse_active = true
	target = _choose(origin)


func _valid(e: Node3D, origin: Vector3) -> bool:
	return is_instance_valid(e) and e.is_alive() and SpellEffect.flat(origin, e.center()) < MAX_RANGE \
		and SpellEffect.has_los(origin, e.center(), player)


## Screen distance from the mouse to the enemy's body (0 when over it).
func _screen_gap(e: Node3D) -> float:
	var cam := camera()
	if cam == null or override != null:
		return SpellEffect.flat(cursor, e.global_position) * 12.0
	var mp := player.get_viewport().get_mouse_position()
	var base := cam.unproject_position(e.global_position)
	var top := cam.unproject_position(e.global_position + Vector3(0, e.height(), 0))
	var half_w: float = e.radius() * 26.0
	var rect := Rect2(Vector2(base.x - half_w, top.y), Vector2(half_w * 2.0, base.y - top.y))
	var cx := clampf(mp.x, rect.position.x, rect.end.x)
	var cy := clampf(mp.y, rect.position.y, rect.end.y)
	return Vector2(cx, cy).distance_to(mp)


func _choose(origin: Vector3) -> Node3D:
	if Settings.aim_mode == "direct":
		return null
	if mouse_active:
		# sticky: keep the current target while the cursor stays roughly on it
		if target and _valid(target, origin) and _screen_gap(target) < ASSIST_PX * 1.6:
			return target
		var best: Node3D = null
		var bd := ASSIST_PX
		for e: Node3D in SpellEffect.enemies():
			var d := _screen_gap(e)
			if d < bd and _valid(e, origin):
				bd = d
				best = e
		return best
	var look: Vector3 = player.look_dir
	if target and _valid(target, origin) and SpellEffect.flat_dir(target.center() - origin).angle_to(look) < FACING_CONE * 1.4:
		return target
	var best2: Node3D = null
	var bd2 := FACING_RANGE
	for e: Node3D in SpellEffect.enemies():
		var v: Vector3 = e.center() - origin
		if SpellEffect.flat_dir(v).angle_to(look) > FACING_CONE:
			continue
		var d := SpellEffect.flat(origin, e.center())
		if d < bd2 and _valid(e, origin):
			bd2 = d
			best2 = e
	return best2


## Horizontal aim direction from `origin`.
func dir_from(origin: Vector3) -> Vector3:
	if target and is_instance_valid(target):
		return SpellEffect.flat_dir(target.center() - origin, player.look_dir)
	if Settings.aim_mode == "direct" or mouse_active:
		return SpellEffect.flat_dir(cursor - origin, player.look_dir) if SpellEffect.flat(cursor, origin) > 0.2 else player.look_dir
	return player.look_dir
