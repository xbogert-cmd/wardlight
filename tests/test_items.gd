extends RefCounted
## Items, fusion, equipment rules, loading safety and the save file.

var t


func test_fusion_rules_and_atomicity() -> void:
	var inv := Inventory.new()
	var a := inv.add(&"moonstone")
	var b := inv.add(&"moonstone")
	var c := inv.add(&"stormglass")
	t.check(inv.fusion_preview(int(a.uid), int(a.uid)).has("error"), "an item can't fuse with itself")
	t.check(inv.fusion_preview(int(a.uid), int(c.uid)).has("error"), "different relics refused")
	t.check(inv.fuse(int(a.uid), 9999).has("error"), "unowned input refused")
	t.eq(inv.items.size(), 3, "refused fusions change nothing")
	inv.equip("relic1", int(a.uid))
	var out := inv.fuse(int(a.uid), int(b.uid))
	t.eq(out.get("tier"), 2, "two tier I make a tier II")
	t.check(not inv.owns(int(a.uid)) and not inv.owns(int(b.uid)), "both inputs consumed")
	t.eq(int(inv.equipped.relic1), 0, "an equipped input is unequipped in the same step")
	t.eq(inv.is_equipped(int(out.uid)), "", "the result starts unworn")
	t.eq(inv.items.size(), 2, "exactly one result")
	var d := inv.add(&"moonstone", 2)
	var hi := inv.fuse(int(out.uid), int(d.uid))
	t.eq(hi.get("tier"), 3, "tier II + II make III")
	var e := inv.add(&"moonstone", 3)
	t.check(inv.fuse(int(hi.uid), int(e.uid)).has("error"), "tier III is the cap")
	var m1 := inv.add(&"ward_bell", 1)
	var m2 := inv.add(&"ward_bell", 2)
	t.check(inv.fuse(int(m1.uid), int(m2.uid)).has("error"), "mixed tiers refused")


func test_equip_rules() -> void:
	var inv := Inventory.new()
	var staff := inv.add(&"stormcoil")
	var robe := inv.add(&"wardweave")
	var r1 := inv.add(&"ember_seed")
	var r2 := inv.add(&"ember_seed")
	t.eq(inv.equip("robe", int(staff.uid)), "That doesn't go there.", "slot kinds are enforced")
	t.eq(inv.equip("staff", int(staff.uid)), "", "staff equips")
	t.eq(inv.equip("robe", int(robe.uid)), "", "robe equips")
	t.eq(inv.equip("relic1", int(r1.uid)), "", "relic equips")
	t.check(inv.equip("relic2", int(r2.uid)) != "", "two of the same relic can't both be worn")
	inv.equip("relic2", int(r1.uid))
	t.eq(int(inv.equipped.relic1), 0, "moving an item between slots leaves no copy behind")
	t.eq(inv.relic_tier(&"ember_seed"), 1, "relic effect reads the worn tier")
	var bonus: Dictionary = staff.bonus
	t.check(bonus.is_empty() or (float(bonus.power) > 0.0 and float(bonus.power) <= 0.08), "staff bonus is capped")


func test_load_drops_unknown_and_dangling() -> void:
	var inv := Inventory.new()
	var a := inv.add(&"moonstone")
	inv.equip("relic1", int(a.uid))
	var d := inv.to_dict()
	d.items.append({"uid": 77, "id": "not_an_item", "tier": 1})
	d.items.append({"uid": int(a.uid), "id": "moonstone", "tier": 1})   # duplicate uid
	d.equipped.staff = 12345
	var inv2 := Inventory.new()
	inv2.from_dict(JSON.parse_string(JSON.stringify(d)))
	t.eq(inv2.items.size(), 1, "unknown ids and duplicate uids dropped")
	t.eq(int(inv2.equipped.staff), 0, "equipment pointing at nothing is cleared")
	t.eq(int(inv2.equipped.relic1), int(a.uid), "valid equipment kept")
	var n := inv2.add(&"stormglass")
	t.check(int(n.uid) > int(a.uid), "new uids never collide with loaded ones")


func test_save_file_validates_and_backs_up() -> void:
	var p: Player = t.make_player("fire")
	await t.frames(2)
	GameState.reset()
	GameState.new_game_kit()
	GameState.wizard_name = "Test"
	SaveSystem.enabled = true
	SaveSystem.delete_all()
	t.eq(SaveSystem.save_now(), "", "first save succeeds")
	GameState.inv.earn(40)
	t.eq(SaveSystem.save_now(), "", "second save succeeds")
	t.check(SaveSystem.has_backup(), "the previous save was kept as a backup")
	var r := SaveSystem.load_main()
	t.eq(r.error, "", "save reads back")
	t.eq(int(r.data.game.inv.coins), 40, "latest progress in the main file")
	t.eq(int(SaveSystem.load_backup().data.game.inv.coins), 0, "older progress in the backup")
	var f := FileAccess.open(SaveSystem.path(), FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	t.check(SaveSystem.load_main().error != "", "a damaged save is reported, not crashed on")
	t.eq(SaveSystem.load_backup().error, "", "the backup still loads")
	SaveSystem.delete_all()
	GameState.reset()
	p.queue_free()


func test_staff_and_robe_fusion() -> void:
	var inv := Inventory.new()
	var a := inv.add(&"stormcoil")
	var b := inv.add(&"stormcoil")
	a.bonus = {"power": 0.02}
	b.bonus = {"power": 0.07}
	inv.equip("staff", int(a.uid))
	var pv := inv.fusion_preview(int(a.uid), int(b.uid))
	t.eq(pv.get("tier"), 2, "two tier I staffs preview a tier II")
	var out := inv.fuse(int(a.uid), int(b.uid))
	t.eq(out.get("tier"), 2, "two tier I staffs make a tier II")
	t.check(not inv.owns(int(a.uid)) and not inv.owns(int(b.uid)), "both staffs consumed")
	t.eq(inv.is_equipped(int(out.uid)), "staff", "a worn staff's result is worn in its place")
	t.near(float(out.bonus.get("power", 0.0)), 0.07, "the better random bonus is kept")
	t.eq(Items.display(out), "Stormcoil Staff II", "tier shows in the name")
	var r1 := inv.add(&"wardweave", 3)
	var r2 := inv.add(&"wardweave", 3)
	t.check(inv.fuse(int(r1.uid), int(r2.uid)).has("error"), "robes stop at tier III")
	var c1 := inv.add(&"crook")
	var c2 := inv.add(&"crook")
	t.check(inv.fusion_preview(int(c1.uid), int(c2.uid)).has("error"), "the plain crook can't be fused")
	t.check(inv.fusion_preview(int(out.uid), int(r1.uid)).has("error"), "a staff and a robe can't be fused")
	var count := inv.items.size()
	inv.fuse(int(c1.uid), int(c2.uid))
	t.eq(inv.items.size(), count, "a refused fusion changes nothing")
	t.eq(Items.display(c1), "Wanderer's Crook", "tier I staffs show no numeral")


func test_fusion_partners() -> void:
	var inv := Inventory.new()
	var a := inv.add(&"moonstone")
	t.check(not inv.any_pair(), "one relic is not a pair")
	var b := inv.add(&"moonstone")
	t.check(inv.has_partner(int(a.uid)) and inv.has_partner(int(b.uid)), "both halves of a pair are marked")
	t.check(inv.any_pair(), "a pair is found")
	var hi1 := inv.add(&"ward_bell", 3)
	var hi2 := inv.add(&"ward_bell", 3)
	t.check(not inv.has_partner(int(hi1.uid)) and not inv.has_partner(int(hi2.uid)), "tier III items have nothing to fuse into")
	var c1 := inv.add(&"crook")
	inv.add(&"crook")
	t.check(not inv.has_partner(int(c1.uid)), "plain items are never marked")
	var s := inv.add(&"stormcoil", 1)
	inv.add(&"stormcoil", 2)
	t.check(not inv.has_partner(int(s.uid)), "different tiers are not partners")


func test_tier_mult() -> void:
	var inv := Inventory.new()
	t.near(inv.tier_mult("staff"), 1.0, "an empty slot counts as tier I")
	var s := inv.add(&"gravewood", 2)
	inv.equip("staff", int(s.uid))
	t.near(inv.tier_mult("staff"), 1.5, "tier II is x1.5")
	var r := inv.add(&"mistcloak", 3)
	inv.equip("robe", int(r.uid))
	t.near(inv.tier_mult("robe"), 2.0, "tier III is x2")
