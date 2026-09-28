class_name Sentinel
extends Enemy
## Hollow Sentinel — slow armoured elite. Every attack has a long, readable
## windup (its eye flares and the strike zone is marked): an overhead slam
## that sends a shockwave both ways and leaves the sword stuck in the ground
## (punish it), and a low sweep (jump or dodge). Enough hits break its poise:
## it kneels, staggered, taking 50% more damage.

var box: MeleeBox
var poise_bar: Node2D
var poise_left := 0.0
var _cd := 1.0
var _next_slam := true


func _setup() -> void:
	box = MeleeBox.make(visual, self, Vector2(56, 34), Vector2(26, -18))
	poise_left = data.poise
	armored = true
	set_state(&"idle")
	var bar := Node2D.new()
	poise_bar = bar
	bar.z_index = 6
	bar.draw.connect(func() -> void:
		if not is_alive() or poise_left >= data.poise:
			return
		var w := 24.0
		var f := poise_left / data.poise if state != &"stagger" else 0.0
		bar.draw_rect(Rect2(-w * 0.5 - 1, -data.body_size.y - 9, w + 2, 3), Color("0c0812"))
		bar.draw_rect(Rect2(-w * 0.5, -data.body_size.y - 8, roundf(w * f), 1), Color("e8e0c8") if f > 0.34 else Color("ffb040")))
	add_child(bar)


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


func block_scale(_d: Damage) -> float:
	return 1.5 if state == &"stagger" else 1.0


func take_hit(d: Damage) -> void:
	super.take_hit(d)
	if not is_alive() or state == &"stagger":
		return
	poise_left -= d.stagger
	poise_bar.queue_redraw()
	if poise_left <= 0.0:
		box.stop()
		set_state(&"stagger")
		armored = false
		Sfx.play("guard_break", 0.0)
		FX.burst(center(), 20, [Color("ffffff"), Color("d8d0e8"), Color("8a80a0")], Vector2(60, 180), Vector2(0.2, 0.5), {"gravity": 250.0})
		GameCamera.shake_all(3.0)


func _flinch() -> void:
	pass  # never flinches; poise breaks into a full stagger instead


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	match state:
		&"idle", &"walk":
			if not alive_p or global_position.distance_to(p.global_position) > data.aggro_range:
				velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
				anim(&"idle")
				return
			face_toward(p.global_position.x)
			var gap := absf(p.global_position.x - global_position.x)
			if gap > 52.0:
				velocity.x = move_toward(velocity.x, facing * data.move_speed, 200.0 * delta)
				anim(&"walk")
				if state != &"walk":
					set_state(&"walk")
			else:
				velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
				anim(&"idle")
			if _cd <= 0.0 and gap < 64.0 and absf(p.global_position.y - global_position.y) < 40.0:
				_next_slam = not _next_slam
				set_state(&"slam_windup" if _next_slam else &"sweep_windup")
				var zone := global_position + Vector2(facing * 30.0, 0)
				FX.tele_mark(zone, 56.0, _p("slam_windup") if _next_slam else _p("sweep_windup"), Color("ff5a3a") if _next_slam else Color("ffb040"))
				Sfx.play("sentinel_windup", -2.0)
		&"slam_windup", &"sweep_windup":
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			anim(state)
			var wt := _p("slam_windup") if state == &"slam_windup" else _p("sweep_windup")
			if state_t >= wt:
				if state == &"slam_windup":
					set_state(&"slam")
					box.swing(data.damage, Vector2(200, -160))
					_shockwave()
				else:
					set_state(&"sweep")
					box.swing(_p("sweep_damage"), Vector2(240, -80))
					Sfx.play("slash", 0.0)
		&"slam", &"sweep":
			anim(state)
			if state_t >= 0.15:
				box.stop()
				set_state(&"stuck" if state == &"slam" else &"recover")
		&"stuck":
			anim(&"stuck")
			if state_t >= _p("stuck"):
				_cd = _p("rest")
				set_state(&"walk")
		&"recover":
			anim(&"idle")
			if state_t >= 0.5:
				_cd = _p("rest")
				set_state(&"walk")
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			anim(&"stagger")
			if state_t >= _p("stagger_time"):
				poise_left = data.poise
				armored = true
				_cd = 0.8
				set_state(&"walk")


func _shockwave() -> void:
	var at := global_position + Vector2(facing * 34.0, 0)
	GameCamera.shake_all(5.0)
	TimeCtl.hitstop(0.05)
	Sfx.play("sentinel_slam", 0.0)
	FX.burst(at, 20, Pal.DUST, Vector2(40, 140), Vector2(0.3, 0.6), {"dir": Vector2.UP, "spread": 2.4, "gravity": 250.0, "add": false})
	FX.ring(at + Vector2(0, -2), 4.0, 60.0, 0.3, [Color("ffffff"), Color("c8c0e0"), Color("8a80a0")], 1.0, true)
	var p := player()
	if p and p.is_alive() and p.is_on_floor() and absf(p.global_position.x - at.x) < 64.0 and absf(p.global_position.y - at.y) < 20.0:
		var d := Damage.make(_p("shock_damage"), self, &"", Vector2(signf(p.global_position.x - at.x) * 160.0, -180.0))
		d.hit_pos = at
		p.take_hit(d)
