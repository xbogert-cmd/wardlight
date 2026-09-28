class_name EmberPatch
extends Node3D
## Burning ground left by fire spells: a smouldering disc that burns enemies
## standing in it and can be scattered by wind (Cinderflight). It glows, so it
## lights the ground around it at night.

var radius := 0.8
var life := 4.0
var source: Node = null
var consumed := false
var _tick := 0.0
var _t := 0.0
var _disc: MeshInstance3D
var _mat: ShaderMaterial
var _lamp: OmniLight3D


static func place(world: Node, at: Vector3, r: float, lifetime: float, src: Node) -> EmberPatch:
	var p := EmberPatch.new()
	p.radius = r
	p.life = lifetime
	p.source = src
	world.add_child(p)
	p.global_position = SpellEffect.ground_at(at, p)
	return p


func _ready() -> void:
	add_to_group(&"ember_patch")
	var ramp := Pal.school(&"fire")
	_mat = ShaderMaterial.new()
	_mat.shader = FX3.DECAL_SHADER
	var size := Vector2.ONE * (radius * 2.0 + 0.3)
	_mat.set_shader_parameter(&"mode", 1)
	_mat.set_shader_parameter(&"size_m", size)
	_mat.set_shader_parameter(&"radius", radius)
	_mat.set_shader_parameter(&"width", 1.0)
	_mat.set_shader_parameter(&"fill", 0.3)
	_mat.set_shader_parameter(&"color", Color(ramp[3], 0.8))
	_disc = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	_disc.mesh = q
	_disc.material_override = _mat
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.rotation.x = -PI / 2
	_disc.position.y = 0.05
	add_child(_disc)
	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.5, 0.2)
	_lamp.light_energy = 1.4
	_lamp.omni_range = radius * 3.0
	_lamp.position.y = 0.5
	add_child(_lamp)


func contains(pt: Vector3, pad: float = 0.0) -> bool:
	return SpellEffect.flat(pt, global_position) <= radius + pad


func extinguish() -> void:
	life = minf(life, 0.25)


func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		for e: Node3D in SpellEffect.in_circle(global_position, radius):
			e.statuses.apply(&"burn", 2.0, 3.0, source)
	var fade := clampf(life / 0.6, 0.0, 1.0)
	var ramp := Pal.school(&"fire")
	var flick := 1.0 if int(_t * 12.0) % 3 else 0.8
	_mat.set_shader_parameter(&"color", Color(ramp[3], 0.8 * fade * flick))
	_lamp.light_energy = 1.4 * fade * flick
	if randf() < delta * 26.0 * radius:
		var a := randf() * TAU
		var rr := sqrt(randf()) * radius
		FX3.burst(global_position + Vector3(cos(a) * rr, 0.08, sin(a) * rr), 1, ramp,
			Vector2(0.3, 1.0), Vector2(0.3, 0.6), {"dir": Vector3.UP, "spread": 0.8, "gravity": -1.2, "size": 2.0 if randf() < 0.3 else 1.0})
