class_name Mana
extends Node
## Mana pool with slow baseline regeneration.

signal changed(mp: float, max_mp: float)

var max_mp := 100.0
var mp := 100.0
var regen := 2.5


func _physics_process(delta: float) -> void:
	if mp < max_mp:
		mp = minf(max_mp, mp + regen * delta)
		changed.emit(mp, max_mp)


func can_spend(x: float) -> bool:
	return mp + 0.001 >= x


func spend(x: float) -> bool:
	if not can_spend(x):
		return false
	mp -= x
	changed.emit(mp, max_mp)
	return true


func gain(x: float) -> void:
	mp = minf(max_mp, mp + x)
	changed.emit(mp, max_mp)


func refill() -> void:
	mp = max_mp
	changed.emit(mp, max_mp)
