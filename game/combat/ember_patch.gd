class_name EmberPatch
extends Node2D
## Burning ground left by fire spells. Burns enemies standing in it and can
## be scattered by wind (Cinderflight). Placed on the ground surface.

var width := 40.0
var life := 4.0
var source: Node = null
var consumed := false
var _tick := 0.0
var _t := 0.0


static func place(world: Node, at: Vector2, w: float, lifetime: float, src: Node) -> EmberPatch:
	var space := (world as Node2D).get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(at + Vector2(0, -8), at + Vector2(0, 90), 1)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return null
	var p := EmberPatch.new()
	p.width = w
	p.life = lifetime
	p.source = src
	world.add_child(p)
	p.global_position = hit.position
	return p


func _ready() -> void:
	add_to_group(&"ember_patch")
	z_index = FX.Z_BACK + 2
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func contains(pt: Vector2, pad: float = 0.0) -> bool:
	return absf(pt.x - global_position.x) <= width * 0.5 + pad and absf(pt.y - global_position.y) < 28.0 + pad


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
		for e: Node2D in SpellEffect.enemies():
			if contains(e.global_position):
				e.statuses.apply(&"burn", 2.0, 3.0, source)
	if randf() < delta * 14.0:
		FX.burst(global_position + Vector2(randf_range(-width * 0.5, width * 0.5), -2), 1, Pal.school(&"fire"),
			Vector2(10, 30), Vector2(0.3, 0.6), {"dir": Vector2.UP, "spread": 0.8, "gravity": -30.0, "front": false})
	queue_redraw()


func _draw() -> void:
	var fade := clampf(life / 0.6, 0.0, 1.0)
	var ramp := Pal.school(&"fire")
	var hw := width * 0.5
	draw_rect(Rect2(-hw, -1, width, 2), Color(ramp[3], 0.6 * fade))
	var x := -hw
	var k := 0
	while x < hw:
		var h := 2.0 + absf(sin(_t * 9.0 + k * 1.7)) * 4.0
		draw_rect(Rect2(roundf(x), roundf(-h), 2, roundf(h)), Color(ramp[2], 0.85 * fade))
		draw_rect(Rect2(roundf(x), roundf(-h), 1, 1), Color(ramp[1], fade))
		x += 3.0 + float(k % 3)
		k += 1
