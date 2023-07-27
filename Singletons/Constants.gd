extends Node

const Groups = {
	BUILD_AREA_GROUP = "build_area"
}

const SettingsSection = {
	HUD = "hud"
}

const SettingsKey = {
	SELECTED_TOWER = "selected tower"
}

const SETTINGS_PATH: String = "user://settings.cfg"

const TILE_HEIGHT: float = 128.0

# NOTE: this was obtained by placing a tower with attack
# radius of 700 5.5 tiles away from middle of mob path and
# confirming that the mob path is within attack radius.
# "Pixels" refers to pixels of raw world tiles, without
# considering current camera zoom and other factors.
const WC3_DISTANCE_TO_PIXELS: float = (5.5 * 256) / 700.0

const DEATH_EXPLODE_EFFECT_SIZE: float = 32.0
const LEVEL_UP_EFFECT_SIZE: float = 32.0

const ARMOR_COEFFICIENT: float = 0.04
const SPELL_DAMAGE_RATIO: float = 0.9

const MAX_LEVEL: int = 25
var EXP_FOR_LEVEL: Dictionary = make_exp_for_level_map()
var LEVEL_AT_EXP: Dictionary = make_LEVEL_AT_EXP_map()


# Example:
# 0 = 0
# 1 = 12
# 2 = 24
# 3 = 37
# 4 = 51
# ...
func make_exp_for_level_map() -> Dictionary:
	var map: Dictionary = {}

	map[0] = 0
	map[1] = 12

	for lvl in range(2, MAX_LEVEL + 1):
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
func make_LEVEL_AT_EXP_map() -> Dictionary:
	var map: Dictionary = {}
	
	var exp_for_level: Dictionary = make_exp_for_level_map()

	for current_level in range(0, MAX_LEVEL):
		var current_level_experience: int = exp_for_level[current_level]
		var next_level: int = current_level + 1
		var next_level_experience: int = exp_for_level[next_level]

		for i in range(current_level_experience, next_level_experience):
			map[i] = current_level

	var max_level_exp: int = exp_for_level[MAX_LEVEL]
	map[max_level_exp] = MAX_LEVEL

	return map


func get_level_at_exp(experience_float: float) -> int:
	var experience: int = floori(experience_float)

	if experience >= 0:
		if LEVEL_AT_EXP.has(experience):
			var level: int = LEVEL_AT_EXP[experience]

			return level
		else:
			return MAX_LEVEL
	else:
		return 0

