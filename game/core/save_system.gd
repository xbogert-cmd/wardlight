extends Node
## One versioned save slot in user://. Writes go to a temporary file that is
## read back and validated before the previous save is kept as a backup and
## the new one takes its place, so an interrupted write never destroys
## progress. Scripted demo runs use their own slot.

signal saved

const VERSION := 1

var enabled := true
var _pending := false


func _base() -> String:
	return "user://demo_save" if " ".join(OS.get_cmdline_user_args()).contains("--demo") else "user://wardlight_save"


func path() -> String:
	return _base() + ".json"


func backup_path() -> String:
	return _base() + ".bak.json"


func has_save() -> bool:
	return FileAccess.file_exists(path())


func has_backup() -> bool:
	return FileAccess.file_exists(backup_path())


## Everything permanent: adventure state plus the wizard's spells.
func snapshot() -> Dictionary:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	return {"version": VERSION, "saved_at": Time.get_datetime_string_from_system(), "game": GameState.to_dict(),
		"wizard": p.wiz.to_dict() if p else {}}


## Save now. Returns "" on success or an error message.
func save_now() -> String:
	if not enabled:
		return ""
	var text := JSON.stringify(snapshot(), "\t")
	var tmp := _base() + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return "Could not write the save file."
	f.store_string(text)
	f.close()
	# validate what actually reached the disk before replacing anything
	var check := read_file(tmp)
	if check.has("error"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return "The save didn't verify; your previous save was kept."
	var dir := DirAccess.open("user://")
	if has_save() and read_file(path()).get("error", "") == "":
		dir.copy(path(), backup_path())
	dir.rename(tmp, path())
	saved.emit()
	return ""


## Coalesce bursts of autosave requests into one save at the end of the frame.
func autosave() -> void:
	if enabled and not _pending:
		_pending = true
		(func() -> void:
			_pending = false
			save_now()).call_deferred()


## {"data": Dictionary} or {"error": message}.
func read_file(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {"error": "No save found."}
	var text := FileAccess.get_file_as_string(p)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"error": "The save file is damaged."}
	var d: Dictionary = parsed
	if int(d.get("version", 0)) > VERSION:
		return {"error": "This save comes from a newer version of Wardlight."}
	if not (d.get("game") is Dictionary) or not (d.get("wizard") is Dictionary):
		return {"error": "The save file is incomplete."}
	return {"data": d, "error": ""}


func load_main() -> Dictionary:
	return read_file(path())


func load_backup() -> Dictionary:
	return read_file(backup_path())


## Apply a loaded save to GameState (the wizard is applied by Main).
func apply(d: Dictionary) -> void:
	GameState.from_dict(d.game)


## Keep a damaged save aside (never silently overwrite it).
func quarantine() -> void:
	if has_save():
		DirAccess.open("user://").rename(path(), _base() + ".corrupt.json")


func delete_all() -> void:
	var dir := DirAccess.open("user://")
	for p in [path(), backup_path()]:
		if FileAccess.file_exists(p):
			dir.remove(p.get_file())
