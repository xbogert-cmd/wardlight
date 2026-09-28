extends RefCounted
## Minimal offline synthesiser for sound effects and music loops.
## Buffers are mono PackedFloat32Array at RATE.

const RATE := 44100


static func buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * RATE))
	return b


static func env(t: float, dur: float, att: float, rel: float) -> float:
	var a := minf(1.0, t / maxf(att, 0.0001))
	var r := clampf((dur - t) / maxf(rel, 0.0001), 0.0, 1.0)
	return a * r


static func osc(wave: String, ph: float) -> float:
	var x := fposmod(ph, 1.0)
	match wave:
		"sine":
			return sin(ph * TAU)
		"saw":
			return 2.0 * x - 1.0
		"square":
			return 1.0 if x < 0.5 else -1.0
		"tri":
			return 4.0 * absf(x - 0.5) - 1.0
	return 0.0


## Tone with exponential pitch glide f0→f1 and exp decay (tau seconds, 0 = sustain).
static func tone(b: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, wave: String, amp: float,
		att: float = 0.005, tau: float = 0.0, rel: float = 0.02, vib: float = 0.0) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var ph := 0.0
	for k in n:
		var i := i0 + k
		if i >= b.size():
			break
		var t := float(k) / RATE
		var f := f0 * pow(f1 / f0, t / dur)
		if vib > 0.0:
			f *= 1.0 + sin(t * TAU * 5.5) * vib
		ph += f / RATE
		var e := env(t, dur, att, rel)
		if tau > 0.0:
			e *= exp(-t / tau)
		b[i] += osc(wave, ph) * amp * e


## Filtered noise; lowpass cutoff sweeps c0→c1 Hz, optional highpass.
static func noise(b: PackedFloat32Array, start: float, dur: float, amp: float, c0: float, c1: float,
		att: float = 0.002, tau: float = 0.0, hp: float = 0.0, rel: float = 0.02) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var lp := 0.0
	var lp2 := 0.0
	var hpx := 0.0
	var hpy := 0.0
	var ahp := 1.0 / (1.0 + TAU * hp / RATE) if hp > 0.0 else 0.0
	for k in n:
		var i := i0 + k
		if i >= b.size():
			break
		var t := float(k) / RATE
		var c := c0 * pow(c1 / c0, t / dur)
		var a := 1.0 - exp(-TAU * c / RATE)
		var x := randf() * 2.0 - 1.0
		lp += (x - lp) * a
		lp2 += (lp - lp2) * a
		var y := lp2
		if hp > 0.0:
			var yy := ahp * (hpy + y - hpx)
			hpx = y
			hpy = yy
			y = yy
		var e := env(t, dur, att, rel)
		if tau > 0.0:
			e *= exp(-t / tau)
		b[i] += y * amp * e * 1.6


## Random electric clicks.
static func crackle(b: PackedFloat32Array, start: float, dur: float, per_sec: float, amp: float) -> void:
	var count := int(dur * per_sec)
	for k in count:
		var t := start + randf() * dur
		var i := int(t * RATE)
		var ln := randi_range(20, 90)
		var a := amp * randf_range(0.4, 1.0)
		for j in ln:
			if i + j < b.size():
				b[i + j] += (randf() * 2.0 - 1.0) * a * (1.0 - float(j) / ln)


## Karplus–Strong plucked string.
static func pluck(b: PackedFloat32Array, start: float, freq: float, dur: float, amp: float, damp: float = 0.996, bright: float = 0.5) -> void:
	var p := maxi(2, int(RATE / freq))
	var line := PackedFloat32Array()
	line.resize(p)
	var lpv := 0.0
	for k in p:
		var x := randf() * 2.0 - 1.0
		lpv += (x - lpv) * bright
		line[k] = lpv
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var idx := 0
	for k in n:
		var i := i0 + k
		if i >= b.size():
			break
		var nxt := (idx + 1) % p
		var v := (line[idx] + line[nxt]) * 0.5 * damp
		b[i] += line[idx] * amp * env(float(k) / RATE, dur, 0.001, 0.05)
		line[idx] = v
		idx = nxt


static func lowpass(b: PackedFloat32Array, cutoff: float) -> void:
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var y := 0.0
	for i in b.size():
		y += (b[i] - y) * a
		b[i] = y


## Small Schroeder reverb (4 combs + 2 allpasses).
static func reverb(b: PackedFloat32Array, wet: float, room: float = 0.8, wrap: bool = false) -> void:
	var dry := b.duplicate()
	var out := PackedFloat32Array()
	out.resize(b.size())
	for d in [1557, 1617, 1491, 1422]:
		var line := PackedFloat32Array()
		line.resize(d)
		var j := 0
		var fb := room * 0.84
		var passes := 2 if wrap else 1
		for pass_i in passes:
			for i in b.size():
				var y := line[j]
				line[j] = dry[i] + y * fb
				j = (j + 1) % d
				if pass_i == passes - 1:
					out[i] += y * 0.25
	for d in [225, 556]:
		var line := PackedFloat32Array()
		line.resize(d)
		var j := 0
		for i in out.size():
			var bufv := line[j]
			var x := out[i]
			line[j] = x + bufv * 0.5
			out[i] = bufv - x * 0.5
			j = (j + 1) % d
	for i in b.size():
		b[i] = dry[i] * (1.0 - wet * 0.5) + out[i] * wet


static func normalize(b: PackedFloat32Array, peak: float = 0.9) -> void:
	var m := 0.0001
	for v in b:
		m = maxf(m, absf(v))
	var g := peak / m
	for i in b.size():
		b[i] = clampf(b[i] * g, -1.0, 1.0)


static func save(b: PackedFloat32Array, path: String) -> void:
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		data.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	s.save_to_wav(path)
