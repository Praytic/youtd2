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
	if csv_line.size() != Tower.Property.CSV_COLUMN_COUNT:
		return {}

	var out: Dictionary = {}

	for property in range(Tower.Property.CSV_COLUMN_COUNT):
		var csv_string: String = csv_line[property]
		var property_value = Tower.convert_csv_string_to_property_value(csv_string, property)
		out[property] = property_value

	return out
