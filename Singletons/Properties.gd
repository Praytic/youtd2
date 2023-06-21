extends Node


const globals = {
	"max_food": 99,
	"ini_food": 55,
	"max_knowledge_tomes": 999999,
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

const _ITEM_CSV_PROPERTIES_PATH = "res://Data/item_properties.csv"
const _TOWER_CSV_PROPERTIES_PATH = "res://Data/tower_properties.csv"
const _WAVE_CSV_PROPERTIES_PATH = "res://Data/wave_properties.csv"


var _tower_csv_properties: Dictionary = {} : get = get_tower_csv_properties
var _item_csv_properties: Dictionary = {} : get = get_item_csv_properties
var _wave_csv_properties: Dictionary = {} : get = get_wave_csv_properties


#########################
### Code starts here  ###
#########################

func _init():
	_load_csv_properties(_TOWER_CSV_PROPERTIES_PATH, _tower_csv_properties, Tower.CsvProperty.ID)
	_load_csv_properties(_ITEM_CSV_PROPERTIES_PATH, _item_csv_properties, Item.CsvProperty.ID)
	_load_csv_properties(_WAVE_CSV_PROPERTIES_PATH, _wave_csv_properties, Wave.CsvProperty.ID)


#########################
###       Public      ###
#########################

func get_tower_csv_properties_by_id(tower_id: int) -> Dictionary:
	if _tower_csv_properties.has(tower_id):
		var out: Dictionary = _tower_csv_properties[tower_id]

		return out
	else:
		return {}

func get_item_csv_properties_by_id(item_id: int) -> Dictionary:
	if _item_csv_properties.has(item_id):
		var out: Dictionary = _item_csv_properties[item_id]

		return out
	else:
		return {}

func get_wave_csv_properties_by_id(wave_id: int) -> Dictionary:
	if _wave_csv_properties.has(wave_id):
		var out: Dictionary = _wave_csv_properties[wave_id]

		return out
	else:
		return {}

func get_tower_csv_properties_by_filter(tower_property: Tower.CsvProperty, filter_value: String) -> Array:
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


func get_tower_id_list_by_filter(tower_property: Tower.CsvProperty, filter_value: String) -> Array:
	var result_list = []
	for tower_id in _tower_csv_properties.keys():
		if _tower_csv_properties[tower_id][tower_property] == filter_value:
			result_list.append(tower_id)
	return result_list


func get_item_id_list_by_filter(item_property: Item.CsvProperty, filter_value: String) -> Array:
	var all_item_list: Array = _item_csv_properties.keys()
	var result_list: Array = filter_item_id_list(all_item_list, item_property, filter_value)

	return result_list


func filter_item_id_list(item_list: Array, item_property: Item.CsvProperty, filter_value: String) -> Array:
	var result_list = []
	for item_id in item_list:
		if _item_csv_properties[item_id][item_property] == filter_value:
			result_list.append(item_id)
	return result_list


#########################
###      Private      ###
#########################

func _load_csv_properties(properties_path: String, properties_dict: Dictionary, id_column: int):
	var file_exists: bool = FileAccess.file_exists(properties_path)

	if !file_exists:
		print_debug("Failed to load CSV propeties because file doesn't exist. Path: %s", % properties_path)

		return

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

func get_wave_csv_properties():
	return _wave_csv_properties
