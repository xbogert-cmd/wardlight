class_name SheetFrames
## Builds SpriteFrames from a generated sheet (png + json written by tools/gen_art.gd).

static var _cache := {}


static func load_sheet(sheet: String) -> SpriteFrames:
	if _cache.has(sheet):
		return _cache[sheet]
	var tex: Texture2D = load("res://assets/generated/%s.png" % sheet)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/%s.json" % sheet))
	var sf := from_texture(tex, Vector2i(int(meta.cell[0]), int(meta.cell[1])), int(meta.hframes), meta.anims)
	_cache[sheet] = sf
	return sf


static func from_texture(tex: Texture2D, cell: Vector2i, hframes: int, anims: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	for a: String in anims:
		var info: Dictionary = anims[a]
		sf.add_animation(a)
		sf.set_animation_speed(a, info.fps)
		sf.set_animation_loop(a, info.loop)
		for f in info.frames:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((int(f) % hframes) * cell.x, (int(f) / hframes) * cell.y, cell.x, cell.y)
			sf.add_frame(a, at)
	return sf
