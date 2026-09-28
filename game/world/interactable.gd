class_name Interactable
extends Node3D
## Something the wizard can use with E when standing close: talk, relight a
## ward, lift a trunk... The player focuses the nearest enabled one and the
## HUD shows its prompt.

signal activated(p: Player)

var prompt := "Interact"
var radius := 1.8
var enabled := true
var prompt_height := 1.8


func _ready() -> void:
	add_to_group(&"interactable")


func activate(p: Player) -> void:
	activated.emit(p)


static func make(at: Vector3, text: String, r: float = 1.8, h: float = 1.8) -> Interactable:
	var it := Interactable.new()
	it.prompt = text
	it.radius = r
	it.prompt_height = h
	it.position = at
	return it
