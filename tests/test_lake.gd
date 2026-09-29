extends RefCounted
## Chapter 2's lake: opening condition, quest order, enemy scaling.

var t


func test_opening_only_after_chapter1() -> void:
	GameState.reset()
	t.check(not Quests.hollowing_ready(), "a new game can't start Chapter 2")
	GameState.start_quest(Quests.MAIN)
	GameState.advance(Quests.MAIN, 5)
	t.check(not Quests.hollowing_ready(), "not while Chapter 1 is running")
	GameState.advance(Quests.MAIN, -1)
	t.check(Quests.hollowing_ready(), "ready once Chapter 1 is done")
	t.eq(Quests.current_main(), Quests.MAIN, "the HUD still shows Chapter 1 until the opening")
	GameState.start_quest(Quests.HOLLOWING)
	t.check(not Quests.hollowing_ready(), "the opening plays once")
	t.eq(Quests.current_main(), Quests.HOLLOWING, "then the HUD follows Chapter 2")
	GameState.reset()


func test_shrine_count() -> void:
	GameState.reset()
	t.eq(Quests.shrines_lit(), 0, "none lit")
	GameState.set_flag(&"shrine_mire")
	GameState.set_flag(&"shrine_chapel")
	t.eq(Quests.shrines_lit(), 2, "any order counts")
	GameState.reset()


func test_enemy_scale_copies_data() -> void:
	var base: EnemyData = preload("res://data/enemies/hound.tres")
	var hp := base.max_hp
	var s := Region.scaled_data(base, 1.25)
	t.near(s.max_hp, hp * 1.25, "health scaled")
	t.near(s.damage, base.damage * 1.25, "damage scaled")
	t.near(base.max_hp, hp, "the shared resource is untouched")


func test_slow_status_scales_movement() -> void:
	var st := Statuses.new()
	t.near(st.move_scale(), 1.0, "unhindered")
	st.apply(&"slow", 0.3, 0.4)
	t.near(st.move_scale(), 0.6, "spores slow walkers by 40%")
	st.apply(&"root", 1.0)
	t.near(st.move_scale(), 0.0, "roots still hold")
	st.free()


func test_hollowed_spawn_is_faster_copy() -> void:
	var base: EnemyData = preload("res://data/enemies/raider.tres")
	var speed := base.move_speed
	var d := Region.scaled_data(base, 1.0)
	d.move_speed *= 1.2
	t.near(d.move_speed, speed * 1.2, "hollowed walk 20% faster")
	t.near(base.move_speed, speed, "the shared raider data is untouched")
