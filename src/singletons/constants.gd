class_name Constants


# NOTE: Constants class is not an autoload because it
# contains only "const" vars which can be accessed
# statically. It also needs to be accessed by some @tool
# scripts which don't work with autoloads.


# NOTE: this tile size is for isometric projection.
const TILE_SIZE: Vector2 = Vector2(256, 128)

# TILE_SIZE_PIXELS is the size of the a tile in a top-down
# projection. Derived using the Pythagorean identity.
const TILE_SIZE_PIXELS: float = sqrt(pow(256, 2) / 2)
const TILE_SIZE_PIXELS_HALF: float = Constants.TILE_SIZE_PIXELS / 2

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

# This extension comes from original youtd2/wc3 engine. It
# basically changes attack range check to start from tower
# edge instead of tower center.
const RANGE_CHECK_BONUS_FOR_TOWERS: float = 72
const RANGE_CHECK_BONUS_FOR_OTHER_UNITS: float = 8

const DEATH_EXPLODE_EFFECT_SIZE: float = 32.0
const LEVEL_UP_EFFECT_SIZE: float = 64.0

const SPELL_DAMAGE_RATIO: float = 0.9
const SPELL_DAMAGE_RATIO_FOR_SIF: float = 0.4

const MAX_LEVEL: int = 25
const MAX_LEVEL_WITH_BONUS: int = 30
const PLAYER_MAX_LEVEL: int = 300
const SIF_ARMOR_CHANCE: float = 0.15
const MIN_WAVE_FOR_SPECIAL: int = 8

const INVENTORY_CAPACITY_MAX: int = 6

const WAVE_COUNT_TRIAL: int = 80
const WAVE_COUNT_FULL: int = 120
const WAVE_COUNT_NEVERENDING: int = 240

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
const ATTACK_COOLDOWN_MIN: float = 0.2

const PROJECTILE_SPEED_MAX: int = 30000
# NOTE: couldn't find the exact value so had to calculate it
# by eye from original youtd. This value is big enough to
# always bounce from mass creeps and almost always bounce
# for normal creeps - works like that in original game as
# well. The calculation is like this:
# Delay between normal creeps is [0.4s-2.2s].
# Default speed is 222.
# delay = 0.4-1.5 = bounce works
# delay = 1.5-2.2 = bounce fails
const BOUNCE_ATTACK_RANGE: int = 340
const BASE_ITEM_DROP_CHANCE: float = 0.0475

# NOTE: DEFAULT_MOVE_SPEED was obtained by measuring speed
# in original game. 2000 / 9s ~= 222
# 
# MOVE_SPEED_MAX can be found online, search "warcraft 3 max
# speed 522"
# 
# NOTE: MOVE_SPEED_MIN is 100 because this appears to be the
# minimum limit applied internaly inside the WC3
# SetUnitMoveSpeed() function.
const MOVE_SPEED_MIN: float = 100.0
const MOVE_SPEED_MAX: float = 522.0
const DEFAULT_MOVE_SPEED: float = 222.0

# 24h = 480 irl seconds
const IRL_SECONDS_TO_GAME_WORLD_HOURS: float = 24.0 / 480.0
# Time of day starts at 12:00, noon
const INITIAL_TIME_OF_DAY: float = 12.0


# NOTE: [ORIGINAL_GAME_DEVIATION] there was no damage
# max in original game. This is just an arbitrary number to
# protect against bugs. Note that it can't be lower than
# this because creep hp can go up to billions in bonus
# waves.
const DAMAGE_MIN: float = 0
const DAMAGE_MAX: float = 1000000000000000

const SIF_CREEP_HEALTH_MULTIPLIER: float = 0.48

const TIME_BEFORE_FIRST_WAVE: float = 180.0
const TIME_BETWEEN_WAVES: float = 15.0

const MAX_ELEMENT_LEVEL: int = 15

const BUFFGROUP_COUNT: int = 6

const MAX_UPDATE_TICKS_PER_PHYSICS_TICK: int = 20

# NOTE: this value is the default, final value can be
# modified by some builders.
const WISDOM_UPGRADE_MAX_DEFAULT: int = 8
# NOTE: this value is the same as in original game. Player
# earns about 60k score points per hour at medium
# difficulty. Player must earn lvl 20 to unlock all
# builders. Player reaches lvl 20 at 411 exp. Therefore it
# takes about 3.5 hours to unlock all builders:
# 
# 411xp / (60,000score * 0.002) ~= 3.5h
const SCORE_TO_EXP: float = 0.002
# NOTE: picked 1 upgrade every 6 levels so that it takes
# around ~20 ingame hours to unlock all upgrades:
# - 10upgrades * 6level/upgrade = 60 levels for all upgrades
# - need 2431 exp to reach level 60
# - 60000score/hour * 0.002exp/score = 120exp/hour
# - 2431exp / 120exp/hour ~= 20 hours
# 
# In addition, this is 20 *ingame* hours. IRL time can be
# half as much because of ability to speed up the game.
const PLAYER_LEVEL_TO_WISDOM_UPGRADE_COUNT: float = 1 / 6.0

const TOMES_WARNING_THRESHOLD: int = 50
const WAVE_LEVEL_AFTER_WHICH_TOME_WARNINGS_STOP: int = 100

# NOTE: picked these values because they are used in a
# certain game about a World on the Rim
const GAME_SPEED_NORMAL: int = 1
const GAME_SPEED_FAST: int = 3
const GAME_SPEED_FASTEST: int = 6

const ITEM_BUTTON_SIZE: Vector2 = Vector2(80, 80)
const ABILITY_BUTTON_SIZE: Vector2 = Vector2(85, 85)

# Picked these ports because they were used in Godot
# examples and are not present on the list of registered or
# common ports as of December 2022:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const SERVER_PORT: int = 8910
const ROOM_SCANNER_SEND_PORT: int = 8911
const ROOM_ADVERTISER_SEND_PORT: int = 8912

const PLAYER_COUNT_MAX: int = 8

const NAKAMA_ADDRESS: String = "161.35.244.122"
const NAKAMA_PORT: int = 7350
const NAKAMA_PROTOCOL: String = "http"

const MAX_CHAT_MESSAGE_LENGTH: int = 200

const PLAYER_NAME_ALLOWED_CHARS: String = "[A-Za-z]"
const PLAYER_NAME_LENGTH_MIN: int = 2
const PLAYER_NAME_LENGTH_MAX: int = 15

const TOWER_ATTACK_ABILITY_NAME_ENGLISH: String = "Normal attack"
