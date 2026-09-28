class_name Level
extends Node2D
## A playable location built from an ASCII map: terrain, backdrop, actors,
## effects and camera. Map legend (data/maps/*.txt):
##   # ruin stone   x earth   v village stone   w ward stone   = plank (one-way)
##   P player start   h Gloamhound

signal player_respawned

const ENEMIES := {
	"h": [preload("res://game/enemies/hound.gd"), preload("res://data/enemies/hound.tres")],
}

@export var map_file := "res://data/maps/arena.txt"
@export var region := "woods"
@export var music := "explore"
@export var display_name := "Briarwood Edge"

var lines: PackedStringArray
var terrain: TileMapLayer
var actors: Node2D
var fx: FX
var camera: GameCamera
var player: Player
var spawn_point := Vector2.ZERO
var checkpoint := Vector2.ZERO
var size_px := Vector2.ZERO
var _enemy_spawns: Array = []


func _ready() -> void:
	lines = FileAccess.get_file_as_string(map_file).strip_edges(false, true).split("\n")
	var bg := ParallaxBG.new()
	bg.region = region
	add_child(bg)
	terrain = TileMapLayer.new()
	terrain.name = "Terrain"
	add_child(terrain)
	Terrain.fill(terrain, lines)
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	fx = FX.new()
	fx.name = "FX"
	add_child(fx)
	var w := 0
	for y in lines.size():
		w = maxi(w, lines[y].length())
		for x in lines[y].length():
			var ch := lines[y][x]
			var pos := Vector2(x * Terrain.T + Terrain.T * 0.5, (y + 1) * Terrain.T)
			if ch == "P":
				spawn_point = pos
			elif ENEMIES.has(ch):
				_enemy_spawns.append([ch, pos])
	size_px = Vector2(w * Terrain.T, lines.size() * Terrain.T)
	checkpoint = spawn_point
	camera = GameCamera.new()
	camera.limit_left = 0
	camera.limit_right = int(size_px.x)
	camera.limit_bottom = int(size_px.y)
	camera.limit_top = int(size_px.y) - 2000
	add_child(camera)
	_spawn_enemies()


func enter(p: Player) -> void:
	player = p
	if p.get_parent():
		p.reparent(actors)
	else:
		actors.add_child(p)
	p.global_position = spawn_point
	camera.target = p
	camera.snap_to_target()
	if not p.died.is_connected(_on_player_died):
		p.died.connect(_on_player_died)
	Sfx.music(music)


func _spawn_enemies() -> void:
	for s in _enemy_spawns:
		var def: Array = ENEMIES[s[0]]
		var e: Enemy = def[0].new()
		e.data = def[1]
		e.position = s[1]
		actors.add_child(e)


func _on_player_died() -> void:
	await get_tree().create_timer(1.6).timeout
	# checkpoint: restore health/mana and reset the nearby encounter
	for e in get_tree().get_nodes_in_group(&"enemy"):
		e.queue_free()
	for n in actors.get_children():
		if n is Area2D:
			n.queue_free()
	await get_tree().process_frame
	_spawn_enemies()
	player.respawn_at(checkpoint)
	camera.snap_to_target()
	player_respawned.emit()
	if OS.get_cmdline_user_args().has("--trace"):
		print("respawned; enemies=", get_tree().get_nodes_in_group(&"enemy").size(), " hp=", player.health.hp)
