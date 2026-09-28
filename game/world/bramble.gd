class_name Bramble
extends StaticBody3D
## A thicket of briars blocking a path. Any spell or staff hit tears it
## apart. It joins the "enemy" group so aim assist and spells treat it as a
## target, but it never fights back.

signal cleared

const THORNS := preload("res://assets/generated/w3d/thorns.png")

var statuses: Statuses
var is_boss := false
var _knock := Vector3.ZERO   # spells that drag enemies write here; brambles stay put
var width := 3.0
var _alive := true
var _parts: Array[PixelBillboard] = []


func _ready() -> void:
	add_to_group(&"enemy")
	# its own layer: blocks the wizard, but spell rays (layer 1) pass through
	collision_layer = 64
	statuses = Statuses.new()
	statuses.owner_actor = self
	add_child(statuses)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.0, 2.0, width)
	cs.shape = sh
	cs.position.y = 1.0
	add_child(cs)
	for k in 9:
		var b := PixelBillboard.still(THORNS)
		b.scale = Vector3.ONE * randf_range(1.0, 1.4)
		b.set_flip(k % 2 == 0)
		add_child(b)
		b.position = Vector3(randf_range(-0.4, 0.4), 0, -width * 0.5 + width * k / 8.0)
		_parts.append(b)


func is_alive() -> bool:
	return _alive


func center() -> Vector3:
	return global_position + Vector3(0, 0.7, 0)


func radius() -> float:
	return 0.9


func height() -> float:
	return 1.4


func take_hit(d: Damage) -> void:
	if not _alive or d.amount <= 0.0:
		return
	_alive = false
	remove_from_group(&"enemy")
	collision_layer = 0
	Sfx.play("roots", 0.0)
	FX3.burst(center(), 30, Pal.DUST, Vector2(1.0, 4.0), Vector2(0.4, 0.8), {"gravity": 6.0, "jitter": 1.0})
	FX3.burst(center(), 16, Pal.school(d.school), Vector2(1.0, 3.0), Vector2(0.3, 0.6), {"gravity": 4.0})
	for b in _parts:
		var tw := b.create_tween()
		tw.tween_property(b, "position:y", -1.2, 0.5).set_delay(randf() * 0.2)
	cleared.emit()
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_callback(queue_free)
