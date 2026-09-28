class_name Interactions
## The three authored cross-school rules. All interaction damage is proc
## damage, so none of them can trigger themselves or each other recursively.
##
## Haunted Embers — a burning *and* cursed enemy releases one spectral ember
##   when it dies; the ember seeks one nearby enemy.
## Grave Current — lightning that hits an enemy arcs once to a nearby cursed
##   enemy (line of sight required).
## Cinderflight — a wind dash or storm burst through burning ground scatters a
##   short fan of embers (once per patch per cast, patch then burns out).

const GRAVE_CURRENT_RANGE := 5.0
const GRAVE_CURRENT_MULT := 0.6
const HAUNTED_EMBER_DAMAGE := 16.0
const CINDER_EMBERS := 5
const CINDER_DAMAGE := 7.0

## Relic bonuses (stage 4) raise these; interactions read them each time.
static var grave_current_chains := 1
static var haunted_ember_bonus := 0.0
static var cinderflight_bonus := 0


static func on_spell_hit(ctx: CastContext, target: Node3D, d: Damage) -> void:
	if d.school == &"storm":
		_grave_current(ctx, target, d)


static func _grave_current(ctx: CastContext, from_actor: Node3D, d: Damage) -> void:
	var done: Array = [from_actor]
	var from: Vector3 = from_actor.center()
	for k in grave_current_chains:
		var best: Node3D = null
		var bd := GRAVE_CURRENT_RANGE
		for e: Node3D in SpellEffect.enemies():
			if done.has(e) or not e.statuses.has(&"curse"):
				continue
			var dist := SpellEffect.flat(from, e.center())
			if dist < bd and SpellEffect.has_los(from, e.center(), from_actor):
				bd = dist
				best = e
		if best == null:
			return
		done.append(best)
		FX3.bolt(from, best.center(), 0.22, Pal.school(&"storm"), 0.12)
		FX3.bolt(from, best.center(), 0.22, Pal.SPECTRAL, 0.2)
		FX3.burst(best.center(), 8, Pal.SPECTRAL, Vector2(1.2, 3.8), Vector2(0.15, 0.3), {"gravity": 4.0})
		var pd := ctx.proc_dmg(d.amount * GRAVE_CURRENT_MULT, &"storm", &"grave_current")
		ctx.hit(best, pd)
		Sfx.play("storm_zap", -4.0)
		from = best.center()


static func on_enemy_died(enemy: Node3D, last: Damage) -> void:
	if last == null or last.spell_id == &"haunted_ember":
		return
	if not (enemy.statuses.has(&"burn") and enemy.statuses.has(&"curse")):
		return
	if enemy.has_meta(&"ember_released"):
		return
	enemy.set_meta(&"ember_released", true)
	var p := Projectile.new()
	p.style = &"spectral"
	p.ramp = Pal.SPECTRAL
	p.velocity = Vector3(0, 3.8, 0)
	p.max_dist = 18.0
	p.homing = true
	p.turn_rate = 7.0
	p.speed_cap = 9.5
	p.ignore_walls = true
	var src: Node = last.source
	enemy.get_parent().add_child(p)
	p.global_position = enemy.center()
	FX3.burst(enemy.center(), 12, Pal.SPECTRAL, Vector2(0.8, 3.0), Vector2(0.3, 0.6), {"gravity": -1.6})
	Sfx.play("hex_spirit", -4.0)
	p.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
		var d := Damage.make(HAUNTED_EMBER_DAMAGE + haunted_ember_bonus, src, &"hex")
		d.spell_id = &"haunted_ember"
		d.is_proc = true
		d.hit_pos = pos
		a.statuses.apply(&"burn", 2.0, 3.0, src)
		a.take_hit(d)
		FX3.burst(pos, 12, Pal.SPECTRAL, Vector2(1.6, 4.6), Vector2(0.15, 0.35), {"gravity": 6.0})
		FX3.ring(pos, 0.1, 0.6, 0.2, Pal.SPECTRAL, 1.0, false))


## Scatter embers from burning ground touched by a wind effect.
## `hits_area` is a Callable(patch: EmberPatch) -> bool; `dir` is horizontal
## (or zero for an outward ring of embers).
static func cinderflight(ctx: CastContext, hits_area: Callable, dir: Vector3) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for patch: EmberPatch in tree.get_nodes_in_group(&"ember_patch"):
		if patch.consumed or not hits_area.call(patch):
			continue
		patch.consumed = true
		var origin := patch.global_position + Vector3(0, 0.5, 0)
		var n := CINDER_EMBERS + cinderflight_bonus
		for k in n:
			var v: Vector3
			if dir == Vector3.ZERO:
				v = Vector3.RIGHT.rotated(Vector3.UP, TAU * k / n)
			else:
				v = dir.rotated(Vector3.UP, lerpf(-0.5, 0.5, float(k) / maxf(1.0, n - 1.0)))
			var p := Projectile.new()
			p.style = &"ember"
			p.ramp = Pal.school(&"fire")
			p.velocity = v * 12.0
			p.max_dist = 6.0
			p.radius = 0.2
			p.lit = false
			ctx.spawn(p)
			p.global_position = origin
			p.hit_actor.connect(func(a: Node3D, pos: Vector3) -> void:
				var d := ctx.proc_dmg(CINDER_DAMAGE, &"fire", &"cinderflight")
				d.hit_pos = pos
				d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0})
				ctx.hit(a, d)
				FX3.burst(pos, 6, Pal.school(&"fire"), Vector2(1.2, 3.2), Vector2(0.15, 0.3), {"gravity": 5.0}))
		FX3.burst(origin, 16, Pal.school(&"fire"), Vector2(2.5, 6.5), Vector2(0.2, 0.4), {"dir": dir if dir != Vector3.ZERO else Vector3.UP, "spread": 1.2 if dir != Vector3.ZERO else 3.0, "gravity": 3.0})
		FX3.light(origin, Color(1.0, 0.55, 0.2), 3.0, 5.0, 0.3)
		Sfx.play("fire_whoosh", -3.0)
		patch.extinguish()
