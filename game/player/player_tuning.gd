class_name PlayerTuning
extends Resource
## Movement and survival numbers for the wizard (see data/tuning/player.tres).
## Distances in metres, speeds in m/s (1 m = 24 sprite pixels).

@export_group("Move")
@export var run_speed := 4.8
@export var accel := 42.0
@export var decel := 55.0
@export var gravity := 22.0
@export_group("Levitate")
## Hold Space to hover a little above the ground (stage 3 unlock).
@export var float_height := 0.9
@export var float_time := 1.6
@export var float_speed_mult := 0.8
@export_group("Dodge")
@export var dodge_speed := 12.5
@export var dodge_time := 0.2
@export var dodge_iframes := 0.17
@export var dodge_cooldown := 0.4
@export_group("Combat")
@export var cast_move_mult := 0.6
@export var hurt_time := 0.28
@export var hurt_iframes := 0.8
@export var respawn_iframes := 1.5
@export var max_hp := 100.0
@export var max_mana := 100.0
@export var mana_regen := 2.5
@export var basic_hit_mana := 3.0
@export var perfect_dodge_mana := 8.0
@export var mote_pickup_radius := 2.7
