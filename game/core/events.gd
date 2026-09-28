extends Node
## Small signal hub for cross-cutting combat events (passives, interactions,
## quests). Holds no state.

signal enemy_killed(enemy: Node2D, last_hit: Damage)
signal damage_dealt(target: Node2D, d: Damage)
