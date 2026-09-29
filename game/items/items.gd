class_name Items
## Item definitions. Each item has an authored identity (its behaviour) and
## an owned *instance* may carry one modest, capped random bonus.
##   staff  - changes the free staff attack (identity) + small spell power
##   robe   - a defensive/movement trait + a little health
##   relic  - one clear effect
## Staffs, robes and relics come in tiers I-III: two alike items of the same
## tier fuse into the next tier. A tier scales the item's effect (relics by
## their RELIC table, staffs and robes by TIER_MULT). The plain starter crook
## and robe have no effect to scale and can't be fused.
## Robes and staffs also change the wizard's look (WizardArt keys) and unlock
## that look for the appearance mirror.

const SLOTS := ["staff", "robe", "relic1", "relic2"]
const MAX_TIER := 3

const DEFS := {
	# ---------------------------------------------------------------- staffs
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
	# ---------------------------------------------------------------- relics
	&"ember_seed": {"kind": "relic", "name": "Ember Seed", "icon": 7,
		"text": "Burns you cause tick harder: +20% / +40% / +60%."},
	&"stormglass": {"kind": "relic", "name": "Stormglass", "icon": 8,
		"text": "Lightning spells deal +8% / +14% / +20% damage."},
	&"whisper_bone": {"kind": "relic", "name": "Whisper Bone", "icon": 9,
		"text": "Curses you cause last +2 / +4 / +6 seconds."},
	&"gale_feather": {"kind": "relic", "name": "Gale Feather", "icon": 10,
		"text": "Dodge cooldown shortened by 0.08 / 0.14 / 0.2 s."},
	&"moonstone": {"kind": "relic", "name": "Moonstone", "icon": 11,
		"text": "Mana regenerates 25% / 45% / 65% faster."},
	&"ward_bell": {"kind": "relic", "name": "Ward Bell", "icon": 12,
		"text": "When struck, 12% / 18% / 24% chance to ring and turn the blow aside (6 s rest)."},
}

## Random bonus rolled once per new instance: [stat, min, max] (capped).
const BONUS := {"staff": ["power", 0.0, 0.08], "robe": ["hp", 0.0, 10.0]}

const TIER_NAMES := ["", "I", "II", "III"]

## Staff and robe effect strength by tier (index 1..3). Relics use RELIC.
const TIER_MULT := [0.0, 1.0, 1.5, 2.0]


static func def(id: StringName) -> Dictionary:
	return DEFS.get(id, {})


static func valid(id: StringName) -> bool:
	return DEFS.has(id)


static func kind(id: StringName) -> String:
	return DEFS.get(id, {}).get("kind", "")


## Can two of this item fuse into a higher tier? (Not the plain starter kit.)
static func fusable(id: StringName) -> bool:
	return valid(id) and not def(id).get("plain", false)


static func display(inst: Dictionary) -> String:
	var d := def(inst.id)
	var n: String = d.get("name", "?")
	var tier := clampi(int(inst.get("tier", 1)), 1, 3)
	if d.get("kind", "") == "relic" or tier > 1:
		n += " " + TIER_NAMES[tier]
	return n


static func bonus_text(inst: Dictionary) -> String:
	var b: Dictionary = inst.get("bonus", {})
	if b.has("power"):
		return "+%d%% spell power" % roundi(float(b.power) * 100.0)
	if b.has("hp"):
		return "+%d health" % roundi(float(b.hp))
	return ""


## Relic strength by tier (index 1..3).
const RELIC := {
	&"ember_seed": [0.0, 0.2, 0.4, 0.6],
	&"stormglass": [0.0, 0.08, 0.14, 0.2],
	&"whisper_bone": [0.0, 2.0, 4.0, 6.0],
	&"gale_feather": [0.0, 0.08, 0.14, 0.2],
	&"moonstone": [0.0, 0.25, 0.45, 0.65],
	&"ward_bell": [0.0, 0.12, 0.18, 0.24],
}
