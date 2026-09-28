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
