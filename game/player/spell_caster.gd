class_name SpellCaster
extends Node
## Four spell slots + the free basic attack. Cooldowns are tracked per spell
## id on the caster's own clock (slowed by the spell wheel, never reset by
## swapping). Mana and cooldown are committed when the windup starts; a dodge
## during windup cancels the spell without refunding it.

signal cast_failed(slot: int, reason: String)
signal cast_started(data: SpellData)
signal cast_released(data: SpellData, ctx: CastContext)
signal loadout_changed

enum { IDLE, WINDUP, RECOVER }

const BASIC_SLOT := -1
const BUFFER_TIME := 0.18

var player: Node2D
var mana: Mana
var aim: Aim
var loadout: Array[StringName] = [&"", &"", &"", &""]
var basic_id := &"storm_gust"
var upgrades := {}      # spell id -> true
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
	var id := basic_id if slot == BASIC_SLOT else loadout[slot]
	return SpellDB.get_spell(id) if id != &"" else null


func remaining(id: StringName) -> float:
	return maxf(0.0, ready_at.get(id, 0.0) - clock)


func busy() -> bool:
	return state != IDLE


## Returns true if the cast started. Failure consumes nothing.
func request(slot: int, quiet: bool = false) -> bool:
	if not player.can_cast():
		return false
	if state == WINDUP or (state == RECOVER and t < cur.recovery * 0.6):
		if not (quiet and slot == BASIC_SLOT):  # held attack just retries next frame
			_buffer_slot = slot
			_buffer_t = BUFFER_TIME
		return false
	var data := spell_in(slot)
	if data == null:
		if not quiet:
			cast_failed.emit(slot, "empty")
		return false
	if remaining(data.id) > 0.0:
		if not quiet:
			cast_failed.emit(slot, "cooldown")
		return false
	if not mana.can_spend(data.mana_cost):
		if not quiet:
			cast_failed.emit(slot, "mana")
		return false
	mana.spend(data.mana_cost)
	ready_at[data.id] = clock + data.cooldown
	cur = data
	cur_slot = slot
	t = 0.0
	ctx = CastContext.new()
	ctx.caster = player
	ctx.data = data
	ctx.upgraded = upgrades.has(data.id)
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
		ctx.aim_point = ctx.origin + ctx.dir * 200.0
	if absf(ctx.dir.x) > 0.05:
		player.face(signi(int(signf(ctx.dir.x))))


func _release() -> void:
	# choose the pointing pose from the shoulder, then aim from the real gem
	_refresh_ctx()
	var shoulder: Vector2 = player.global_position + Vector2(0, -24)
	ctx.dir = (ctx.aim_point - shoulder).normalized() if ctx.aim_point.distance_to(shoulder) > 4.0 else ctx.dir
	player.on_cast_release(cur, ctx)
	_refresh_ctx()
	_effect(cur).cast(ctx)
	state = RECOVER
	t = 0.0
	cast_released.emit(cur, ctx)


func _effect(data: SpellData) -> SpellEffect:
	if not _effects.has(data.id):
		_effects[data.id] = data.effect.new()
	return _effects[data.id]


## Aim angle bucket (0..4) for the release pose, relative to facing.
func pose_index() -> int:
	if ctx == null:
		return 2
	var ang := rad_to_deg(atan2(ctx.dir.y, absf(ctx.dir.x)))
	var best := 2
	var bd := 999.0
	for k in WizardArt.AIM_ANGLES.size():
		var d := absf(ang - WizardArt.AIM_ANGLES[k])
		if d < bd:
			bd = d
			best = k
	return best


func equip(slot: int, id: StringName) -> void:
	# a spell appears only once: equipping it elsewhere swaps the two slots
	var prev := loadout.find(id)
	if prev != -1 and prev != slot:
		loadout[prev] = loadout[slot]
	loadout[slot] = id
	loadout_changed.emit()
