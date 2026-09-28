class_name PlayerTuning
extends Resource
## Movement and survival numbers for the wizard (see data/tuning/player.tres).

@export_group("Run")
@export var run_speed := 118.0
@export var accel := 1500.0
@export var decel := 1900.0
@export var air_accel := 1100.0
@export_group("Jump")
@export var jump_height := 58.0
@export var gravity_up := 950.0
@export var gravity_down := 1350.0
@export var jump_cut := 0.45
@export var max_fall := 380.0
@export var coyote := 0.10
@export var jump_buffer := 0.12
@export var double_jump_height := 40.0
@export var float_fall_speed := 36.0
@export var float_time := 0.9
@export_group("Dodge")
@export var dodge_speed := 300.0
@export var dodge_time := 0.2
@export var dodge_iframes := 0.17
@export var dodge_cooldown := 0.4
@export_group("Combat")
@export var cast_move_mult := 0.7
@export var hurt_time := 0.28
@export var hurt_iframes := 0.8
@export var respawn_iframes := 1.5
@export var max_hp := 100.0
@export var max_mana := 100.0
@export var mana_regen := 2.5
@export var basic_hit_mana := 3.0
@export var perfect_dodge_mana := 8.0
@export var mote_pickup_radius := 64.0
