extends Node


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

const item_csv_properties_path = "res://Assets/item_properties.csv"
const tower_csv_properties_path = "res://Assets/tower_properties.csv"

var waves = []
var _tower_csv_properties: Dictionary = {} : get = get_tower_csv_properties
var _item_csv_properties: Dictionary = {} : get = get_item_csv_properties


#########################
### Code starts here  ###
#########################

func _init():
	waves.resize(3)
	for wave_index in range(0, 3):
		var wave_file_name = "res://Assets/Waves/wave%d.json" % wave_index
		var wave_file: FileAccess = FileAccess.open(wave_file_name, FileAccess.READ)
		
		if wave_file == null:
			var open_error: Error = FileAccess.get_open_error()
			push_error("Failed to open wave file at path: %s" % wave_file_name)
			continue
			
		var wave_text: String = wave_file.get_as_text()
		var parsed_json: Variant = JSON.parse_string(wave_text)
		waves[wave_index] = parsed_json
	
	_load_csv_properties(tower_csv_properties_path, _tower_csv_properties, Tower.CsvProperty.ID)
	_load_csv_properties(item_csv_properties_path, _item_csv_properties, Item.CsvProperty.ID)


#########################
###       Public      ###
#########################

func get_tower_csv_properties_by_id(tower_id: int) -> Dictionary:
	if _tower_csv_properties.has(tower_id):
		var out: Dictionary = _tower_csv_properties[tower_id]

		return out
	else:
		return {}


func get_tower_csv_properties_by_filter(tower_property: int, filter_value: String) -> Array:
	var result_list_of_dicts = []
	for tower_id in _tower_csv_properties.keys():
		if _tower_csv_properties[tower_id][tower_property] == filter_value:
			result_list_of_dicts.append(_tower_csv_properties[tower_id])
	if result_list_of_dicts.is_empty():
		print_debug("Failed to find tower by property [%s=%s]. ", \
			"Check for typos in tower .csv file." % \
			[Tower.CsvProperty.keys()[tower_property], filter_value])
	return result_list_of_dicts


func get_item_id_list() -> Array:
	return _item_csv_properties.keys()


func get_tower_id_list() -> Array:
	return _tower_csv_properties.keys()


func get_tower_id_list_by_filter(tower_property: int, filter_value: String) -> Array:
	var result_list = []
	for tower_id in _tower_csv_properties.keys():
		if _tower_csv_properties[tower_id][tower_property] == filter_value:
			result_list.append(tower_id)
	return result_list


#########################
###      Private      ###
#########################

func _load_csv_properties(properties_path: String, properties_dict: Dictionary, id_column: int):
	var file: FileAccess = FileAccess.open(properties_path, FileAccess.READ)

	var skip_title_row: bool = true
	while !file.eof_reached():
		var csv_line: PackedStringArray = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false
			continue

# 		NOTE: skip last line which has size of 1
		if csv_line.size() <= 1:
			continue

		var properties: Dictionary = _load_csv_line(csv_line)
		var id = properties[id_column].to_int()
		properties_dict[id] = properties


func _load_csv_line(csv_line) -> Dictionary:
	var out: Dictionary = {}

	for property in range(csv_line.size()):
		var csv_string: String = csv_line[property]
		out[property] = csv_string

	return out


#########################
### Setters / Getters ###
#########################

func get_item_csv_properties():
	return _item_csv_properties

func get_tower_csv_properties():
	return _tower_csv_properties
