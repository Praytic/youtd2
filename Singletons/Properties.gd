extends Node


const CsvColumn = {
	FILENAME = 0,
	NAME = 1,
	ID = 2,
	FAMILY_ID = 3,
	AUTHOR = 4,
	RARITY = 5,
	ELEMENT = 6,
	ATTACK_TYPE = 7,
	ATTACK_RANGE = 8,
	ATTACK_CD = 9,
	ATTACK_DAMAGE = 10,
	COST = 11,
	DESCRIPTION = 12,

	COUNT = 13,
}

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

var waves = []
var _csv_properties: Dictionary = {}
var _tower_filename_to_id_map: Dictionary = {}


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
	
	_load_csv_properties()


func get_csv_properties(tower_id: int) -> Dictionary:
	if _csv_properties.has(tower_id):
		var out: Dictionary = _csv_properties[tower_id]

		return out
	else:
		return {}


func get_csv_properties_by_filename(tower_name: String) -> Dictionary:
	if _tower_filename_to_id_map.has(tower_name):
		var tower_id: int = _tower_filename_to_id_map[tower_name]

		return get_csv_properties(tower_id)
	else:
		print_debug("Failed to find tower_name:", _tower_filename_to_id_map, " Check for typos in tower .csv file.")

		return {}


func get_tower_id_list() -> Array:
	return _csv_properties.keys()


func _load_csv_properties():
	var file: File = File.new()
	file.open("res://Assets/tower_properties.csv", file.READ)

	var skip_title_row: bool = true

	while !file.eof_reached():
		var csv_line = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false

			continue

		var properties: Dictionary = _load_csv_line(csv_line)

		if properties.size() > 0:
			var id: int = properties[Tower.Property.ID]
			var script_name: String = properties[Tower.Property.FILENAME]

			_csv_properties[id] = properties
			_tower_filename_to_id_map[script_name] = id


func _load_csv_line(csv_line) -> Dictionary:
	if csv_line.size() != CsvColumn.COUNT:
		return {}

	var out: Dictionary = {}

	out[Tower.Property.FILENAME] = csv_line[CsvColumn.FILENAME]
	out[Tower.Property.NAME] = csv_line[CsvColumn.NAME]
	out[Tower.Property.ID] = csv_line[CsvColumn.ID].to_int()
	out[Tower.Property.FAMILY_ID] = csv_line[CsvColumn.FAMILY_ID].to_int()
	out[Tower.Property.AUTHOR] = csv_line[CsvColumn.AUTHOR]
	out[Tower.Property.RARITY] = csv_line[CsvColumn.RARITY]
	out[Tower.Property.ELEMENT] = csv_line[CsvColumn.ELEMENT]
	out[Tower.Property.ATTACK_TYPE] = csv_line[CsvColumn.ATTACK_TYPE]
	out[Tower.Property.ATTACK_RANGE] = csv_line[CsvColumn.ATTACK_RANGE].to_float()
	out[Tower.Property.ATTACK_CD] = csv_line[CsvColumn.ATTACK_CD].to_float()

	var attack_damage: String = csv_line[CsvColumn.ATTACK_DAMAGE]
	var attack_damage_split: Array = attack_damage.split("-")

	if attack_damage_split.size() == 2:
		var attack_damage_min = attack_damage_split[0].to_int()
		var attack_damage_max = attack_damage_split[1].to_int()

		out[Tower.Property.ATTACK_DAMAGE_MIN] = attack_damage_min
		out[Tower.Property.ATTACK_DAMAGE_MAX] = attack_damage_max
	else:
		out[Tower.Property.ATTACK_DAMAGE_MIN] = 0
		out[Tower.Property.ATTACK_DAMAGE_MAX] = 0

	out[Tower.Property.COST] = csv_line[CsvColumn.COST].to_float()
	out[Tower.Property.DESCRIPTION] = csv_line[CsvColumn.DESCRIPTION]

	return out
