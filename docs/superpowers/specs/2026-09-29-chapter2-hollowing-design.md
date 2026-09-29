# Chapter 2: The Hollowing (design)

Agreed with the owner on 2026-09-29. Builds on the finished first adventure (Chapter 1). Where this
document and `docs/brief.md` disagree, this document wins for Chapter 2. All names are working names.

## Campaign frame

Wardlight is a long campaign with many chapters. Each chapter keeps the core (combat, the three
schools, the sanctuary) and changes a few things from this set, so no two chapters play alike:

- a new ability each chapter, used when exploring and in fights (Chapter 1: levitation)
- new enemy families mixed in with familiar ones
- local rules per area (fog, darkness, water)
- different kinds of missions (defend, escort, chase, puzzle ruin)
- new companions with distinct roles
- growing power: spells, upgrades, the sanctuary, reputation

**The evil: the Hollowing.** It empties living things out and leaves obedient husks. Chapter 1's
Hollowed Warden was an early victim. The Hollowing has three layers:

1. **The source:** ancient, far away, unseen and unnamed in Chapter 2. It is felt through whispers
   and dying land. It is the campaign-long threat, in the spirit of a distant dark lord.
2. **The Herald:** the source's masked "gardener", who plants the Hollowing in person. It appears
   and talks in Chapter 2, is driven off, and returns later.
3. **The victims:** things that were good before they were hollowed. In Chapter 2 that is the
   **Deepwillow**, the root being under the lake that feeds every ward's light.

**Set aside for later chapters (owner-approved ideas):**
- Wardsight (revealing hidden paths and veiled enemies)
- hold-the-ward defence missions
- local area rules as a gameplay system
- bigger battles with more than two companions
- mixing different items into new ones (recipes)
- a music pass
- castles (owner, 2026-09-29): a castle as a place to explore in a later chapter, not necessarily Chapter 2

## Chapter 2 summary

- About 45–60 minutes of play. The structure is an open lake with a hub.
- About 60% familiar enemies and 40% new ones per area; new types appear more in later areas.
- A second companion, Kess, a ranged scout. She travels with Tamsin: two companions follow at once.
- A teaser side quest in the middle points at the next chapter.

## Story beats

| # | Beat | Where | Outcome |
| --- | --- | --- | --- |
| 0 | **Opening.** Wounded Kess reaches Hearthmere with a hollow-mask shard and asks for the wizard. Maren: the wider world has come knocking. | Hearthmere (after Chapter 1 ends) | Main quest `hollowing` starts; the waystone offers the Fenway |
| 1 | **The Fenway.** A marsh road; Kess travels as a guest. First Husks appear. | `fenway` | Reach Reedhollow |
| 2 | **Reedhollow.** A stilt village on the lake (the hub). The elder explains the Deepwillow and the sealed Heart Isle; three shrines must be relit. Kess joins properly. | `reedhollow` | Party of two; three shrine quests open; boat rides unlock |
| 3 | **Shrines (any order).** Each area has a contextual-magic moment, a guarded shrine fight, and a guaranteed reward. | `sunken_chapel`, `mire`, `stilled_grove` | One shrine lit per area |
| 4 | **The Herald.** After the second shrine, Reedhollow is under attack. Fight the Herald, who flees at about 30% health. | `reedhollow` (attack state) | Village recovers further; teaser quest opens |
| 5 | **Teaser (side quest).** The mapmaker Orla's spyglass is at a watchtower on the far shore. From the top: a grey, dead land on the horizon and a huge shape moving in the haze. No fight. | `far_watch` | Journal entry "Beyond the east"; reward |
| 6 | **Heart Isle.** With all three shrines lit, the seal opens. Deepwillow fight: cleanse, don't kill. Healed, it blesses the wizard and remembers who did this. | `heart_isle` | Chapter ends; Reedfolk become allies; new spells; sanctuary camp and decor |

The Mire's lost Reedfolk child is a "people need you" beat: the child reappears in Reedhollow afterwards.
Reedhollow visibly recovers with each shrine: lanterns, people, repaired walkways, then the shop.

## Areas (6 new regions)

Each area is a `Region` subclass like Chapter 1's. Palettes:

- **Fenway:** reed green and teal.
- **Reedhollow:** warm lanterns over cold water.
- **Sunken Chapel:** slate, moonlight and violet.
- **Mire:** sickly green fog.
- **Stilled Grove:** pale grey, with frozen shapes.
- **Far watch:** a dusk horizon.
- **Heart Isle:** deep water around a root island.

- **Getting there:** the Fenway is reached by waystone from Briarwood or Hearthmere. Reedhollow's
  boats take you to the shrines, the far watch and the Heart Isle, using the existing journey screen
  shown as a boat ride. The Fenway and Reedhollow connect by walking.
- **Camera rule (learned from the Chapter 1 gorge):** no terrain or prop taller than about 1.6 m
  between the camera and a walkable path or fight area. Check every area with screenshots.
- **Existing checks cover the new areas:** exit reachability, invisible walls on layer 128, and
  `Steps.move` for small ledges.

## Enemies

- **Familiar enemies:** hound, raider, hexer, knot and sentinel appear throughout.
- **Hollowed variants:** a mask overlay and a `hollowed` flag in the enemy data give them +20% move
  speed and one extra attack per type:
  - hound: a double lunge
  - raider: a spinning follow-up
  - hexer: a second, delayed bolt
  - knot: a larger thorn ring
  - sentinel: a shockwave after its slam
  They guard the shrines.
- **Husk:** slow, with a telegraphed lunge. On death it leaves a 3 s spore patch that slows walkers
  by 40%. The patch has a visible edge.
- **Mire Lurker:** moves hidden as a ripple through mud and shallow water. It surfaces under the
  wizard after a 0.8 s ring warning, then is exposed on land for 2 s.
- **Hollow Moth:** a flyer about 1.8 m up that keeps 6–9 m away and fires slow homing spores
  (dodgeable, and destroyed by any spell). It has low health.

**Rules carried over from Chapter 1:**
- every attack has a clear tell
- nothing attacks from off-screen
- no one-hit kills from full health
- decoration never hides attack cues

## Bosses

**The Herald (mid-boss, Reedhollow).** A mobile duellist-caster.
- **Blinks** between shadow pools, with a visible marker before it reappears.
- **Sweeping slash:** an arc telegraph.
- **Hollow seeds:** it plants 2–3 seeds that sprout into Husks after 6 s unless destroyed.
- **Below 50%:** it tethers Tamsin or Kess (the companion is held in place); hitting the tether
  breaks it.
- **At 30%:** it flees, with dialogue. It is not killed.

**The Deepwillow (final boss, Heart Isle).** Three layers:
1. **Hollow bark:** break 4 glowing knots, each exposed in turn, while dodging line and arc root
   sweeps.
2. **The flood:** water surges sweep the arena edges and are crossed by levitating. Root slams in
   lines.
3. **Hollow core:** the corruption emerges and attacks faster. Breaking it triggers a
   contextual-magic cleansing channel that ends the fight.

The camera framing uses the existing boss blend. The seal wall closes only once the wizard is
inside the arena (the Chapter 1 fix).

## Companions and the party

- **Refactor:** `Shieldbearer` becomes a shared `Companion` base, with the shieldbearer's
  follow/unstick/knockdown/leash behaviour moved into the base. `Shieldbearer` (Tamsin) and `Scout`
  (Kess) extend it.
- **Party state:** `GameState.party` holds up to 2 companion ids. The rest wait at the sanctuary
  camp. The sanctuary gets a companion camp (fire, bedrolls) where you choose who comes.
- **Kess:**
  - Ranged attacks at the wizard's current target, or the nearest visible enemy within 10 m.
  - Every 6 s she fires a **marking arrow**: the marked enemy takes +25% damage from the wizard's
    next spell hit, and the mark is then used up.
  - When an enemy comes within 2.5 m she hops back.
  - Knocked down, never dies, recovers.
  - At two scripted spots she points out a hidden route or cache.
- **Banter:** short exchanges between Tamsin and Kess, triggered by area entry and events (once
  each, tracked with `GameState.once`).

## Items and combining

- **Inventory tabs:** Staffs, Robes and Relics, sorted by tier then name. Opening from an equipment
  slot selects that slot's tab.
- **Tiers for staffs and robes:** tiers I–III, like relics. Each tier scales that item's bonus:
  tier II ×1.5, tier III ×2 (random bonuses stay capped).
- **Fusion for any kind:** the altar fuses any two items with the **same id and tier** into the
  next tier. It keeps the Chapter 1 rules: an exact preview, all-or-nothing, an equipped input is
  unequipped, and the result starts unworn.
- **Discoverability:**
  - a one-time toast the first time a matching pair exists
  - a small marker on bag items that have a partner
  - the altar prompt says what it does
- **New loot:**
  - three new relics (guaranteed shrine rewards), fusable
  - one new staff and one new robe (found in areas)
  - Reedhollow shop stock
  - two new sanctuary placeables from the lake (a reed boat decoration and a lake lantern)

## New spells

The Deepwillow teaches **one new spell per school**. Each is a fifth option to swap into the
loadout, with an upgrade. Exact spells are designed in the implementation plan. Each must pass the
Warden damage check (`--demo=dps_<school>`) without making its school the clear outlier.

## Progress and saves

- **Main quest:** `hollowing`, with steps:
  1. opening
  2. reach Reedhollow
  3. shrines (three flags, any order)
  4. the Herald
  5. Heart Isle
  6. done
- **Side quests:** `lost_child` (Mire) and `far_watch` (the teaser).
- **Save format version 2:**
  - Migrates version 1 on load: Chapter 1's `companion` becomes `party`; staffs and robes without
    a tier get tier 1.
  - A Chapter 1 save that has finished the main quest starts the Chapter 2 opening the next time
    you're in Hearthmere.
- **Difficulty:** Chapter 2 enemies get about +25% health and damage over their Chapter 1 values,
  set per area in the region's spawn data, not globally. Progression points and item tiers keep
  pace.

## Music

New looping tracks, made the same way as the existing ones (`tools/gen_audio.gd`):
- `mus_lake`: the Fenway, Reedhollow and shrines
- `mus_herald`: the Herald fight
- `mus_deepwillow`: the final boss

The full music pass comes after Chapter 2.

## Build order

Each step ends playable. Steps marked **(look)** or **(feel)** stop for the owner's screenshot review.

1. Inventory tabs, staff and robe tiers, generalised fusion, fusion hints.
2. `Companion` refactor, party of two, Kess, sanctuary camp. Tested in the Chapter 1 areas.
3. Opening beat, Fenway, Reedhollow, boat travel. **(look)**
4. Husk, Mire Lurker, Hollow Moth, hollowed variants. **(feel)**
5. Sunken Chapel, Mire, Stilled Grove, with rewards and the lost child. **(look)**
6. The attack on Reedhollow and the Herald fight. **(feel)**
7. The far-watch teaser quest.
8. Heart Isle, the Deepwillow, the three new spells, the ending. **(look + feel)**
9. Balance pass, `--demo=story2` for the whole chapter, report and screenshots, Mac build.

**Cloud-friendly work** (a branch plus a pull request each):
- step 1
- the logic parts of step 2
- dialogue and banter writing
- quest scripts
- the save migration
- tests

Look and feel steps are done on the owner's Mac.

## Testing

- **New tests:**
  - version-1 saves load into version 2 (party, tiers)
  - fusion for staffs and robes: no duplication, no loss, equipped inputs handled, tier cap
  - party save/load and the two-companion limit
  - shrines in any order, each reward exactly once
  - Chapter 2 opening triggers only after Chapter 1 is done
  - the Kess mark is consumed by exactly one hit
- **Existing checks that cover the new content automatically:**
  - exit reachability across all regions
  - spells landing at the aim point
  - the Warden damage comparison for the new spells
- **Scripted runs:** `--demo=story2` plays Chapter 2 start to finish, then `resume --continue`
  reloads it. Scripted demos per area and boss produce the review screenshots.
