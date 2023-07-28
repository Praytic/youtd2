extends Node

# Containts data about how tower levels map to experience.
# Mapping of level -> required experience
# Mapping of experience -> current level

var _exp_for_level: Dictionary = _make_exp_for_level_map()
var _level_at_exp: Dictionary = make_level_at_exp_map()


# Example:
# 0 = 0
# 1 = 12
# 2 = 24
# 3 = 37
# 4 = 51
# ...
func _make_exp_for_level_map() -> Dictionary:
	var map: Dictionary = {}

	map[0] = 0
	map[1] = 12

	for lvl in range(2, Constants.MAX_LEVEL + 1):
		map[lvl] = map[lvl - 1] + 12 + (lvl - 2)

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
func make_level_at_exp_map() -> Dictionary:
	var map: Dictionary = {}
	
	var exp_for_level: Dictionary = _make_exp_for_level_map()

	for current_level in range(0, Constants.MAX_LEVEL):
		var current_level_experience: int = exp_for_level[current_level]
		var next_level: int = current_level + 1
		var next_level_experience: int = exp_for_level[next_level]

		for i in range(current_level_experience, next_level_experience):
			map[i] = current_level

	var max_level_exp: int = exp_for_level[Constants.MAX_LEVEL]
	map[max_level_exp] = Constants.MAX_LEVEL

	return map


func get_exp_for_level(level: int) -> int:
	if _exp_for_level.has(level):
		var experience: int = _exp_for_level[level]

		return experience
	else:
		push_error("No exp for level value for level: ", level)
		
		return 0


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

