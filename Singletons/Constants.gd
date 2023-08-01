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
const SIF_ARMOR_CHANCE: float = 0.15

# Map of rarity -> tier -> inventory capacity
const INVENTORY_CAPACITY: Dictionary = {
	Rarity.enm.COMMON: {
		1: 1,
		2: 1,
		3: 1,
		4: 2,
		5: 3,
		6: 4,
	},
	Rarity.enm.UNCOMMON: {
		1: 1,
		2: 2,
		3: 3,
		4: 4,
		5: 5,
		6: 6,
	},
	Rarity.enm.RARE: {
		1: 4,
		2: 5,
		3: 6,
		4: 6,
		5: 6,
		6: 6,
	},
	Rarity.enm.UNIQUE: {
		1: 5,
		2: 6,
		3: 6,
		4: 6,
		5: 6,
		6: 6,
	}
}

const WAVE_COUNT_TRIAL: int = 80
const WAVE_COUNT_FULL: int = 120
const WAVE_COUNT_NEVERENDING: int = 240
