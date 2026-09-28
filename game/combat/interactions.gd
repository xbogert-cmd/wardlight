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

const GRAVE_CURRENT_RANGE := 120.0
const GRAVE_CURRENT_MULT := 0.6
const HAUNTED_EMBER_DAMAGE := 16.0
const CINDER_EMBERS := 4
const CINDER_DAMAGE := 7.0

## Relic bonuses (stage 4) raise these; interactions read them each time.
static var grave_current_chains := 1
static var haunted_ember_bonus := 0.0
static var cinderflight_bonus := 0


static func on_spell_hit(ctx: CastContext, target: Node2D, d: Damage) -> void:
	if d.school == &"storm":
		_grave_current(ctx, target, d)


static func _grave_current(ctx: CastContext, from_actor: Node2D, d: Damage) -> void:
	var done: Array = [from_actor]
	var from: Vector2 = from_actor.center()
	for k in grave_current_chains:
		var best: Node2D = null
		var bd := GRAVE_CURRENT_RANGE
		for e: Node2D in SpellEffect.enemies():
			if done.has(e) or not e.statuses.has(&"curse"):
				continue
			var dist := from.distance_to(e.center())
			if dist < bd and SpellEffect.has_los(from, e.center(), from_actor):
				bd = dist
				best = e
		if best == null:
			return
		done.append(best)
		FX.bolt(from, best.center(), 0.22, Pal.school(&"storm"), 3.0, 1.0, true)
		FX.bolt(from, best.center(), 0.22, Pal.SPECTRAL, 5.0, 1.0, true)
		FX.burst(best.center(), 8, Pal.SPECTRAL, Vector2(30, 90), Vector2(0.15, 0.3), {"gravity": 100.0})
		var pd := ctx.proc_dmg(d.amount * GRAVE_CURRENT_MULT, &"storm", &"grave_current")
		ctx.hit(best, pd)
		Sfx.play("storm_zap", -4.0)
		from = best.center()


static func on_enemy_died(enemy: Node2D, last: Damage) -> void:
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
	p.velocity = Vector2(0, -90)
	p.max_dist = 420.0
	p.homing = true
	p.turn_rate = 7.0
	p.speed_cap = 230.0
	var src: Node = last.source
	enemy.get_parent().add_child(p)
	p.global_position = enemy.center()
	FX.burst(enemy.center(), 12, Pal.SPECTRAL, Vector2(20, 70), Vector2(0.3, 0.6), {"gravity": -40.0})
	Sfx.play("hex_spirit", -4.0)
	p.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void:
		var d := Damage.make(HAUNTED_EMBER_DAMAGE + haunted_ember_bonus, src, &"hex")
		d.spell_id = &"haunted_ember"
		d.is_proc = true
		d.hit_pos = pos
		a.statuses.apply(&"burn", 2.0, 3.0, src)
		a.take_hit(d)
		FX.burst(pos, 12, Pal.SPECTRAL, Vector2(40, 110), Vector2(0.15, 0.35), {"gravity": 150.0})
		FX.ring(pos, 2.0, 14.0, 0.2, Pal.SPECTRAL))


## Scatter embers from burning ground touched by a wind effect.
## `hits_area` is a Callable(patch: EmberPatch) -> bool.
static func cinderflight(ctx: CastContext, hits_area: Callable, dir: Vector2) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for patch: EmberPatch in tree.get_nodes_in_group(&"ember_patch"):
		if patch.consumed or not hits_area.call(patch):
			continue
		patch.consumed = true
		var origin := patch.global_position + Vector2(0, -4)
		var n := CINDER_EMBERS + cinderflight_bonus
		for k in n:
			var ang := dir.angle() + lerpf(-0.45, 0.45, float(k) / maxf(1.0, n - 1.0))
			var p := Projectile.new()
			p.style = &"ember"
			p.ramp = Pal.school(&"fire")
			p.velocity = Vector2.from_angle(ang) * 300.0
			p.max_dist = 150.0
			p.radius = 3.0
			ctx.spawn(p)
			p.global_position = origin
			p.hit_actor.connect(func(a: Node2D, pos: Vector2) -> void:
				var d := ctx.proc_dmg(CINDER_DAMAGE, &"fire", &"cinderflight")
				d.hit_pos = pos
				d.statuses.append({"id": &"burn", "duration": 2.0, "power": 3.0})
				ctx.hit(a, d)
				FX.burst(pos, 6, Pal.school(&"fire"), Vector2(30, 80), Vector2(0.15, 0.3), {"gravity": 120.0}))
		FX.burst(origin, 14, Pal.school(&"fire"), Vector2(60, 160), Vector2(0.2, 0.4), {"dir": dir, "spread": 1.2, "gravity": 80.0})
		Sfx.play("fire_whoosh", -3.0)
		patch.extinguish()
