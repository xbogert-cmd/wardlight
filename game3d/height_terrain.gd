class_name HeightTerrain
extends Node3D
## Heightfield ground (1 m cells) with a splat map (R = road, G = dirt) and
## trimesh collision. Steep faces render as rock in the shader.

const SHADER := preload("res://game3d/terrain.gdshader")

var origin := Vector2(-40, -40)
var nx := 80
var nz := 80
var h := PackedFloat32Array()


func build(height_fn: Callable, splat_fn: Callable) -> void:
	h.resize((nx + 1) * (nz + 1))
	for z in nz + 1:
		for x in nx + 1:
			h[z * (nx + 1) + x] = height_fn.call(origin.x + x, origin.y + z)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in nz + 1:
		for x in nx + 1:
			st.set_normal(_normal(x, z))
			st.add_vertex(Vector3(origin.x + x, _h(x, z), origin.y + z))
	for z in nz:
		for x in nx:
			var i := z * (nx + 1) + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + nx + 1)
			st.add_index(i + 1)
			st.add_index(i + nx + 2)
			st.add_index(i + nx + 1)
	var mesh := st.commit()
	var splat := Image.create_empty(nx, nz, false, Image.FORMAT_RGBA8)
	for z in nz:
		for x in nx:
			splat.set_pixel(x, z, splat_fn.call(origin.x + x + 0.5, origin.y + z + 0.5))
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var d := "res://assets/generated/w3d/"
	mat.set_shader_parameter(&"grass_tex", load(d + "grass.png"))
	mat.set_shader_parameter(&"path_tex", load(d + "cobble.png"))
	mat.set_shader_parameter(&"dirt_tex", load(d + "dirt.png"))
	mat.set_shader_parameter(&"rock_tex", load(d + "rock.png"))
	mat.set_shader_parameter(&"splat", ImageTexture.create_from_image(splat))
	mat.set_shader_parameter(&"map_origin", origin)
	mat.set_shader_parameter(&"map_size", Vector2(nx, nz))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)
	add_child(body)


func _h(x: int, z: int) -> float:
	return h[clampi(z, 0, nz) * (nx + 1) + clampi(x, 0, nx)]


func _normal(x: int, z: int) -> Vector3:
	return Vector3(_h(x - 1, z) - _h(x + 1, z), 2.0, _h(x, z - 1) - _h(x, z + 1)).normalized()


## Bilinear height at a world position.
func height_at(wx: float, wz: float) -> float:
	var fx := wx - origin.x
	var fz := wz - origin.y
	var x0 := floori(fx)
	var z0 := floori(fz)
	var tx := fx - x0
	var tz := fz - z0
	var a := lerpf(_h(x0, z0), _h(x0 + 1, z0), tx)
	var b := lerpf(_h(x0, z0 + 1), _h(x0 + 1, z0 + 1), tx)
	return lerpf(a, b, tz)
