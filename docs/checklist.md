# Implementation checklist

Status: **Stage 1 complete — waiting for combat-feel and visuals review.**

## Agreed changes to the original brief
- Cross-relic recipes cut; same-relic tier fusion (I → II → III) kept.
- Home decorations come from thank-you gifts *and* coin purchases.
- Trackpad tap/hold = staff attack (J alternative); the cursor aims attacks and spells.
- Hat and beard appearance options added.
- "People need you" beats: named villager asks for help in the opening; rescued travellers reappear.
- Aim with an active mouse never redirects to an enemy behind the cursor's direction; the
  facing-direction fallback is used when the mouse is idle (keyboard play).

## Stage 1 — feel and visual style
- [x] Project: Godot 4.7.1, Compatibility renderer, 640×360, integer scaling, nearest filtering
- [x] Remappable input map (Settings autoload), key labels from physical keys
- [x] Layered wizard generated from appearance (robe, skin, hair, beard, hat, staff) — idle, run,
      jump, fall, land, raise, gather, 5 aimed releases, recover, dodge, hurt, death
- [x] Movement: acceleration, variable jump, coyote 100 ms, buffer 120 ms, drop-through planks,
      directional dodge with i-frames, air dodge once, double jump / float hooks (locked)
- [x] Pixel FX system (particles, rings, arcs, lightning, textured glows, telegraph layer on top)
- [x] Arc Lance (gather → rune circle → bolt → impact) + Forked upgrade logic
- [x] Static Gust free staff attack (hold to repeat, close-range knockback, mana on hit)
- [x] Mana (slow regen, motes, basic-hit return, perfect-dodge pulse), cooldowns by spell id
- [x] Gloamhound flanker (stalk, telegraphed leap, punishable landing, pack sides, flinch limits)
- [x] HUD, reticle, target brackets, failed-cast feedback, pause + focus-loss pause
- [x] Checkpoint respawn resets the encounter, keeps progress
- [x] Synthesised SFX set + exploration music loop, original pixel font
- [ ] **User review: combat feel**
- [ ] **User review: visuals**

## Stage 2 — combat toolkit
- [ ] Pyromancer, Hexbinder, Stormcaller: 4 spells each + upgrades, 3 basics
- [ ] Class passives (Heat, Soul Echo, Conduction), foreign affinity 75/85/95/100
- [ ] Spell wheel (Tab, 15% time) and loadouts per class
- [ ] Statuses (burn, curse, root, shock) and the three bounded interactions
- [ ] Shield raider, hex caster, root creature, hollow knight

## Stage 3 — adventure
- [ ] Sanctuary, Hearthmere, Briarwood, Old Ward ruins; exits and animated journey
- [ ] Contextual magic ×3, double jump + float unlocks, quests, journal
- [ ] Troll miniboss, corrupted guardian (2 phases), aftermath and restoration

## Stage 4 — discoveries and home
- [ ] Loot, equipment, relic fusion, progression points, cosmetics
- [ ] Shieldbearer companion, home building, herbalist choice, full persistence

## Stage 5 — refine and hand off
- [ ] Full playthrough, profiling, save/load verification, Mac export, evidence report
