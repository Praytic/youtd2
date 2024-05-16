extends Node


# Functions for converting player experience to player level.

# NOTE: this class duplicates some code from "Experience"
# class which is used for tower experience. Need two
# separate versions of experience f-ns because
# get_level_at_exp() needs to be implemented differently for
# player vs tower. For tower, it's possible to optimize that
# f-n by pre-calculating 576 values (576exp=25lvl). For
# player, experience maxes out at ~27000, which is too much
# to pre-calculate.

const EXP_FOR_LEVEL_PATH: String = "res://data/player_exp_for_level.csv"

enum ExpForLevelColumn {
	LEVEL = 0,
	EXPERIENCE,
}

# This map is loaded from csv file
var _exp_for_level_map: Dictionary = _load_exp_for_level_map()


#########################
###       Public      ###
#########################

# Returns how much experience is required to reach given
# level
func get_exp_for_level(level: int) -> int:
	var value_for_invalid_level: int = 1000000
	var experience: int = _exp_for_level_map.get(level, value_for_invalid_level)

	return experience


# Returns what level the player should be at when it has a
# certain amount of experience
func get_level_at_exp(player_exp: int) -> int:
	var player_level: int = 0

	for level in range(0, Constants.PLAYER_MAX_LEVEL + 1):
		var exp_for_level: int = _exp_for_level_map[level]
		var enough_exp: bool = player_exp >= exp_for_level

		if enough_exp:
			player_level = level

	return player_level


#########################
###      Private      ###
#########################

func _load_exp_for_level_map() -> Dictionary:
	var map: Dictionary = {}

	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(EXP_FOR_LEVEL_PATH)

	for csv_line in csv:
		var level: int = csv_line[ExpForLevelColumn.LEVEL].to_int()
		var experience: int = csv_line[ExpForLevelColumn.EXPERIENCE].to_int()

		map[level] = experience

	return map
