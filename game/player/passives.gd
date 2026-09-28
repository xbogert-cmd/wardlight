class_name Passives
extends Node
## Class passives. Only the active school's passive runs, and only that
## school's native spells (not the free basic attack) trigger it.
##   Pyromancer / Heat: each native fire cast that lands adds 1 charge (max 3,
##     once per cast). At 3 charges the next native damaging fire spell spends
##     them: +15% power per charge and its hits spread a short burn.
##   Hexbinder / Soul Echo: killing a cursed enemy grants a small recovery pulse
##     (at most one per second). The pulse deals no damage.
##   Stormcaller / Conduction: every third native lightning cast that lands
##     adds one reduced-damage chain to a nearby enemy (line of sight). Chains
##     are proc damage and never chain again.

signal changed

const HEAT_MAX := 3
const HEAT_PER_CHARGE := 0.15
const ECHO_HP := 5.0
const ECHO_MANA := 6.0
const ECHO_COOLDOWN := 1.0
const CONDUCTION_EVERY := 3
const CONDUCTION_MULT := 0.5
const CONDUCTION_RANGE := 130.0

var player: Node2D
var heat := 0
var storm_count := 0
var _echo_cd := 0.0


func _ready() -> void:
	Events.enemy_killed.connect(_on_enemy_killed)


func school() -> String:
	return player.wiz.school


func _physics_process(delta: float) -> void:
	_echo_cd = maxf(0.0, _echo_cd - delta)


func reset() -> void:
	heat = 0
	storm_count = 0
	changed.emit()


## Before a spell's effect runs.
func on_release(ctx: CastContext) -> void:
	if not ctx.native or ctx.data.is_basic:
		return
	if school() == "fire" and ctx.data.school == "fire" and heat >= HEAT_MAX and ctx.data.damage > 0.0:
		ctx.bonus["heat"] = heat
		ctx.power *= 1.0 + HEAT_PER_CHARGE * heat
		heat = 0
		changed.emit()
		FX.ring(ctx.origin, 2.0, 16.0, 0.25, Pal.school(&"fire"), 1.0, true)
		FX.burst(ctx.origin, 14, Pal.school(&"fire"), Vector2(50, 130), Vector2(0.2, 0.4), {"gravity": -60.0})
		Sfx.play("fire_heat", -2.0)


## First and later real hits of a cast.
func on_cast_hit(ctx: CastContext, target: Node2D, d: Damage) -> void:
	if not ctx.native or ctx.data.is_basic:
		return
	match school():
		"fire":
			if ctx.data.school == "fire" and not ctx.bonus.has("heat") and not ctx.bonus.has("heat_gained"):
				ctx.bonus["heat_gained"] = true
				if heat < HEAT_MAX:
					heat += 1
					changed.emit()
		"storm":
			if ctx.data.school == "storm" and not ctx.bonus.has("conduction_counted"):
				ctx.bonus["conduction_counted"] = true
				storm_count += 1
				if storm_count >= CONDUCTION_EVERY:
					storm_count = 0
					_conduct(ctx, target, d)
				changed.emit()


func _conduct(ctx: CastContext, from_actor: Node2D, d: Damage) -> void:
	var from: Vector2 = from_actor.center()
	var e := SpellEffect.nearest(from, CONDUCTION_RANGE, [from_actor], from_actor)
	if e == null:
		return
	FX.bolt(from, e.center(), 0.25, Pal.school(&"storm"), 5.0, 1.0, true, 2)
	FX.burst(e.center(), 10, Pal.school(&"storm"), Vector2(40, 120), Vector2(0.1, 0.3), {"gravity": 180.0})
	var pd := ctx.proc_dmg(d.amount * CONDUCTION_MULT, &"storm", &"conduction")
	ctx.hit(e, pd)
	Sfx.play("storm_zap", -2.0)


func _on_enemy_killed(enemy: Node2D, last: Damage) -> void:
	if school() != "hex" or last == null or last.source != player:
		return
	if not enemy.statuses.has(&"curse") or _echo_cd > 0.0:
		return
	_echo_cd = ECHO_COOLDOWN
	player.health.heal(ECHO_HP)
	player.mana.gain(ECHO_MANA)
	# a spirit wisp flies from the body to the wizard
	var p := Projectile.new()
	p.style = &"spectral"
	p.ramp = Pal.SPECTRAL
	p.team = &"none"
	p.velocity = Vector2(0, -80)
	p.homing_point = player
	p.turn_rate = 9.0
	p.speed_cap = 260.0
	p.max_dist = 600.0
	enemy.get_parent().add_child(p)
	p.global_position = enemy.center()
	FX.ring(player.center(), 3.0, 18.0, 0.3, Pal.SPECTRAL, 1.0, true)
	Sfx.play("hex_echo", -4.0)
