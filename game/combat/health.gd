class_name Health
extends Node
## Hit points for any actor.

signal changed(hp: float, max_hp: float)
signal died

@export var max_hp := 100.0
var hp := 100.0


func _ready() -> void:
	hp = max_hp


func is_dead() -> bool:
	return hp <= 0.0


func damage(amount: float) -> float:
	if is_dead():
		return 0.0
	var dealt := minf(amount, hp)
	hp -= dealt
	changed.emit(hp, max_hp)
	if hp <= 0.0:
		died.emit()
	return dealt


func heal(amount: float) -> void:
	if is_dead():
		return
	hp = minf(max_hp, hp + amount)
	changed.emit(hp, max_hp)


func reset() -> void:
	hp = max_hp
	changed.emit(hp, max_hp)


func ratio() -> float:
	return hp / max_hp
