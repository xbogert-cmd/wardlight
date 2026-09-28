class_name SpellCaster
extends Node
## Four spell slots + the free basic attack, driven by the WizardState's
## active loadout. Cooldowns are tracked per spell id on the caster's own
## clock (slowed by the spellbook, never reset by swapping or switching
## school). Mana and cooldown are committed when the windup starts; a dodge
## during windup cancels the spell without refunding it.

signal cast_failed(slot: int, reason: String)
signal cast_started(data: SpellData)
signal cast_released(data: SpellData, ctx: CastContext)

enum { IDLE, WINDUP, RECOVER }

const BASIC_SLOT := -1
const BUFFER_TIME := 0.18

var player: Node3D
var mana: Mana
var aim: Aim
var clock := 0.0
var ready_at := {}      # spell id -> clock time when usable again

var state := IDLE
var cur: SpellData
var cur_slot := 0
var ctx: CastContext
var t := 0.0
var _effects := {}
var _buffer_slot := -99
var _buffer_t := 0.0


func _physics_process(delta: float) -> void:
	clock += delta
	match state:
		WINDUP:
			t += delta
			_refresh_ctx()
			_effect(cur).gather(ctx, clampf(t / maxf(cur.windup, 0.001), 0.0, 1.0), delta)
			if t >= cur.windup:
				_release()
		RECOVER:
			t += delta
			if t >= cur.recovery:
				state = IDLE
	if _buffer_slot != -99:
		_buffer_t -= delta
		if _buffer_t <= 0.0:
			_buffer_slot = -99
		elif state == IDLE:
			var s := _buffer_slot
			_buffer_slot = -99
			request(s, true)


func spell_in(slot: int) -> SpellData:
	var id: StringName = player.wiz.basic() if slot == BASIC_SLOT else player.wiz.loadout()[slot]
	return SpellDB.get_spell(id) if id != &"" else null


func remaining(id: StringName) -> float:
	return maxf(0.0, ready_at.get(id, 0.0) - clock)


func busy() -> bool:
	return state != IDLE


## Why a cast would fail right now ("" = it would start).
func check(slot: int) -> String:
	var data := spell_in(slot)
	if data == null:
		return "empty"
	if remaining(data.id) > 0.0:
		return "cooldown"
	if not mana.can_spend(data.mana_cost):
		return "mana"
	return ""


## Returns true if the cast started. Failure consumes nothing.
func request(slot: int, quiet: bool = false) -> bool:
	if not player.can_cast():
		return false
	if state == WINDUP or (state == RECOVER and t < cur.recovery * 0.6):
		if not (quiet and slot == BASIC_SLOT):  # a held attack just retries next frame
			_buffer_slot = slot
			_buffer_t = BUFFER_TIME
		return false
	var why := check(slot)
	if why != "":
		if not quiet:
			cast_failed.emit(slot, why)
		return false
	var data := spell_in(slot)
	mana.spend(data.mana_cost)
	ready_at[data.id] = clock + data.cooldown
	cur = data
	cur_slot = slot
	t = 0.0
	ctx = CastContext.new()
	ctx.caster = player
	ctx.data = data
	ctx.upgraded = player.wiz.upgrades.has(data.id)
	ctx.native = player.wiz.is_native(data.school)
	ctx.power = player.wiz.affinity_mult(data.school)
	ctx.world = player.get_parent()
	_refresh_ctx()
	cast_started.emit(data)
	if data.windup <= 0.0:
		_release()
	else:
		state = WINDUP
		Sfx.play(data.school + "_gather", -6.0)
	return true


## Dodge / hurt: drop the windup. Resources stay spent (no free spell).
func interrupt() -> void:
	if state == WINDUP:
		state = IDLE
	_buffer_slot = -99


func _refresh_ctx() -> void:
	ctx.origin = player.cast_origin()
	aim.update_aim(ctx.origin)
	ctx.dir = aim.dir_from(ctx.origin)
	ctx.target = aim.target
	if aim.target:
		ctx.aim_point = aim.target.center()
	elif aim.mouse_active or Settings.aim_mode == "direct":
		ctx.aim_point = aim.cursor
	else:
		ctx.aim_point = SpellEffect.ground_at(player.global_position + ctx.dir * 8.0, player)
	if absf(ctx.dir.x) > 0.05:
		player.face(signi(int(signf(ctx.dir.x))))


func _release() -> void:
	# pick the pointing pose for this direction, then aim from the real gem
	_refresh_ctx()
	player.on_cast_release(cur, ctx)
	_refresh_ctx()
	player.passives.on_release(ctx)
	_effect(cur).cast(ctx)
	state = RECOVER
	t = 0.0
	cast_released.emit(cur, ctx)


func _effect(data: SpellData) -> SpellEffect:
	if not _effects.has(data.id):
		_effects[data.id] = data.effect.new()
	return _effects[data.id]


## Aim angle bucket (0..4) for the release pose: the staff points up the
## screen for shots away from the camera, down for shots toward it.
func pose_index() -> int:
	if ctx == null:
		return 2
	return pose_for(ctx.dir)


static func pose_for(d: Vector3) -> int:
	var ang := rad_to_deg(atan2(d.z * 0.7, absf(d.x)))
	var best := 2
	var bd := 999.0
	for k in WizardArt.AIM_ANGLES.size():
		var diff := absf(ang - WizardArt.AIM_ANGLES[k])
		if diff < bd:
			bd = diff
			best = k
	return best
