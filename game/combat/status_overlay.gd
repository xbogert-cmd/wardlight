class_name StatusOverlay
extends Node2D
## Readable status marks drawn on an actor: a violet sigil above cursed
## enemies, flickering flames on burning ones, root tendrils when rooted.

var actor: Node2D
var _t := 0.0


func _ready() -> void:
	z_index = 6
	actor.statuses.changed.connect(queue_redraw)


func _process(delta: float) -> void:
	if actor.statuses._s.is_empty():
		return
	_t += delta
	if actor.statuses.has(&"burn") and randf() < delta * 16.0:
		var r: Rect2 = actor.hurt_rect()
		FX.burst(Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y + 4, r.end.y)), 1, Pal.school(&"fire"),
			Vector2(10, 30), Vector2(0.25, 0.45), {"dir": Vector2.UP, "spread": 0.7, "gravity": -40.0})
	queue_redraw()


func _draw() -> void:
	if not actor.is_alive():
		return
	var r: Rect2 = actor.hurt_rect()
	var local := r.position - actor.global_position
	if actor.statuses.has(&"curse"):
		var c := Vector2(roundf(local.x + r.size.x * 0.5), roundf(local.y - 7))
		var bob := roundf(sin(_t * 4.0))
		var col := Pal.SCHOOL[&"hex"][1]
		# small eye-sigil: diamond with a spectral pupil
		draw_line(c + Vector2(-4, bob), c + Vector2(0, -3 + bob), col, 1.0)
		draw_line(c + Vector2(0, -3 + bob), c + Vector2(4, bob), col, 1.0)
		draw_line(c + Vector2(4, bob), c + Vector2(0, 3 + bob), col, 1.0)
		draw_line(c + Vector2(0, 3 + bob), c + Vector2(-4, bob), col, 1.0)
		draw_rect(Rect2(c + Vector2(-1, -1 + bob), Vector2(2, 2)), Pal.SPECTRAL[1])
	if actor.statuses.has(&"root"):
		var col2 := Color("7a5a3a")
		var y := roundf(local.y + r.size.y)
		for k in 4:
			var x := roundf(local.x + (k + 0.5) * r.size.x / 4.0)
			var h := 6.0 + (k % 2) * 3.0
			draw_line(Vector2(x, y), Vector2(x + (1 if k % 2 else -1) * 2, y - h), col2, 2.0)
			draw_rect(Rect2(x + (1 if k % 2 else -1) * 2, y - h - 1, 1, 1), Pal.SCHOOL[&"hex"][1])
