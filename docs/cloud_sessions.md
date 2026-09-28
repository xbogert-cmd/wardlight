# Using cloud sessions on Wardlight

Repo: https://github.com/xbogert-cmd/wardlight (private). Cloud sessions read `CLAUDE.md` for the
project rules and run `scripts/cloud_setup.sh` to install Godot. The cloud computer is Linux with no
real graphics card, so it can check code and run tests but can't judge how the game *looks* or
*feels*. Anything it builds gets pushed to a branch; the local session (on the Mac) pulls it, looks
at it, and shows you.

## Good cloud jobs (logic, data, text — little or no visual judgement)
- **Save/load system** — save slots, autosave, what gets saved (quests, inventory, home, settings),
  plus tests that save → load gives the same state.
- **Quest + journal logic** — quest data files, steps/flags, rewards, journal entries, tests.
- **Dialogue and story writing** — villager lines, quest text, item descriptions, the "people need
  you" beats, lore notes. (Tell it the tone: dark fantasy, hopeful.)
- **Items, equipment and relic fusion rules** — stats, rarity, same-relic tier fusion I → II → III,
  loot tables, tests.
- **Progression and economy** — XP/points, coin prices, shop lists, balance spreadsheets in
  `docs/tuning.md`.
- **Home building rules** — decor catalogue (gift vs coin), placement grid rules, unlocks.
- **Settings menu logic** — key remapping save, volume, accessibility options.
- **Automated tests and bug hunts** — "add tests for X", "run the checks and fix anything failing",
  code cleanup that doesn't change behaviour.
- **Mac export setup** — export preset, version numbering, a build script.

## Keep local (on the Mac)
- Anything about **how it looks**: art, lighting, spell effects, camera, UI layout, animation.
- **Combat feel**: timing, knockback, enemy behaviour tuning, boss fights.
- **Map building** — needs screenshots to judge.
- Performance checks and the final Mac build/test.

## Tips
- Start each cloud task with one clear job, e.g. *"Build the save/load system described in
  docs/brief.md, with tests. Don't change visuals."*
- Run only one cloud task at a time in the same area of code as the local session, to avoid clashing
  edits. Different areas (e.g. dialogue text vs. combat) are fine in parallel.
- When it's done, tell the local session: *"pull the cloud branch <name> and check it"*.
