# Chapter 2 Step 5: The Three Shrine Areas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Sunken Chapel, the Mire and the Stilled Grove: each reached by boat from Reedhollow, each with a contextual-magic moment, a guarded shrine and a guaranteed reward; the lost child side quest; Reedhollow recovering as the shrines are relit.

**Architecture:** A shared `ShrineArea` base (extends `Region`) owns what the three areas have in common: the landing (pier, boat home), the shrine stone with its guards (enemies spawned only while the shrine is dark; the shrine can't be relit while any live guard is near), the relight channel, the reward (`GameState.once`), and Kess's arrival lines. Each area script adds its terrain, props, enemies and its one contextual-magic moment. New relics, staff and robe are ordinary `Items.DEFS` entries with hooks at the places Chapter 1's items already use.

## Global Constraints

- Camera rule: nothing taller than ~1.6 m between the camera and a path or fight area; tall things go north (−z) of paths.
- Natural terrain only; no jumping; levitation is the only traversal ability.
- Shrines in any order; each reward exactly once (`GameState.once`); the shrine flags are `Quests.SHRINES`.
- About 60% familiar enemies, 40% new; hollowed variants guard the shrines; Chapter 2 enemies at `enemy_scale` 1.25.
- New relics are shrine rewards only (not random drops), fusable like any relic.
- Step 5 is a **(look)** gate: screenshots of each area, the shrine moments and the boat journey screen.

## Decisions

- **Shrine relics:**
  - Sunken Chapel: **Vesper Candle** (kills restore 3 / 5 / 7 mana).
  - Mire: **Bogheart Pearl** (slows on you are 40% / 70% / 100% weaker; spores and mud).
  - Stilled Grove: **Stillwater Acorn** (a spell cast within 1 s of a dodge deals +12% / 18% / 24%).
- **Found gear:** the **Lakeweave Robe** (chapel chest: below half health you take 10% / 15% / 20% less damage) and the **Reedwhistle Staff** (grove chest: staff attacks slow enemies by 20% / 30% / 40% for 1.5 s).
- **Contextual magic:** the Chapel's flooded nave drains when the wizard rings the drowned bell; the Mire's old stepping stones rise out of the bog to reach the lost child; the Grove's stilled roots thaw to open the shrine glade (and the stilled shapes wake when the shrine is lit).
- **Lost child:** Wenna in Reedhollow asks after her son Pip (quest `lost_child`); Pip is stranded in the Mire; he goes home by boat and appears in Reedhollow; Wenna thanks you (coins and a point, once). Finding Pip first also works.
- **Reedhollow recovery:** lanterns and returning folk (step 3), a broken walkway mended at two shrines, the Reedfolk shop at three.
- The quest step stays at "Relight the three lake shrines" in step 5; step 6 inserts the Herald attack after the second shrine.

### Task 1: Items — five new defs, icons 14–18, hooks (tests: each effect at tier I and III; shrine relics never random drops)
### Task 2: `ShrineArea` base — landing, shrine, guards, relight, reward, banter (tests: guarded shrine refuses; lit once; any order; guards don't respawn once lit)
### Task 3: Sunken Chapel — drowned nave, bell drains the flood, chest with the Lakeweave Robe
### Task 4: The Mire — bog, stepping stones, Pip, `lost_child` (tests: quest either order; reward once)
### Task 5: The Stilled Grove — stilled shapes, root wall, chest with the Reedwhistle Staff
### Task 6: Reedhollow — Wenna and Pip, mended walkway, shop; map places and boat routes; Main.REGIONS
### Task 7: `--demo=shrines` screenshots (each area, each moment, the boat journey), checklist, send captures
