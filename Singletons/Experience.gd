extends Node

# Containts data about how tower levels map to experience.
# Mapping of level -> required experience
# Mapping of experience -> current level

const EXP_FOR_LEVEL_PATH: String = "res://Data/exp_for_level.csv"

enum ExpForLevelColumn {
	LEVEL = 0,
	EXPERIENCE,
}

# This map is loaded from csv file
var _exp_for_level: Dictionary = _load_exp_for_level_map()
# This map is generated based on _exp_for_level
var _level_at_exp: Dictionary = make_level_at_exp_map(_exp_for_level)


func _load_exp_for_level_map() -> Dictionary:
	var map: Dictionary = {}

	var csv: Array[PackedStringArray] = Utils.load_csv(EXP_FOR_LEVEL_PATH)

	for csv_line in csv:
		var level: int = csv_line[ExpForLevelColumn.LEVEL].to_int()
		var experience: int = csv_line[ExpForLevelColumn.EXPERIENCE].to_int()

		map[level] = experience

	return map

# NOTE: this map is needed to simplify implementation of
# Unit._change_experience()
# Example:
# 0 = 0
# 1 = 0
# 2 = 0
# 3 = 0
# ...
# 12 = 1
# 13 = 1
# 14 = 1
# ...
# 24 = 2
# 25 = 2
# 26 = 2
# ...
func make_level_at_exp_map(exp_for_level: Dictionary) -> Dictionary:
	var map: Dictionary = {}
	
	for current_level in range(0, Constants.MAX_LEVEL):
		var current_level_experience: int = exp_for_level[current_level]
		var next_level: int = current_level + 1
		var next_level_experience: int = exp_for_level[next_level]

		for i in range(current_level_experience, next_level_experience):
			map[i] = current_level

	var max_level_exp: int = exp_for_level[Constants.MAX_LEVEL]
	map[max_level_exp] = Constants.MAX_LEVEL

	return map


# Returns how much experience is required to reach given
# level
func get_exp_for_level(level: int) -> int:
	if _exp_for_level.has(level):
		var experience: int = _exp_for_level[level]

		return experience
	else:
		push_error("No exp for level value for level: ", level)
		
		return 0


# Returns what level the tower should be at when it has a
# certain amount of experience
func get_level_at_exp(experience_float: float) -> int:
	var experience: int = floori(experience_float)

	if experience >= 0:
		if _level_at_exp.has(experience):
			var level: int = _level_at_exp[experience]

			return level
		else:
			return Constants.MAX_LEVEL
	else:
		return 0

