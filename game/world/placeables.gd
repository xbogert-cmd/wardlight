class_name Placeables
## The six home objects: complete pieces, not walls and roofs. Each is built
## as one Node3D (meshes + a solid footprint) so it can be placed, moved,
## previewed as a ghost or removed.

const D := "res://assets/generated/w3d/"
const PROP_SHADER := preload("res://game3d/prop.gdshader")

## id -> {name, cost (coins), size (footprint x, z in metres)}
const DEFS := {
	&"lantern": {"name": "Lantern post", "cost": 5, "size": Vector2(0.8, 0.8)},
	&"bench": {"name": "Bench", "cost": 8, "size": Vector2(1.8, 0.8)},
	&"planter": {"name": "Planter", "cost": 6, "size": Vector2(1.4, 1.0)},
	&"tent": {"name": "Tent", "cost": 15, "size": Vector2(2.4, 2.2)},
	&"bookshelf": {"name": "Bookshelf", "cost": 20, "size": Vector2(1.4, 0.7)},
	&"hut": {"name": "Gatewood hut", "cost": 40, "size": Vector2(3.2, 2.8)},
}
const ORDER := [&"lantern", &"bench", &"planter", &"tent", &"bookshelf", &"hut"]


static func footprint(id: StringName, rot: int) -> Vector2:
	var s: Vector2 = DEFS[id].size
	return Vector2(s.y, s.x) if rot % 2 == 1 else s


static func _box(parent: Node3D, size: Vector3, pos: Vector3, tex: String, tint := Color.WHITE, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := ShaderMaterial.new()
	mat.shader = PROP_SHADER
	mat.set_shader_parameter(&"tex", load(D + tex))
	mat.set_shader_parameter(&"tint", tint)
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	parent.add_child(m)
	return m


static func _bill(parent: Node3D, tex: Texture2D, pos: Vector3, scale := 1.0) -> PixelBillboard:
	var b := PixelBillboard.still(tex)
	b.position = pos
	b.scale = Vector3.ONE * scale
	parent.add_child(b)
	return b


## Build `id` as a node (origin at its footprint centre on the ground).
static func build(id: StringName, rot: int, solid := true) -> Node3D:
	var n := Node3D.new()
	n.set_meta(&"id", id)
	var inner := Node3D.new()
	inner.rotation.y = rot * PI / 2
	n.add_child(inner)
	match id:
		&"lantern":
			_box(inner, Vector3(0.2, 3.0, 0.2), Vector3(0, 1.5, 0), "wood.png")
			_box(inner, Vector3(0.9, 0.12, 0.12), Vector3(0.4, 2.9, 0), "wood.png")
			var lan := _bill(n, load(D + "lantern.png"), Vector3(0.8, 2.25, 0).rotated(Vector3.UP, rot * PI / 2))
			lan.mat.set_shader_parameter(&"emit", 1.0)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.56, 0.24)
			l.light_energy = 2.6
			l.omni_range = 6.0
			l.position = lan.position + Vector3(0, 0, 0.3)
			n.add_child(l)
		&"bench":
			_box(inner, Vector3(1.8, 0.12, 0.55), Vector3(0, 0.5, 0), "wood.png", Color(0.9, 0.75, 0.6))
			_box(inner, Vector3(1.8, 0.5, 0.1), Vector3(0, 0.85, -0.25), "wood.png", Color(0.85, 0.7, 0.55))
			for x: float in [-0.75, 0.75]:
				_box(inner, Vector3(0.12, 0.5, 0.5), Vector3(x, 0.25, 0), "wood.png", Color(0.7, 0.55, 0.45))
		&"planter":
			_box(inner, Vector3(1.4, 0.45, 1.0), Vector3(0, 0.22, 0), "wood.png", Color(0.75, 0.6, 0.5))
			_box(inner, Vector3(1.2, 0.08, 0.8), Vector3(0, 0.46, 0), "dirt.png")
			var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/props_woods.json"))
			for k in 3:
				var r: Array = props["flowers" if k != 1 else "fern"]
				var tex: Texture2D = load("res://assets/generated/props_woods.png")
				var b := PixelBillboard.new()
				b.setup(tex, Vector2i(r[2], r[3]), 1, {}, Vector2(r[2] * 0.5, r[3]))
				var tw := float(tex.get_width())
				var th := float(tex.get_height())
				b.mat.set_shader_parameter(&"region", Vector4(r[0] / tw, r[1] / th, r[2] / tw, r[3] / th))
				b.position = Vector3(-0.4 + k * 0.4, 0.5, 0).rotated(Vector3.UP, rot * PI / 2)
				n.add_child(b)
		&"tent":
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var hw := 1.2
			var hd := 1.1
			var h := 1.7
			# two canvas slopes meeting at a ridge along x, clockwise from outside
			for side: float in [1.0, -1.0]:
				st.set_normal(Vector3(0, hd, h * side).normalized())
				var a := Vector3(-hw, 0, hd * side)
				var b := Vector3(hw, 0, hd * side)
				var ra := Vector3(-hw, h, 0)
				var rb := Vector3(hw, h, 0)
				var tri := [a, rb, b, a, ra, rb] if side > 0 else [b, ra, a, b, rb, ra]
				for v: Vector3 in tri:
					st.add_vertex(v)
			for side: float in [1.0, -1.0]:
				st.set_normal(Vector3(side, 0, 0))
				var tri2 := [Vector3(hw * side, 0, -hd), Vector3(hw * side, 0, hd), Vector3(hw * side, h, 0)]
				if side < 0:
					tri2.reverse()
				for v: Vector3 in tri2:
					st.add_vertex(v)
			var m := MeshInstance3D.new()
			m.mesh = st.commit()
			var mat := ShaderMaterial.new()
			mat.shader = PROP_SHADER
			mat.set_shader_parameter(&"tex", load(D + "plaster.png"))
			mat.set_shader_parameter(&"tint", Color(0.85, 0.7, 0.5))
			m.material_override = mat
			inner.add_child(m)
			_box(inner, Vector3(0.1, 1.9, 0.1), Vector3(-hw - 0.05, 0.95, 0), "wood.png")
			_box(inner, Vector3(0.1, 1.9, 0.1), Vector3(hw + 0.05, 0.95, 0), "wood.png")
		&"bookshelf":
			_box(inner, Vector3(1.4, 2.0, 0.5), Vector3(0, 1.0, 0), "wood.png", Color(0.7, 0.5, 0.4))
			for k in 3:
				_box(inner, Vector3(1.2, 0.35, 0.06), Vector3(0, 0.45 + k * 0.55, 0.23), "rune_bricks.png", Color(0.9, 0.6, 0.5).lerp(Color(0.5, 0.6, 0.9), k / 2.0))
		&"hut":
			_box(inner, Vector3(3.0, 2.2, 2.6), Vector3(0, 1.1, 0), "wood.png", Color(0.85, 0.72, 0.6))
			_box(inner, Vector3(3.5, 0.25, 3.1), Vector3(0, 2.3, 0), "thatch.png", Color(1, 1, 1), Vector3(0, 0, 0))
			_box(inner, Vector3(2.6, 0.9, 2.2), Vector3(0, 2.8, 0), "thatch.png", Color(0.95, 0.95, 0.95))
			var door := _bill(n, load(D + "door.png"), Vector3(0, -0.05, 1.33).rotated(Vector3.UP, rot * PI / 2))
			door.mat.set_shader_parameter(&"depth_bias", 0.02)
			var win := _bill(n, load(D + "window_lit.png"), Vector3(0.9, 1.1, 1.33).rotated(Vector3.UP, rot * PI / 2))
			win.mat.set_shader_parameter(&"depth_bias", 0.02)
			win.mat.set_shader_parameter(&"emit", 1.2)
	if solid:
		var fp := footprint(id, rot)
		var body := StaticBody3D.new()
		body.collision_layer = 64   # blocks the wizard, not spells
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(fp.x, 2.0, fp.y)
		cs.shape = sh
		cs.position.y = 1.0
		body.add_child(cs)
		n.add_child(body)
	return n


## Tint every mesh/billboard (ghost preview: green ok, red blocked).
static func tint(n: Node, col: Color) -> void:
	for c in n.get_children():
		if c is PixelBillboard:
			(c as PixelBillboard).set_tint(col)
		elif c is MeshInstance3D and (c as MeshInstance3D).material_override is ShaderMaterial:
			((c as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter(&"tint", col)
		tint(c, col)
