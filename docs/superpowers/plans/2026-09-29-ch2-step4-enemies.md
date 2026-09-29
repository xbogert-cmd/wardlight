# Chapter 2 Step 4: New Enemies and Hollowed Variants Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chapter 2's enemy roster: the Husk, the Mire Lurker, the Hollow Moth (with its spores), and hollowed versions of the five familiar enemies.

**Architecture:** Each new enemy is an `Enemy` subclass with an `EnemyData` resource and a generated sprite sheet (`tools/art/hollow_art.gd`). Hollowed variants are the existing classes with `Enemy.hollowed = true` (set by `Region.spawn(kind, x, z, {"hollowed": true})`): data copied with +20% move speed, a mask drawn over the face, and one extra attack each. A new status `slow` (power = fraction) feeds `Statuses.move_scale()`, which the player and enemies already use.

## Global Constraints

- Every attack has a clear tell; nothing attacks from off-screen (aggro ≤ ~11 m, the Lurker only hunts within 8 m); no one-hit kills from full health; decoration never hides attack cues.
- Husk: slow; telegraphed lunge; on death a 3 s spore patch that slows walkers by 40%, with a visible edge.
- Mire Lurker: hidden ripple (untargetable, can't be hit); surfaces under the wizard after a 0.8 s ring warning; exposed on land for 2 s.
- Hollow Moth: flies ~1.8 m up, keeps 6–9 m away, fires slow homing spores that can be dodged and are destroyed by any spell (a spore is a 1-HP enemy with no rewards); low health.
- Hollowed: +20% move speed; hound double lunge, raider spinning follow-up, hexer second delayed bolt, knot larger thorn ring, sentinel a second wider shockwave (it already has one).
- Step 4 is a **(feel)** gate: capture fight clips per enemy, wait for the owner.

### Task 1: Hooks — `slow` status, `Enemy.hollowed`, mask overlay, spawn options (tests: slow scales move, hollowed copies data +20% speed without touching the shared resource)
### Task 2: Art — `hollow_art.gd` sheets `husk`, `lurker`, `moth`, `spore`; data `.tres` for each; `Region.ENEMIES` entries
### Task 3: Husk + `SporePatch` (tests: patch slows the player inside it, not outside, and is gone after 3 s)
### Task 4: Mire Lurker (tests: can't be hurt or targeted while hidden; hurtable while exposed)
### Task 5: Hollow Moth + Spore (tests: a spore dies to one hit and gives no rewards)
### Task 6: Hollowed behaviours for hound, raider, hexer, knot, sentinel
### Task 7: Fenway gets its first Husks; `--demo=bestiary` fight clips per enemy; checklist; send clips
