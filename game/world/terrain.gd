class_name Terrain
## Builds TileMapLayers from ASCII maps using the generated atlas
## (tools/art/tiles_art.gd): 16 neighbour masks + 6 slope shapes per terrain.
##
## Solid:  # ruin stone   x earth   r rock   v village stone   w ward stone
## Slopes (take the terrain beneath them):
##   /  \   45° up / down
##   1 2    gentle rise over two tiles (1 = low half, 2 = high half)
##   3 4    gentle fall over two tiles (3 = high half, 4 = low half)

const T := 16
const SOLID := {"#": 0, "x": 1, "r": 2, "v": 3, "w": 4}
const SLOPES := ["/", "\\", "1", "2", "3", "4"]
const MASK_COLS := 16
const SLOPE_POLYS := {
	"/": [Vector2(-8, 8), Vector2(8, -8), Vector2(8, 8)],
	"\\": [Vector2(-8, -8), Vector2(8, 8), Vector2(-8, 8)],
	"1": [Vector2(-8, 8), Vector2(8, 0), Vector2(8, 8)],
	"2": [Vector2(-8, 0), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)],
	"3": [Vector2(-8, -8), Vector2(8, 0), Vector2(8, 8), Vector2(-8, 8)],
	"4": [Vector2(-8, 0), Vector2(8, 8), Vector2(-8, 8)],
}

static var _tileset: TileSet


static func tileset() -> TileSet:
	if _tileset:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/generated/tiles.png")
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var full := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	var rows := src.texture.get_height() / T
	for row in rows:
		for col in MASK_COLS + SLOPES.size():
			var c := Vector2i(col, row)
			src.create_tile(c)
			var td := src.get_tile_data(c, 0)
			td.add_collision_polygon(0)
			if col < MASK_COLS:
				td.set_collision_polygon_points(0, 0, full)
			else:
				td.set_collision_polygon_points(0, 0, PackedVector2Array(SLOPE_POLYS[SLOPES[col - MASK_COLS]]))
	_tileset = ts
	return ts


static func char_at(lines: PackedStringArray, x: int, y: int) -> String:
	if y < 0 or x < 0:
		return "."
	if y >= lines.size():
		return "x"
	if x >= lines[y].length():
		return "."
	return lines[y][x]


## Anything that occupies ground (solid tiles and slopes).
static func is_ground(ch: String) -> bool:
	return SOLID.has(ch) or SLOPES.has(ch)


static func is_solid(lines: PackedStringArray, x: int, y: int) -> bool:
	if y >= lines.size() or x < 0 or (y >= 0 and x >= lines[y].length()):
		return y >= 0  # map edges and below the map count as ground
	return is_ground(char_at(lines, x, y))


## Terrain index for a slope: the first solid tile beneath it.
static func _terrain_below(lines: PackedStringArray, x: int, y: int) -> int:
	for yy in range(y + 1, lines.size()):
		var ch := char_at(lines, x, yy)
		if SOLID.has(ch):
			return SOLID[ch]
	return SOLID["x"]


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
			elif SLOPES.has(ch):
				var tr := _terrain_below(lines, x, y)
				layer.set_cell(Vector2i(x, y), 0, Vector2i(MASK_COLS + SLOPES.find(ch), tr * 2 + v))


## Flat walkable tops: [{pos (world, top-centre), terrain}], used for scenery.
static func flat_tops(lines: PackedStringArray) -> Array:
	var out := []
	for y in lines.size():
		for x in lines[y].length():
			var ch := lines[y][x]
			if SOLID.has(ch) and not is_ground(char_at(lines, x, y - 1)) and y > 0:
				out.append({"pos": Vector2(x * T + T * 0.5, y * T), "terrain": ch, "cell": Vector2i(x, y)})
	return out
