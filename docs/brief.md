> Original design brief as pasted by the owner (2026-09-27). Agreed changes and later
> direction overrides live in CLAUDE.md and docs/checklist.md; those win where they conflict.

# Claude Code prompt: build my wizard game

Copy the text below into Claude Code in the folder where you want the game project. It is self-contained. The separate game design is a shorter review copy.

---

You are building my original Godot game. Act as an experienced 2D gameplay programmer and pixel art technical artist. Implement a complete first playable adventure from this brief, then verify it. My highest priorities, in order, are clean combat, impressive spell animation, consistent pixel graphics, and the feeling of being a wizard whom people need.

Read the whole brief before implementing. Inspect the current folder and any project instructions. Preserve existing work. Use a dedicated game subfolder if this is not already a game project. Write a short implementation checklist and keep it updated. Make routine implementation choices from the defaults below and document them. Ask only when missing information or authority actually prevents progress. Do not keep stopping to ask me about decisions this brief already resolves.

## 1. Game identity and scope

Create a single-player 2D side-view dark fantasy action adventure for Mac, using a keyboard and trackpad. The player is a locally respected wizard who becomes legendary through helping people and restoring troubled places. The wizard's name, robes, hairstyle, complexion, and staff appearance are customizable.

The tone combines frightening wilderness and ancient ruins with warmth, companionship, and hope in settlements. Use original fantasy characters, names, story, and assets. The inspiration is the presence of a trusted wandering wizard, Terraria's class and gear progression, adventure loot discoveries, and a four-spell combat loadout.

The world is mostly connected. Players walk between nearby locations and discover optional routes. Distant trips between regions show an animated journey while the destination loads. Quests exist inside the world. A central storyline coexists with local choices and optional discoveries.

There is no mining, conventional crafting, destructible block terrain, multiplayer, survival hunger, or elaborate base construction. Building is a small supporting activity.

Build the first playable adventure described here. Give all approved systems a small working example. Extendable data and scenes should make later regions practical, but do not build an empty campaign or promise mechanics that only have menu buttons. Content names, passive designs, item counts, percentages, and timing values below are selected production defaults. They are concrete starting decisions, not facts about an existing game. Preserve the agreed systems and priorities while tuning these defaults through actual play.

### First-build content contract

- One sanctuary, one village, one connected woodland route, and one distant ruined ward site.
- Three playable classes: Pyromancer, Hexbinder, Stormcaller.
- Four equipped spells at a time, plus a separate class-specific free basic attack.
- Four spells per school, twelve total, plus three basic attacks. Every spell has a base version and one visibly different upgraded version.
- Six base relics, duplicate upgrades through three tiers, and three authored cross-relic recipes.
- Three staffs and three robes with different effects. At least four hairstyle choices, three robe looks, three staff looks, and complexion choices. All unlocked appearances can be used independently of equipment stats.
- Five regular enemy roles, one troll miniboss, and a two-phase corrupted forest guardian boss.
- One recruitable companion found during the adventure; none at the start.
- Double jump and brief float unlocks; three contextual magic interactions.
- One local story choice, changed dialogue, and a visibly restored village.
- Simple free placement of six structure/decor types at home.
- Animated distant travel, checkpoints, save/load, settings, and a pause menu.

Target a 20–30 minute first playthrough. Quality and a complete loop matter more than an exact duration. A later campaign can add new regions, creatures, companions, and spells after this slice works.

## 2. Engine and project setup

Use a stable Godot 4 version, typed GDScript, native scenes, and native resources. Detect the available Godot version and record it in the README; consult documentation for that version. Use Godot 4.2 or newer because integer stretch scaling is required. Do not silently install or change the user's engine installation.

Start with the Compatibility renderer. Create rich effects using compatible particles, additive sprites, authored arc/ring textures, and custom 2D trails. The look must remain effective without relying on advanced HDR or renderer-specific effects. Verify every shader against the actual renderer.

Use a 640 × 360 base game viewport, nearest texture filtering, viewport stretch, preserved aspect ratio, and integer scaling. Keep rendered pixels consistent across actors, environment, effects, and UI. Test Mac window resizing and Retina display behavior. Use a readable UI with keyboard focus, and keep collision physics smooth while rendered camera/actor positions avoid pixel shimmer.

Use clear, focused units, for example:

```text
project.godot
scenes/main.tscn
game/player/          # movement, layered appearance, spell slots, class state
game/combat/          # damage, statuses, projectiles, targeting, effect presentation
game/enemies/         # shared actor behavior and distinct role scenes
game/companions/      # follow, attack, support, recovery
game/world/           # locations, encounters, contextual magic, quest consequences
game/home/            # simple placement and home services
game/items/           # inventory, equipment, fusion
game/ui/              # HUD, spell wheel, character setup, dialogue, menus
data/                 # stable-ID resources for spells, items, classes, enemies, recipes
assets/               # original sprites, effects, UI, sound, and music
tests/                # focused rule and integration checks
docs/                 # implementation checklist, tuning, playtest results
```

Equivalent organization is fine. Keep health, mana, movement, combat, UI, and persistence from becoming one giant player script. Use signals and small shared interfaces where needed. Save state, world transitions, and session state may be autoloads; avoid a large network of global managers. Keep balance values in resources rather than scattered scripts. Use a small native test runner if no test framework is already present; avoid installing a framework just to assert simple rules.

## 3. Controls and movement

The game must be comfortable with a Mac keyboard and trackpad. Do not require right click, a mouse wheel, rapid clicking, or precise pointer gestures.

Initial remappable controls:

| Action | Default |
| --- | --- |
| Move | A / D |
| Climb / drop through | W / S when applicable |
| Jump | Space |
| Double jump | Space again after the unlock |
| Float | Hold Space while falling after the unlock |
| Dodge | Shift |
| Basic attack | J; left click is an optional alternate |
| Four equipped spells | 1 / 2 / 3 / 4 |
| Interact / contextual magic | E |
| Spell wheel | Tab toggle |
| Inventory / equipment | I |
| Quest journal | Q |
| Building mode at home | B |
| Pause / back | Escape |

Keep keyboard shortcuts independent of macOS modifier-click conventions. Key prompts update after remapping. Keyboard selection and confirmation must work in menus, the spell wheel, dialogue, equipment, and building.

Provide Assisted and Direct aim settings. Assisted is the default: prefer a visible target near the cursor; when the cursor has no suitable target, use a target in the wizard's facing direction. Keep target selection stable, show a subtle indicator, and never target through solid walls. Direct aim follows the cursor. Both allow keyboard casting, so the player can move the cursor and then press attack keys without holding a trackpad click. With no target, fire in the chosen direction instead of refusing to cast.

Movement has immediate acceleration, variable jump height, approximately 100 ms of coyote time, approximately 120 ms of jump buffering, and a reliable directional dodge. These are tuning starting points. Use short, readable recovery rather than long uninterruptible animation locks. Most spells and the basic attack allow movement. Dodge can interrupt the vulnerable portion of a cast, consuming already-committed resources without creating a free spell.

Unlock double jump through an early discovery. Unlock a short float through helping a woodland creature. Use them for optional routes and secrets; the initial critical route remains accessible before the unlocks. No infinite flight.

## 4. Three classes and mixed builds

Choose an initial school during character setup. All three are available for free switching at the sanctuary's study. Character progression and discovered spells persist across switches. Maintain a saved four-slot loadout per class. Begin with the selected school's four base spells; switching makes the other schools' four base spells available. Later spells and upgrades can be discovered or earned.

Native spells have 100% base effectiveness. Foreign spells begin at 75%; investment in that foreign school raises affinity to 85%, 95%, then 100%. Affinity scales positive spell effects, not mana cost, cooldown duration, or animation speed. Healing and shielding scale where present. Control effects retain their advertised behavior rather than failing randomly. Show exact effective values in the spellbook.

Any unlocked spell can occupy a slot, including all four foreign spells if the player deliberately wants that build. Each spell appears only once per loadout. Only the active class's passive applies, and passive triggers use that school's spells. This preserves class identity even after foreign affinity is trained.

Production defaults for school passives:

- **Pyromancer — Heat:** successful native fire casts build up to three heat charges. The next native damaging spell spends them for a stronger impact and a short burn spread. One cast awards at most one charge; effects cannot recursively generate heat.
- **Hexbinder — Soul Echo:** cursed enemies killed by the player grant a small, capped recovery pulse and a short spectral effect. The passive is independent of ordinary mana drops and cannot proc from its own damage.
- **Stormcaller — Conduction:** every third successful native lightning cast adds one reduced-damage chain to a nearby enemy with line of sight. One cast counts once, and chains never trigger another chain recursively.

Starting spell concepts, implemented as data and distinct effects:

| School | Four spells |
| --- | --- |
| Pyromancer | Ember Spear: piercing fire projectile; Cinder Fan: close cone; Hearth Ward: protective burning ring; Ashfall: targeted ember shower |
| Hexbinder | Grave Needle: projectile that applies curse; Binding Roots: ground control; Siphon Circle: area damage and bounded recovery; Spirit Lantern: orbiting spirit that intercepts an attack and retaliates |
| Stormcaller | Arc Lance: aimed lightning; Thunder Ring: close radial push; Slipstream: wind dash that scatters existing embers; Tempest Orb: lingering lightning zone |

Each class also has its own basic staff attack: a short flame pulse, spectral thrust, or electric gust. It costs zero mana and has a brief repeat interval. At close range it creates modest knockback. It cannot permanently stun-lock enemies. Bosses resist displacement, while still showing impacts and stagger opportunities.

Use one visible upgrade tier for each spell initially. Add a genuinely different shape or event: an extra ring, forked projectile, spreading spirit, longer trail pattern, or changed casting detail. Communicate the mechanical change in the upgrade preview. Do not represent evolution solely by larger damage or a recolor.

## 5. Combat, mana, spell swapping, and difficulty

Maintain exactly four equipped active spell slots and the separate free basic attack. Skills such as dodge, double jump, float, and contextual magic remain outside those slots.

Use mana plus per-spell cooldowns. Start with a slow baseline mana recovery, a small return on successful basic hits, and mana motes dropped by defeated enemies. A dodge that avoids an active attack can grant a small recovery pulse once per dodge; ordinary movement dodges do not grant mana. Motes move toward the wizard within pickup range and expire after a short time. Equipment can improve pickup radius, mana gained, or recovery after specific actions. Boss encounters have a recovery route even when ordinary enemies are absent. The basic attack always provides an option at zero mana.

Mana costs and cooldowns are previewed before equipping. A failed cast gives brief feedback and consumes nothing. Track cooldowns by stable spell ID, including unequipped spells. Swapping, school switching, death/reload transitions, and save/load must not create unintended cooldown resets; an explicit checkpoint respawn may reset the encounter's combat state consistently.

Tab opens a keyboard-accessible spell wheel/book at 15% simulation speed. The player chooses a slot, then an unlocked spell, and confirms. UI navigation runs at normal speed, while enemies, projectiles, mana regeneration, cooldowns, and status timers all use slowed simulation time. Closing restores the prior game speed. Pause, death, dialogue, focus loss, and scene changes must restore the correct state. UI input cannot accidentally fire an equipped spell.

One initial difficulty: challenging but fair. Ordinary enemies have clear windups, attack/recovery windows, and meaningful damage. Avoid unavoidable off-screen attacks, surprise contact damage before a tell, and routine full-health one-hit kills. Bosses reward pattern learning and positioning rather than damage sponges. Decorative effects never hide attack cues.

Checkpoints restore health, mana, and the nearby encounter after defeat. The player retains loot, spells, equipment, upgrades, recruits, story choices, completed objectives, fusion results, and home placement. Bosses reset their encounter health unless already defeated. Add brief protection on respawn. Avoid spawning the player inside enemies or hazards.

## 6. Three deliberate spell interactions

Implement these authored interactions first, with clear icons or visual marks and short explanatory text:

1. **Haunted Embers:** burning a cursed enemy creates a spectral ember that seeks one nearby enemy when the victim dies. One ember per eligible victim; its damage cannot spawn more embers.
2. **Grave Current:** lightning can conduct to a nearby cursed enemy, with line of sight and a bounded chain count. Chain damage does not recursively repeat the interaction.
3. **Cinderflight:** a wind dash or burst crossing burning ground/embers scatters a short fan of ember projectiles. One trigger per dash/area pair, with a cooldown.

These are readable combat rules, not a general-purpose chemistry simulation. Cross-school spells work together, and corresponding fusion relics enhance these rules without requiring both schools in the loadout. Define the distinction in tooltips so an ordinary spell interaction and its relic upgrade never accidentally apply twice.

## 7. Loot, equipment, upgrades, and fusion

Use authored item identities with modest capped random bonuses. Put the strongest identity in behavior, not tiny percentage differences. Guarantee critical discoveries and the companion through quests; randomness cannot block progression.

Initial slots: one staff, one robe, and two relics. A separate appearance panel selects unlocked looks without changing stats. Hair and complexion are cosmetic. Equipment changes silhouette details and spell embellishments while retaining the common animation scale.

Six base relic names/default concepts: Ember Seed, Stormglass, Whisper Bone, Gale Feather, Moonstone, Ward Bell. Give each one a clear effect. Matching copies of the same relic at the same tier combine into the next tier, up to tier III. Provide obtainable duplicate drops or repeat encounters so this is usable in the slice.

Three cross-relic recipes:

- Ember Seed + Whisper Bone → Haunted Ember: improves the bounded cursed-burn effect.
- Stormglass + Whisper Bone → Grave Current: enables or improves conduction through curse marks.
- Ember Seed + Gale Feather → Cinderflight: improves ember scattering during wind movement.

Cross-relic recipes initially accept tier-I inputs only and produce tier-I results. Their results may also use matching-copy tier upgrades when copies become available. The UI explicitly explains eligible inputs and rejects unsupported tier combinations. This avoids silently destroying the value of higher-tier items.

At the sanctuary's fusion station, show the two owned input instances, whether each is equipped, the exact output, and its effect before confirmation. Validate ownership, distinct instance IDs, tiers, compatibility, and available capacity. Commit consumption and output creation atomically. If an input was equipped, unequip it as part of the same transaction; the output starts unequipped. Invalid operations preserve both items. Save the completed transaction, and make it impossible to duplicate items by reloading.

Shared progression points buy visible spell upgrades and cross-school training. Keep the first skill panel compact and comprehensible. Document starting balance values and tune them through play; avoid building an enormous skill tree.

## 8. Connected world, quests, and useful magic

Use the following original first-adventure framing. These names are working production defaults.

**Sanctuary → Hearthmere village → Briarwood path → distant Old Ward ruins.** The sanctuary, village, and nearby woodland connect through playable exits. The remote ruin uses a travel link reached from the woodland route. A world map shows learned connections and unlocked distant journeys.

People already know the wizard locally. The village's ward has gone dark, travelers are disappearing, and roots have begun to overrun the road. The wizard investigates, helps survivors, discovers a damaged ward, and confronts the corrupted guardian protecting it. The opening should teach movement and one spell through a short interaction, then start play quickly. Use brief dialogue instead of a long unskippable introduction.

Implement three contextual magic events, using E and a visible prompt:

- Relight a roadside ward, visibly making the area safer.
- Lift a fallen trunk to reopen a route.
- Calm a frightened woodland creature, earning the brief float ability.

These are authored interactions and animations. They do not require unequipping a combat spell. A discovered hidden doorway can demonstrate revealing magic later; keep the first three interactions complete before adding more.

Include a compact journal and one local choice: a rescued herbalist can settle at the sanctuary or help rebuild the village. Both choices provide access to an equivalent small buff service, but their location, dialogue, and surrounding decoration differ. Preview the consequence. The choice never blocks the central story or the combat companion.

After the guardian is defeated and the ward restored, village lanterns return, travelers appear, dialogue changes, and a restored-road detail appears. Persist these changes across loading and travel. Quest rewards use unique event IDs and cannot be granted twice.

The first adventure moves the wizard from local respect to wider recognition. A later campaign earns legendary status over time; do not declare the player legendary after the first boss.

## 9. Enemies and bosses

Use original sprites and animations for five regular roles:

- Shield raider: protects a nearby caster; can be bypassed or pushed out of position.
- Hex caster: telegraphed ranged attacks and a vulnerable recovery period.
- Wolf-like flanker: fast approach, clear leap windup, and punishable landing.
- Root creature: controls part of the ground, encouraging movement.
- Hollow knight: slow armored elite with readable stagger opportunities.

Stage mixed encounters that demonstrate protection, flanking, control, and recovery. Keep initial crowds small enough for side-view readability. Do not have every enemy simply chase directly and deal touch damage. Their silhouettes, sounds, and tells distinguish them at a glance.

The miniboss is a troll wearing pieces of a broken gate. Its attacks reference the gate: a heavy sweep, a ground slam, and thrown rubble. Show substantial anticipation and recovery.

The main boss is a woodland guardian corrupted around an ancient ward. Its appearance blends old protective symbols with invading roots. Use two phases and three primary patterns: a sweeping limb, telegraphed root eruptions, and a ranged corrupted seed burst. The transition changes patterns and presentation without an unavoidable damage burst. Telegraphs remain on top of decorative magic. Place a checkpoint immediately before each boss.

Boss death or cleansing visibly affects the location. Include a short aftermath moment and guaranteed meaningful loot. Every encounter must work without a companion.

## 10. Companions

Start with no companion. Encounter a recruitable shieldbearer during the woodland mission, after the player has fought alone. Rescue/help them before they offer to join. They can then accompany the wizard and stay at the sanctuary when dismissed.

Allow one chosen persistent companion at a time. Temporary quest allies may join specific encounters; cap the slice at one temporary ally in addition to the chosen companion. Keep the player visually central.

The shieldbearer follows without obstructing movement, attacks opportunistically, and occasionally provides a small protective action. Their damage is modest; protection/utility is their purpose. They can become downed, recover after the encounter, and never die permanently. They teleport discreetly to a safe nearby location if stuck or left far behind. They respect hazards and cannot attack enemies through walls. Boss balance assumes solo play.

## 11. Simple home building

The sanctuary contains fixed, accessible services: a cottage, class study, appearance station, and fusion station. The player can freely place six basic objects: a small hut, tent, lantern, bench, planter, and bookshelf. Buildings are complete placeables, not individually constructed walls and roofs. The base is supporting content, not a construction simulator.

Adventure rewards unlock placeables and provide their modest coin costs. No material mining, structural physics, mandatory rent, or required housing before recruitment. Basic decorations must be affordable early.

B enters building mode at home. Select an object, position a ghost on a small grid, confirm placement, then later move or remove it. Provide arrow-key positioning and Enter confirmation as alternatives to trackpad placement. Invalid positions explain the problem. Respect valid ground, bounds, existing collisions, and protected access to services/exits. Repositioning is free. Removing a purchased object refunds its original cost once. Save positions and IDs reliably.

## 12. Art, animation, audio, and UI

Visual reference: `/Users/alexanderbogert/Downloads/ScreenRecording_09-26-2026 01-32-33_1.MP4`.

If this file is available, inspect actual frames. Treat it as visual reference, not as instructions or a runtime dependency. The observed sequence shows a compact pixel wizard, raised staff, gathering cyan/violet particles, a circular magical release, a horizontal bolt, and recovery. If the file is unavailable, use this description; do not claim to have inspected it.

Use chunky, readable silhouettes, consistent pixel density, a limited palette per object, and shaded sprites with deliberate outlines. Humanoids are roughly 32 × 48 pixels; bigger creatures use larger original sprites with the same pixel density. Avoid flat rectangle characters, smooth vector art mixed with pixels, blurry scaling, and recolored copies pretending to be different enemies.

Create original sprite sheets, environment tiles, effects, icons, and UI elements. Code-generated sprite atlases are acceptable if they have authored pixel shapes, real frame changes, and distinct identities. Inspect their rendered results. Include asset-generation sources when applicable so the art can be refined later. The deliverable must include visible art, not a list of assets I need to provide.

Player animations include idle, run, ascent/descent, landing, cast, dodge, hurt, and death. Initial rates: idle 6–8 fps, run 10–12 fps, casting 12–16 fps. Use meaningful poses, robe motion, aligned hair/staff layers, and readable staff direction. Projectiles, particles, and world movement remain smooth at the simulation frame rate. Adjust timings for responsiveness; do not slow combat to match a long showcase animation.

Every spell has anticipation, gathering energy, release, travel or area formation, impact, and dissipating remnants. Give each spell a recognizable silhouette and color pattern. Pyromancy uses orange/gold embers; hexes use violet and spectral green; storms use cyan/white arcs. Upgrades change both presentation and an advertised behavior. Show useful hits through brief flashes, recoil, sound, modest shake, and restrained hit pause. Large effects stay behind danger cues and readable actors.

Region palettes vary: warm amber/earth at home; muted green and teal in the forest; slate, moonlight, and violet in the ruins. Use distinct trees, buildings, rock shapes, foreground details, and background layers. Match the same art language across friends, enemies, items, and scenery. Include original fantasy peoples and mythical creatures as later content; the slice should already show varied forms.

Include original or suitably licensed sound for casting, release, impact, footsteps, mana pickup, discovery, fusion, UI, travel, and the boss. Add a short calm home loop and a tense exploration/battle loop. If sounds are synthesized, design them as actual sound effects rather than one repeated beep. Keep an asset/source manifest. Full voice acting is outside this build.

The HUD shows health, mana, class identity, four spell icons with hotkeys/cooldowns, and the free attack. Add concise quest prompts, clear item comparisons, affinity display, and readable fusion previews. Menus use consistent pixel graphics and keyboard focus. Pause/settings include remapping, audio sliders, aim mode, window/fullscreen, and reduced shake/flashes. These visual comfort settings do not create extra difficulty modes. Pause on focus loss to protect play with macOS app switching.

## 13. Persistence and transitions

Use a versioned local save in Godot's `user://` location. Persist character name/appearance, class/loadouts, progression, inventory instances, equipment and cosmetic overrides, recipes/discoveries, recruited allies, companion selection, quests, local choice, world changes, defeated bosses, home placement, settings, and checkpoint position. Keep permanent progress separate from temporary encounter state.

Autosave at checkpoints, quest outcomes, loot discoveries, completed fusion, home edits, school changes, and major world transitions. A temporary-file write and validated replacement with a previous backup should keep interruptions from destroying progress. Reject invalid/unknown item IDs safely. Corrupt or incompatible saves should show a recoverable message and offer a backup; do not silently overwrite existing progress. New Game requires an explicit in-game decision to replace the existing slot.

Checkpoints cannot duplicate unique loot or rewards. Reopening a scene applies saved world changes once. Companion recruitment and placement are idempotent. Cooldown, timescale, and UI state must remain consistent across pause, wheel, travel, defeat, and loading.

Short connected exits use a brief transition without a long travel screen. The distant ward site uses a real animated journey with a looping wizard silhouette, scrolling scenery, and destination text while background loading completes. Check load status before retrieving the scene so the animation does not freeze. Do not add a long fake wait to disguise small scenes. Handle failed loading with a clear return option instead of an endless loop.

## 14. Build in stages

Make each stage playable, verify it, update the checklist, then continue. Do not wait for approval at every routine stage. Keep useful version-control checkpoints if this project has Git; never commit unrelated work or initialize a repository in a broad parent folder.

1. **Prove the feel and visual style.** Configure the project, controls, camera, pixel scaling, layered wizard, movement, dodge, one polished spell, a free attack, one enemy, and a tiny combat scene. Verify actual casting and impact animation before multiplying content.
2. **Complete the combat toolkit.** Add all three schools, four-slot loadouts, mana/cooldowns, wheel, foreign affinity, upgraded spell visuals, five enemy roles, and the three bounded interactions. Verify every spell and mixed build.
3. **Build the adventure.** Connect sanctuary, village, and woodland; add remote travel, contextual magic, movement unlocks, quests, checkpoint respawn, miniboss, guardian, and visible aftermath.
4. **Complete discoveries and home.** Add loot/equipment, progression, cosmetics, fusion, the earned companion, simple placement, the local choice, and complete persistence. Place these systems naturally in the adventure rather than only in debug menus.
5. **Refine and hand off.** Play the whole adventure, fix readability and pacing, inspect art and sound, profile busy combat, verify save/load, and prepare the Mac run/export instructions and evidence.

## 15. Verification and completion requirements

Run the project with the detected Godot executable. Check import/parse errors before claiming it runs. Use meaningful automated checks for rules most likely to break, and visual playtesting for feel/art. Do not claim screenshots prove controls work, or that headless tests prove animation quality.

Focused automated checks should cover:

- Four unique spell slots, availability validation, native/foreign affinity, and only the active school passive.
- Failed casts consuming nothing; basic attack at zero mana; cooldown preservation through swapping; bounded status interactions without recursive procs.
- Fusion using two distinct owned instances; correct tiers; invalid inputs unchanged; equipped inputs handled; transaction persistence without duplication.
- Exactly-once quest/recruit/reward events, checkpoint inventory retention, defeated-boss persistence, and world consequences after revisiting.
- Placement bounds, overlapping/protected positions, repositioning, and one-time refunds.
- Save round-trip, invalid IDs, backup recovery, and load failure handling.

Manual integration checks should cover:

- Movement, jumping, dodging, casting, wheel navigation, dialogue, loot, equipment, and building using a keyboard and trackpad without right click.
- Every school playing differently; every base and upgraded spell visibly working; readable enemy tells during the busiest encounter.
- Mixed enemy formations, all solo boss patterns, and a valid zero-mana recovery path during bosses.
- No companion at the start; earned recruitment; companion recovery and getting unstuck.
- Both local choice outcomes, village restoration, useful magic, and long/short travel behavior.
- Death, focus loss, pause, spell wheel, save/load, and scene transition restoring normal timing and input correctly.
- Crisp graphics and usable HUD in resizable Mac windows and fullscreen.

Aim for a steady 60 fps in the busiest included encounter. Measure on available hardware and record the machine/context instead of claiming performance on Macs you did not test. Bound particles, projectiles, and active encounters based on profiling rather than premature complexity.

Prepare a short evidence report with commands/checks actually run, pass/fail results, screenshots of all three classes and several locations, and a brief gameplay capture if possible. If GUI, Mac hardware, or export templates are unavailable, finish unaffected work and state the exact checks that remain. Do not describe the project as fully verified while those checks remain.

Deliver a project that opens with its assets included, a README with exact engine version and run steps, a completed/remaining checklist, controls, tuning notes, asset sources, and a Mac export preset. Create and test a local Mac export when the required templates are available. Public distribution, signing, notarization, and store publishing are separate tasks.

At handoff, report what is playable, where to open/run it, how to control it, what was verified, and any concrete remaining limitation. Finish the complete slice, rather than stopping after scaffolding or a combat demo.

## Engine references

Use the documentation matching the selected version. The stable guides supporting these engine choices are:

- Compatibility as a starting renderer for 2D: [Godot renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
- Viewport, preserved aspect ratio, and integer scaling for crisp pixel art: [Godot multiple resolutions guide](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html).
- Non-blocking scene loading for an animated journey: [Godot background loading guide](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html).

Start by inspecting the environment, writing the checklist, and building the combat-and-art foundation. Then continue through the complete first adventure.
