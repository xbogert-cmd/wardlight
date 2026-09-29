# Chapter 2 Step 1: Items (tabs, tiers, fusion for all) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Staffs and robes get tiers I–III like relics, the altar fuses any two alike items, the inventory bag is split into Staffs / Robes / Relics tabs, and the game points out fusable pairs.

**Architecture:** Tier rules live in `Items` (data) and `Inventory` (instances, fusion). Effects read `Inventory.tier_mult(slot)` where they already read the staff/robe id. The two UIs (`InventoryUI`, `FusionUI`) share one sorted-list helper, `InventoryUI.tab_items()`. No save format change: every instance already stores `tier` and old saves load as tier 1.

**Tech Stack:** Godot 4.7.1, typed GDScript. Tests: the in-repo runner (`tests/test_*.gd`, methods `test_*`, helpers `t.check / t.eq / t.near / t.make_player / t.make_enemy / t.frames`).

## Global Constraints

- Godot **4.7.1.stable**, typed GDScript: annotate types explicitly (`var x: Type = ...`) when inference is ambiguous; the checker treats inference failures as errors.
- Tier multipliers: tier I ×1, tier II ×1.5, tier III ×2. `Items.MAX_TIER` stays 3.
- Random bonuses stay capped (staff power ≤ 0.08, robe health ≤ 10). Fusion never raises them.
- Fusion keeps the Chapter 1 rules: exact preview, all-or-nothing, equipped inputs are unequipped, relic results start unworn. (Decision in the roadmap: a fused staff/robe goes back into the slot its worn input used.)
- The plain `crook` and `wanderer` are not fusable.
- Do not touch the owner's uncommitted edits in `data/spells/*.tres` or `AGENTS.md`; stage only the files each task names.
- Full check after every task: `tools/dev/check.sh` must print `CHECK OK` and `TESTS PASSED n` (no `FAIL`).

---

### Task 1: Tiered staffs and robes, fusion for every kind

**Files:**
- Modify: `game/items/items.gd`
- Modify: `game/items/inventory.gd` (`fusion_preview`, `fuse`, new `tier_mult`, `has_partner`, `any_pair`)
- Test: `tests/test_items.gd`

**Interfaces:**
- Produces:
  - `Items.TIER_MULT: Array` = `[0.0, 1.0, 1.5, 2.0]` (index = tier)
  - `Items.fusable(id: StringName) -> bool`
  - `Items.display(inst)` now appends the tier numeral for relics always and for staffs/robes above tier I
  - `Inventory.tier_mult(slot: String) -> float` (1.0 for an empty slot)
  - `Inventory.has_partner(uid: int) -> bool` (a same-id, same-tier item exists and the tier is below III)
  - `Inventory.any_pair() -> bool`
  - `Inventory.fusion_preview(a, b)` returns `{"id", "tier", "bonus"}` or `{"error"}`

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_items.gd`:

```gdscript
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `tools/dev/check.sh`
Expected: `SCRIPT ERROR` / `FAIL` lines naming `tier_mult`, `has_partner`, `any_pair` (not defined) and the staff-fusion checks.

- [ ] **Step 3: Implement `Items` changes**

In `game/items/items.gd`:

Replace the header comment's relic line block (lines 3–8) with:

```gdscript
##   staff  - changes the free staff attack (identity) + small spell power
##   robe   - a defensive/movement trait + a little health
##   relic  - one clear effect
## Staffs, robes and relics come in tiers I-III: two alike items of the same
## tier fuse into the next tier. A tier scales the item's effect (relics by
## their RELIC table, staffs and robes by TIER_MULT). The plain starter crook
## and robe have no effect to scale and can't be fused.
```

Mark the two starter items as plain and give the others tiered texts. Replace these `DEFS` entries:

```gdscript
	&"crook": {"kind": "staff", "name": "Wanderer's Crook", "look": {"staff": "crook"}, "icon": 0, "plain": true,
		"text": "A plain travelling staff. It has been everywhere you have."},
	&"stormcoil": {"kind": "staff", "name": "Stormcoil Staff", "look": {"staff": "rod"}, "icon": 1,
		"text": "Staff attacks leap to one more enemy nearby for 50% / 75% / 100% damage."},
	&"cinderbrand": {"kind": "staff", "name": "Cinderbrand Staff", "look": {"staff": "fork"}, "icon": 2,
		"text": "Staff attacks set enemies burning briefly. Tiers II and III burn 1.5x and 2x as hard."},
	&"gravewood": {"kind": "staff", "name": "Gravewood Staff", "look": {"staff": "rod"}, "icon": 3,
		"text": "Staff attacks curse enemies for 2.5 / 3.75 / 5 seconds."},
	# ---------------------------------------------------------------- robes
	&"wanderer": {"kind": "robe", "name": "Wanderer's Robe", "look": {"robe": "wanderer"}, "icon": 4, "plain": true,
		"text": "Red wool, patched at the hem. Warm enough."},
	&"wardweave": {"kind": "robe", "name": "Wardweave Mantle", "look": {"robe": "mantle"}, "icon": 5,
		"text": "Dodging leaves a brief ward: the next hit within 1.5 s is reduced by 40% / 60% / 80%."},
	&"mistcloak": {"kind": "robe", "name": "Mistwalker Coat", "look": {"robe": "coat"}, "icon": 6,
		"text": "Levitate lasts 50% / 75% / 100% longer and dodges travel 12% / 18% / 24% further."},
```

Below `const TIER_NAMES`, add:

```gdscript
## Staff and robe effect strength by tier (index 1..3). Relics use RELIC.
const TIER_MULT := [0.0, 1.0, 1.5, 2.0]
```

Below `static func kind(...)`, add:

```gdscript
## Can two of this item fuse into a higher tier? (Not the plain starter kit.)
static func fusable(id: StringName) -> bool:
	return valid(id) and not def(id).get("plain", false)
```

Replace `static func display(...)` with:

```gdscript
static func display(inst: Dictionary) -> String:
	var d := def(inst.id)
	var n: String = d.get("name", "?")
	var tier := clampi(int(inst.get("tier", 1)), 1, 3)
	if d.get("kind", "") == "relic" or tier > 1:
		n += " " + TIER_NAMES[tier]
	return n
```

- [ ] **Step 4: Implement `Inventory` changes**

In `game/items/inventory.gd`, replace `fusion_preview` and `fuse` with:

```gdscript
## What fusing these two would make, or an error explaining why not.
func fusion_preview(a: int, b: int) -> Dictionary:
	if a == b:
		return {"error": "Choose two different items."}
	var ia := find(a)
	var ib := find(b)
	if ia.is_empty() or ib.is_empty():
		return {"error": "Both items must be yours."}
	if ia.id != ib.id:
		return {"error": "Only two of the same item can be fused."}
	if not Items.fusable(ia.id):
		return {"error": "There is nothing in a plain %s to deepen." % Items.def(ia.id).name}
	if int(ia.tier) != int(ib.tier):
		return {"error": "Both must be the same tier."}
	if int(ia.tier) >= Items.MAX_TIER:
		return {"error": "Tier III is as strong as it can grow."}
	var keep: Dictionary = ia if _bonus_value(ia) >= _bonus_value(ib) else ib
	return {"id": ia.id, "tier": int(ia.tier) + 1, "bonus": (keep.get("bonus", {}) as Dictionary).duplicate()}


## Consume both inputs and create the result in one step. Inputs that were
## worn are taken off as part of it; a relic result starts unworn, but a
## staff or robe result goes back into its slot so the wizard is never left
## without one. The better of the two random bonuses is kept.
func fuse(a: int, b: int) -> Dictionary:
	var pv := fusion_preview(a, b)
	if pv.has("error"):
		return pv
	var rewear := ""
	for s: String in equipped:
		if int(equipped[s]) == a or int(equipped[s]) == b:
			equipped[s] = 0
			if not s.begins_with("relic"):
				rewear = s
	items = items.filter(func(it: Dictionary) -> bool: return int(it.uid) != a and int(it.uid) != b)
	var out := {"uid": next_uid, "id": pv.id, "tier": pv.tier, "bonus": pv.bonus}
	next_uid += 1
	items.append(out)
	if rewear != "":
		equipped[rewear] = out.uid
	changed.emit()
	return out


static func _bonus_value(it: Dictionary) -> float:
	var b: Dictionary = it.get("bonus", {})
	return 0.0 if b.is_empty() else float(b.values()[0])


## Does a same-id, same-tier partner exist that this item could fuse with?
func has_partner(uid: int) -> bool:
	var it := find(uid)
	if it.is_empty() or not Items.fusable(it.id) or int(it.tier) >= Items.MAX_TIER:
		return false
	for o: Dictionary in items:
		if int(o.uid) != uid and o.id == it.id and int(o.tier) == int(it.tier):
			return true
	return false


## ponytail: O(n^2) over at most MAX_ITEMS (40) items; fine at this size.
func any_pair() -> bool:
	return items.any(func(it: Dictionary) -> bool: return has_partner(int(it.uid)))
```

In the `# ---- effects` section, below `func robe_id()`, add:

```gdscript
## Effect strength of the worn staff or robe from its tier (1.0 if empty).
func tier_mult(slot: String) -> float:
	return Items.TIER_MULT[clampi(int(slot_item(slot).get("tier", 1)), 1, Items.MAX_TIER)]
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `tools/dev/check.sh`
Expected: `CHECK OK` and `TESTS PASSED n`, no `FAIL`. The Chapter 1 test `test_fusion_rules_and_atomicity` must still pass unchanged (relic results still start unworn).

- [ ] **Step 6: Commit**

```bash
git add game/items/items.gd game/items/inventory.gd tests/test_items.gd
git commit -m "Staff and robe tiers; the altar rules cover every item kind"
```

---

### Task 2: Tiers scale staff and robe effects

**Files:**
- Modify: `game/combat/cast_context.gd:31-46` (`_staff_identity`)
- Modify: `game/player/player.gd:141` (`float_time`), `:389` (`_dodge`), `:466-469` (ward reduction in the hurt path)
- Test: `tests/test_items.gd`

**Interfaces:**
- Consumes: `Inventory.tier_mult(slot: String) -> float` (Task 1)
- Produces: no new names. Effects at tier I are unchanged from Chapter 1.

- [ ] **Step 1: Write the failing test**

Append to `tests/test_items.gd`:

```gdscript
func test_tiers_scale_equipment_effects() -> void:
	GameState.reset()
	var p: Player = t.make_player("fire")
	await t.frames(2)
	var base := p.float_time()
	var cloak := GameState.inv.add(&"mistcloak", 2)
	GameState.inv.equip("robe", int(cloak.uid))
	t.near(p.float_time(), base * 1.75, "tier II Mistwalker Coat: levitate lasts 75% longer")
	var brand := GameState.inv.add(&"cinderbrand", 3)
	GameState.inv.equip("staff", int(brand.uid))
	var e: Enemy = t.make_enemy(Vector3(2, 0, 0))
	var d := Damage.make(10.0, p, &"fire")
	CastContext.new()._staff_identity(e, d)
	t.near(float(d.statuses[0].power), 6.0, "tier III Cinderbrand burns twice as hard")
	var wood := GameState.inv.add(&"gravewood", 2)
	GameState.inv.equip("staff", int(wood.uid))
	var d2 := Damage.make(10.0, p, &"hex")
	CastContext.new()._staff_identity(e, d2)
	t.near(float(d2.statuses[0].duration), 3.75, "tier II Gravewood curses 1.5x as long")
	GameState.reset()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `tools/dev/check.sh`
Expected: `FAIL test_items.test_tiers_scale_equipment_effects` (float time got `base * 1.5`, burn power got 3.0).

- [ ] **Step 3: Implement**

In `game/combat/cast_context.gd`, replace the body of `_staff_identity` with:

```gdscript
## The equipped staff's signature on staff attacks, scaled by its tier.
func _staff_identity(target_actor: Node3D, d: Damage) -> void:
	var m := GameState.inv.tier_mult("staff")
	match GameState.inv.staff_id():
		&"cinderbrand":
			d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0 * m})
		&"gravewood":
			d.statuses.append({"id": &"curse", "duration": 2.5 * m})
		&"stormcoil":
			if bonus.has("coil"):
				return
			bonus["coil"] = true
			var e := SpellEffect.nearest(target_actor.center(), 3.5, [target_actor], target_actor)
			if e:
				FX3.bolt(target_actor.center(), e.center(), 0.15, Pal.school(&"storm"), 0.12)
				var pd := proc_dmg(d.amount * 0.5 * m, &"storm", &"stormcoil")
				pd.hit_pos = e.center()
				SpellEffect.later(0.05, func() -> void: hit(e, pd))
```

(Delete the old one-line `## The equipped staff's signature on staff attacks.` comment above it.)

In `game/player/player.gd`, replace `float_time`:

```gdscript
func float_time() -> float:
	var inv := GameState.inv
	return tuning.float_time * ((1.0 + 0.5 * inv.tier_mult("robe")) if inv.robe_id() == &"mistcloak" else 1.0)
```

In `_dodge`, replace the `var sp := ...` line with:

```gdscript
	var inv := GameState.inv
	var sp := tuning.dodge_speed * ((1.0 + 0.12 * inv.tier_mult("robe")) if inv.robe_id() == &"mistcloak" else 1.0) * (0.55 + 0.45 * _dodge_t / tuning.dodge_time)
```

and in the same function change `if GameState.inv.robe_id() == &"wardweave":` to `if inv.robe_id() == &"wardweave":`.

In the hurt path, replace `amount *= 0.6` (inside `if _ward_t > 0.0:`) with:

```gdscript
		amount *= 1.0 - 0.4 * GameState.inv.tier_mult("robe")
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `tools/dev/check.sh`
Expected: `CHECK OK`, `TESTS PASSED n`, no `FAIL`.

- [ ] **Step 5: Commit**

```bash
git add game/combat/cast_context.gd game/player/player.gd tests/test_items.gd
git commit -m "Staff and robe effects grow with their tier"
```

---

### Task 3: Inventory tabs and pair markers

**Files:**
- Modify: `game/ui/inventory_ui.gd`
- Test: `tests/test_items.gd`

**Interfaces:**
- Consumes: `Inventory.has_partner(uid)` (Task 1)
- Produces: `static func InventoryUI.tab_items(inv: Inventory, kind: String) -> Array` — that kind's instances, highest tier first, then by name. Task 4 uses it.

- [ ] **Step 1: Write the failing test**

Append to `tests/test_items.gd`:

```gdscript
func test_bag_tabs_sort() -> void:
	var inv := Inventory.new()
	inv.add(&"moonstone", 1)
	inv.add(&"stormcoil")
	inv.add(&"ember_seed", 1)
	inv.add(&"ward_bell", 2)
	inv.add(&"wardweave")
	var relics := InventoryUI.tab_items(inv, "relic")
	t.eq(relics.map(func(it: Dictionary) -> String: return Items.display(it)),
		["Ward Bell II", "Ember Seed I", "Moonstone I"], "relics: tier first, then name")
	t.eq(InventoryUI.tab_items(inv, "staff").size(), 1, "only staffs on the staff tab")
	t.eq(InventoryUI.tab_items(inv, "robe").size(), 1, "only robes on the robe tab")
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `tools/dev/check.sh`
Expected: `SCRIPT ERROR` / `FAIL` naming `tab_items`.

- [ ] **Step 3: Implement**

In `game/ui/inventory_ui.gd`:

Update the header comment:

```gdscript
## Inventory (I): four equipment slots on the left, the bag on the right
## split into Staffs / Robes / Relics tabs (Tab or click to switch; landing
## on an equipment slot shows its tab), details and a comparison with what is
## worn at the bottom. Arrows move, Enter equips/unequips, I/Esc closes; the
## mouse works too. A gold corner marks items that have a fusion partner.
```

Add constants and state below `const SLOT_NAMES`:

```gdscript
const TABS := ["staff", "robe", "relic"]
const TAB_NAMES := {"staff": "Staffs", "robe": "Robes", "relic": "Relics"}
```

and below `var cur := ...`:

```gdscript
var tab := "staff"
```

Replace `_bag()` with:

```gdscript
func _bag() -> Array:
	return tab_items(GameState.inv, tab)


## One tab's items: highest tier first, then by name.
static func tab_items(inv: Inventory, kind: String) -> Array:
	var out := inv.items.filter(func(it: Dictionary) -> bool: return Items.kind(it.id) == kind)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.tier) != int(b.tier):
			return int(a.tier) > int(b.tier)
		return String(Items.def(a.id).name) < String(Items.def(b.id).name))
	return out


func _tab_rect(k: int) -> Rect2:
	return Rect2(PANEL.position + Vector2(200 + k * 56, 26), Vector2(52, 14))


## Move the cursor; an equipment slot shows its own tab.
func _set_cur(c: Vector2i) -> void:
	cur = c
	if c.x < 0:
		tab = "relic" if c.y >= 2 else String(Items.SLOTS[c.y])
```

In `_input`, replace the mouse block with:

```gdscript
	if e is InputEventMouseMotion or (e is InputEventMouseButton and e.pressed):
		var mp := get_local_mouse_position()
		for k in 4:
			if _slot_rect(k).has_point(mp):
				_set_cur(Vector2i(-1, k))
		for y in ROWS:
			for x in COLS:
				if _cell_rect(Vector2i(x, y)).has_point(mp):
					cur = Vector2i(x, y)
		if e is InputEventMouseButton:
			for k in TABS.size():
				if _tab_rect(k).has_point(mp):
					_switch_tab(TABS[k])
			if (e as InputEventMouseButton).double_click:
				_use()
		return
	if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		_switch_tab(TABS[(TABS.find(tab) + 1) % TABS.size()])
		return
```

In the same function, replace the cursor-movement block (`if d != Vector2i.ZERO:` … `Sfx.play("ui_move", -10.0)`) with:

```gdscript
	if d != Vector2i.ZERO:
		get_viewport().set_input_as_handled()
		if cur.x < 0:
			if d.x > 0:
				cur = Vector2i(0, mini(cur.y, ROWS - 1))
			else:
				_set_cur(Vector2i(-1, posmod(cur.y + d.y, 4)))
		else:
			var nx := cur.x + d.x
			if nx < 0:
				_set_cur(Vector2i(-1, mini(cur.y, 3)))
			else:
				cur = Vector2i(mini(nx, COLS - 1), posmod(cur.y + d.y, ROWS))
		Sfx.play("ui_move", -10.0)
```

Add below `_input`:

```gdscript
## Show another tab; the cursor moves into the bag so the slot column
## doesn't switch it straight back.
func _switch_tab(k: String) -> void:
	tab = k
	if cur.x < 0:
		cur = Vector2i(0, 0)
	Sfx.play("ui_move", -10.0)
```

In `_draw`, after the `_t("Coins %d ...` line, add the tab row:

```gdscript
	for k in TABS.size():
		var tr := _tab_rect(k)
		var on: bool = TABS[k] == tab
		HUD.frame(self, tr, HUD.COL_BG, Color("f4d890") if on else HUD.COL_FRAME_DARK)
		_t(TAB_NAMES[TABS[k]], tr.position + Vector2(6, 10), Color("f4d890") if on else Color("8a7a60"))
```

In the bag-cell loop, replace the item-drawing block (from `var i := y * COLS + x` to the equipped marker) with:

```gdscript
			var i := y * COLS + x
			var bag := _bag()
			if i < bag.size():
				var it: Dictionary = bag[i]
				_icon(r, it.id)
				if int(it.tier) > 1:
					_t(Items.TIER_NAMES[int(it.tier)], r.position + Vector2(2, 22), Color("f4d890"))
				if inv.has_partner(int(it.uid)):
					draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(4, 4)), Color("f4d890"))
				if inv.is_equipped(int(it.uid)) != "":
					draw_rect(Rect2(r.end - Vector2(6, 6), Vector2(4, 4)), Color("9ae8ff"))
```

(`_bag()` sorts on each call; hoist `var bag := _bag()` above the `for y in ROWS:` loop instead of inside it.)

In the details block, after the bonus-text lines (`if b != "": ... y += 11`), add:

```gdscript
		if inv.has_partner(int(it.uid)):
			_t("A matching pair: fuse them at the sanctuary altar.", Vector2(dr.position.x + 8, y), Color("f4d890"))
			y += 11
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `tools/dev/check.sh`
Expected: `CHECK OK`, `TESTS PASSED n`, no `FAIL`.

- [ ] **Step 5: Commit**

```bash
git add game/ui/inventory_ui.gd tests/test_items.gd
git commit -m "Inventory tabs for staffs, robes and relics; pair markers"
```

---

### Task 4: The altar fuses every kind; one-time pair hint

**Files:**
- Modify: `game/ui/fusion_ui.gd`
- Modify: `game/ui/hud.gd` (new `fusion_hint`)
- Modify: `game/world/region.gd:751-754` (`give`), `game/items/loot.gd:82-90` (`_collect`)
- Modify: `game/world/sanctuary.gd:166-171` (altar prompt and comment)
- Modify: `game/core/demo_driver.gd` (`"inv"` demo)

**Interfaces:**
- Consumes: `InventoryUI.tab_items` (Task 3), `Items.fusable`, `Inventory.has_partner`, `Inventory.any_pair`, `Inventory.fuse` (Task 1)
- Produces: `HUD.fusion_hint() -> void`

- [ ] **Step 1: Generalise the altar screen**

In `game/ui/fusion_ui.gd`:

Header comment:

```gdscript
## The sanctuary's fusion altar. Pick two alike items (staffs, robes or
## relics of the same tier); the preview shows both (and whether each is
## worn), the exact result and its effect, or why they can't be fused. Enter
## confirms; the fusion commits in one step and saves.
```

Add below `const PANEL`:

```gdscript
const VISIBLE := 12           # list rows on screen; the list scrolls past that
```

and below `var _flash := 0.0`:

```gdscript
var _top := 0                 # first list row on screen
var _bad := false             # the message is an error
```

Replace `_relics()` with:

```gdscript
## Every fusable item: staffs, then robes, then relics, each tier-then-name.
func _items() -> Array:
	var out: Array = []
	for k: String in InventoryUI.TABS:
		out.append_array(InventoryUI.tab_items(GameState.inv, k).filter(func(it: Dictionary) -> bool: return Items.fusable(it.id)))
	return out
```

Rename every other `_relics()` call in the file to `_items()`, and every local `rel` to `items` (in `_input`, `_pick`, `_draw_panel`).

In `_process`, before `canvas.queue_redraw()`, keep the selection on screen:

```gdscript
	var n := _items().size()
	_top = clampi(clampi(_top, sel - VISIBLE + 1, sel), 0, maxi(0, n - VISIBLE))
```

In `_input`'s mouse loop, only test visible rows:

```gdscript
		for k in range(_top, mini(items.size(), _top + VISIBLE)):
			if _row(k - _top).has_point(mp):
```

In `_confirm`, set `_bad = true` next to the error message, and `_bad = false` next to the `"Fused: "` message.

In `_draw_panel`:
- Change the subtitle to `"Two alike items of the same tier become one of the next tier (up to III)."`
- Change the empty text to `"You carry nothing that can be fused."`
- Replace `for k in rel.size():` with `for k in range(_top, mini(items.size(), _top + VISIBLE)):` and `var r := _row(k)` with `var r := _row(k - _top)`.
- After the icon is drawn, add the pair marker:

```gdscript
		if GameState.inv.has_partner(int(it.uid)):
			canvas.draw_rect(Rect2(r.position + Vector2(2, 1), Vector2(3, 3)), Color("f4d890"))
```

- Change `"%s: choose a relic"` to `"%s: choose an item"`.
- Change `"Both are consumed. The result starts unworn."` to:

```gdscript
			var worn_note := "The result starts unworn." if Items.kind(pv.id) == "relic" else "If one was worn, the result is worn."
			_t("Both are consumed. " + worn_note, Vector2(pr.position.x + 8, y), Color("a89878"))
```

- Change the message colour test `Color("f4d890") if not _msg.begins_with("Only") else Color("ff9a8a")` to `Color("ff9a8a") if _bad else Color("f4d890")`.

- [ ] **Step 2: The one-time hint and the altar prompt**

In `game/ui/hud.gd`, below `func toast(...)`:

```gdscript
## One-time nudge the first time two alike items could be fused.
func fusion_hint() -> void:
	if GameState.inv.any_pair() and GameState.once(&"hint_fusion"):
		toast("Two alike: fuse them at the sanctuary altar")
```

In `game/world/region.gd` `give()`, after `reward([...])` (inside the `if`):

```gdscript
		var hud := get_tree().get_first_node_in_group(&"hud") as HUD
		if hud:
			hud.fusion_hint()
```

In `game/items/loot.gd` `_collect()`, directly after `hud.toast("Found: " + Items.display(inst))` (same indent):

```gdscript
			hud.fusion_hint()
```

In `game/world/sanctuary.gd`, change the comment `# fusion altar (relic fusion arrives with stage 4 loot)` to `# fusion altar: two alike items of a tier become the next tier` and the prompt `"Fusion altar"` to `"Fusion altar: fuse two alike items"`.

- [ ] **Step 3: Update the `inv` demo**

In `game/core/demo_driver.gd`, replace the `"inv"` entry with (keys: 4194306 Tab, 4194309 Enter, 4194321 Right, 4194322 Down, 4194305 Esc):

```gdscript
	"inv": [
		[0.3, "give", "stormcoil"], [0.32, "give", "stormcoil"], [0.35, "give", "moonstone"], [0.4, "give", "moonstone"], [0.45, "give", "ward_bell"], [0.5, "give", "wardweave"],
		[0.6, "inventory", ""], [0.9, "shot", "i1_staffs"], [1.0, "key", "4194321"], [1.1, "key", "4194309"], [1.4, "shot", "i2_equipped"],
		[1.5, "key", "4194306"], [1.6, "key", "4194306"], [1.8, "shot", "i2b_relics"],
		[2.0, "key", "4194305"], [2.2, "travel", "sanctuary:start"], [3.4, "tp", "3,-7.8"], [3.7, "tap", "interact"], [4.0, "key", "4194309"],
		[4.2, "key", "4194322"], [4.4, "key", "4194309"], [4.7, "shot", "i3_fusion"], [4.9, "key", "4194309"], [5.3, "shot", "i4_fused"],
		[5.5, "key", "4194305"], [5.9, "state", "inv"], [6.0, "quit", ""],
	],
```

(Rows 0 and 1 at the altar are the two Stormcoil staffs; one is worn, so `i4_fused` should show "Fused: Stormcoil Staff II" and the `state inv` print should list it in the staff slot.)

- [ ] **Step 4: Check and capture**

Run: `tools/dev/check.sh`
Expected: `CHECK OK`, `TESTS PASSED n`, no `FAIL`.

Run: `tools/dev/run.sh /tmp/inv.log 40 --path . -- --demo=inv --shots=/tmp/shots_inv`
Expected: `/tmp/shots_inv/` holds `i1_staffs`, `i2_equipped`, `i2b_relics`, `i3_fusion`, `i4_fused` images; the log's `state inv` line shows a tier-2 `stormcoil` equipped as staff; no `SCRIPT ERROR` in `/tmp/inv.log`.

Open each capture and check: tabs readable and not overlapping the Coins line; gold pair corners on both Stormcoils and both Moonstones; the altar list shows staffs first; the preview says "Becomes: Stormcoil Staff II".

- [ ] **Step 5: Commit**

```bash
git add game/ui/fusion_ui.gd game/ui/hud.gd game/world/region.gd game/items/loot.gd game/world/sanctuary.gd game/core/demo_driver.gd
git commit -m "The altar fuses staffs, robes and relics; one-time pair hint"
```

---

### Task 5: Checklist and hand-off

**Files:**
- Modify: `docs/checklist.md`

- [ ] **Step 1: Record step 1 in the checklist**

Update the `Status:` line to `**Chapter 1 complete. Chapter 2 (The Hollowing) in progress: see docs/superpowers/plans/2026-09-29-chapter2-roadmap.md.**` and append:

```markdown
## Chapter 2 — The Hollowing
- [x] Step 1: inventory tabs (Staffs / Robes / Relics), staff and robe tiers I–III (×1 / ×1.5 / ×2
  effect), the altar fuses any two alike items, pair markers and a one-time hint. The plain starter
  crook and robe can't be fused; a fused staff/robe stays worn; fusion keeps the better bonus.
- [ ] Step 2: `Companion` base, party of two, Kess, sanctuary camp, save v2
- [ ] Step 3: opening, Fenway, Reedhollow, boat travel (look)
- [ ] Step 4: Husk, Mire Lurker, Hollow Moth, hollowed variants (feel)
- [ ] Step 5: Sunken Chapel, Mire, Stilled Grove, lost child (look)
- [ ] Step 6: attack on Reedhollow, the Herald (feel)
- [ ] Step 7: far-watch teaser
- [ ] Step 8: Heart Isle, the Deepwillow, three new spells, ending (look + feel)
- [ ] Step 9: balance, `--demo=story2`, report, Mac build
```

- [ ] **Step 2: Commit and send captures to the owner**

```bash
git add docs/checklist.md
git commit -m "Checklist: Chapter 2 step 1 done"
```

Send the five `/tmp/shots_inv` captures to the owner with a short list of what changed.
