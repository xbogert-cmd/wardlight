class_name Steps
## Walking up small ledges (bridge decks, pad edges, kerbs) instead of
## treating them as walls. Replaces move_and_slide() for walkers.

const MAX_STEP := 0.4   # metres; anything taller stays a wall


## move_and_slide(), then if a grounded walker was stopped by a wall, try the
## same motion lifted by MAX_STEP and settle onto a walkable top.
static func move(body: CharacterBody3D) -> void:
	var want := Vector3(body.velocity.x, 0.0, body.velocity.z) * body.get_physics_process_delta_time()
	var was_floor := body.is_on_floor()
	body.move_and_slide()
	if not (was_floor and body.is_on_wall()) or want.length() < 0.001:
		return
	var t := body.global_transform
	var up := Vector3.UP * MAX_STEP
	if body.test_move(t, up):
		return
	t.origin += up
	if body.test_move(t, want):
		return   # still blocked a step higher: a real wall
	t.origin += want
	var col := KinematicCollision3D.new()
	if not body.test_move(t, Vector3.DOWN * (MAX_STEP + 0.05), col):
		return
	var land := t.origin + col.get_travel()
	if col.get_normal().y < cos(body.floor_max_angle):
		# resting on the ledge's rim: judge by the ground under the body's centre
		# instead, so hillsides stay too steep while kerbs and deck ends pass
		var q := PhysicsRayQueryParameters3D.create(land + Vector3.UP * 0.2, land + Vector3.DOWN * (MAX_STEP + 0.3), body.collision_mask, [body.get_rid()])
		var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or (hit.normal as Vector3).y < cos(body.floor_max_angle):
			return
	body.global_position = land
