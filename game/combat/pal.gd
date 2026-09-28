class_name Pal
## Shared effect colour ramps (bright → dark). Pixel effects step through
## these instead of lerping, which keeps them crisp.

const SCHOOL := {
	&"fire": [Color("fff6c8"), Color("ffd24a"), Color("ff8a24"), Color("d9401c"), Color("7a1c14")],
	&"hex": [Color("f4e8ff"), Color("c88cff"), Color("8a4ae0"), Color("4f2a9a"), Color("2a1650")],
	&"storm": [Color("ffffff"), Color("b4f6ff"), Color("52cfff"), Color("3a78f0"), Color("5a3ab8")],
	&"": [Color("ffffff"), Color("e0dcd0"), Color("a8a090"), Color("6a6458"), Color("3a3630")],
}
const SPECTRAL := [Color("e8fff4"), Color("8affc8"), Color("3ad69a"), Color("1e8a66"), Color("0e4a3a")]
const DANGER := [Color("fff0c0"), Color("ffb040"), Color("ff5030"), Color("b01830")]
const MANA := [Color("ffffff"), Color("b8e8ff"), Color("5aaaff"), Color("3a5ae0"), Color("2a2a90")]
const SMOKE := [Color("6a6478", 0.8), Color("4a4458", 0.6), Color("342e40", 0.4)]
const DUST := [Color("8a7a6a"), Color("6a5a50"), Color("4a3e3a")]
const HEAL := [Color("ffffff"), Color("d0ffb0"), Color("80e060"), Color("3a9a3a")]


static func school(s: StringName) -> Array:
	return SCHOOL.get(s, SCHOOL[&""])
