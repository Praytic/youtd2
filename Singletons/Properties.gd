extends Node

var waves = []

func _init():
	waves.resize(3)
	for wave_index in range(0, 3):
		var wave_file: File = File.new()
		var wave_file_name = "res://Assets/Waves/wave%d.json" % wave_index
		var open_error = wave_file.open(wave_file_name, File.READ)
		
		if open_error != OK:
			push_error("Failed to open wave file at path: %s" % wave_file_name)
			continue
			
		var wave_text: String = wave_file.get_as_text()
		var parsed_json = JSON.parse(wave_text)
		waves[wave_index] = parsed_json

const globals = {
	"max_food": 99,
	"ini_food": 55,
	"max_gold": 999999,
	"ini_gold": 70,
	"max_income": 999999,
	"ini_income": 10,
	"max_knowledge_tomes": 999999,
	"ini_knowledge_tomes": 90,
	"max_knowledge_tomes_income": 999999,
	"ini_knowledge_tomes_income": 8
}
const tower_families = {
	1: {
		"todo": "todo"
	},
	41: {
		"todo": "todo"
	}
}


# TODO: for spells and auras
# 
# Event triggers. For example casting spell on kill. I think
# this should be implemented as another Spell class, like
# ProjectileSpell and ProximitySpell. Name it
# "KillingBlowSpell". KillingBlowSpell will detect when
# tower lands a killing blow on a mob and cast it's spell.
#
# Tower speicific modifiers for experience gain, item
# chance, item quality, etc. Needs to be implemented
# directly in tower's apply_aura().
# 
# Damage types: increased dmg vs X type of mob
# Probably add another aura parameter and implement mob types.
#
# Misses for aura's
#
# Modifying mob armor. Maybe mob armor can be implemented as
# self aura that reduces damage?
# 
# Weird projectile behavior. Shooting up to two mobs at the
# same time. Currently if there are two projectile spells on
# tower, they just shoot the same target. Will need to add
# special targeting logic.
#
# Chain projectiles. Projectiles that create a new
# projectile on impact. Repeat N times. Projectiles need to
# avoid visiting mobs that are already in chain.
#
# Graphical effects for aura's and projectiles. Add as
# parameter to aura's.
# 
# Aura apply types. For example slow that only affects land
# mobs. Or frost attack that doesn't affect fire mobs.
# Implement as parameter (AuraParameter.IMMUNE_MOB_TYPE_LIST)
#
# Chained aura's. For example poison that stuns target when
# it expires. (AuraParameter.FOLLOWUP_AURA)
#
# Every 7th/8th/9th/10th attack deals more damage. Can
# implement as multiple spells that are cast every 10s, with
# 7/8/9/10 having higher value. But that would mean that
# tower will do nothing for first 10s if there's mob in
# range. Need to change behavior of ProjectileSpell so that
# it casts first projectile and then starts cast cd.

enum ScriptParameter {
	ON_DAMAGE_CHANCE,
	ON_DAMAGE_CHANCE_LEVEL_ADD,
	ON_ATTACK_CHANCE,
	ON_ATTACK_CHANCE_LEVEL_ADD,
}

enum TowerStat {
	ATTACK_RANGE,
	ATTACK_CD,
	ATTACK_DAMAGE_MIN,
	ATTACK_DAMAGE_MAX,
	CRIT_CHANCE,
	CRIT_BONUS,
	MISS_CHANCE,
}

enum EffectParameter {
	TYPE,
	AFFECTED_TOWER_STAT,
	VALUE_BASE,
	VALUE_PER_LEVEL,
}

enum EffectType {
	MOD_TOWER_STAT,
}


# TODO: Replace filenames with IDs when switching to Godot 4 with first-class functions
# TODO: Think of the way to load tower properties without loading the Scene or GDScript 
const towers = { 
	"TinyShrub": {
		"id": 1,
		"name": "Tiny Shrub",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"base_stats": {
			TowerStat.ATTACK_RANGE: 600.0,
			TowerStat.ATTACK_CD: 1.0,
			TowerStat.ATTACK_DAMAGE_MIN: 10,
			TowerStat.ATTACK_DAMAGE_MAX: 20
		},
		"splash": {
			320: 0.5
		},
		"cost": 30,
		"description": "Basic nature tower with a slightly increased chance to critical strike.",
		"script": "res://Scenes/Towers/TestTowerScript.gd",
		"effects": [
			{
				EffectParameter.TYPE: EffectType.MOD_TOWER_STAT,
				EffectParameter.AFFECTED_TOWER_STAT: TowerStat.CRIT_CHANCE,
				EffectParameter.VALUE_BASE: 0.2,
				EffectParameter.VALUE_PER_LEVEL: 0.0035,
			}
		],
	},
	"Shrub": {
		"id": 439,
		"name": "Shrub",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"cost": 140,
		"description": "Common nature tower with an increased critical strike chance and damage.",
		"resource": "res://Scenes/Towers/Instances/Shrub.gd"
	},
	"GreaterShrub": {
		"id": 511,
		"name": "Greater Shrub",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"cost": 400,
		"description": "Common nature tower with an increased critical strike chance and damage.",
		"resource": "res://Scenes/Towers/Instances/GreaterShrub.gd"
	},
	"SmallCactus": {
		"id": 41,
		"name": "Small Cactus",
		"family_id": 41,
		"author": "Lapsus",
		"rarity": "common",
		"element": "nature",
		"attack_type": "essence",
		"cost": 30,
		"description": "A tiny desert plant with a high AoE. Slightly more efficient against mass creeps and humans.",
		"resource": "res://Scenes/Towers/Instances/TinyShrub.gd"
	}
}
