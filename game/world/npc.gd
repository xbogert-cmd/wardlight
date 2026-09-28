class_name Npc
extends Interactable
## A villager or traveller: side-view sprite from a generated npc_* sheet,
## turns toward the wizard, gestures while talking. `on_talk` runs the
## conversation (the region sets it, usually awaiting Dialogue).

const PX := 1.0 / 24.0

var sheet := "pell"
var display := "Pell"
var on_talk: Callable
var sprite: PixelBillboard
var facing := 1
var talking := false
var walk_to := Vector3.INF
var walk_speed := 2.0


func _ready() -> void:
	super._ready()
	if prompt == "Interact":
		prompt = "Talk to " + display
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/npc_%s.json" % sheet))
	var cell := Vector2i(int(meta.cell[0]), int(meta.cell[1]))
	sprite = PixelBillboard.new()
	sprite.setup(load("res://assets/generated/npc_%s.png" % sheet), cell, int(meta.hframes), meta.anims, Vector2(cell.x * 0.5 - 1, cell.y - 2))
	add_child(sprite)
	sprite.play(&"idle")
	add_child(BlobShadow.make(0.7))
	var body := StaticBody3D.new()
	body.collision_layer = 64   # blocks the wizard, not spells
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.3
	sh.height = 1.6
	cs.shape = sh
	cs.position.y = 0.8
	body.add_child(cs)
	add_child(body)
	activated.connect(_talk)


func _talk(p: Player) -> void:
	if talking:
		return
	talking = true
	_face(p.global_position)
	sprite.play(&"talk")
	if on_talk.is_valid():
		await on_talk.call()
	sprite.play(&"idle")
	talking = false


func _face(at: Vector3) -> void:
	var dx := at.x - global_position.x
	if absf(dx) > 0.1:
		facing = int(signf(dx))
	sprite.set_flip(facing < 0)


func _physics_process(delta: float) -> void:
	if walk_to != Vector3.INF:
		var d := walk_to - global_position
		d.y = 0.0
		if d.length() < 0.1:
			walk_to = Vector3.INF
			sprite.play(&"idle")
		else:
			var step := d.normalized() * minf(walk_speed * delta, d.length())
			global_position += step
			global_position.y = SpellEffect.ground_at(global_position, self).y
			_face(global_position + step)
			sprite.play(&"walk")
		return
	if talking:
		return
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	if p and SpellEffect.flat(p.global_position, global_position) < 4.0:
		_face(p.global_position)
