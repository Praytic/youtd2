extends Node


enum enm {
	BEGINNER,
	EASY,
	MEDIUM,
	HARD,
	EXTREME,
}


const _string_map: Dictionary = {
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
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Difficulty.enm.BEGINNER
