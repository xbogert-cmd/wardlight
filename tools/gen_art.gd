extends SceneTree
## Regenerates all static art into res://assets/generated/.
## godot --headless --path . --script tools/gen_art.gd
## Then run `godot --headless --path . --import` so Godot picks the files up.

const OUT := "res://assets/generated/"
const Enemies = preload("res://tools/art/enemies_art.gd")
const Fx = preload("res://tools/art/fx_art.gd")
const Icons = preload("res://tools/art/icons_art.gd")
const Props = preload("res://tools/art/props_art.gd")
const W3 = preload("res://tools/art/world3d_art.gd")
const Npcs = preload("res://tools/art/npcs_art.gd")
const Bgs = preload("res://tools/art/backgrounds_art.gd")
const Bosses = preload("res://tools/art/bosses_art.gd")
const ItemsArt = preload("res://tools/art/items_art.gd")
const Hollow = preload("res://tools/art/hollow_art.gd")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var t0 := Time.get_ticks_msec()
	var only := OS.get_cmdline_user_args()
	var want := func(k: String) -> bool: return only.is_empty() or only.has(k)
	if want.call("enemies"):
		_save_sheet("hound", Enemies.hound())
		_save_sheet("raider", Enemies.raider())
		_save_sheet("hexer", Enemies.hexer())
		_save_sheet("knot", Enemies.knot())
		_save_sheet("sentinel", Enemies.sentinel())
		_save_sheet("husk", Hollow.husk())
		_save_sheet("lurker", Hollow.lurker())
		_save_sheet("moth", Hollow.moth())
		_save_sheet("spore", Hollow.spore())
		_save_sheet("hollow_seed", Hollow.hollow_seed())
		_save_sheet("tether_knot", Hollow.tether_knot())
	if want.call("bg"):
		# parallax layers for the animated journey screen
		for region in ["woods", "ruins", "lake"]:
			var layers: Dictionary = Bgs.build(region)
			for k in layers:
				(layers[k] as Image).save_png(OUT + "bg_%s_%s.png" % [region, k])
	if want.call("bosses"):
		_save_sheet("troll", Bosses.troll())
		_save_sheet("guardian", Bosses.guardian())
		_save_sheet("herald", Hollow.herald())
		_save_sheet("deepwillow", Hollow.deepwillow())
		_save_sheet("deep_knot", Hollow.deep_knot())
	if want.call("npcs"):
		for n in Npcs.CAST:
			_save_sheet("npc_" + n, Npcs.build(Npcs.CAST[n]))
		_save_sheet("npc_fawn", Npcs.fawn())
		_save_sheet("npc_tamsin", Npcs.shieldbearer())
		_save_sheet("npc_kess", Npcs.scout())
	if want.call("fx"):
		for s in [16, 32, 64]:
			Fx.glow(s).save_png(OUT + "glow%d.png" % s)
		Fx.rune_ring(24, 3).save_png(OUT + "rune24.png")
		Fx.rune_ring(40, 7).save_png(OUT + "rune40.png")
		Fx.rune_ring(64, 11).save_png(OUT + "rune64.png")
		Fx.cloud(96, 40, 5).save_png(OUT + "cloud96.png")
	if want.call("props"):
		var pr: Dictionary = Props.build()
		(pr.image as Image).save_png(OUT + "props_woods.png")
		var f := FileAccess.open(OUT + "props_woods.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(pr.props, "\t"))
	if want.call("w3d"):
		var d := OUT + "w3d/"
		DirAccess.make_dir_recursive_absolute(d)
		W3.grass().save_png(d + "grass.png")
		W3.cobble().save_png(d + "cobble.png")
		W3.dirt().save_png(d + "dirt.png")
		W3.rock().save_png(d + "rock.png")
		W3.bricks(false).save_png(d + "bricks.png")
		W3.bricks(true).save_png(d + "rune_bricks.png")
		W3.wood().save_png(d + "wood.png")
		W3.water().save_png(d + "water.png")
		W3.pine(112, 1).save_png(d + "pine_a.png")
		W3.pine(88, 2).save_png(d + "pine_b.png")
		W3.oak(84, 92, 3).save_png(d + "oak.png")
		W3.dead_tree(60, 104, 4).save_png(d + "dead_tree.png")
		W3.lantern().save_png(d + "lantern.png")
		W3.banner().save_png(d + "banner.png")
		W3.flames().save_png(d + "flames.png")
		W3.castle().save_png(d + "castle.png")
		W3.village_far().save_png(d + "village_far.png")
		W3.thorns().save_png(d + "thorns.png")
		W3.roots().save_png(d + "roots.png")
		W3.spirit().save_png(d + "spirit.png")
		W3.plaster().save_png(d + "plaster.png")
		W3.roof().save_png(d + "roof.png")
		W3.thatch().save_png(d + "thatch.png")
		W3.window(true).save_png(d + "window_lit.png")
		W3.window(false).save_png(d + "window_dark.png")
		W3.door().save_png(d + "door.png")
		W3.signpost().save_png(d + "signpost.png")
		W3.crate().save_png(d + "crate.png")
		W3.barrel().save_png(d + "barrel.png")
		W3.ward_crystal(true).save_png(d + "ward_lit.png")
		W3.ward_crystal(false).save_png(d + "ward_dark.png")
	if want.call("icons"):
		Icons.build().save_png(OUT + "icons.png")
		ItemsArt.build().save_png(OUT + "items.png")
	if want.call("icon"):
		var w := WizardArt.build({})
		var icon := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
		icon.fill(Color.html("1d1830"))
		icon.blend_rect(w.image, Rect2i(8, 0, 64, 64), Vector2i(0, 0))
		icon.resize(256, 256, Image.INTERPOLATE_NEAREST)
		icon.save_png(OUT + "icon.png")
	print("art generated in %d ms" % (Time.get_ticks_msec() - t0))
	quit()


func _save_sheet(sheet_name: String, s: Dictionary) -> void:
	(s.image as Image).save_png(OUT + sheet_name + ".png")
	var meta := {"cell": [s.cell.x, s.cell.y], "hframes": s.hframes, "anims": s.anims}
	var f := FileAccess.open(OUT + sheet_name + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t"))
