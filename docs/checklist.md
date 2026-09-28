# Implementation checklist

Status: **Stage 2 complete and ported to 3D. Stage 3 (adventure) next.**

## Agreed changes to the original brief
- Cross-relic recipes cut; same-relic tier fusion (I → II → III) kept.
- Home decorations come from thank-you gifts *and* coin purchases.
- Trackpad tap/hold = staff attack (J alternative); the cursor aims attacks and spells.
- Hat and beard appearance options added.
- "People need you" beats: named villager asks for help in the opening; rescued travellers reappear.
- No floating/Mario-style platforms: natural terrain only (hills, 45° and gentle slopes, rock
  cliffs and outcrops, scenery props). One-way planks removed from the engine.
- **3D world, 2D characters** (approved mockup, 2026-09-27): third-person diagonal-down camera over
  heightfield terrain; pixel-art billboard characters (1 px = 1/24 m), side-facing sprites only.
  No jumping: hills are walked; levitation is the traversal unlock.
- Aim with an active mouse never redirects to an enemy behind the cursor's direction; the
  facing-direction fallback is used when the mouse is idle (keyboard play).

## Stage 1 — feel and visual style
- [x] Project: Godot 4.7.1, Compatibility renderer, 640×360, integer scaling, nearest filtering
- [x] Remappable input map (Settings autoload), key labels from physical keys
- [x] Layered wizard generated from appearance (robe, skin, hair, beard, hat, staff) — idle, run,
      jump, fall, land, raise, gather, 5 aimed releases, recover, dodge, hurt, death
- [x] Movement: acceleration, variable jump, coyote 100 ms, buffer 120 ms, slopes,
      directional dodge with i-frames, air dodge once, double jump / float hooks (locked)
- [x] Pixel FX system (particles, rings, arcs, lightning, textured glows, telegraph layer on top)
- [x] Arc Lance (gather → rune circle → bolt → impact) + Forked upgrade logic
- [x] Static Gust free staff attack (hold to repeat, close-range knockback, mana on hit)
- [x] Mana (slow regen, motes, basic-hit return, perfect-dodge pulse), cooldowns by spell id
- [x] Gloamhound flanker (stalk, telegraphed leap, punishable landing, pack sides, flinch limits)
- [x] HUD, reticle, target brackets, failed-cast feedback, pause + focus-loss pause
- [x] Checkpoint respawn resets the encounter, keeps progress
- [x] Synthesised SFX set + exploration music loop, original pixel font
- [x] User review: combat feel — approved
- [x] User review: visuals — approved after replacing platforms with natural terrain
- [x] Natural terrain: slopes (45°, 22.5°), rock terrain, scattered scenery props

## Stage 2 — combat toolkit
- [x] Pyromancer, Hexbinder, Stormcaller: 4 spells each + visibly different upgrades, 3 basics
- [x] Class passives (Heat, Soul Echo, Conduction) — only the active school's, native spells only
- [x] Foreign affinity 75/85/95/100% (scales positive effects only), shown in the spellbook
- [x] Spellbook (Tab, world at 15%), per-school saved loadouts, unique slots, keyboard + trackpad
- [x] Statuses: burn, curse, root (bosses resist); status marks drawn on enemies
- [x] Interactions: Haunted Embers, Grave Current, Cinderflight — all proc damage, non-recursive
- [x] Briar Raider (shield, guards casters, guard break), Hollow Hexer (telegraphed bolt, punish
      window), Briar Knot (ground control, burrows), Hollow Sentinel (poise, stagger, slam/sweep)
- [x] Mixed-encounter gauntlet (data/maps/arena.txt, regenerate with tools/maps/gen_arena.py)
- [x] Automated rule tests (tests/): 14 passing
- Dev keys (debug builds): F5 next school, F6 toggle upgrades, F7 train affinity, F8 learn all

## 3D port
- [x] 3D look mockup approved (terrain shader, dithered lighting, pixel billboards, FX3)
- [x] Data in metres; player (8-way move, dodge, dash, levitate hooks), aim (screen-space assist)
- [x] All 12 spells + upgrades + 3 basics, statuses, passives, interactions, ember patches
- [x] Hound, Raider, Hexer, Knot, Sentinel re-authored for open ground (ring/line/arc telegraphs)
- [x] HUD target brackets + poise bars projected from 3D; spellbook unchanged
- [x] Trees between camera and wizard dither out; ground marks stay visible on slopes
- [x] Tests ported (14 passing); side-view world code removed

## Stage 3 — adventure
- [ ] Sanctuary, Hearthmere, Briarwood, Old Ward ruins; exits and animated journey
- [ ] Contextual magic ×3, levitate unlock, quests, journal
- [ ] Troll miniboss, corrupted guardian (2 phases), aftermath and restoration

## Stage 4 — discoveries and home
- [ ] Loot, equipment, relic fusion, progression points, cosmetics
- [ ] Shieldbearer companion, home building, herbalist choice, full persistence

## Stage 5 — refine and hand off
- [ ] Full playthrough, profiling, save/load verification, Mac export, evidence report
