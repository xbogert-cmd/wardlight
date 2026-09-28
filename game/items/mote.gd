extends Area2D
## Mana mote dropped by defeated enemies. Pops out, settles, then drifts to
## the wizard inside pickup range. Expires after a while (blinks first).

var velocity := Vector2.ZERO
var amount := 6.0
var life := 9.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = FX.Z_FRONT
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 6.0
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var p := get_tree().get_first_node_in_group(&"player") as Player
	var homing := false
	if p and p.is_alive() and _t > 0.35:
		var d := p.center() - global_position
		if d.length() < p.tuning.mote_pickup_radius:
			homing = true
			velocity = velocity.move_toward(d.normalized() * 280.0, 1100.0 * delta)
	if not homing:
		velocity.y = minf(velocity.y + 420.0 * delta, 200.0)
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + velocity * delta + Vector2(0, 3), 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and velocity.y > 0.0:
			global_position.y = hit.position.y - 3.0
			velocity.y = -velocity.y * 0.35 if velocity.y > 40.0 else 0.0
	global_position += velocity * delta
	visible = life > 2.0 or int(life * 10.0) % 2 == 0
	queue_redraw()


func _on_body(b: Node) -> void:
	if b is Player and b.is_alive() and _t > 0.2:
		b.mana.gain(amount)
		Sfx.play("mote", -8.0, 0.12)
		FX.burst(global_position, 5, Pal.MANA, Vector2(20, 50), Vector2(0.15, 0.3))
		queue_free()


func _draw() -> void:
	var bob := roundf(sin(_t * 6.0) * 1.0)
	var c := Pal.MANA
	draw_circle(Vector2(0, bob), 4.0, Color(c[3], 0.35))
	draw_rect(Rect2(-1, -2 + bob, 3, 5), c[2])
	draw_rect(Rect2(-2, -1 + bob, 5, 3), c[2])
	draw_rect(Rect2(0, -1 + bob, 1, 3), c[0])
	draw_rect(Rect2(-1, 0 + bob, 3, 1), c[1])
