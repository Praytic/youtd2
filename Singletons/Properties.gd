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

const item_properties_path = "res://Assets/item_properties.csv"
const tower_properties_path = "res://Assets/tower_properties.csv"

var waves = []
var _tower_properties: Dictionary = {} setget ,get_tower_properties
var _item_properties: Dictionary = {} setget ,get_item_properties
var _tower_scene_name_to_id_map: Dictionary = {}
var _item_scene_name_to_id_map: Dictionary = {}


#########################
### Code starts here  ###
#########################

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
	
	_load_tower_properties()
	_load_item_properties(item_properties_path, _item_properties)


#########################
###       Public      ###
#########################

func get_csv_properties(tower_id: int) -> Dictionary:
	if _tower_properties.has(tower_id):
		var out: Dictionary = _tower_properties[tower_id]

		return out
	else:
		return {}


func get_csv_properties_by_filter(tower_property: int, filter_value) -> Array:
	var result_list_of_dicts = []
	for tower_id in _tower_properties.keys():
		if _tower_properties[tower_id][tower_property] == filter_value:
			result_list_of_dicts.append(_tower_properties[tower_id])
	if result_list_of_dicts.empty():
		print_debug("Failed to find tower by property [%s=%s]. ", \
			"Check for typos in tower .csv file." % \
			[Tower.TowerProperty.keys()[tower_property], filter_value])
	return result_list_of_dicts


func get_tower_id_list() -> Array:
	return _tower_properties.keys()


func get_tower_id_list_by_filter(tower_property: int, filter_value) -> Array:
	var result_list = []
	for tower_id in _tower_properties.keys():
		if _tower_properties[tower_id][tower_property] == filter_value:
			result_list.append(tower_id)
	return result_list


#########################
###      Private      ###
#########################

func _load_item_properties(properties_path, properties_dict):
	var file: File = File.new()
	file.open(properties_path, file.READ)

	var skip_title_row: bool = true
	while !file.eof_reached():
		var csv_line: PoolStringArray = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false
			continue

# 		NOTE: skip last line which has size of 1
		if csv_line.size() <= 1:
			continue

		var properties: Dictionary = _load_csv_line(csv_line)
		var id = properties[0].to_int()
		properties_dict[id] = properties

		var scene_name: String = properties[Item.CsvProperty.SCENE_NAME]
		_item_scene_name_to_id_map[scene_name] = id


func get_csv_properties_by_filename(filename: String) -> Dictionary:
	var scene_file: String = filename.get_file()
	var scene_name: String = scene_file.trim_suffix(".tscn")

	if _tower_scene_name_to_id_map.has(scene_name):
		var tower_id: int = _tower_scene_name_to_id_map[scene_name]

		return get_csv_properties(tower_id)
	else:
		print_debug("Failed to find scene_name:", scene_name, ". Check for typos in tower .csv file.")

		return {}


func _load_tower_properties():
	var file: File = File.new()
	file.open("res://Assets/tower_properties.csv", file.READ)

	var skip_title_row: bool = true

	while !file.eof_reached():
		var csv_line = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false

			continue

		var properties: Dictionary = _load_csv_line_typed(csv_line)

		if properties.size() > 0:
			var id: int = properties[2]
			var script_name: String = properties[0]

			_tower_properties[id] = properties
			_tower_scene_name_to_id_map[script_name] = id


func _load_csv_line(csv_line) -> Dictionary:
	var out: Dictionary = {}

	for property in range(csv_line.size()):
		var csv_string: String = csv_line[property]
		out[property] = csv_string

	return out


func _load_csv_line_typed(csv_line) -> Dictionary:
	if csv_line.size() != Tower.TowerProperty.CSV_COLUMN_COUNT:
		return {}

	var out: Dictionary = {}

	for property in range(Tower.TowerProperty.CSV_COLUMN_COUNT):
		var csv_string: String = csv_line[property]
		var property_value = Tower.convert_csv_string_to_property_value(csv_string, property)
		out[property] = property_value

	return out


#########################
### Setters / Getters ###
#########################

func get_item_properties():
	return _item_properties

func get_tower_properties():
	return _tower_properties
