class_name Spyglass
extends CanvasLayer
## The view through Orla's spyglass from the far watchtower (Chapter 2's
## teaser): a dusk horizon over grey, dead land, and a vast shape walking
## slowly through the haze. Drawn in code; pauses the world until a key
## press after it has played for a while.

const FONT := preload("res://assets/fonts/wardhand.tres")
const MIN_TIME := 5.5

var canvas: Control
var _t := 0.0


## Show the view and wait for the wizard to lower the glass.
static func look(host: Node) -> void:
	var s := Spyglass.new()
	host.add_child(s)
	await s._run()
	s.queue_free()


func _ready() -> void:
	layer = 27
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_view)
	add_child(canvas)


func _run() -> void:
	get_tree().paused = true
	Sfx.play("ward_light", -12.0)
	while true:
		await get_tree().process_frame
		if _t >= MIN_TIME and (Input.is_action_pressed(&"interact") or Input.is_action_pressed(&"ui_accept")
				or Input.is_action_pressed(&"attack") or _t >= MIN_TIME + 6.0):
			break
	get_tree().paused = false


func _process(delta: float) -> void:
	_t += delta
	canvas.queue_redraw()


func _draw_view() -> void:
	var c := canvas
	# dusk sky in bands
	var bands := [Color("2a1a34"), Color("4a2a44"), Color("7a3a48"), Color("a8584a"), Color("c8805a")]
	for k in bands.size():
		c.draw_rect(Rect2(0, k * 36, 640, 36), bands[k])
	# far grey hills, dead and flat-toned
	var hills := PackedVector2Array([Vector2(0, 200)])
	for k in 33:
		var x := k * 20.0
		hills.append(Vector2(x, 176 + sin(x * 0.021) * 10 + sin(x * 0.07) * 4))
	hills.append(Vector2(640, 200))
	hills.append(Vector2(640, 360))
	hills.append(Vector2(0, 360))
	c.draw_colored_polygon(hills, Color("5a5660"))
	# the vast shape: a hunched, many-limbed walker far off in the haze
	# (small and low-contrast: it is very far away, and very big)
	var q := 0.55
	var x0 := 200.0 + _t * 5.0
	var sway := sin(_t * 1.1) * 2.0 * q
	var body := Color(0.3, 0.27, 0.33, 0.8)
	var base := 180.0
	var at := func(x: float, y: float) -> Vector2: return Vector2(x0 + x * q, base - y * q + sway)
	for leg in 4:
		var lx := leg * 26.0 + sin(_t * 1.1 + leg * 1.7) * 8.0
		c.draw_line(Vector2(x0 + lx * q, base), at.call(30.0 + leg * 12, 70.0), body, 3.0)
	c.draw_colored_polygon(PackedVector2Array([at.call(10.0, 64.0), at.call(60.0, 98.0), at.call(110.0, 80.0), at.call(96.0, 56.0), at.call(24.0, 50.0)]), body)
	for k in 5:   # branching growths on its back
		c.draw_line(at.call(30.0 + k * 16, 86.0), at.call(24.0 + k * 19, 118.0 + k % 2 * 8), body, 1.0)
	var eye := Color(0.9, 0.85, 0.7, 0.35 + 0.3 * sin(_t * 2.0))
	c.draw_rect(Rect2(at.call(104.0, 74.0), Vector2(2, 1)), eye)
	# haze drifting across (the shape comes and goes in it)
	for k in 6:
		var hy := 120 + k * 16
		var hx := fposmod(k * 131.0 + _t * (8 + k * 3), 900.0) - 200.0
		for j in 4:
			c.draw_rect(Rect2(hx + j * 20, hy - j, 260 - j * 40, 4 + j * 2), Color(0.62, 0.56, 0.62, 0.07))
			c.draw_rect(Rect2(hx + 300 + j * 15, hy + 5 - j, 180 - j * 30, 3 + j * 2), Color(0.62, 0.56, 0.62, 0.05))
	# near dark ridge and the tower's rail
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, 250), Vector2(180, 238), Vector2(420, 246), Vector2(640, 232), Vector2(640, 360), Vector2(0, 360)]), Color("1a1420"))
	# the spyglass circle: everything outside is dark
	var ctr := Vector2(320, 170)
	var r := 150.0
	var ring := PackedVector2Array()
	for k in 65:
		ring.append(ctr + Vector2.from_angle(k * TAU / 64.0) * r)
	for k in 64:
		var a := ring[k]
		var b := ring[k + 1]
		var ea := ctr + (a - ctr) * 3.0
		var eb := ctr + (b - ctr) * 3.0
		c.draw_colored_polygon(PackedVector2Array([a, ea, eb, b]), Color("06040a"))
	c.draw_arc(ctr, r, 0, TAU, 64, Color("8a6a40"), 3.0)
	var fade := clampf(_t * 1.5, 0.0, 1.0)
	c.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 1.0 - fade))
	if _t >= MIN_TIME:
		var s := "%s: lower the glass" % Settings.key_label("interact")
		c.draw_string(FONT, Vector2(0, 346), s, HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color("c8b898"))
