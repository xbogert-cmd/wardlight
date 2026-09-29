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
