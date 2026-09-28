class_name Terrain
## Builds TileMapLayers from ASCII maps using the generated autotile atlas
## (tools/art/tiles_art.gd: 16 neighbour masks × 2 variants per terrain).

const T := 16
const SOLID := {"#": 0, "x": 1, "v": 3, "w": 4}
const PLANK := "="
const PLANK_ROW := 2

static var _tileset: TileSet


static func tileset() -> TileSet:
	if _tileset:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(1, 32)
	ts.set_physics_layer_collision_mask(1, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/generated/tiles.png")
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var full := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	var deck := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, -4), Vector2(-8, -4)])
	var rows := src.texture.get_height() / T
	for row in rows:
		for mask in 16:
			var c := Vector2i(mask, row)
			src.create_tile(c)
			var td := src.get_tile_data(c, 0)
			if row / 2 == PLANK_ROW:
				td.add_collision_polygon(1)
				td.set_collision_polygon_points(1, 0, deck)
				td.set_collision_polygon_one_way(1, 0, true)
			else:
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, full)
	_tileset = ts
	return ts


static func is_solid(lines: PackedStringArray, x: int, y: int) -> bool:
	if y < 0 or y >= lines.size():
		return y >= lines.size()  # below the map counts as ground
	if x < 0 or x >= lines[y].length():
		return true  # map edges count as solid so walls read as continuous
	return SOLID.has(lines[y][x])


static func fill(layer: TileMapLayer, lines: PackedStringArray) -> void:
	layer.tile_set = tileset()
	for y in lines.size():
		var line := lines[y]
		for x in line.length():
			var ch := line[x]
			var v := (x * 7 + y * 13) % 2
			if SOLID.has(ch):
				var m := 0
				if is_solid(lines, x, y - 1): m |= 1
				if is_solid(lines, x + 1, y): m |= 2
				if is_solid(lines, x, y + 1): m |= 4
				if is_solid(lines, x - 1, y): m |= 8
				layer.set_cell(Vector2i(x, y), 0, Vector2i(m, SOLID[ch] * 2 + v))
			elif ch == PLANK:
				var m2 := 0
				if x + 1 < line.length() and line[x + 1] == PLANK: m2 |= 2
				if x > 0 and line[x - 1] == PLANK: m2 |= 8
				layer.set_cell(Vector2i(x, y), 0, Vector2i(m2, PLANK_ROW * 2 + v))
