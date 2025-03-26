class_name Difficulty extends Node


enum enm {
	BEGINNER,
	EASY,
	MEDIUM,
	HARD,
	EXTREME,
}


static var _string_map: Dictionary = {
	Difficulty.enm.BEGINNER: "beginner",
	Difficulty.enm.EASY: "easy",
	Difficulty.enm.MEDIUM: "medium",
	Difficulty.enm.HARD: "hard",
	Difficulty.enm.EXTREME: "extreme",
}

static var _color_map: Dictionary = {
	Difficulty.enm.BEGINNER: Color.ROYAL_BLUE,
	Difficulty.enm.EASY: Color.LIME_GREEN,
	Difficulty.enm.MEDIUM: Color.YELLOW,
	Difficulty.enm.HARD: Color.RED,
	Difficulty.enm.EXTREME: Color.WEB_PURPLE,
}


static func convert_to_string(type: Difficulty.enm):
	return _string_map[type]


static func get_display_string(type: Difficulty.enm) -> String:
	var string: String
	match type:
		Difficulty.enm.BEGINNER: string = Utils.tr("DIFFICULTY_BEGINNER")
		Difficulty.enm.EASY: string = Utils.tr("DIFFICULTY_EASY")
		Difficulty.enm.MEDIUM: string = Utils.tr("DIFFICULTY_MEDIUM")
		Difficulty.enm.HARD: string = Utils.tr("DIFFICULTY_HARD")
		Difficulty.enm.EXTREME: string = Utils.tr("DIFFICULTY_EXTREME")

	return string


static func from_string(string: String) -> Difficulty.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Difficulty.enm.BEGINNER


static func get_color(difficulty: Difficulty.enm) -> Color:
	var color: Color = _color_map[difficulty]

	return color


static func convert_to_colored_string(type: Difficulty.enm) -> String:
	var string: String = get_display_string(type)
	var color: Color = get_color(type)
	var out: String = Utils.get_colored_string(string, color)

	return out
