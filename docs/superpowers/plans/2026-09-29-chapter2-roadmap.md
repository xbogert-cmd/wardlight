# Chapter 2 (The Hollowing) — Build Roadmap

Spec: `docs/superpowers/specs/2026-09-29-chapter2-hollowing-design.md`.

The chapter is nine build steps (spec § Build order). Each step gets its own detailed plan
(`docs/superpowers/plans/2026-09-29-ch2-stepN-*.md`), written when the step before it has landed,
so each plan is written against the real code. Steps marked **(look)** / **(feel)** stop for the
owner's screenshot review before they count as done.

| Step | What | Plan | Where it can run |
| --- | --- | --- | --- |
| 1 | Inventory tabs, staff/robe tiers, fusion for every kind, fusion hints | `2026-09-29-ch2-step1-items.md` | cloud or Mac |
| 2 | `Companion` base, party of two, Kess, sanctuary camp, save v2 | written after step 1 | logic in cloud; camp look on Mac |
| 3 | Opening beat, Fenway, Reedhollow, boat travel **(look)** | later | Mac |
| 4 | Husk, Mire Lurker, Hollow Moth, hollowed variants **(feel)** | later | Mac |
| 5 | Sunken Chapel, Mire, Stilled Grove, rewards, lost child **(look)** | later | Mac |
| 6 | Attack on Reedhollow, the Herald **(feel)** | later | Mac |
| 7 | Far-watch teaser quest | later | cloud or Mac |
| 8 | Heart Isle, the Deepwillow, the three new spells, ending **(look + feel)** | later | Mac |
| 9 | Balance, `--demo=story2`, report, screenshots, Mac build | later | Mac |

## The three new spells (for the owner's OK before step 8)

The Deepwillow is a lake spirit, so each spell is its school's magic bent through water. Each one
fills a gap its school doesn't cover yet. Numbers are starting values for the `--demo=dps_<school>`
check.

**Fire — Boiling Spring.** Aim a spot: the ground bubbles for 0.6 s (the tell), then a scalding
geyser erupts in a 1.8 m circle for 30 damage, knocking small enemies up and burning them.
Cooldown 7 s. *Upgrade:* it erupts a second time 1 s later. *Why:* fire has a zone (Ashfall) and a
cone, but no big delayed burst for enemies held by roots or grouped by a pull.

**Storm — Chain Current.** A bolt at the target that jumps to up to 4 more enemies within 4 m of
each other, each jump at 80% of the last (24 damage to start). Cooldown 3 s. *Upgrade:* 6 jumps and
jumps can return to an enemy already hit. *Why:* storm has no chain; Hollow Moths and Husk packs
are exactly what it's for.

**Hex — Drowning Grasp.** Dark water hands rise at the aimed spot and drag every enemy within 3 m
to its centre over 0.4 s, then slow them by 40% for 2 s (12 damage). Cooldown 8 s. *Upgrade:*
pulled enemies are also cursed. *Why:* Binding Roots holds enemies where they stand; this gathers
them, which sets up Ashfall, Boiling Spring and Thunder Ring.

## Step 1 decisions to confirm with the owner (from writing its plan)

- **The plain starter crook and robe can't be fused.** They have no effect for a tier to scale, so
  fusing them would waste two items. The altar explains why.
- **A fused staff or robe stays worn** if one of the inputs was worn, so the wizard is never left
  empty-handed. Relics keep the Chapter 1 rule: the result starts unworn.
- **Fusing keeps the better random bonus** of the two inputs (still within the cap).
