extends RefCounted
## Party membership, its limit, and loading Chapter 1 saves.

var t


func test_party_limit() -> void:
	GameState.reset()
	GameState.recruit(&"tamsin", true)
	GameState.recruit(&"kess", true)
	t.eq(GameState.party, [&"tamsin", &"kess"] as Array[StringName], "two can follow")
	GameState.recruit(&"orla", true)
	t.check(GameState.recruited.has(&"orla"), "a third can still be recruited")
	t.check(not GameState.in_party(&"orla"), "but waits at the camp")
	t.check(GameState.join_party(&"orla") != "", "joining a full party is refused")
	GameState.leave_party(&"tamsin")
	t.eq(GameState.join_party(&"orla"), "", "room again after someone rests")
	t.check(GameState.join_party(&"nobody") != "", "only recruited companions can join")
	GameState.reset()


func test_party_round_trip() -> void:
	GameState.reset()
	GameState.recruit(&"tamsin", false)
	GameState.recruit(&"kess", true)
	var d: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(d)
	t.check(GameState.recruited.has(&"tamsin") and GameState.recruited.has(&"kess"), "recruits kept")
	t.eq(GameState.party, [&"kess"] as Array[StringName], "party kept")
	GameState.reset()


func test_version1_save_migrates() -> void:
	var v1 := {"name": "Wren", "companion": {"recruited": true, "following": true},
		"inv": {"items": [{"uid": 1, "id": "stormcoil"}], "equipped": {"staff": 1}}}
	GameState.from_dict(v1)
	t.check(GameState.recruited.has(&"tamsin"), "Chapter 1's Tamsin stays recruited")
	t.eq(GameState.party, [&"tamsin"] as Array[StringName], "and still follows")
	t.eq(int(GameState.inv.find(1).tier), 1, "an untiered staff loads as tier I")
	GameState.from_dict({"companion": {"recruited": true, "following": false}})
	t.eq(GameState.party.size(), 0, "a resting Tamsin stays at the sanctuary")
	var junk := {"recruited": ["tamsin", "kess", "orla"], "party": ["tamsin", "kess", "orla", "tamsin", "ghost"]}
	GameState.from_dict(junk)
	t.eq(GameState.party, [&"tamsin", &"kess"] as Array[StringName], "a damaged party list is trimmed to recruits, no repeats, max 2")
	GameState.reset()
	t.eq(SaveSystem.VERSION, 2, "saves are version 2")
