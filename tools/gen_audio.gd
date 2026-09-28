extends SceneTree
## Synthesises all sound effects and music loops into res://assets/audio/.
## godot --headless --path . --script tools/gen_audio.gd [-- sfx|music|<name>]

const S = preload("res://tools/audio/synth.gd")
const SFX := "res://assets/audio/sfx/"
const MUS := "res://assets/audio/music/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SFX)
	DirAccess.make_dir_recursive_absolute(MUS)
	seed(1234)
	var only := OS.get_cmdline_user_args()
	var t0 := Time.get_ticks_msec()
	for m in get_method_list():
		var n: String = m.name
		if n.begins_with("sfx_") and (only.is_empty() or only.has("sfx") or only.has(n.trim_prefix("sfx_"))):
			var b: PackedFloat32Array = call(n)
			S.save(b, SFX + n.trim_prefix("sfx_") + ".wav")
		elif n.begins_with("mus_") and (only.is_empty() or only.has("music") or only.has(n.trim_prefix("mus_"))):
			var b2: PackedFloat32Array = call(n)
			S.save(b2, MUS + n.trim_prefix("mus_") + ".wav")
	print("audio generated in %d ms" % (Time.get_ticks_msec() - t0))
	quit()


static func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


static func fin(b: PackedFloat32Array, peak: float = 0.85, verb: float = 0.0) -> PackedFloat32Array:
	if verb > 0.0:
		S.reverb(b, verb, 0.7)
	S.normalize(b, peak)
	return b


# ---------------------------------------------------------------- movement
func sfx_step() -> PackedFloat32Array:
	var b := S.buf(0.09)
	S.noise(b, 0, 0.09, 0.8, 900, 200, 0.001, 0.025)
	S.tone(b, 0, 0.06, 110, 70, "sine", 0.5, 0.001, 0.02)
	return fin(b, 0.6)


func sfx_jump() -> PackedFloat32Array:
	var b := S.buf(0.2)
	S.noise(b, 0, 0.2, 0.7, 700, 2600, 0.01, 0.07, 300)
	S.tone(b, 0, 0.08, 120, 90, "sine", 0.3, 0.001, 0.03)
	return fin(b, 0.6)


func sfx_land() -> PackedFloat32Array:
	var b := S.buf(0.14)
	S.noise(b, 0, 0.14, 0.9, 700, 150, 0.001, 0.04)
	S.tone(b, 0, 0.1, 90, 55, "sine", 0.7, 0.001, 0.04)
	return fin(b, 0.7)


func sfx_dodge() -> PackedFloat32Array:
	var b := S.buf(0.26)
	S.noise(b, 0, 0.26, 1.0, 3200, 500, 0.02, 0.09, 250)
	S.noise(b, 0.02, 0.1, 0.4, 1800, 900, 0.001, 0.03, 600)  # cloth flap
	return fin(b, 0.7)


func sfx_perfect_dodge() -> PackedFloat32Array:
	var b := S.buf(0.6)
	S.noise(b, 0, 0.2, 0.5, 3000, 800, 0.01, 0.07, 300)
	for k in 3:
		S.tone(b, 0.03 + k * 0.05, 0.45, hz(84 + k * 4), hz(84 + k * 4), "sine", 0.3, 0.002, 0.18)
		S.tone(b, 0.03 + k * 0.05, 0.3, hz(96 + k * 4), hz(96 + k * 4), "sine", 0.1, 0.002, 0.1)
	return fin(b, 0.7, 0.3)


# ---------------------------------------------------------------- storm
func sfx_storm_gather() -> PackedFloat32Array:
	var b := S.buf(0.3)
	S.noise(b, 0, 0.3, 0.5, 900, 6000, 0.15, 0.0, 500, 0.03)
	S.crackle(b, 0.02, 0.26, 70, 0.35)
	S.tone(b, 0, 0.3, 220, 880, "saw", 0.08, 0.2, 0.0, 0.03)
	return fin(b, 0.6)


func sfx_storm_release() -> PackedFloat32Array:
	var b := S.buf(0.45)
	S.noise(b, 0, 0.08, 1.0, 9000, 3000, 0.0005, 0.02, 1200)       # crack
	S.tone(b, 0, 0.22, 2400, 180, "saw", 0.35, 0.001, 0.06)          # zap sweep
	S.tone(b, 0, 0.22, 2350, 175, "square", 0.15, 0.001, 0.05)
	S.tone(b, 0, 0.3, 90, 45, "sine", 0.6, 0.001, 0.08)             # body thump
	S.crackle(b, 0.03, 0.3, 90, 0.3)
	return fin(b, 0.85, 0.2)


func sfx_storm_impact() -> PackedFloat32Array:
	var b := S.buf(0.6)
	S.noise(b, 0, 0.05, 1.0, 10000, 5000, 0.0003, 0.012, 800)
	S.noise(b, 0.01, 0.45, 0.6, 6000, 1500, 0.001, 0.12, 900)       # sizzle
	S.crackle(b, 0.02, 0.4, 120, 0.4)
	S.tone(b, 0, 0.35, 70, 38, "sine", 0.9, 0.001, 0.12)            # boom
	return fin(b, 0.9, 0.25)


func sfx_storm_fizzle() -> PackedFloat32Array:
	var b := S.buf(0.3)
	S.noise(b, 0, 0.3, 0.6, 5000, 1200, 0.001, 0.08, 800)
	S.crackle(b, 0.0, 0.25, 60, 0.3)
	return fin(b, 0.6)


func sfx_storm_gust() -> PackedFloat32Array:
	var b := S.buf(0.28)
	S.noise(b, 0, 0.28, 1.0, 1200, 4500, 0.01, 0.08, 400)
	S.crackle(b, 0.0, 0.18, 90, 0.35)
	S.tone(b, 0, 0.12, 1600, 600, "saw", 0.12, 0.001, 0.03)
	return fin(b, 0.7)


func sfx_storm_zap() -> PackedFloat32Array:
	var b := S.buf(0.14)
	S.noise(b, 0, 0.14, 0.8, 8000, 2500, 0.0005, 0.03, 1500)
	S.tone(b, 0, 0.08, 900, 300, "square", 0.25, 0.001, 0.02)
	return fin(b, 0.7)


# ---------------------------------------------------------------- hits
func sfx_hit_flesh() -> PackedFloat32Array:
	var b := S.buf(0.18)
	S.noise(b, 0, 0.18, 1.0, 2500, 300, 0.0005, 0.035)
	S.tone(b, 0, 0.12, 180, 70, "sine", 0.8, 0.001, 0.04)
	return fin(b, 0.8)


func sfx_hurt() -> PackedFloat32Array:
	var b := S.buf(0.35)
	S.noise(b, 0, 0.12, 1.0, 3000, 400, 0.0005, 0.04)
	S.tone(b, 0, 0.25, 260, 150, "square", 0.25, 0.005, 0.1, 0.05)
	S.tone(b, 0, 0.2, 120, 60, "sine", 0.7, 0.001, 0.06)
	return fin(b, 0.85)


func sfx_player_death() -> PackedFloat32Array:
	var b := S.buf(1.6)
	S.tone(b, 0, 1.4, 330, 82, "tri", 0.4, 0.01, 0.6, 0.3, 0.01)
	S.tone(b, 0, 1.4, 165, 41, "sine", 0.4, 0.01, 0.7, 0.3)
	S.noise(b, 0, 1.2, 0.3, 800, 120, 0.3, 0.5)
	return fin(b, 0.8, 0.4)


func sfx_enemy_die() -> PackedFloat32Array:
	var b := S.buf(0.6)
	S.noise(b, 0, 0.55, 0.9, 2400, 180, 0.005, 0.18)
	S.tone(b, 0, 0.4, 150, 45, "sine", 0.7, 0.001, 0.15)
	S.tone(b, 0.05, 0.3, hz(62), hz(55), "tri", 0.15, 0.01, 0.12)
	return fin(b, 0.8, 0.2)


# ---------------------------------------------------------------- hound
func sfx_hound_growl() -> PackedFloat32Array:
	var b := S.buf(0.7)
	S.tone(b, 0, 0.7, 72, 64, "saw", 0.5, 0.08, 0.0, 0.2, 0.04)
	S.noise(b, 0, 0.7, 0.4, 500, 300, 0.1, 0.0, 60, 0.2)
	S.lowpass(b, 700)
	return fin(b, 0.6)


func sfx_hound_snarl() -> PackedFloat32Array:
	var b := S.buf(0.6)
	S.tone(b, 0, 0.6, 95, 130, "saw", 0.5, 0.03, 0.0, 0.08, 0.09)
	S.tone(b, 0, 0.6, 190, 260, "square", 0.12, 0.03, 0.0, 0.08, 0.1)
	S.noise(b, 0, 0.6, 0.7, 2200, 3000, 0.03, 0.0, 400, 0.08)
	S.lowpass(b, 2200)
	return fin(b, 0.85)


func sfx_hound_leap() -> PackedFloat32Array:
	var b := S.buf(0.4)
	S.noise(b, 0, 0.35, 0.8, 900, 3500, 0.02, 0.12, 300)
	S.tone(b, 0, 0.14, 420, 250, "saw", 0.4, 0.004, 0.05)   # bark
	S.tone(b, 0, 0.14, 210, 125, "square", 0.2, 0.004, 0.05)
	S.lowpass(b, 3000)
	return fin(b, 0.85)


func sfx_hound_land() -> PackedFloat32Array:
	var b := S.buf(0.4)
	S.tone(b, 0, 0.12, 100, 60, "sine", 0.7, 0.001, 0.05)
	S.noise(b, 0, 0.38, 0.6, 1800, 400, 0.005, 0.14, 200)   # skid
	return fin(b, 0.7)


# ---------------------------------------------------------------- pickups / ui
func sfx_mote() -> PackedFloat32Array:
	var b := S.buf(0.35)
	S.tone(b, 0, 0.3, hz(91), hz(91), "sine", 0.35, 0.002, 0.09)
	S.tone(b, 0.05, 0.28, hz(98), hz(98), "sine", 0.3, 0.002, 0.08)
	S.tone(b, 0, 0.2, hz(103), hz(103), "sine", 0.1, 0.002, 0.05)
	return fin(b, 0.55, 0.25)


func sfx_fail() -> PackedFloat32Array:
	var b := S.buf(0.14)
	S.tone(b, 0, 0.14, 120, 100, "square", 0.3, 0.003, 0.0, 0.04)
	S.lowpass(b, 900)
	return fin(b, 0.45)


func sfx_ui_move() -> PackedFloat32Array:
	var b := S.buf(0.06)
	S.tone(b, 0, 0.05, 1400, 1400, "tri", 0.4, 0.001, 0.015)
	return fin(b, 0.35)


func sfx_ui_select() -> PackedFloat32Array:
	var b := S.buf(0.18)
	S.tone(b, 0, 0.08, hz(81), hz(81), "tri", 0.4, 0.001, 0.03)
	S.tone(b, 0.06, 0.12, hz(88), hz(88), "tri", 0.4, 0.001, 0.04)
	return fin(b, 0.45)


func sfx_ui_back() -> PackedFloat32Array:
	var b := S.buf(0.14)
	S.tone(b, 0, 0.07, hz(84), hz(84), "tri", 0.4, 0.001, 0.03)
	S.tone(b, 0.05, 0.09, hz(77), hz(77), "tri", 0.4, 0.001, 0.03)
	return fin(b, 0.4)


# ---------------------------------------------------------------- fire
func sfx_fire_gather() -> PackedFloat32Array:
	var b := S.buf(0.32)
	S.noise(b, 0, 0.32, 0.7, 400, 2200, 0.2, 0.0, 120, 0.04)   # rising roar
	S.crackle(b, 0.0, 0.3, 40, 0.25)
	return fin(b, 0.6)


func sfx_fire_release() -> PackedFloat32Array:
	var b := S.buf(0.5)
	S.noise(b, 0, 0.45, 1.0, 2600, 500, 0.005, 0.15, 150)     # whoomp
	S.tone(b, 0, 0.3, 110, 55, "sine", 0.6, 0.002, 0.1)
	S.crackle(b, 0.02, 0.4, 60, 0.35)
	return fin(b, 0.85, 0.15)


func sfx_fire_impact() -> PackedFloat32Array:
	var b := S.buf(0.6)
	S.noise(b, 0, 0.55, 1.0, 1800, 250, 0.001, 0.16)
	S.tone(b, 0, 0.3, 80, 40, "sine", 0.8, 0.001, 0.1)
	S.crackle(b, 0.05, 0.5, 70, 0.4)
	return fin(b, 0.9, 0.2)


func sfx_fire_whoosh() -> PackedFloat32Array:
	var b := S.buf(0.45)
	S.noise(b, 0, 0.45, 1.0, 700, 3200, 0.03, 0.14, 200)
	S.crackle(b, 0.05, 0.35, 70, 0.3)
	return fin(b, 0.8)


func sfx_fire_ward() -> PackedFloat32Array:
	var b := S.buf(0.9)
	S.noise(b, 0, 0.9, 0.8, 300, 1400, 0.1, 0.4, 80, 0.3)
	S.tone(b, 0, 0.9, hz(50), hz(50), "tri", 0.3, 0.05, 0.4, 0.3)
	S.tone(b, 0, 0.9, hz(57), hz(57), "tri", 0.2, 0.05, 0.4, 0.3)
	S.crackle(b, 0.05, 0.8, 50, 0.3)
	return fin(b, 0.8, 0.3)


func sfx_fire_burst() -> PackedFloat32Array:
	var b := S.buf(0.9)
	S.noise(b, 0, 0.85, 1.0, 3000, 150, 0.001, 0.3)
	S.tone(b, 0, 0.6, 70, 30, "sine", 1.0, 0.001, 0.2)
	S.crackle(b, 0.05, 0.7, 90, 0.4)
	return fin(b, 0.95, 0.3)


func sfx_fire_rain() -> PackedFloat32Array:
	var b := S.buf(1.4)
	S.noise(b, 0, 1.4, 0.5, 1200, 700, 0.2, 0.0, 200, 0.4)
	S.crackle(b, 0.0, 1.3, 90, 0.45)
	return fin(b, 0.7, 0.2)


func sfx_fire_pulse() -> PackedFloat32Array:
	var b := S.buf(0.22)
	S.noise(b, 0, 0.22, 1.0, 2200, 600, 0.002, 0.06, 200)
	S.tone(b, 0, 0.1, 160, 90, "sine", 0.4, 0.001, 0.03)
	return fin(b, 0.75)


func sfx_fire_heat() -> PackedFloat32Array:
	var b := S.buf(0.5)
	S.noise(b, 0, 0.45, 0.8, 800, 4000, 0.02, 0.15, 300)
	for k in 3:
		S.tone(b, k * 0.05, 0.3, hz(72 + k * 5), hz(72 + k * 5), "tri", 0.2, 0.002, 0.1)
	return fin(b, 0.8, 0.2)


# ---------------------------------------------------------------- hex
func sfx_hex_gather() -> PackedFloat32Array:
	var b := S.buf(0.35)
	S.tone(b, 0, 0.35, hz(69), hz(81), "sine", 0.25, 0.1, 0.0, 0.05, 0.02)
	S.tone(b, 0, 0.35, hz(70), hz(82), "sine", 0.2, 0.1, 0.0, 0.05, 0.02)   # beating = eerie
	S.noise(b, 0, 0.35, 0.3, 3000, 5000, 0.15, 0.0, 1500, 0.05)             # whisper
	return fin(b, 0.55)


func sfx_hex_release() -> PackedFloat32Array:
	var b := S.buf(0.5)
	S.tone(b, 0, 0.4, hz(86), hz(62), "sine", 0.4, 0.002, 0.14)
	S.tone(b, 0, 0.4, hz(87), hz(63), "tri", 0.2, 0.002, 0.12)
	S.noise(b, 0, 0.25, 0.6, 5000, 1500, 0.002, 0.07, 1000)
	return fin(b, 0.8, 0.35)


func sfx_hex_impact() -> PackedFloat32Array:
	var b := S.buf(0.6)
	S.noise(b, 0, 0.1, 0.8, 4000, 1200, 0.001, 0.03, 600)
	S.tone(b, 0, 0.5, hz(62), hz(55), "sine", 0.5, 0.002, 0.18)
	S.tone(b, 0.02, 0.45, hz(73), hz(66), "sine", 0.3, 0.002, 0.15)
	return fin(b, 0.8, 0.35)


func sfx_hex_siphon() -> PackedFloat32Array:
	var b := S.buf(1.2)
	S.tone(b, 0, 1.2, hz(45), hz(45), "saw", 0.12, 0.2, 0.0, 0.4, 0.03)
	S.tone(b, 0, 1.2, hz(64), hz(76), "sine", 0.25, 0.3, 0.0, 0.4, 0.02)
	S.noise(b, 0, 1.2, 0.3, 2500, 800, 0.3, 0.0, 700, 0.4)
	S.lowpass(b, 3000)
	return fin(b, 0.7, 0.4)


func sfx_hex_spirit() -> PackedFloat32Array:
	var b := S.buf(0.8)
	for k in 4:
		S.tone(b, k * 0.06, 0.6, hz(79 + [0, 3, 7, 10][k]), hz(79 + [0, 3, 7, 10][k]), "sine", 0.22, 0.01, 0.25, 0.1, 0.01)
	S.noise(b, 0, 0.5, 0.2, 5000, 3000, 0.05, 0.2, 2500)
	return fin(b, 0.7, 0.45)


func sfx_hex_block() -> PackedFloat32Array:
	var b := S.buf(0.5)
	S.tone(b, 0, 0.45, hz(91), hz(91), "tri", 0.4, 0.001, 0.15)
	S.tone(b, 0, 0.45, hz(98), hz(98), "sine", 0.3, 0.001, 0.12)
	S.noise(b, 0, 0.08, 0.7, 6000, 3000, 0.001, 0.02, 1500)
	return fin(b, 0.8, 0.35)


func sfx_hex_echo() -> PackedFloat32Array:
	var b := S.buf(0.7)
	S.tone(b, 0, 0.6, hz(74), hz(86), "sine", 0.3, 0.02, 0.2)
	S.tone(b, 0.08, 0.5, hz(81), hz(93), "sine", 0.25, 0.02, 0.18)
	return fin(b, 0.6, 0.45)


func sfx_hex_thrust() -> PackedFloat32Array:
	var b := S.buf(0.2)
	S.noise(b, 0, 0.18, 0.8, 5000, 1500, 0.002, 0.05, 800)
	S.tone(b, 0, 0.15, hz(79), hz(67), "sine", 0.3, 0.001, 0.05)
	return fin(b, 0.7)


func sfx_roots() -> PackedFloat32Array:
	var b := S.buf(0.7)
	S.noise(b, 0, 0.6, 1.0, 900, 200, 0.005, 0.2)             # earth burst
	S.tone(b, 0, 0.3, 90, 50, "sine", 0.7, 0.001, 0.1)
	S.crackle(b, 0.02, 0.5, 45, 0.5)                          # creaking wood
	S.tone(b, 0.1, 0.4, 180, 140, "saw", 0.08, 0.02, 0.15)
	S.lowpass(b, 2500)
	return fin(b, 0.85)


# ---------------------------------------------------------------- storm extras
func sfx_storm_thunder() -> PackedFloat32Array:
	var b := S.buf(1.2)
	S.noise(b, 0, 0.06, 1.0, 9000, 4000, 0.0003, 0.015, 600)   # crack
	S.noise(b, 0.02, 1.1, 1.0, 600, 90, 0.01, 0.35)            # rumble
	S.tone(b, 0, 0.5, 60, 32, "sine", 0.9, 0.001, 0.2)
	S.crackle(b, 0.0, 0.4, 100, 0.4)
	return fin(b, 0.95, 0.3)


func sfx_storm_wind() -> PackedFloat32Array:
	var b := S.buf(0.4)
	S.noise(b, 0, 0.4, 1.0, 600, 5000, 0.02, 0.13, 300)
	S.noise(b, 0.05, 0.3, 0.5, 3000, 1200, 0.02, 0.1, 800)
	return fin(b, 0.8)


func sfx_storm_hum() -> PackedFloat32Array:
	var b := S.buf(1.0)
	S.tone(b, 0, 1.0, 110, 112, "saw", 0.15, 0.05, 0.0, 0.3, 0.02)
	S.tone(b, 0, 1.0, 220, 223, "square", 0.05, 0.05, 0.0, 0.3)
	S.crackle(b, 0.0, 1.0, 40, 0.3)
	S.lowpass(b, 2500)
	return fin(b, 0.6, 0.2)


func sfx_ui_open() -> PackedFloat32Array:
	var b := S.buf(0.4)
	S.noise(b, 0, 0.3, 0.4, 1500, 4000, 0.05, 0.1, 400)      # page rustle
	S.tone(b, 0.05, 0.3, hz(76), hz(76), "tri", 0.3, 0.002, 0.1)
	S.tone(b, 0.1, 0.3, hz(83), hz(83), "tri", 0.25, 0.002, 0.1)
	return fin(b, 0.5, 0.3)


# ---------------------------------------------------------------- enemies
func sfx_block() -> PackedFloat32Array:
	var b := S.buf(0.3)
	S.tone(b, 0, 0.25, 420, 380, "square", 0.25, 0.001, 0.07)
	S.tone(b, 0, 0.25, 1260, 1200, "sine", 0.3, 0.001, 0.05)
	S.noise(b, 0, 0.1, 0.6, 3000, 1500, 0.001, 0.03, 500)
	S.tone(b, 0, 0.15, 120, 80, "sine", 0.5, 0.001, 0.04)
	return fin(b, 0.8, 0.15)


func sfx_guard_break() -> PackedFloat32Array:
	var b := S.buf(0.6)
	S.noise(b, 0, 0.4, 1.0, 2500, 400, 0.001, 0.12)
	S.tone(b, 0, 0.3, 300, 140, "square", 0.3, 0.001, 0.1)
	S.crackle(b, 0.02, 0.3, 80, 0.5)  # splintering wood
	S.tone(b, 0, 0.3, 90, 45, "sine", 0.7, 0.001, 0.1)
	return fin(b, 0.9, 0.2)


func sfx_raider_grunt() -> PackedFloat32Array:
	var b := S.buf(0.3)
	S.tone(b, 0, 0.25, 150, 110, "saw", 0.4, 0.01, 0.1, 0.05, 0.02)
	S.noise(b, 0, 0.2, 0.3, 900, 500, 0.01, 0.08)
	S.lowpass(b, 1200)
	return fin(b, 0.7)


func sfx_slash() -> PackedFloat32Array:
	var b := S.buf(0.3)
	S.noise(b, 0, 0.28, 1.0, 1500, 7000, 0.01, 0.07, 800)
	S.tone(b, 0.02, 0.15, 1800, 900, "sine", 0.15, 0.001, 0.05)
	return fin(b, 0.8)


func sfx_knot_creak() -> PackedFloat32Array:
	var b := S.buf(0.8)
	S.tone(b, 0, 0.8, 140, 95, "saw", 0.25, 0.1, 0.0, 0.15, 0.03)
	S.crackle(b, 0.0, 0.8, 35, 0.5)
	S.noise(b, 0, 0.8, 0.4, 500, 250, 0.2, 0.0, 60, 0.2)
	S.lowpass(b, 1500)
	return fin(b, 0.8)


func sfx_sentinel_windup() -> PackedFloat32Array:
	var b := S.buf(0.9)
	S.tone(b, 0, 0.9, 55, 70, "saw", 0.3, 0.2, 0.0, 0.1, 0.02)
	S.tone(b, 0, 0.9, hz(74), hz(81), "sine", 0.15, 0.3, 0.0, 0.1)
	S.noise(b, 0, 0.9, 0.3, 300, 1200, 0.3, 0.0, 80, 0.1)   # armour grinding
	S.crackle(b, 0.1, 0.7, 25, 0.3)
	S.lowpass(b, 2000)
	return fin(b, 0.75, 0.2)


func sfx_sentinel_slam() -> PackedFloat32Array:
	var b := S.buf(1.0)
	S.noise(b, 0, 0.08, 1.0, 6000, 2000, 0.0005, 0.02, 400)
	S.tone(b, 0, 0.6, 55, 28, "sine", 1.0, 0.001, 0.25)
	S.noise(b, 0.02, 0.9, 0.7, 700, 90, 0.01, 0.3)
	S.tone(b, 0, 0.4, 900, 850, "square", 0.08, 0.001, 0.15)   # ringing steel
	return fin(b, 0.95, 0.3)

# ---------------------------------------------------------------- music
## Tense night-woods loop: D minor, 80 bpm, 8 bars.
func mus_explore() -> PackedFloat32Array:
	var bpm := 80.0
	var beat := 60.0 / bpm
	var bars := 8
	var b := S.buf(bars * 4 * beat)
	var chords := [[50, 53, 57], [46, 50, 53], [43, 46, 50], [45, 49, 52]]  # Dm Bb Gm A
	var scale := [62, 65, 67, 69, 72, 74, 77]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for bar in bars:
		var ch: Array = chords[(bar / 2) % 4]
		var t0 := bar * 4 * beat
		if bar % 2 == 0:
			for n in ch:
				for det in [-0.08, 0.08]:
					S.tone(b, t0, 8 * beat, hz(n + det), hz(n + det), "saw", 0.045, 1.2, 0.0, 1.4)
		# bass pulse
		for k in [0, 2]:
			S.tone(b, t0 + k * beat, 1.8 * beat, hz(ch[0] - 12), hz(ch[0] - 12), "tri", 0.28, 0.01, 0.9)
		# heartbeat kick: 1 and the and-of-2
		for kb in [0.0, 1.5]:
			S.tone(b, t0 + kb * beat, 0.25, 90, 42, "sine", 0.5, 0.002, 0.08)
		# quiet shaker on off-beats
		for k in 8:
			if k % 2 == 1:
				S.noise(b, t0 + k * beat * 0.5, 0.06, 0.05, 9000, 6000, 0.002, 0.02, 3000)
		# sparse plucked motif
		for k in 8:
			if rng.randf() < (0.45 if k % 2 == 0 else 0.2):
				var note: int = scale[rng.randi_range(0, scale.size() - 1)]
				S.pluck(b, t0 + k * beat * 0.5, hz(note), 1.6, 0.22, 0.995, 0.45)
	S.lowpass(b, 5200)
	S.reverb(b, 0.35, 0.82, true)
	S.normalize(b, 0.7)
	return b


## Sanctuary and Hearthmere: a slow, warm 3/4 in F with a plucked melody.
func mus_home() -> PackedFloat32Array:
	var bpm := 84.0
	var beat := 60.0 / bpm
	var bars := 12
	var b := S.buf(bars * 3 * beat)
	var chords := [[53, 57, 60], [50, 53, 57], [46, 50, 53], [48, 52, 55]]  # F Dm Bb C
	var melody := [72, 69, 67, 69, 72, 74, 72, 69, 65, 67, 69, 67, 65, 64, 65, 67, 69, 72, 74, 72, 69, 67, 65, 64]
	for bar in bars:
		var ch: Array = chords[bar % 4]
		var t0 := bar * 3 * beat
		for n in ch:
			S.tone(b, t0, 3.2 * beat, hz(n), hz(n), "tri", 0.05, 0.3, 1.0)
		S.tone(b, t0, 2.8 * beat, hz(ch[0] - 12), hz(ch[0] - 12), "sine", 0.22, 0.02, 0.8)
		for k in [1, 2]:
			S.pluck(b, t0 + k * beat, hz(ch[1]), 0.8, 0.08, 0.99, 0.3)
		for k in 2:
			var note: int = melody[(bar * 2 + k) % melody.size()]
			S.pluck(b, t0 + k * 1.5 * beat, hz(note), 1.8, 0.2, 0.996, 0.55)
	S.lowpass(b, 4800)
	S.reverb(b, 0.4, 0.85, true)
	S.normalize(b, 0.62)
	return b


## The Old Ward: low drones, a slow bell and whispering noise.
func mus_ruins() -> PackedFloat32Array:
	var dur := 24.0
	var b := S.buf(dur)
	for n in [38, 45, 50]:
		for det in [-0.12, 0.12]:
			S.tone(b, 0.0, dur, hz(n + det), hz(n + det), "saw", 0.035, 3.0, 3.0)
	for k in 6:
		var t := k * 4.0 + 0.5
		var bell: int = [74, 73, 69, 70, 74, 65][k]
		S.tone(b, t, 3.5, hz(bell), hz(bell), "sine", 0.12, 0.005, 3.2)
		S.tone(b, t, 3.5, hz(bell + 12) * 1.003, hz(bell + 12), "sine", 0.04, 0.005, 2.5)
	for k in 12:
		S.noise(b, k * 2.0, 1.8, 0.03, 1200, 600, 0.8, 0.9, 400)
	S.lowpass(b, 3000)
	S.reverb(b, 0.55, 0.9, true)
	S.normalize(b, 0.6)
	return b


## Boss fights: driving drums under a minor riff.
func mus_boss() -> PackedFloat32Array:
	var bpm := 132.0
	var beat := 60.0 / bpm
	var bars := 8
	var b := S.buf(bars * 4 * beat)
	var roots := [45, 45, 41, 43, 45, 45, 48, 44]
	var riff := [0, 0, 3, 0, 5, 3, 0, -2]
	for bar in bars:
		var t0 := bar * 4 * beat
		var r: int = roots[bar]
		for k in 8:
			S.tone(b, t0 + k * beat * 0.5, beat * 0.45, hz(r - 12 + riff[k]), hz(r - 12 + riff[k]), "saw", 0.16, 0.005, 0.2)
		for n in [r, r + 3, r + 7]:
			S.tone(b, t0, 4 * beat, hz(n), hz(n), "saw", 0.03, 0.05, 0.5)
		for k in 4:
			S.tone(b, t0 + k * beat, 0.3, 100, 40, "sine", 0.6, 0.002, 0.1)
			if k % 2 == 1:
				S.noise(b, t0 + k * beat, 0.15, 0.25, 5000, 1500, 0.002, 0.1, 800)
		for k in 8:
			S.noise(b, t0 + k * beat * 0.5 + beat * 0.25, 0.04, 0.06, 10000, 8000, 0.001, 0.02, 4000)
	S.lowpass(b, 6000)
	S.reverb(b, 0.2, 0.7, true)
	S.normalize(b, 0.66)
	return b


func sfx_ward_light() -> PackedFloat32Array:
	var b := S.buf(2.2)
	for k in 4:
		var n: int = [72, 76, 79, 84][k]
		S.tone(b, k * 0.09, 1.8, hz(n), hz(n), "sine", 0.3, 0.005, 1.6)
		S.tone(b, k * 0.09, 1.8, hz(n + 12) * 1.002, hz(n + 12), "sine", 0.1, 0.005, 1.2)
	S.noise(b, 0.0, 0.8, 0.12, 9000, 3000, 0.01, 0.7, 2000)
	return fin(b, 0.8, 0.45)


func sfx_levitate() -> PackedFloat32Array:
	var b := S.buf(0.9)
	S.tone(b, 0.0, 0.8, hz(76), hz(88), "sine", 0.25, 0.02, 0.6)
	S.tone(b, 0.05, 0.7, hz(83), hz(91), "sine", 0.12, 0.02, 0.5)
	S.noise(b, 0.0, 0.6, 0.08, 7000, 11000, 0.05, 0.4, 3000)
	return fin(b, 0.6, 0.3)
