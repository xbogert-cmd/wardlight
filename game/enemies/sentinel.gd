class_name Sentinel
extends Enemy
## Hollow Sentinel — slow armoured elite. Every attack has a long, readable
## windup (its eye flares and the strike zone is marked): an overhead slam
## whose shockwave ring rolls outward (dodge through it) and leaves the sword
## stuck in the ground (punish it), and a wide low sweep. Enough hits break
## its poise: it kneels, staggered, taking 50% more damage.

const WAVE_SPEED := 6.5
const WAVE_MAX := 4.2
const ECHO_DELAY := 0.4
var box: MeleeBox
var poise_left := 0.0
var _cd := 1.0
var _next_slam := true
var _wave_at := Vector3.ZERO
var _wave_r := -1.0
var _wave_max := WAVE_MAX
var _echoed := false        # hollowed: the second, wider wave has gone out
var _wave_hit := false


func _setup() -> void:
	box = MeleeBox.make(self, 2.3, 75.0)
	poise_left = data.poise
	armored = true
	set_state(&"idle")


func _p(k: String) -> float:
	return data.params.get(k, 0.0)


## 0..1 for the HUD's poise bar (1 = full; hidden while full).
func poise_ratio() -> float:
	return 0.0 if state == &"stagger" else poise_left / data.poise


func block_scale(_d: Damage) -> float:
	return 1.5 if state == &"stagger" else 1.0


func take_hit(d: Damage) -> void:
	super.take_hit(d)
	if not is_alive() or state == &"stagger":
		return
	poise_left -= d.stagger
	if poise_left <= 0.0:
		box.stop()
		set_state(&"stagger")
		armored = false
		Sfx.play("guard_break", 0.0)
		FX3.burst(center(), 20, [Color("ffffff"), Color("d8d0e8"), Color("8a80a0")], Vector2(2.5, 7.5), Vector2(0.2, 0.5), {"gravity": 10.0})
		GameCamera3D.shake_all(3.0)


func _flinch() -> void:
	pass  # never flinches; poise breaks into a full stagger instead


func _ai(delta: float) -> void:
	var p := player()
	_cd -= delta
	var alive_p := p != null and p.is_alive()
	_update_wave(delta, p)
	match state:
		&"idle", &"walk":
			if not alive_p or dist_to(p.global_position) > data.aggro_range:
				steer(Vector3.ZERO, 12.0, delta)
				anim(&"idle")
				return
			face_toward(p.global_position)
			var gap := dist_to(p.global_position)
			if gap > 2.0:
				steer(heading * data.move_speed, 8.0, delta)
				anim(&"walk")
				if state != &"walk":
					set_state(&"walk")
			else:
				steer(Vector3.ZERO, 16.0, delta)
				anim(&"idle")
			if _cd <= 0.0 and gap < 2.8:
				_next_slam = not _next_slam
				var wt := _p("slam_windup") if _next_slam else _p("sweep_windup")
				set_state(&"slam_windup" if _next_slam else &"sweep_windup")
				if _next_slam:
					FX3.tele_ring(_slam_point(), 1.2, wt, Color(1.0, 0.35, 0.23, 0.9))
				else:
					FX3.arc(global_position + Vector3(0, 0.05, 0), 2.3, 2.3, heading, deg_to_rad(150.0), wt, [Color(1.0, 0.69, 0.25, 0.9)], 3.0)
				FX3.flash(global_position + Vector3(0, height() * 0.85, 0) + heading * 0.2, 0.25, wt * 0.6, Color(1.0, 0.5, 0.3), 1.0)
				Sfx.play("sentinel_windup", -2.0)
		&"slam_windup", &"sweep_windup":
			steer(Vector3.ZERO, 16.0, delta)
			anim(state)
			var wt := _p("slam_windup") if state == &"slam_windup" else _p("sweep_windup")
			if state_t >= wt:
				if state == &"slam_windup":
					set_state(&"slam")
					_slam(p)
				else:
					set_state(&"sweep")
					box.swing(_p("sweep_damage"), 10.0, 2.0)
					FX3.arc(global_position + Vector3(0, 0.4, 0), 0.6, 2.4, heading, deg_to_rad(150.0), 0.18, [Color("ffffff"), Color("e0d8c8"), Color("a09888")], 3.0)
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
			steer(Vector3.ZERO, 16.0, delta)
			anim(&"stagger")
			if state_t >= _p("stagger_time"):
				poise_left = data.poise
				armored = true
				_cd = 0.8
				set_state(&"walk")


func _slam_point() -> Vector3:
	return global_position + heading * 1.4


func _slam(p: Player) -> void:
	var at := _slam_point()
	GameCamera3D.shake_all(5.0)
	TimeCtl.hitstop(0.05)
	Sfx.play("sentinel_slam", 0.0)
	FX3.burst(at + Vector3(0, 0.1, 0), 22, Pal.DUST, Vector2(1.6, 5.8), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 2.4, "gravity": 10.0})
	FX3.light(at + Vector3(0, 0.5, 0), Color(0.9, 0.85, 1.0), 3.0, 6.0, 0.25)
	# direct hit under the blade
	if p and p.is_alive() and SpellEffect.flat(p.global_position, at) < 1.2 + p.radius():
		var d := Damage.make(data.damage, self, &"", SpellEffect.push(at, p.global_position, 8.0, 5.0))
		d.hit_pos = at
		p.take_hit(d)
	_wave_at = at
	_wave_r = 0.3
	_wave_max = WAVE_MAX
	_echoed = false
	_wave_hit = false
	FX3.ring(at + Vector3(0, 0.06, 0), 0.3, WAVE_MAX, WAVE_MAX / WAVE_SPEED, [Color("ffffff"), Color("c8c0e0"), Color("8a80a0")], 3.0)


## The shockwave hits once, when its edge passes the wizard.
func _update_wave(delta: float, p: Player) -> void:
	if _wave_r < 0.0:
		return
	var prev := _wave_r
	_wave_r += WAVE_SPEED * delta
	if not _wave_hit and p and p.is_alive():
		var d := SpellEffect.flat(p.global_position, _wave_at)
		if d >= prev - 0.3 and d <= _wave_r + 0.3 and absf(p.global_position.y - _wave_at.y) < 1.0:
			_wave_hit = true
			var dmg := Damage.make(_p("shock_damage"), self, &"", SpellEffect.push(_wave_at, p.global_position, 6.5, 5.0))
			dmg.hit_pos = _wave_at
			p.take_hit(dmg)
	if randf() < 0.6:
		var a := randf() * TAU
		FX3.burst(_wave_at + Vector3(cos(a), 0.05, sin(a)) * _wave_r, 2, Pal.DUST, Vector2(0.5, 1.5), Vector2(0.2, 0.35), {"dir": Vector3.UP, "spread": 1.0, "gravity": 6.0})
	if _wave_r >= _wave_max:
		_wave_r = -1.0
		if hollowed and not _echoed:
			_echoed = true
			# the tell: the slam point flares, then a wider wave rolls out
			FX3.flash(_wave_at + Vector3(0, 0.3, 0), 0.6, ECHO_DELAY, Color(1.0, 0.5, 0.3), 2.0)
			SpellEffect.later(ECHO_DELAY, func() -> void:
				if is_alive():
					_wave_r = 0.3
					_wave_max = WAVE_MAX * 1.5
					_wave_hit = false
					Sfx.play("sentinel_slam", -6.0, 0.2)
					FX3.ring(_wave_at + Vector3(0, 0.06, 0), 0.3, _wave_max, _wave_max / WAVE_SPEED, [Color("ffd0b0"), Color("e0a080"), Color("a06050")], 3.0))
