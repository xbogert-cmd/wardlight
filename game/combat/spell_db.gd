class_name SpellDB
## Loads every SpellData in res://data/spells by stable id.

static var _spells := {}


static func all() -> Dictionary:
	if _spells.is_empty():
		var dir := DirAccess.open("res://data/spells")
		for f in dir.get_files():
			f = f.trim_suffix(".remap")
			if f.ends_with(".tres") or f.ends_with(".res"):
				var s: SpellData = load("res://data/spells/" + f)
				_spells[s.id] = s
	return _spells


static func get_spell(id: StringName) -> SpellData:
	return all().get(id)


static func exists(id: StringName) -> bool:
	return all().has(id)
