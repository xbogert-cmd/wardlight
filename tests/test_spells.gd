extends RefCounted
## Loadouts, affinity, casting rules and cooldowns.

var t


func test_loadout_unique_and_swap() -> void:
	var w := WizardState.new()
	w.setup("fire")
	t.eq(w.loadout().size(), 4, "four slots")
	t.check(w.equip(0, &"cinder_fan"), "equip unlocked spell")
	t.eq(w.loadout()[0], &"cinder_fan", "spell placed")
	t.eq(w.loadout()[1], &"ember_spear", "previous occupant swapped into old slot")
	var counts := {}
	for id in w.loadout():
		counts[id] = counts.get(id, 0) + 1
	t.check(counts.values().max() == 1, "no spell appears twice")
	t.check(not w.equip(2, &"arc_lance"), "cannot equip an unlearned spell")


func test_switch_school_unlocks_and_keeps_loadouts() -> void:
	var w := WizardState.new()
	w.setup("fire")
	t.check(not w.unlocked.has(&"grave_needle"), "hex spells start locked")
	w.equip(3, &"cinder_fan")
	w.switch_school("hex")
	t.check(w.unlocked.has(&"grave_needle"), "switching unlocks that school's base spells")
	t.eq(w.basic(), &"spectral_thrust", "basic attack follows the school")
	w.switch_school("fire")
	t.eq(w.loadout()[3], &"cinder_fan", "per-school loadout is remembered")
	t.check(w.equip(0, &"grave_needle"), "foreign spells can be slotted once learned")


func test_affinity_steps() -> void:
	var w := WizardState.new()
	w.setup("storm")
	t.near(w.affinity_mult("storm"), 1.0, "native 100%")
	t.near(w.affinity_mult("fire"), 0.75, "foreign starts at 75%")
	w.train("fire")
	t.near(w.affinity_mult("fire"), 0.85, "trained once 85%")
	w.train("fire")
	w.train("fire")
	t.near(w.affinity_mult("fire"), 1.0, "fully trained 100%")
	t.check(not w.train("fire"), "cannot train past 100%")
	t.check(not w.train("storm"), "native school has nothing to train")


func test_state_roundtrip_drops_unknown_ids() -> void:
	var w := WizardState.new()
	w.setup("hex")
	w.upgrades[&"grave_needle"] = true
	var d := w.to_dict()
	d.unlocked.append("not_a_spell")
	d.loadouts["hex"][2] = "not_a_spell"
	var w2 := WizardState.new()
	w2.from_dict(d)
	t.eq(w2.school, "hex", "school restored")
	t.check(w2.upgrades.has(&"grave_needle"), "upgrade restored")
	t.check(not w2.unlocked.has(&"not_a_spell"), "unknown id dropped")
	t.eq(w2.loadout()[2], &"", "unknown slot emptied")


func test_failed_casts_consume_nothing() -> void:
	var p: Player = t.make_player("storm")
	await t.frames(2)
	p.mana.mp = 5.0
	var before := p.mana.mp
	t.check(not p.caster.request(0), "cast refused without mana")
	t.near(p.mana.mp, before, "mana untouched")
	t.near(p.caster.remaining(&"arc_lance"), 0.0, "cooldown not started")
	p.wiz.equip(1, &"")
	t.check(not p.caster.request(1), "empty slot refused")
	p.mana.mp = 100.0
	t.check(p.caster.request(0), "cast starts with mana")
	await t.frames(20)
	var m := p.mana.mp
	t.check(not p.caster.request(0), "cast refused on cooldown")
	t.near(p.mana.mp, m, "cooldown refusal spends nothing")


func test_basic_attack_at_zero_mana() -> void:
	var p: Player = t.make_player("fire")
	await t.frames(2)
	p.mana.mp = 0.0
	p.mana.regen = 0.0
	t.check(p.caster.request(SpellCaster.BASIC_SLOT), "free attack works at zero mana")


func test_cooldown_survives_swap_and_school_switch() -> void:
	var p: Player = t.make_player("storm")
	await t.frames(2)
	t.check(p.caster.request(0), "cast arc lance")
	await t.frames(15)
	var rem := p.caster.remaining(&"arc_lance")
	t.check(rem > 0.3, "arc lance cooling down")
	p.wiz.equip(0, &"thunder_ring")
	p.wiz.equip(3, &"arc_lance")
	p.wiz.switch_school("fire")
	p.wiz.switch_school("storm")
	t.check(p.caster.remaining(&"arc_lance") > 0.0, "cooldown kept after swapping and switching")
	t.check(p.caster.remaining(&"arc_lance") <= rem, "cooldown never increased")


func test_dodge_interrupt_keeps_cost() -> void:
	var p: Player = t.make_player("storm")
	await t.frames(2)
	p.mana.regen = 0.0
	p.caster.request(0)
	t.eq(p.caster.state, SpellCaster.WINDUP, "in windup")
	var m := p.mana.mp
	p.caster.interrupt()
	await t.frames(20)
	t.eq(p.caster.state, SpellCaster.IDLE, "windup cancelled")
	t.near(p.mana.mp, m, "committed mana not refunded, no free spell")
	t.check(p.caster.remaining(&"arc_lance") > 0.0, "cooldown stays committed")
