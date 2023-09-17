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

# NOTE: this tile height is for isometric projection.
const TILE_HEIGHT: float = 128.0

const TILE_DIAGONAL_LENGTH: float = 256.0

# TILE_SIZE_PIXELS is the size of the a tile in a top-down
# projection. Derived using the Pythagorean identity.
const TILE_SIZE_PIXELS: float = sqrt(pow(TILE_DIAGONAL_LENGTH, 2) / 2)

# NOTE: can be checked by placing a range checker in
# original game and setting ranges to different values,
# then divide range by tile count.
# 700 / 5.5 = 127
# 2000 / 15.5 = 129
const TILE_SIZE_WC3: float = 128

# NOTE: this constant should be used to convert between wc3
# distances and youtd2 distances in top-down projection.
# This cannot be used for converting directly from youtd2 in
# isometric projection, need to unproject vectors first.
const WC3_DISTANCE_TO_PIXELS: float = TILE_SIZE_PIXELS / TILE_SIZE_WC3

const DEATH_EXPLODE_EFFECT_SIZE: float = 32.0
const LEVEL_UP_EFFECT_SIZE: float = 32.0

const ARMOR_COEFFICIENT: float = 0.04
const SPELL_DAMAGE_RATIO: float = 0.9

const MAX_LEVEL: int = 25
const SIF_ARMOR_CHANCE: float = 0.15
const MIN_WAVE_FOR_SPECIAL: int = 8

const INVENTORY_CAPACITY_MAX: int = 6

const WAVE_COUNT_TRIAL: int = 80
const WAVE_COUNT_FULL: int = 120
const WAVE_COUNT_NEVERENDING: int = 240
const FINAL_WAVE: int = WAVE_COUNT_FULL

const INNATE_MOD_ATK_CRIT_CHANCE: float = 0.0125
const INNATE_MOD_ATK_CRIT_DAMAGE: float = 1.25
const INNATE_MOD_SPELL_CRIT_DAMAGE: float = 1.25
const INNATE_MOD_SPELL_CRIT_CHANCE: float = 0.0125

const INNATE_MOD_ATK_CRIT_CHANCE_LEVEL_ADD: float = 0.0015
const INNATE_MOD_ATK_CRIT_DAMAGE_LEVEL_ADD: float = 0.02
const INNATE_MOD_SPELL_CRIT_CHANCE_LEVEL_ADD: float = 0.0015
const INNATE_MOD_SPELL_CRIT_DAMAGE_LEVEL_ADD: float = 0.02
const INNATE_MOD_DAMAGE_BASE_PERC_LEVEL_ADD: float = 0.04
const INNATE_MOD_ATTACKSPEED_LEVEL_ADD: float = 0.01

const ATK_CRIT_CHANCE_CAP: float = 0.8
const ATK_MULTICRIT_DIMISHING: float = 0.8
const MOD_ATTACKSPEED_MIN: float = 0.2
const MOD_ATTACKSPEED_MAX: float = 5.0
