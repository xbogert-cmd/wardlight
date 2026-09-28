class_name StatusOverlay
extends Node3D
## Readable status marks on an actor: a violet eye-sigil above cursed
## enemies, flickering flames on burning ones, root tendrils at the feet.

const PX := 1.0 / 24.0

static var _curse_tex: Texture2D
static var _root_tex: Texture2D

var actor: Node3D
var _t := 0.0
var _curse: MeshInstance3D
var _root: MeshInstance3D


func _ready() -> void:
	_make_textures()
	_curse = _mark(_curse_tex, true)
	_root = _mark(_root_tex, false)
	actor.statuses.changed.connect(_refresh)
	_refresh()


static func _make_textures() -> void:
	if _curse_tex:
		return
	var hex: Color = Pal.SCHOOL[&"hex"][1]
	var eye := ["....#....", "...#.#...", "..#...#..", ".#.sOs.#.", "..#...#..", "...#.#...", "....#...."]
	var img := Image.create_empty(9, 7, false, Image.FORMAT_RGBA8)
	for y in eye.size():
		for x in 9:
			var ch: String = eye[y][x]
			if ch != ".":
				img.set_pixel(x, y, {"#": hex, "O": Pal.SPECTRAL[1], "s": Pal.SPECTRAL[2]}[ch])
	_curse_tex = ImageTexture.create_from_image(img)
	var r := Image.create_empty(24, 12, false, Image.FORMAT_RGBA8)
	var bark := Color("7a5a3a")
	for k in 5:
		var x := 2 + k * 5
		var h := 7 + (k % 2) * 3
		var lean := 1 if k % 2 else -1
		for y in h:
			var xx := x + int(lean * y / 4.0)
			r.set_pixel(clampi(xx, 0, 23), 11 - y, bark)
			if y < h - 2:
				r.set_pixel(clampi(xx + 1, 0, 23), 11 - y, bark.darkened(0.3))
		r.set_pixel(clampi(x + int(lean * h / 4.0), 0, 23), 11 - h, hex)
	_root_tex = ImageTexture.create_from_image(r)


func _mark(tex: Texture2D, glow: bool) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tex.get_width(), tex.get_height()) * PX
	m.mesh = q
	var mat := ShaderMaterial.new()
	mat.shader = FX3.DECAL_SHADER if glow else PixelBillboard.SHADER
	mat.set_shader_parameter(&"tex", tex)
	if glow:
		mat.set_shader_parameter(&"billboard", true)
		mat.set_shader_parameter(&"color", Color(1.4, 1.4, 1.4))
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	add_child(m)
	return m


func _refresh() -> void:
	var alive: bool = actor.is_alive()
	_curse.visible = alive and actor.statuses.has(&"curse")
	_root.visible = alive and actor.statuses.has(&"root")
	set_process(_curse.visible or _root.visible or actor.statuses.has(&"burn"))


func _process(delta: float) -> void:
	_t += delta
	if not actor.is_alive():
		_curse.visible = false
		_root.visible = false
		return
	var h: float = actor.height()
	_curse.position = Vector3(0, h + 0.35 + roundf(sin(_t * 4.0)) * PX, 0)
	_root.position = Vector3(0, 0.25, 0.02)
	if actor.statuses.has(&"burn") and randf() < delta * 16.0:
		var rr: float = actor.radius()
		FX3.burst(actor.global_position + Vector3(randf_range(-rr, rr), randf_range(0.1, h), randf_range(-rr, rr) * 0.5), 1, Pal.school(&"fire"),
			Vector2(0.4, 1.2), Vector2(0.25, 0.45), {"dir": Vector3.UP, "spread": 0.7, "gravity": -1.6})
