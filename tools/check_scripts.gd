extends Node
## Loads every script and resource under res://game, res://data and res://tools
## so parse errors surface in one pass. Prints "CHECK OK n" on success.
## godot --headless --path . res://tools/check_scripts.tscn   (runs with autoloads)

var count := 0
var failed := 0


func _ready() -> void:
	for root in ["res://game", "res://game3d", "res://data", "res://tools"]:
		_scan(root)
	print("CHECK %s %d files, %d failed" % ["OK" if failed == 0 else "FAILED", count, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _scan(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_scan(dir + "/" + sub)
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tres"):
			if f == "check_scripts.gd":
				continue
			count += 1
			var r := ResourceLoader.load(dir + "/" + f, "", ResourceLoader.CACHE_MODE_IGNORE)
			if r == null or (r is GDScript and not (r as GDScript).can_instantiate()):
				failed += 1
				printerr("FAILED: ", dir + "/" + f)
