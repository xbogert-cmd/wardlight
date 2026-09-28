extends Node3D
## Mana mote dropped by defeated enemies. Pops out, bounces to rest, then
## drifts to the wizard inside pickup range. Expires after a while (blinks first).

var velocity := Vector3.ZERO
var amount := 6.0
var life := 9.0
var _t := 0.0
var _glow: MeshInstance3D


func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = FX3.DECAL_SHADER
	mat.set_shader_parameter(&"tex", FX3.GLOW_S)
	mat.set_shader_parameter(&"billboard", true)
	mat.set_shader_parameter(&"color", Color(Pal.MANA[1], 1.0))
	_glow = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(16, 16) * FX3.PX
	_glow.mesh = q
	_glow.material_override = mat
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)


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
			velocity = velocity.move_toward(d.normalized() * 11.0, 45.0 * delta)
		if d.length() < 0.45:
			p.mana.gain(amount)
			Sfx.play("mote", -8.0, 0.12)
			FX3.burst(global_position, 5, Pal.MANA, Vector2(0.8, 2.0), Vector2(0.15, 0.3))
			queue_free()
			return
	if not homing:
		velocity.y -= 17.0 * delta
		velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
		var q := PhysicsRayQueryParameters3D.create(global_position, global_position + velocity * delta + Vector3(0, -0.15, 0), 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and velocity.y < 0.0:
			global_position.y = hit.position.y + 0.15
			velocity.y = -velocity.y * 0.35 if velocity.y < -1.6 else 0.0
	global_position += velocity * delta
	_glow.position.y = 0.25 + roundf(sin(_t * 6.0)) * FX3.PX
	visible = life > 2.0 or int(life * 10.0) % 2 == 0
	if randf() < delta * 6.0:
		FX3.burst(global_position + _glow.position, 1, Pal.MANA, Vector2(0.1, 0.4), Vector2(0.3, 0.5), {"gravity": -0.8})
