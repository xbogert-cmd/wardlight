class_name Quests
## Quest definitions. Progress lives in GameState.quests (id -> step, -1 done).

const MAIN := &"dark_ward"
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
	&"fawn": {
		"title": "Something in the Reeds",
		"steps": ["Calm the frightened creature by the stream."],
	},
	&"isolde": {
		"title": "A Place for Isolde",
		"steps": ["Talk to Isolde about where she will settle."],
	},
}


static func title(id: StringName) -> String:
	return DATA.get(id, {}).get("title", String(id))


## Current step text, or "" when not active.
static func step_text(id: StringName) -> String:
	var s := GameState.quest_step(id)
	var steps: Array = DATA.get(id, {}).get("steps", [])
	return steps[s] if s >= 0 and s < steps.size() else ""
