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


func make_exp_for_level_map() -> Dictionary:
	var map: Dictionary = {}

	map[0] = 0
	map[1] = 12

	for lvl in range(2, 25):
		map[lvl] = map[lvl - 1] + 12 + (lvl - 2)

	return map
