extends Node
## Game root. Owns the persistent player, the HUD and the current level.

const LEVEL := preload("res://game/world/level.gd")

var player: Player
var level: Level
var hud: HUD
var paused_overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	player = Player.new()
	hud = HUD.new()
	add_child(hud)
	load_level("res://data/maps/arena.txt", "woods", "Briarwood Edge")
	player.caster.loadout = [&"arc_lance", &"", &"", &""]
	hud.bind(player)
	_build_pause()


func load_level(map: String, region: String, title: String) -> void:
	if level:
		level.queue_free()
	level = LEVEL.new()
	level.map_file = map
	level.region = region
	level.display_name = title
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	level.enter(player)
	hud.banner(title)


func _build_pause() -> void:
	paused_overlay = Control.new()
	paused_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	paused_overlay.visible = false
	paused_overlay.draw.connect(func() -> void:
		paused_overlay.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.06, 0.6))
		HUD.frame(paused_overlay, Rect2(250, 150, 140, 44))
		paused_overlay.draw_string(HUD.FONT, Vector2(250, 168), "Paused", HORIZONTAL_ALIGNMENT_CENTER, 140, 9, Color("f0e6d0"))
		paused_overlay.draw_string(HUD.FONT, Vector2(250, 184), "Esc to resume", HORIZONTAL_ALIGNMENT_CENTER, 140, 9, Color("a89878")))
	hud.add_child(paused_overlay)


func set_paused(on: bool) -> void:
	get_tree().paused = on
	paused_overlay.visible = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_HIDDEN


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed(&"pause"):
		set_paused(not get_tree().paused)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not get_tree().paused:
		set_paused(true)
