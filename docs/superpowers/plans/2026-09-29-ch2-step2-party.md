# Chapter 2 Step 2: Companions, Party of Two, Kess Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two companions can travel with the wizard at once. Tamsin moves onto a shared `Companion` base, Kess the scout is added (ranged shots, a marking arrow, hopping back), the sanctuary gets a companion camp, and saves move to version 2.

**Architecture:** `GameState` swaps its single `companion` dict for `recruited` (id → true) and `party` (ordered ids, max 2), with a version-1 migration in `from_dict`. `Companion` (new base) owns the body, sprite, talk prompt, hurt/downed/recover, following, unsticking and warping; `Shieldbearer` and `Scout` only choose targets and act. `Main.sync_party()` keeps one node per party member. The mark is a status (`&"mark"`) that `CastContext.hit` consumes.

**Tech Stack:** Godot 4.7.1, typed GDScript, the in-repo test runner.

## Global Constraints

- `GameState.PARTY_MAX = 2`. Everyone else waits at the sanctuary camp.
- Save format version 2. A version-1 save's `companion` becomes `recruited`/`party`; items without a tier load as tier 1 (already true).
- Kess: attacks the wizard's current target or the nearest visible enemy within 10 m; a marking arrow every 6 s; mark = +25% on the wizard's next spell hit on that enemy (staff attacks and procs don't use it up); hops back when an enemy is within 2.5 m; knocked down, never dies, recovers.
- Companions are never the reason a fight is lost: no one-hit kills on them, they never block the wizard (collision layer 16).
- Kess's two "hidden route" hints and Tamsin–Kess banter belong to the areas that host them (steps 3 and 5), not here.
- Kess joins for real in Reedhollow (step 3). Here she's recruited by a demo command for testing.
- Full check after every task: `tools/dev/check.sh` prints `CHECK OK` and `TESTS PASSED n`.

---

### Task 1: Party state and save version 2

**Files:**
- Modify: `game/core/game_state.gd` (state, `reset`, `to_dict`, `from_dict`, new party functions)
- Modify: `game/core/save_system.gd` (`VERSION := 2`)
- Modify callers of `GameState.companion`: `game/world/briarwood.gd` (recruit, `apply_state`), `game/world/sanctuary.gd` (Tamsin NPC, `apply_state`), `game/companions/shieldbearer.gd` (talk), `game/main.gd` (`sync_companion`), `game/core/demo_driver.gd` (`state` print)
- Test: `tests/test_party.gd` (new)

**Interfaces:**
- Produces on `GameState`:
  - `const PARTY_MAX := 2`
  - `var recruited := {}` (StringName → true), `var party: Array[StringName] = []`
  - `func recruit(id: StringName, follow: bool) -> void` (follows only if there is room)
  - `func join_party(id: StringName) -> String` ("" or a reason it can't)
  - `func leave_party(id: StringName) -> void`
  - `func in_party(id: StringName) -> bool`

- [ ] **Step 1: Failing tests** — `tests/test_party.gd`:

```gdscript
extends RefCounted
## Party membership, its limit, and loading Chapter 1 saves.

var t


func test_party_limit() -> void:
	GameState.reset()
	GameState.recruit(&"tamsin", true)
	GameState.recruit(&"kess", true)
	t.eq(GameState.party, [&"tamsin", &"kess"] as Array[StringName], "two can follow")
	GameState.recruit(&"orla", true)
	t.check(GameState.recruited.has(&"orla"), "a third can still be recruited")
	t.check(not GameState.in_party(&"orla"), "but waits at the camp")
	t.check(GameState.join_party(&"orla") != "", "joining a full party is refused")
	GameState.leave_party(&"tamsin")
	t.eq(GameState.join_party(&"orla"), "", "room again after someone rests")
	t.check(GameState.join_party(&"nobody") != "", "only recruited companions can join")
	GameState.reset()


func test_party_round_trip() -> void:
	GameState.reset()
	GameState.recruit(&"tamsin", false)
	GameState.recruit(&"kess", true)
	var d: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(d)
	t.check(GameState.recruited.has(&"tamsin") and GameState.recruited.has(&"kess"), "recruits kept")
	t.eq(GameState.party, [&"kess"] as Array[StringName], "party kept")
	GameState.reset()


func test_version1_save_migrates() -> void:
	var v1 := {"name": "Wren", "companion": {"recruited": true, "following": true},
		"inv": {"items": [{"uid": 1, "id": "stormcoil"}], "equipped": {"staff": 1}}}
	GameState.from_dict(v1)
	t.check(GameState.recruited.has(&"tamsin"), "Chapter 1's Tamsin stays recruited")
	t.eq(GameState.party, [&"tamsin"] as Array[StringName], "and still follows")
	t.eq(int(GameState.inv.find(1).tier), 1, "an untiered staff loads as tier I")
	GameState.from_dict({"companion": {"recruited": true, "following": false}})
	t.eq(GameState.party.size(), 0, "a resting Tamsin stays at the sanctuary")
	var junk := {"recruited": ["tamsin", "kess", "orla"], "party": ["tamsin", "kess", "orla", "tamsin", "ghost"]}
	GameState.from_dict(junk)
	t.eq(GameState.party, [&"tamsin", &"kess"] as Array[StringName], "a damaged party list is trimmed to recruits, no repeats, max 2")
	GameState.reset()
	t.eq(SaveSystem.VERSION, 2, "saves are version 2")
```

- [ ] **Step 2:** Run `tools/dev/check.sh` — expect failures naming `recruit`, `party`.
- [ ] **Step 3: Implement** `GameState`:

```gdscript
const PARTY_MAX := 2
var recruited := {}                  # companion id -> true
var party: Array[StringName] = []    # who walks with the wizard, in order
```

`reset()` clears both. `to_dict()` writes `"recruited": recruited.keys(), "party": party` instead of `"companion"`. `from_dict()`:

```gdscript
	var c: Dictionary = d.get("companion", {})      # version 1 (Chapter 1)
	if c.get("recruited", false):
		recruited[&"tamsin"] = true
		if c.get("following", false):
			party.append(&"tamsin")
	for k in d.get("recruited", []):
		recruited[StringName(k)] = true
	for k in d.get("party", []):
		var id := StringName(k)
		if recruited.has(id) and not party.has(id) and party.size() < PARTY_MAX:
			party.append(id)
```

Functions:

```gdscript
func in_party(id: StringName) -> bool:
	return party.has(id)


## Recruit a companion; they follow straight away if asked and there's room.
func recruit(id: StringName, follow: bool) -> void:
	recruited[id] = true
	if follow:
		join_party(id)
	changed.emit()


func join_party(id: StringName) -> String:
	if not recruited.has(id):
		return "They haven't joined you yet."
	if party.has(id):
		return ""
	if party.size() >= PARTY_MAX:
		return "Two already walk with you. Ask one to rest at the camp first."
	party.append(id)
	changed.emit()
	return ""


func leave_party(id: StringName) -> void:
	if party.has(id):
		party.erase(id)
		changed.emit()
```

`SaveSystem.VERSION := 2`. Callers: Briarwood recruit → `GameState.recruit(&"tamsin", k == 0)`; Briarwood `apply_state` → `GameState.recruited.has(&"tamsin")`; Sanctuary Tamsin "Come with me" → `join_party` (say the refusal if not ""); Sanctuary waiting → `recruited.has(id) and not in_party(id)`; Shieldbearer "Wait at the sanctuary" → `leave_party(&"tamsin")`; `Main.sync_companion` reads `GameState.in_party(&"tamsin")` (replaced in Task 2); demo `state` print shows `party=` and `recruited=`.

- [ ] **Step 4:** `tools/dev/check.sh` passes; `tools/dev/run.sh /tmp/t.log 40 --path . -- --demo=tamsin --shots=/tmp/shots_tamsin` still ends with Tamsin following (`state tamsin` prints `party=[&"tamsin"]`).
- [ ] **Step 5: Commit** `Party of up to two; save version 2 migrates Chapter 1 saves`.

---

### Task 2: The `Companion` base

**Files:**
- Create: `game/companions/companion.gd`
- Modify: `game/companions/shieldbearer.gd` (keeps only targeting, spear, shield guard)
- Modify: `game/main.gd` (`companion` → `companions: Dictionary`, `sync_companion` → `sync_party`, `_load_region` reparenting)
- Modify: every `sync_companion()` call → `sync_party()`
- Test: `tests/test_party.gd`

**Interfaces:**
- Produces `class_name Companion extends CharacterBody3D`:
  - fields `id: StringName`, `display: String`, `sheet: String`, `max_hp: float`, `speed: float`, `slot: int` (0 or 1 = place in the party), `hp`, `state`, `facing`, `sprite`
  - `static func make(id: StringName) -> Companion` (`&"tamsin"` → `Shieldbearer`, `&"kess"` → `Scout`)
  - `func follow_spot(p: Player) -> Vector3` — slot 0 behind-right as today, slot 1 behind-left and further back
  - `func move_to(goal: Vector3, delta: float) -> void`
  - virtual `func _act(p: Player, delta: float) -> void` (default: follow)
  - kept: `player()`, `center()`, `radius()`, `height()`, `is_alive()`, `take_hit()`, `warp_near()`, downed/recover, `_unstick()`, the talk prompt (`"Talk to <display>"` → Keep close / Wait at the sanctuary)
- `Main.companions: Dictionary` (id → Companion), `Main.sync_party() -> void`

- [ ] **Step 1: Failing test** (append to `tests/test_party.gd`):

```gdscript
func test_companion_make() -> void:
	var a := Companion.make(&"tamsin")
	var b := Companion.make(&"kess")
	t.check(a is Shieldbearer and b is Scout, "each id makes its own kind")
	t.eq(a.display, "Tamsin", "Tamsin is named")
	t.eq(b.display, "Kess", "Kess is named")
	t.check(Companion.make(&"nobody") == null, "unknown ids make nothing")
	a.free()
	b.free()
```

- [ ] **Step 2:** check fails (`Companion` unknown).
- [ ] **Step 3:** Move everything from `Shieldbearer` except `_act`, `_pick_target`, `_enemy_winding_up`, the guard constants and `ATTACK_DMG` into `Companion`, parameterised by `id/display/sheet/max_hp/speed`. The follow branch of `_act` becomes `follow_spot()` + `move_to()`. `Shieldbearer._init()` sets `id = &"tamsin"`, `display = "Tamsin"`, `sheet = "tamsin"`, `max_hp = 90.0`, `speed = 5.4`. `Main.sync_party()` frees nodes whose id left the party and creates `Companion.make(id)` for new ones, sets `slot` from the party index, reparents to the level and `warp_near`s on region change.
- [ ] **Step 4:** check passes; the `tamsin` demo behaves as before (capture `c2_follow`, `c3_fight` and compare with Chapter 1 behaviour: she follows, spears, guards, recovers).
- [ ] **Step 5: Commit** `Companion base: Tamsin's follow/downed/unstick shared by every companion`.

---

### Task 3: Kess the scout and the marking arrow

**Files:**
- Create: `game/companions/scout.gd`
- Modify: `tools/art/npcs_art.gd` (`scout()` sheet: bow, hood, reed-green and teal), `tools/gen_art.gd` (save `npc_kess`)
- Modify: `game/combat/statuses.gd` (`MARK_MULT := 1.25`, doc line), `game/combat/cast_context.gd` (`hit` consumes the mark), `game/combat/status_overlay.gd` (a gold arrowhead above marked enemies)
- Modify: `game/core/demo_driver.gd` (`recruit` command, `party` demo)
- Test: `tests/test_party.gd`

**Interfaces:**
- Consumes: `Companion` (Task 2)
- Produces: `class_name Scout extends Companion`; `Statuses.MARK_MULT`; status id `&"mark"` (8 s)

- [ ] **Step 1: Failing test:**

```gdscript
func test_mark_used_by_one_spell_hit() -> void:
	GameState.reset()
	var p: Player = t.make_player("storm")
	await t.frames(2)
	var e: Enemy = t.make_enemy(Vector3(3, 0, 0))
	e.statuses.apply(&"mark", 8.0)
	var ctx := CastContext.new()
	ctx.caster = p
	ctx.data = SpellDB.get_spell(&"arc_lance")
	var hp0 := e.health.hp
	ctx.hit(e, Damage.make(20.0, p, &"storm"))
	t.near(hp0 - e.health.hp, 25.0, "the marked hit deals +25%")
	t.check(not e.statuses.has(&"mark"), "the mark is used up")
	var hp1 := e.health.hp
	ctx.hit(e, Damage.make(20.0, p, &"storm"))
	t.near(hp1 - e.health.hp, 20.0, "the next hit is normal")
	e.statuses.apply(&"mark", 8.0)
	var basic := CastContext.new()
	basic.caster = p
	basic.data = SpellDB.get_spell(&"storm_gust")
	basic.hit(e, Damage.make(7.0, p, &"storm"))
	t.check(e.statuses.has(&"mark"), "a staff attack leaves the mark for a spell")
	GameState.reset()
```

(If the hound's `block_scale` or armour changes the numbers, compare against an unmarked control hit on a second hound instead of fixed values.)

- [ ] **Step 2:** check fails.
- [ ] **Step 3: Implement.** In `CastContext.hit`, before `take_hit`:

```gdscript
	if not d.is_proc and not data.is_basic and target_actor.statuses.has(&"mark"):
		target_actor.statuses.remove(&"mark")
		d.amount *= Statuses.MARK_MULT
		FX3.ring(target_actor.center(), 0.1, 0.9, 0.25, [Color("fff0c0"), Color("f0c870"), Color("a07840")], 1.0, false)
```

`Scout` (`id &"kess"`, `display "Kess"`, `sheet "kess"`, `max_hp 70`, `speed 5.8`):
  - target: `Aim`'s current target if the wizard has one within 10 m and in sight, else the nearest visible enemy within 10 m of Kess
  - stands at her follow spot; if an enemy is within 2.5 m, hops 2.5 m directly away (0.25 s, `hop` anim), 1.5 s cooldown
  - shoots every 1.3 s: a `Projectile` (`team &"player"`, `style &"needle"`, reed-green ramp, speed 16) for 5 damage; every 6 s the shot is a marking arrow (gold ramp) that also applies `&"mark"` for 8 s
  - a 0.3 s `draw` anim before each shot (the tell for the player that she's firing)
- [ ] **Step 4:** Art: `Npcs.scout()` with anims `idle 4, walk 6, draw 2, shoot 2, hop 2, hurt 1, downed 2, rise 2`; `godot --headless --path . --script tools/gen_art.gd -- npcs` then `--import`. Demo `party`: travel to Briarwood, `recruit kess` (+ Tamsin), walk, fight; shots `p1_follow`, `p2_fight`, `p3_mark`.
- [ ] **Step 5:** check passes; captures reviewed. **Commit** `Kess the scout: ranged support and a marking arrow`.

---

### Task 4: Sanctuary companion camp

**Files:**
- Modify: `game/world/sanctuary.gd` (camp: fire + two bedrolls; waiting companions stand there; talk offers Come with me / Rest here)
- Modify: `tools/art/props_art.gd` or reuse existing props for the fire and bedrolls

- [ ] **Step 1:** Replace the single `tamsin` NPC with one camp NPC per companion id (`tamsin`, `kess`), placed around a campfire west of the house. Each is visible only if `recruited.has(id) and not in_party(id)`. Talking: "Come with me" → `GameState.join_party(id)`; a non-empty reason is spoken by the companion. Then `sync_party()` and `SaveSystem.autosave()`.
- [ ] **Step 2:** Capture the camp (`--demo=camp`: recruit both, rest both, travel to sanctuary, shot `k1_camp`) and check it follows the camera rule (nothing taller than ~1.6 m between camera and the camp).
- [ ] **Step 3:** check passes. **Commit** `Sanctuary companion camp`.

---

### Task 5: Hand-off

- [ ] Checklist: tick step 2, note that Kess's recruitment scene, route hints and banter arrive with steps 3 and 5.
- [ ] Send the owner the captures (Tamsin unchanged, Kess's look, a fight with both, the mark, the camp). Kess's look and the camp are **look** items: wait for OK.
