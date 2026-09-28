class_name BlobShadow
extends MeshInstance3D
## Soft dithered shadow under a sprite (billboards cast no real shadows).

static var _tex: Texture2D


static func make(width_m: float) -> BlobShadow:
	if _tex == null:
		var img := Image.create_empty(24, 10, false, Image.FORMAT_RGBA8)
		for y in 10:
			for x in 24:
				var d := Vector2((x + 0.5 - 12.0) / 12.0, (y + 0.5 - 5.0) / 5.0).length()
				if d < 1.0 and ((x + y) % 2 == 0 or d < 0.7):
					img.set_pixel(x, y, Color(0, 0, 0.05, 0.55))
		_tex = ImageTexture.create_from_image(img)
	var s := BlobShadow.new()
	var q := QuadMesh.new()
	q.size = Vector2(width_m, width_m * 0.42)
	q.orientation = PlaneMesh.FACE_Y
	s.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.material_override = m
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.position.y = 0.04
	return s
