extends SceneTree
## godot --headless --path . --script tools/preview_wizard.gd
## Writes wizard sheets + an x4 contact sheet to assets/generated/preview/.

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/generated/preview")
	var looks := [
		{},
		{"robe": "mantle", "hat": "hood", "beard": "short", "hair": "short", "hair_color": "black", "complexion": "brown", "staff": "rod"},
		{"robe": "coat", "hat": "none", "beard": "none", "hair": "wild", "hair_color": "auburn", "complexion": "tan", "staff": "fork"},
		{"robe": "wanderer", "hat": "none", "beard": "short", "hair": "braid", "hair_color": "gold", "complexion": "deep", "staff": "crook"},
	]
	var t0 := Time.get_ticks_msec()
	var sheets := []
	for look in looks:
		sheets.append(WizardArt.build(look))
	print("built %d sheets in %d ms" % [looks.size(), Time.get_ticks_msec() - t0])
	(sheets[0].image as Image).save_png("res://assets/generated/preview/wizard_default.png")
	# contact sheet: first frame of each anim for every look, x4
	var anims: Dictionary = sheets[0].anims
	var names := anims.keys()
	var cs := Image.create_empty(names.size() * 80, looks.size() * 64, false, Image.FORMAT_RGBA8)
	cs.fill(Color.html("2a2440"))
	for li in sheets.size():
		var img: Image = sheets[li].image
		for ai in names.size():
			var f: int = sheets[li].anims[names[ai]].frames[0]
			cs.blend_rect(img, Rect2i((f % 16) * 80, (f / 16) * 64, 80, 64), Vector2i(ai * 80, li * 64))
	cs.resize(cs.get_width() * 3, cs.get_height() * 3, Image.INTERPOLATE_NEAREST)
	cs.save_png("res://assets/generated/preview/wizard_contact.png")
	# every frame of default look, x3
	var all := (sheets[0].image as Image).duplicate() as Image
	var bg := Image.create_empty(all.get_width(), all.get_height(), false, Image.FORMAT_RGBA8)
	bg.fill(Color.html("2a2440"))
	bg.blend_rect(all, Rect2i(Vector2i.ZERO, all.get_size()), Vector2i.ZERO)
	bg.resize(bg.get_width() * 2, bg.get_height() * 2, Image.INTERPOLATE_NEAREST)
	bg.save_png("res://assets/generated/preview/wizard_all.png")
	print(names)
	quit()
