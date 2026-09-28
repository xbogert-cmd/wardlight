extends Node2D
## Minimal test runner (no framework). Runs every tests/test_*.gd file's
## test_* methods. Each test gets a fresh `world` node inside the scene tree.
## godot --headless --path . res://tests/run_tests.tscn
## Prints "TESTS PASSED n" or lists failures; exit code 1 on failure.

var failures: Array[String] = []
var current := ""
var world: Node2D


func _ready() -> void:
	var total := 0
	var dir := DirAccess.open("res://tests")
	var files := Array(dir.get_files()).filter(func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and f != "test_runner.gd")
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		var suite: Object = script.new()
		for m in suite.get_method_list():
			var name: String = m.name
			if not name.begins_with("test_"):
				continue
			total += 1
			current = f.get_basename() + "." + name
			world = Node2D.new()
			add_child(world)
			suite.set("t", self)
			var before := failures.size()
			await suite.call(name)
			world.queue_free()
			await get_tree().process_frame
			TimeCtl.clear_all()
			if failures.size() == before:
				print("  ok  ", current)
	if failures.is_empty():
		print("TESTS PASSED %d" % total)
		get_tree().quit(0)
	else:
		for fl in failures:
			printerr("FAIL ", fl)
		print("TESTS FAILED %d of %d" % [failures.size(), total])
		get_tree().quit(1)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append("%s: %s" % [current, msg])


func eq(a: Variant, b: Variant, msg: String) -> void:
	check(a == b, "%s (got %s, expected %s)" % [msg, str(a), str(b)])


func near(a: float, b: float, msg: String) -> void:
	check(absf(a - b) < 0.01, "%s (got %s, expected %s)" % [msg, str(a), str(b)])


## Helpers that build real game objects inside the test world.
func make_player(school: String = "storm") -> Player:
	var p := Player.new()
	p.wiz.setup(school)
	world.add_child(p)
	p.global_position = Vector2(100, 100)
	return p


func make_enemy(pos: Vector2) -> Enemy:
	var e: Enemy = preload("res://game/enemies/hound.gd").new()
	e.data = preload("res://data/enemies/hound.tres")
	world.add_child(e)
	e.global_position = pos
	e.set_physics_process(false)
	return e


func frames(n: int) -> void:
	for k in n:
		await get_tree().physics_frame
