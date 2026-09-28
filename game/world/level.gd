class_name Level
extends Node2D
## A playable location built from an ASCII map: terrain, backdrop, scenery,
## actors, effects and camera. Terrain legend: see Terrain. Also:
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
	_scatter_scenery()
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


## Natural dressing along flat ground: bushes, ferns, rocks, stumps,
## mushrooms and grass (a few tufts sit in front of actors for depth).
## Deterministic per map so the same place always looks the same.
func _scatter_scenery() -> void:
	var path := "res://assets/generated/props_%s.json" % region
	if not FileAccess.file_exists(path):
		path = "res://assets/generated/props_woods.json"
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var tex: Texture2D = load(path.replace(".json", ".png"))
	var back := Node2D.new()
	back.name = "Scenery"
	back.z_index = -2
	add_child(back)
	var front := Node2D.new()
	front.name = "SceneryFront"
	front.z_index = 4
	add_child(front)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_file.hash()
	var table := [["tuft_a", 14], ["tuft_b", 12], ["tuft_c", 10], ["bush_s", 9], ["bush_l", 6], ["fern", 8],
		["rock_s", 5], ["rock_l", 3], ["shrooms", 4], ["shrooms_red", 2], ["flowers", 5], ["stump", 2],
		["log", 1], ["roots", 3], ["dead_tree", 2], ["", 40]]
	var total := 0
	for e in table:
		total += e[1]
	for top: Dictionary in Terrain.flat_tops(lines):
		var roll := rng.randi_range(0, total - 1)
		var pick := ""
		for e in table:
			roll -= e[1]
			if roll < 0:
				pick = e[0]
				break
		if pick == "" or not props.has(pick):
			continue
		var r: Array = props[pick]
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(r[0], r[1], r[2], r[3])
		var s := Sprite2D.new()
		s.texture = at
		s.centered = false
		s.offset = Vector2(-roundf(r[2] * 0.5), -r[3] + 2)
		s.position = (top.pos as Vector2) + Vector2(rng.randi_range(-4, 4), 0)
		s.flip_h = rng.randf() < 0.5
		var in_front: bool = pick.begins_with("tuft") and rng.randf() < 0.35
		if pick == "dead_tree":
			s.z_index = -1
		(front if in_front else back).add_child(s)


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
