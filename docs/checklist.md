# Implementation checklist

Status: **Chapters 1 and 2 built. Chapter 2 (The Hollowing) awaits the owner's look/feel reviews for steps 5, 6 and 8: see `docs/superpowers/plans/2026-09-29-chapter2-roadmap.md`.**

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
- [x] Region base: code-built terrain (hills, pads, roads, streams, cliffs), houses, wards, waystones
- [x] Sanctuary (home, study, mirror, altar, plot), Hearthmere, Briarwood Road, the Old Ward
- [x] Walk-off exits with fades; waystone journey with threaded loading and a failure fallback
- [x] Character setup (name, school, looks); opening with Pell and a bramble spell tutorial
- [x] Dialogue (typewriter, choices, pauses the world), NPCs, journal (Q), world map (M)
- [x] Contextual magic: relight the roadside ward, lift the fallen trunk, calm the fawn
- [x] Levitate (hold Space, recharges on ground) crosses the cliff chasm to a hidden satchel
- [x] Checkpoints: ward stones and rune stones (one right before each boss)
- [x] Gatebreaker troll (sweep, slam, thrown rubble; triple throw below half) with boss bar
- [x] Hollowed Warden, 2 phases (sweep, root eruptions, seed burst; transform without damage)
- [x] Aftermath: ward relit, roots wither, reward; Hearthmere restored (wardlight, lanterns,
      travellers home, roots gone, garland arch, changed dialogue); Isolde's choice (sanctuary / village)
- [x] Boss camera framing, per-region music (home / explore / ruins / boss), new sfx
- [x] Tests: exactly-once rewards, forward-only quests, state round trip, idempotent restoration (18 total)

## Stage 4 — discoveries and home
- [x] Items: 4 staffs (staff-attack identities), 3 robes (traits), 6 relics tiers I–III, capped bonuses
- [x] Inventory (I) with comparisons; equipment changes the wizard's look; mirror sets cosmetics
- [x] Fusion altar: same-relic tier fusion with exact preview, atomic commit (cross recipes cut)
- [x] Loot: chests, boss rewards, village gifts, Brannoc's shop, enemy coins/XP/relic drops
- [x] Progression points (XP + milestones) spent on upgrades (U) and training (T) in the spellbook
- [x] Tamsin the shieldbearer: rescue, recruit, follow, fight, shield wall, downed/recover, unstick, dismiss
- [x] Home building (B): six placeables, grid ghost, reasons, move free, refunds
- [x] Saves: versioned, temp + verify + backup, autosaves, damaged-save recovery, new-game confirm
- [x] Title, pause menu, settings (audio, aim mode, fullscreen, reduce shake/flash, remapping)

## Stage 5 — refine and hand off
- [x] Scripted full playthrough (`--demo=story`) + continue from save (`--demo=resume --continue`)
- [x] Profiling: 110–120 fps on the M3
- [x] 22 automated rule tests (tests never touch real saves or settings)
- [x] macOS export: `build/Wardlight.zip` (universal, ad-hoc signed), verified running
- [x] Evidence report (`docs/report.md`) and asset manifest (`docs/assets.md`)
- [ ] Human playtest for difficulty and feel

## Chapter 2 — The Hollowing
- [x] Step 1: inventory tabs (Staffs / Robes / Relics), staff and robe tiers I–III (×1 / ×1.5 / ×2
  effect), the altar fuses any two alike items, pair markers and a one-time hint. The plain starter
  crook and robe can't be fused; a fused staff/robe stays worn; fusion keeps the better bonus.
- [x] Step 2: `Companion` base (Tamsin's follow/downed/unstick shared), party of up to two
  (`GameState.party`), Kess the scout (shoots the wizard's target, marking arrow every 6 s = +25% on
  the next spell hit, hops back from close enemies), sanctuary companion camp, save version 2
  (Chapter 1 saves migrate). Kess's recruitment scene, route hints and banter come with steps 3 and 5.
- [x] Step 3 (look approved): Hearthmere opening (Kess arrives once Chapter 1 is done;
  she's a guest until Reedhollow), waystones to the Fenway (Hearthmere, Briarwood), the Fenway marsh road
  (enemies ×1.25), Reedhollow (lake to the north, stilt houses, dock, elder; deep water puts you back ashore),
  boat menu and boat journey (no stops until step 5), lake music, map places. `--demo=lake` plays it.
- [x] Step 4 (feel approved): Husk (lunge, spore patch slows 40% for 3 s), Mire Lurker (hidden
  ripple, 0.8 s ring, 2 s exposed), Hollow Moth (hovers 1.8 m, keeps 6–9 m, homing spores that pop to any hit),
  hollowed variants (+20% speed, mask; hound double lunge, raider spin, hexer echo bolt, knot wider ring,
  sentinel second wider wave). First Husks on the Fenway road. `--demo=bestiary` records a clip per enemy.
- [x] Step 5 (built, awaiting look review): shared `ShrineArea` (boat landing, guarded shrine, relight channel,
  reward once). Sunken Chapel (flooded nave; ring the bell to drain it; Lakeweave Robe chest), the Mire (bog,
  raise the stepping stones to rescue Pip; `lost_child`), the Stilled Grove (frozen figures, thaw the root wall,
  colour returns when lit; Reedwhistle Staff chest). Shrine relics: Vesper Candle, Bogheart Pearl, Stillwater
  Acorn (fusable, never random drops). Reedhollow recovers: walkway mended at two shrines, Corrin's shop at three,
  Wenna and Pip. `--demo=shrines` tours it all.
- [x] Step 6 (built, awaiting feel review): the second shrine sets Reedhollow on fire; the Herald on the sealed
  square (blinks between shadow pools with a ring tell, arc slash, hollow seeds that sprout Husks after 6 s,
  below half a tether on Tamsin/Kess broken by hitting its knot); at 30% it speaks and flees. `mus_herald`.
  Quest gains "Relight the last lake shrine". `--demo=herald`.
- [x] Step 7: Orla the mapmaker (after the Herald), boat to the Far Watch, climb the tower, the spyglass view
  east (grey land, a vast walker in the haze); reward on return. `--demo=farwatch`.
- [x] Step 8 (built, awaiting look + feel review): the Heart Isle (sealed until three shrines; deep water all
  round), the Deepwillow (four bark knots opened one at a time; then the tree itself with flood surges over the
  clearing's edge (levitate or stay near the trunk) and root lines; at half health the hollow core tears free and
  everything speeds up; spent, not killed: cleanse it), the ending (Chapter 2 complete; Reedfolk allies; the lake
  light burns in Reedhollow). Three new spells in a fifth spellbook column: Boiling Spring, Chain Current,
  Drowning Grasp (checked against the Warden: none an outlier). Home decor: reed boat, lake lamp.
  `mus_deepwillow`. `--demo=deepwillow`; `--demo=dps_<school>_lake`.
- [x] Step 9: `--demo=story2` plays the whole chapter from a finished Chapter 1 save to the epilogue, and
  `resume --continue` reloads it; lake spells checked against the Warden; report (`docs/report.md`,
  Chapter 2 section) and asset list updated; Mac build exported and verified.
- [ ] Owner reviews still open: step 5 (look), step 6 (feel), step 8 (look + feel); a human playtest
  for Chapter 2 difficulty (Herald, Deepwillow).
