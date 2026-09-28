class_name Loot
extends Node3D
## A pickup on the ground: coins (drawn to the wizard) or an item (walk over
## it). Items pop out with a glow and a light pillar so discoveries read.

const ICONS := preload("res://assets/generated/items.png")
const COIN_ICON := 13

var item_id := &""
var tier := 1
var coins := 0
var velocity := Vector3.ZERO
var _t := 0.0
var _icon: PixelBillboard
var _lamp: OmniLight3D


static func item(parent: Node, at: Vector3, id: StringName, t: int = 1) -> Loot:
	var l := Loot.new()
	l.item_id = id
	l.tier = t
	l.velocity = Vector3(randf_range(-1.5, 1.5), 4.5, randf_range(-1.5, 1.5))
	parent.add_child(l)
	l.global_position = at
	return l


static func coin(parent: Node, at: Vector3, amount: int) -> Loot:
	var l := Loot.new()
	l.coins = amount
	l.velocity = Vector3(randf_range(-2.5, 2.5), randf_range(3.5, 5.5), randf_range(-2.5, 2.5))
	parent.add_child(l)
	l.global_position = at
	return l


func _ready() -> void:
	var icon: int = COIN_ICON if coins > 0 else int(Items.def(item_id).get("icon", 0))
	_icon = PixelBillboard.new()
	_icon.setup(ICONS, Vector2i(16, 16), 14, {}, Vector2(8, 16))
	_icon._apply(icon)
	_icon.mat.set_shader_parameter(&"emit", 0.8)
	_icon.scale = Vector3.ONE * (0.6 if coins > 0 else 1.0)
	add_child(_icon)
	if coins == 0:
		add_child(FX3.make_glow(FX3.GLOW_M, Color(1.0, 0.85, 0.5, 0.7), 1.0))
		_lamp = OmniLight3D.new()
		_lamp.light_color = Color(1.0, 0.85, 0.5)
		_lamp.light_energy = 1.5
		_lamp.omni_range = 3.0
		add_child(_lamp)


func _physics_process(delta: float) -> void:
	_t += delta
	var p := get_tree().get_first_node_in_group(&"player") as Player
	var ground := SpellEffect.ground_at(global_position, self).y
	if coins > 0 and p and p.is_alive() and _t > 0.4 and SpellEffect.flat(p.global_position, global_position) < p.tuning.mote_pickup_radius:
		velocity = velocity.move_toward((p.center() - global_position).normalized() * 11.0, 45.0 * delta)
	else:
		velocity.y -= 17.0 * delta
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
		if global_position.y + velocity.y * delta < ground + 0.1 and velocity.y < 0.0:
			global_position.y = ground + 0.1
			velocity.y = -velocity.y * 0.3 if velocity.y < -1.5 else 0.0
	global_position += velocity * delta
	_icon.position.y = 0.15 + roundf(sin(_t * 4.0) * 1.5) * FX3.PX
	if coins == 0 and randf() < delta * 8.0:
		FX3.burst(global_position + Vector3(randf_range(-0.2, 0.2), 0.1, randf_range(-0.2, 0.2)), 1, [Color("fff0c0"), Color("f0c870"), Color("a07840")],
			Vector2(0.4, 1.2), Vector2(0.5, 0.9), {"dir": Vector3.UP, "spread": 0.2})
	if p and p.is_alive() and _t > 0.5 and SpellEffect.flat(p.global_position, global_position) < (0.6 if coins > 0 else 0.9):
		_collect(p)


func _collect(p: Player) -> void:
	if coins > 0:
		GameState.inv.earn(coins)
		Sfx.play("mote", -6.0, 0.2)
		FX3.burst(global_position + Vector3(0, 0.3, 0), 5, [Color("fff0a0"), Color("f0c850"), Color("a88830")], Vector2(0.5, 1.5), Vector2(0.2, 0.4))
	else:
		var inst := GameState.inv.add(item_id, tier)
		if inst.is_empty():
			return   # bags full: leave it where it lies
		Sfx.play("perfect_dodge", -2.0)
		FX3.ring(global_position + Vector3(0, 0.05, 0), 0.1, 1.2, 0.35, [Color("fff0c0"), Color("f0c870"), Color("a07840")], 1.0)
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.toast("Found: " + Items.display(inst))
		SaveSystem.autosave()
	queue_free()
