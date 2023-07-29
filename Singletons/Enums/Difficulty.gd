extends Node


enum enm {
	NONE,
	BEGINNER,
	EASY,
	MEDIUM,
	HARD,
	EXTREME,
}


const _string_map: Dictionary = {
	Difficulty.enm.NONE: "none",
	Difficulty.enm.BEGINNER: "beginner",
	Difficulty.enm.EASY: "easy",
	Difficulty.enm.MEDIUM: "medium",
	Difficulty.enm.HARD: "hard",
	Difficulty.enm.EXTREME: "extreme",
}


func convert_to_string(type: Difficulty.enm):
	return _string_map[type]


func from_string(string: String) -> Difficulty.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid difficulty string: \"%s\"" % string)

		return Difficulty.enm.BEGINNER
