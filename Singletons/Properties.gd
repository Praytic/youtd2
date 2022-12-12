extends Node

var waves = []

func _init():
	waves.resize(3)
	for wave_index in range(0, 3):
		var wave_file: File = File.new()
		var wave_file_name = "res://Assets/Waves/wave%d.json" % wave_index
		wave_file.open(wave_file_name, File.READ)
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
const towers = { 
	"GunT1": {
		"id": 1,
		"name": "Tiny Shrub",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"attack_range": 800,
		"attack_cd": 0.9,
		"damage_l": 26,
		"damage_r": 26,
		"cost": 30,
		"description": "Basic nature tower with a slightly increased chance to critical strike."
	},
	"GunT2": {
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
		"cost": 30,
		"description": "Common nature tower with an increased critical strike chance and damage."
	},
	"MissleT1": {
		"id": 439,
		"name": "Small Cactus",
		"family_id": 41,
		"author": "Lapsus",
		"rarity": "common",
		"element": "nature",
		"attack_type": "essence",
		"attack_range": 820,
		"attack_cd": 2.5,
		"damage_l": 58,
		"damage_r": 58,
		"cost": 30,
		"description": "A tiny desert plant with a high AoE. Slightly more efficient against mass creeps and humans."
	}
}
