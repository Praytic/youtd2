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


# TODO: for spells, effects and debuffs
# 
# Tower aura.
# 
# Periodic trigger function
# 
# Tower creation trigger function
#
# Killing blow trigger function
#
# Implement modifications:
# experience gain, item chance, item quality, etc.
# 
# Increased dmg vs X type of mob. Implement mob types, tower
# stats for dmg bonus to mob types and tower effects that
# change those stats.
#
# Mob armor and modification for mob armor.
# 
# One tower shooting at two different targest at the same
# time.
#
# Chain attack.
#
# Graphical effects for buffs and projectiles.
# 
# Mob immunity.


# NOTE: these TODO's are talking about tower properties which are now located in tower scripts
# TODO: Replace filenames with IDs when switching to Godot 4 with first-class functions
# TODO: Think of the way to load tower properties without loading the Scene or GDScript 

# TODO: this used to contain tower properties. Had to
# redefine id here so TowerManager can use it. Figure out
# what should be done with this. Maybe can use tower name
# from script path instead of id?
var tower_id_map: Dictionary = {
	"TinyShrub": 1,
	"Shrub": 439,
	"GreaterShrub": 511,
	"SmallCactus": 41,
}
