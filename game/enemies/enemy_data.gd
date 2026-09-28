class_name EnemyData
extends Resource
## Stable-id enemy definition. Behaviour lives in the enemy's script.

@export var id: StringName
@export var display_name := ""
@export var sheet := ""
@export var origin := Vector2(28, 38)      # feet point inside a sheet cell
@export var body_size := Vector2(24, 18)   # collision box (feet at origin)
@export var max_hp := 60.0
@export var damage := 14.0
@export var move_speed := 120.0
@export var poise := 18.0                  # stagger needed to flinch
@export var knock_resist := 0.0            # 0 = full knockback, 1 = immovable
@export var flinch_cooldown := 1.4
@export var motes := 2
@export var aggro_range := 260.0
@export var params: Dictionary = {}
