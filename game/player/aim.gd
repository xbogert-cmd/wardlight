class_name Aim
extends Node2D
## Chooses where spells go. Assisted (default): an enemy near the cursor,
## else toward the cursor. With the mouse idle (keyboard play) it uses the
## nearest visible enemy in the facing direction, else straight ahead
## (W/S tilt). Direct: always the cursor. Never targets through walls.

const ASSIST_RADIUS := 56.0
const FACING_RANGE := 250.0
const MAX_RANGE := 360.0
const MOUSE_IDLE := 4.0

var player: Node2D
var target: Node2D = null
var cursor := Vector2.ZERO
var mouse_active := false
var _last_move := -100.0
var override: Variant = null     # demo driver: fixed world cursor
var override_enemy := false      # demo driver: cursor follows nearest enemy
var _pulse := 0.0


func _ready() -> void:
	top_level = true
	z_index = 25


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion or e is InputEventMouseButton:
		_last_move = Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func update_aim(origin: Vector2) -> void:
	cursor = get_global_mouse_position()
	mouse_active = Time.get_ticks_msec() / 1000.0 - _last_move < MOUSE_IDLE
	if override_enemy:
		var e := SpellEffect.nearest(origin, 600.0, [], player)
		override = e.center() if e else null
	if override != null:
		cursor = override
		mouse_active = true
	target = _choose(origin)


func _valid(e: Node2D, origin: Vector2) -> bool:
	return is_instance_valid(e) and e.is_alive() and origin.distance_to(e.center()) < MAX_RANGE \
		and SpellEffect.has_los(origin, e.center(), player)


func _choose(origin: Vector2) -> Node2D:
	if Settings.aim_mode == "direct":
		return null
	if mouse_active:
		# sticky: keep the current target while the cursor stays roughly on it
		if target and _valid(target, origin) and target.center().distance_to(cursor) < ASSIST_RADIUS * 1.5:
			return target
		var best: Node2D = null
		var bd := ASSIST_RADIUS
		for e: Node2D in SpellEffect.enemies():
			var d: float = e.center().distance_to(cursor)
			if d < bd and _valid(e, origin):
				bd = d
				best = e
		return best
	var facing: int = player.facing
	if target and _valid(target, origin) and signf(target.center().x - origin.x) == facing:
		return target
	var best2: Node2D = null
	var bd2 := FACING_RANGE
	for e: Node2D in SpellEffect.enemies():
		var dx: float = e.center().x - origin.x
		if signf(dx) != facing or absf(e.center().y - origin.y) > 90.0:
			continue
		var d: float = origin.distance_to(e.center())
		if d < bd2 and _valid(e, origin):
			bd2 = d
			best2 = e
	return best2


func dir_from(origin: Vector2) -> Vector2:
	if target and is_instance_valid(target):
		return (target.center() - origin).normalized()
	if Settings.aim_mode == "direct" or mouse_active:
		var d := cursor - origin
		return d.normalized() if d.length() > 4.0 else Vector2(player.facing, 0)
	var v := Vector2(player.facing, 0)
	if Input.is_action_pressed(&"up"):
		v.y = -0.6
	elif Input.is_action_pressed(&"down"):
		v.y = 0.6
	return v.normalized()


func _draw() -> void:
	if target == null or not is_instance_valid(target):
		return
	var r: Rect2 = target.hurt_rect()
	var pad := 2.0 + (1.0 if fmod(_pulse, 0.6) < 0.3 else 0.0)
	r = r.grow(pad)
	var c := Color("a8f0ff")
	var k := 3.0
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var sx := 1.0 if corner.x == r.position.x else -1.0
		var sy := 1.0 if corner.y == r.position.y else -1.0
		var p := corner.round()
		draw_line(p, p + Vector2(k * sx, 0), c, 1.0)
		draw_line(p, p + Vector2(0, k * sy), c, 1.0)
