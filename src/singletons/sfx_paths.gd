extends Node


const BUILD_TOWER: String = "res://assets/sfx/683044__brettrader__stomp-soft.ogg"
const PICKUP_ITEM: String = "res://assets/sfx/411177__silverillusionist__pick-up-item-1-short.ogg"
const DROP_ITEM: String = "res://assets/sfx/michel_baradari_jump.ogg"
const PICKUP_GOLD: String = "res://assets/sfx/734247__noisyredfox__coins3.ogg"
const HUMAN_DEATH_EXPLODE: String = "res://assets/sfx/442903__qubodup__slash-remix.ogg"
const START_WAVE: String = "res://assets/sfx/161654__qubodup__war-game-battle-level-up-remix.ogg"
const LEVEL_UP: String = "res://assets/sfx/kevl_level_up.ogg"

const TOWER_ATTACK_MAP: Dictionary = {
	Element.enm.NATURE: "res://assets/sfx/unknown_swosh-08.ogg",
	Element.enm.STORM: "res://assets/sfx/opengameart/bart/foom_0.ogg",
	Element.enm.FIRE: "res://assets/sfx/unknown_fire_attack1.ogg",
	Element.enm.ICE: "res://assets/sfx/unknown_iceball.ogg",
	Element.enm.ASTRAL: "res://assets/sfx/unknown_attack_sound1.ogg",
	Element.enm.DARKNESS: "res://assets/sfx/unknown_swosh-11.ogg",
	Element.enm.IRON: "res://assets/sfx/unknown_iron_attack1.ogg",
}

const UI_ERROR: String = "res://assets/sfx/665082__sunflora__thud.ogg"
const ORC_GRUNT: String = "res://assets/sfx/738438__qubodup__orc-grunt-2.ogg"
const ARCHERS_SHOOTING: String = "res://assets/sfx/copyc4t_Archers-shooting.ogg"
const FLIES_BUZZING: String = "res://assets/sfx/p0ss_pestilence.ogg"
const SAND_RUB: String = "res://assets/sfx/p0ss_sand.ogg"
const CURSE_NOISE: String = "res://assets/sfx/p0ss_curse5.ogg"
const GHOST_EXHALE: String = "res://assets/sfx/p0ss_spell.ogg"
const BAM_ECHO: String = "res://assets/sfx/p0ss_explode4.ogg"
const POW: String = "res://assets/sfx/p0ss_shot.ogg"
const CLOUD_POOF: String = "res://assets/sfx/714258__qubodup__cloud-poof.ogg"
const SPIT: String = "res://assets/sfx/spit_01.ogg"

const EXPLOSION: String = "res://assets/sfx/745156__tigreplayz__blast-explosion.ogg"
const EXPLOSION_MUFFLED_BOUNCING: String = "res://assets/sfx/p0ss_explode2.ogg"

const ENCHANT_LONG: String = "res://assets/sfx/202147__qubodup__enchant.ogg"
const ENCHANT_SHORT: String = "res://assets/sfx/p0ss_enchant.ogg"
const ENCHANT_DRONE: String = "res://assets/sfx/p0ss_enchant2.ogg"

const MAGIC_STROBE: String = "res://assets/sfx/682635__bastianhallo__magic-spell.ogg"
const MAGIC_HIGH_TONE: String = "res://assets/sfx/420676__sypherzent__spell-cast-buff-high-tone.ogg"
const MAGIC_CHANNEL: String = "res://assets/sfx/little_robot_Spell_00.ogg"
const MAGIC_FIZZLE: String = "res://assets/sfx/little_robot_Spell_01.ogg"
const MAGIC_CONFUSE: String = "res://assets/sfx/p0ss_confusion.ogg"
const MAGIC_FAIL: String = "res://assets/sfx/p0ss_magicfail.ogg"

const TELEPORT: String = "res://assets/sfx/p0ss_teleport.ogg"
const TELEPORT_BASS: String = "res://assets/sfx/michel_baradari_teleport.ogg"

const WARP: String = "res://assets/sfx/p0ss_warp.ogg"
const WARP_LONG: String = "res://assets/sfx/p0ss_warp2.ogg"

const ELECTRIC_BUZZ: String = "res://assets/sfx/little_robot_UI_Electric_00.ogg"
const ELECTRIC_BUMP: String = "res://assets/sfx/little_robot_Whoosh_Electric_01.ogg"
const ELECTRIC_SPRING: String = "res://assets/sfx/p0ss_spring.ogg"
const ELECTRIC_WHOOSH: String = "res://assets/sfx/little_robot_Whoosh_Electric_00.ogg"
const ELECTRIC_WHOOSH_UP: String = "res://assets/sfx/little_robot_Whoosh_Electric_02.ogg"
const ELECTRIC_WHOOSH_DOWN: String = "res://assets/sfx/little_robot_Whoosh_Electric_03.ogg"

const ZAP_HIGH_PITCH: String = "res://assets/sfx/p0ss_zap.ogg"
const ZAP_LOW: String = "res://assets/sfx/p0ss_zap5a.ogg"
const ZAP_LONG: String = "res://assets/sfx/p0ss_zap10.ogg"

const WATER_SLASH: String = "res://assets/sfx/649359__sonofxaudio__sword_water01.ogg"
const WATER_STEAM: String = "res://assets/sfx/p0ss_steam.ogg"
const WATER_HISS: String = "res://assets/sfx/p0ss_water.ogg"

const ICE_CRACKLE: String = "res://assets/sfx/artisticdude_freeze.ogg"
const ICE_HISS: String = "res://assets/sfx/p0ss_freeze2.ogg"

const HEAL: String = "res://assets/sfx/DoKashiteru_healspell1.ogg"
const HEAL_DEEP: String = "res://assets/sfx/DoKashiteru_healspell2.ogg"
const HEAL_REVERB: String = "res://assets/sfx/DoKashiteru_healspell3.ogg"

const SPARKLE_SHORT: String = "res://assets/sfx/562292__colorscrimsontears__heal-rpg.ogg"
const SPARKLE_LONG: String = "res://assets/sfx/p0ss_heal.ogg"

const FIRE_BALL: String = "res://assets/sfx/442827__qubodup__fireball.ogg"
const FIRE_PUNCH: String = "res://assets/sfx/541478__eminyildirim__magic-fire-spell-impact-punch.ogg"
const FIRE_SPLASH: String = "res://assets/sfx/michel_baradari_lava.ogg"
