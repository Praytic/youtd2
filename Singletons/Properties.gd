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
				"cast_cd": 1,
				"type": "projectile",
				"cast_range": 1000,
				"target_type": "mobs",
				"aura_list": [
					{
						"type": "damage",
						"value": 2,
						"duration": 0,
						"period": 0,
						"add_range": 0
					}
				]
			},
			{
				"cast_cd": 1,
				"type": "proximity",
				"target_type": "towers",
				"cast_range": 100,
				"aura_list": [
					{
						"type": "reduce cast cd",
						"value": 0.5,
						"duration": 1.01,
						"period": 0,
						"add_range": 0
					}
				]
			}
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
		"attack_range": 840,
		"attack_cd": 0.9,
		"damage_l": 113,
		"damage_r": 113,
		"cost": 140,
		"description": "Common nature tower with an increased critical strike chance and damage.",
		"resource": "res://Scenes/Towers/Instances/Shrub.gd",
		"spell_list": [
			{
				"cast_cd": 0.5,
				"type": "projectile",
				"cast_range": 500,
				"target_type": "mobs",
				"aura_list": [
					{
						"type": "damage",
						"value": 1,
						"duration": 0,
						"period": 0,
						"add_range": 0
					}
				]
			},
			{
				"cast_cd": 1.5,
				"type": "projectile",
				"cast_range": 300,
				"target_type": "mobs",
				"aura_list": [
					{
						"type": "damage",
						"value": 2,
						"duration": 0,
						"period": 0,
						"add_range": 0
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
		"attack_range": 880,
		"attack_cd": 0.9,
		"damage_l": 299,
		"damage_r": 299,
		"cost": 400,
		"description": "Common nature tower with an increased critical strike chance and damage.",
		"resource": "res://Scenes/Towers/Instances/GreaterShrub.gd",
		"spell_list": [
			{
				"cast_cd": 0.5,
				"type": "projectile",
				"cast_range": 500,
				"target_type": "mobs",
				"aura_list": [
					{
						"type": "damage",
						"value": 1,
						"duration": 0,
						"period": 0,
						"add_range": 0
					}
				]
			},
			{
				"cast_cd": 1.5,
				"type": "projectile",
				"cast_range": 300,
				"target_type": "mobs",
				"aura_list": [
					{
						"type": "damage",
						"value": 2,
						"duration": 0,
						"period": 0,
						"add_range": 0
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
		"attack_range": 820,
		"attack_cd": 0.5,
		"damage_l": 58,
		"damage_r": 58,
		"cost": 30,
		"description": "A tiny desert plant with a high AoE. Slightly more efficient against mass creeps and humans.",
		"resource": "res://Scenes/Towers/Instances/TinyShrub.gd",
		"spell_list": []
	}
}

var example_spells = {
	"Fire ball": {
		"cast_cd": 1,
		"type": "projectile",
		"cast_range": 300,
		"target_type": "mobs",
		"aura_list": [
			{
				"type": "damage",
				"value": [1, 2],
				"duration": 0,
				"period": 0,
				"add_range": 0
			}
		]
	},
	"Poison": {
		"cast_cd": 1,
		"type": "projectile",
		"cast_range": 300,
		"target_type": "mobs",
		"aura_list": [
			{
				"type": "damage",
				"value": [1, 2],
				"duration": 10,
				"period": 1,
				"add_range": 0
			}
		]
	},
	"Stun projectile": {
		"cast_cd": 1,
		"type": "projectile",
		"cast_range": 300,
		"target_type": "mobs",
		"aura_list": [
			{
				"type": "slow",
				"value": 1.0,
				"duration": 10,
				"period": 0,
				"add_range": 0
			}
		]
	}
}
