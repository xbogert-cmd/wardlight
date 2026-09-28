extends Node
## Small signal hub for cross-cutting combat events (passives, interactions,
## quests). Holds no state.

signal enemy_killed(enemy: Node3D, last_hit: Damage)
signal damage_dealt(target: Node3D, d: Damage)
