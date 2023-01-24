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


enum SpellParameter {
	CAST_CD,
	TYPE,
	CAST_RANGE,
	TARGET_TYPE,
	AURA_LIST
}

enum SpellType {
	PROJECTILE,
	PROXIMITY
}

enum SpellTargetType {
	MOBS,
	TOWERS
}

enum AuraParameter {
	TYPE,
	VALUE,
	DURATION,
	PERIOD,
	ADD_RANGE
}

enum AuraType {
	DAMAGE,
	SLOW,
	DECREASE_CAST_CD
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
		"cost": 30,
		"description": "Basic nature tower with a slightly increased chance to critical strike.",
		"resource": "res://Scenes/Towers/Instances/TinyShrub.gd",
		"spell_list": [
			{
				SpellParameter.CAST_CD: 1,
				SpellParameter.TYPE: SpellType.PROJECTILE,
				SpellParameter.CAST_RANGE: 1000,
				SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
				SpellParameter.AURA_LIST: [
					{
						AuraParameter.TYPE: AuraType.DAMAGE,
						AuraParameter.VALUE: 2,
						AuraParameter.DURATION: 0,
						AuraParameter.PERIOD: 0,
						AuraParameter.ADD_RANGE: 0
					}
				]
			},
		]
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
		"resource": "res://Scenes/Towers/Instances/Shrub.gd",
		"spell_list": [
			{
				SpellParameter.CAST_CD: 0.5,
				SpellParameter.TYPE: SpellType.PROJECTILE,
				SpellParameter.CAST_RANGE: 500,
				SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
				SpellParameter.AURA_LIST: [
					{
						AuraParameter.TYPE: AuraType.DAMAGE,
						AuraParameter.VALUE: 1,
						AuraParameter.DURATION: 0,
						AuraParameter.PERIOD: 0,
						AuraParameter.ADD_RANGE: 0
					}
				]
			},
			{
				SpellParameter.CAST_CD: 1.5,
				SpellParameter.TYPE: SpellType.PROJECTILE,
				SpellParameter.CAST_RANGE: 300,
				SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
				SpellParameter.AURA_LIST: [
					{
						AuraParameter.TYPE: AuraType.DAMAGE,
						AuraParameter.VALUE: 2,
						AuraParameter.DURATION: 0,
						AuraParameter.PERIOD: 0,
						AuraParameter.ADD_RANGE: 0
					}
				]
			}
		]
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
		"resource": "res://Scenes/Towers/Instances/GreaterShrub.gd",
		"spell_list": [
			{
				SpellParameter.CAST_CD: 0.5,
				SpellParameter.TYPE: SpellType.PROJECTILE,
				SpellParameter.CAST_RANGE: 500,
				SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
				SpellParameter.AURA_LIST: [
					{
						AuraParameter.TYPE: AuraType.DAMAGE,
						AuraParameter.VALUE: 1,
						AuraParameter.DURATION: 0,
						AuraParameter.PERIOD: 0,
						AuraParameter.ADD_RANGE: 0
					}
				]
			},
			{
				SpellParameter.CAST_CD: 1.5,
				SpellParameter.TYPE: SpellType.PROJECTILE,
				SpellParameter.CAST_RANGE: 300,
				SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
				SpellParameter.AURA_LIST: [
					{
						AuraParameter.TYPE: AuraType.DAMAGE,
						AuraParameter.VALUE: 2,
						AuraParameter.DURATION: 0,
						AuraParameter.PERIOD: 0,
						AuraParameter.ADD_RANGE: 0
					}
				]
			}
		]
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
		"resource": "res://Scenes/Towers/Instances/TinyShrub.gd",
		"spell_list": []
	}
}

var example_spells = {
	"Fire ball": {
		SpellParameter.CAST_CD: 1,
		SpellParameter.TYPE: SpellType.PROJECTILE,
		SpellParameter.CAST_RANGE: 300,
		SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
		SpellParameter.AURA_LIST: [
			{
				AuraParameter.TYPE: AuraType.DAMAGE,
				AuraParameter.VALUE: [1, 2],
				AuraParameter.DURATION: 0,
				AuraParameter.PERIOD: 0,
				AuraParameter.ADD_RANGE: 0
			}
		]
	},
	"Poison": {
		SpellParameter.CAST_CD: 1,
		SpellParameter.TYPE: SpellType.PROJECTILE,
		SpellParameter.CAST_RANGE: 300,
		SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
		SpellParameter.AURA_LIST: [
			{
				AuraParameter.TYPE: AuraType.DAMAGE,
				AuraParameter.VALUE: [1, 2],
				AuraParameter.DURATION: 10,
				AuraParameter.PERIOD: 1,
				AuraParameter.ADD_RANGE: 0
			}
		]
	},
	"Stun projectile": {
		SpellParameter.CAST_CD: 1,
		SpellParameter.TYPE: SpellType.PROJECTILE,
		SpellParameter.CAST_RANGE: 300,
		SpellParameter.TARGET_TYPE: SpellTargetType.MOBS,
		SpellParameter.AURA_LIST: [
			{
				AuraParameter.TYPE: AuraType.SLOW,
				AuraParameter.VALUE: 1.0,
				AuraParameter.DURATION: 10,
				AuraParameter.PERIOD: 0,
				AuraParameter.ADD_RANGE: 0
			}
		]
	}
}
