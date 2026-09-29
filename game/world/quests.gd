class_name Quests
## Quest definitions. Progress lives in GameState.quests (id -> step, -1 done).

const MAIN := &"dark_ward"
const HOLLOWING := &"hollowing"      # Chapter 2
const SHRINES := [&"shrine_chapel", &"shrine_mire", &"shrine_grove"]
const DATA := {
	&"dark_ward": {
		"title": "The Dark Wardlight",
		"steps": [
			"Go to Hearthmere and speak with Elder Maren.",
			"Take the Briarwood road east. Relight the roadside ward.",
			"Clear the fallen trunk blocking the road.",
			"Find the missing travellers beyond the broken gate.",
			"Travel to the Old Ward from the waystone.",
			"Cleanse the Old Ward.",
			"Return to Hearthmere with the news.",
		],
	},
	&"hollowing": {
		"title": "The Hollowing",
		"steps": [
			"Find out who has come to Hearthmere's square.",
			"Take a waystone to the Fenway with Kess.",
			"Follow the marsh road to Reedhollow.",
			"Relight the lake shrines.",
			"Defend Reedhollow.",
			"Relight the last lake shrine.",
			"Cross to the Heart Isle.",
		],
	},
	&"lost_child": {
		"title": "Lost in the Mire",
		"steps": ["Find Pip, Wenna's son, somewhere in the Mire.", "Tell Wenna in Reedhollow that Pip is safe."],
	},
	&"far_watch": {
		"title": "Beyond the East",
		"steps": ["Find Orla's spyglass at the far watchtower (boat from Reedhollow).", "Bring the spyglass back to Orla in Reedhollow."],
	},
	&"fawn": {
		"title": "Something in the Reeds",
		"steps": ["Calm the frightened creature by the stream."],
	},
	&"isolde": {
		"title": "A Place for Isolde",
		"steps": ["Talk to Isolde about where she will settle."],
	},
}


## Chapter 2 opens once Chapter 1 is finished (and only once).
static func hollowing_ready() -> bool:
	return GameState.quest_done(MAIN) and GameState.quest_step(HOLLOWING) == -2


## The main quest the HUD and map follow: Chapter 2 once it has begun.
static func current_main() -> StringName:
	return HOLLOWING if GameState.quest_step(HOLLOWING) != -2 else MAIN


static func shrines_lit() -> int:
	return SHRINES.filter(func(f: StringName) -> bool: return GameState.flag(f)).size()


static func title(id: StringName) -> String:
	return DATA.get(id, {}).get("title", String(id))


## Current step text, or "" when not active.
static func step_text(id: StringName) -> String:
	var s := GameState.quest_step(id)
	var steps: Array = DATA.get(id, {}).get("steps", [])
	return steps[s] if s >= 0 and s < steps.size() else ""
