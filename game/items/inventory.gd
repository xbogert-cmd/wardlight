class_name Inventory
extends RefCounted
## Owned item instances, equipment, coins and progression points.
## An instance is {uid, id, tier, bonus}. Every change validates first and
## then commits in one step, so a refused operation leaves everything as it was.

signal changed

const XP_PER_POINT := 100
const MAX_ITEMS := 40

var items: Array = []          # instances
var equipped := {"staff": 0, "robe": 0, "relic1": 0, "relic2": 0}   # slot -> uid (0 empty)
var coins := 0
var xp := 0
var points := 0
var decor := {}                # placeable id -> true (unlocked for building)
var looks := {}                # unlocked cosmetic looks: "robe:mantle" -> true
var next_uid := 1


func find(uid: int) -> Dictionary:
	for it: Dictionary in items:
		if int(it.uid) == uid:
			return it
	return {}


func owns(uid: int) -> bool:
	return not find(uid).is_empty()


func is_equipped(uid: int) -> String:
	for s in equipped:
		if int(equipped[s]) == uid and uid != 0:
			return s
	return ""


func slot_item(slot: String) -> Dictionary:
	return find(int(equipped.get(slot, 0)))


## New instance of `id` (tier 1 unless given). Staffs and robes roll their
## small capped bonus once. Returns {} if the id is unknown or bags are full.
func add(id: StringName, tier: int = 1, rng: RandomNumberGenerator = null) -> Dictionary:
	if not Items.valid(id) or items.size() >= MAX_ITEMS:
		return {}
	var inst := {"uid": next_uid, "id": id, "tier": clampi(tier, 1, Items.MAX_TIER), "bonus": {}}
	next_uid += 1
	var k := Items.kind(id)
	if Items.BONUS.has(k):
		var b: Array = Items.BONUS[k]
		var r := rng
		if r == null:
			r = RandomNumberGenerator.new()
			r.randomize()
		var v := snappedf(r.randf_range(b[1], b[2]), 0.01)
		if v > 0.0:
			inst.bonus = {b[0]: v}
	items.append(inst)
	var d := Items.def(id)
	for key in d.get("look", {}):
		looks["%s:%s" % [key, d.look[key]]] = true
	changed.emit()
	return inst


func equip(slot: String, uid: int) -> String:
	if not equipped.has(slot):
		return "No such slot."
	var inst := find(uid)
	if inst.is_empty():
		return "You don't have that."
	var k := Items.kind(inst.id)
	if (slot.begins_with("relic") and k != "relic") or (not slot.begins_with("relic") and k != slot):
		return "That doesn't go there."
	if k == "relic":
		var other := "relic2" if slot == "relic1" else "relic1"
		var o := slot_item(other)
		if not o.is_empty() and o.id == inst.id and int(o.uid) != uid:
			return "Two of the same relic won't resonate. Fuse them instead."
	var prev := is_equipped(uid)
	if prev != "":
		equipped[prev] = 0
	equipped[slot] = uid
	changed.emit()
	return ""


func unequip(slot: String) -> void:
	if equipped.has(slot):
		equipped[slot] = 0
		changed.emit()


## What fusing these two would make, or an error explaining why not.
func fusion_preview(a: int, b: int) -> Dictionary:
	if a == b:
		return {"error": "Choose two different relics."}
	var ia := find(a)
	var ib := find(b)
	if ia.is_empty() or ib.is_empty():
		return {"error": "Both relics must be yours."}
	if Items.kind(ia.id) != "relic" or Items.kind(ib.id) != "relic":
		return {"error": "Only relics can be fused."}
	if ia.id != ib.id:
		return {"error": "Only two of the same relic can be fused."}
	if int(ia.tier) != int(ib.tier):
		return {"error": "Both relics must be the same tier."}
	if int(ia.tier) >= Items.MAX_TIER:
		return {"error": "Tier III is as strong as a relic can grow."}
	return {"id": ia.id, "tier": int(ia.tier) + 1}


## Consume both inputs and create the result in one step (inputs that were
## equipped are unequipped as part of it; the result starts unequipped).
func fuse(a: int, b: int) -> Dictionary:
	var pv := fusion_preview(a, b)
	if pv.has("error"):
		return pv
	for s in equipped:
		if int(equipped[s]) == a or int(equipped[s]) == b:
			equipped[s] = 0
	items = items.filter(func(it: Dictionary) -> bool: return int(it.uid) != a and int(it.uid) != b)
	var out := {"uid": next_uid, "id": pv.id, "tier": pv.tier, "bonus": {}}
	next_uid += 1
	items.append(out)
	changed.emit()
	return out


func spend(amount: int) -> bool:
	if amount < 0 or coins < amount:
		return false
	coins -= amount
	changed.emit()
	return true


func earn(amount: int) -> void:
	coins += maxi(0, amount)
	changed.emit()


## Experience from defeats; every XP_PER_POINT grants a progression point.
func gain_xp(amount: int) -> int:
	xp += amount
	var got := 0
	while xp >= XP_PER_POINT:
		xp -= XP_PER_POINT
		points += 1
		got += 1
	changed.emit()
	return got


# ------------------------------------------------------------------ effects
## Tier of an equipped relic `id` (0 if not worn).
func relic_tier(id: StringName) -> int:
	for s in ["relic1", "relic2"]:
		var it := slot_item(s)
		if not it.is_empty() and it.id == id:
			return int(it.tier)
	return 0


func relic(id: StringName) -> float:
	return Items.RELIC[id][relic_tier(id)]


func staff_id() -> StringName:
	var it := slot_item("staff")
	return it.id if not it.is_empty() else &""


func robe_id() -> StringName:
	var it := slot_item("robe")
	return it.id if not it.is_empty() else &""


func spell_power_bonus() -> float:
	return float(slot_item("staff").get("bonus", {}).get("power", 0.0))


func hp_bonus() -> float:
	return float(slot_item("robe").get("bonus", {}).get("hp", 0.0))


## The look equipment gives (robe/staff keys), for the wizard sprite.
func look() -> Dictionary:
	var out := {}
	for s in ["staff", "robe"]:
		var it := slot_item(s)
		if not it.is_empty():
			out.merge(Items.def(it.id).get("look", {}), true)
	return out


# ------------------------------------------------------------------ save
func to_dict() -> Dictionary:
	return {"items": items, "equipped": equipped, "coins": coins, "xp": xp, "points": points,
		"decor": decor.keys(), "looks": looks.keys(), "next_uid": next_uid}


## Load, silently dropping unknown item ids and dangling equipment.
func from_dict(d: Dictionary) -> void:
	items.clear()
	var seen := {}
	for it in d.get("items", []):
		if it is Dictionary and Items.valid(StringName(it.get("id", ""))) and not seen.has(int(it.get("uid", 0))):
			var inst := {"uid": int(it.uid), "id": StringName(it.id), "tier": clampi(int(it.get("tier", 1)), 1, Items.MAX_TIER), "bonus": it.get("bonus", {})}
			seen[inst.uid] = true
			items.append(inst)
	equipped = {"staff": 0, "robe": 0, "relic1": 0, "relic2": 0}
	var eq: Dictionary = d.get("equipped", {})
	for s in equipped:
		var u := int(eq.get(s, 0))
		if owns(u):
			equipped[s] = u
	coins = maxi(0, int(d.get("coins", 0)))
	xp = maxi(0, int(d.get("xp", 0)))
	points = maxi(0, int(d.get("points", 0)))
	decor = {}
	for k in d.get("decor", []):
		decor[StringName(k)] = true
	looks = {}
	for k in d.get("looks", []):
		looks[String(k)] = true
	var max_uid := 0
	for it: Dictionary in items:
		max_uid = maxi(max_uid, int(it.uid))
	next_uid = maxi(int(d.get("next_uid", 1)), max_uid + 1)
	changed.emit()
