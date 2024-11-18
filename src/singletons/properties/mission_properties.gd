extends Node


# Stores mission properties. For controlling mission state,
# see mission_manager.gd.


enum CsvProperty {
	ID,
	SECTION,
	DESCRIPTION,
	SCRIPT_PATH,
	WAVE_COUNT,
	GAME_MODE,
	DIFFICULTY,
	BUILDER,
}

const PROPERTIES_PATH: String = "res://data/mission_properties.csv"
const BUILDER_ANY_STRING: String = "any"
const BUILDER_ANY_ID: int = -1
const SECTION_LIST: Array = ["general", "builders", "elements", "special"]

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)
	
	var id_list: Array = get_id_list()
	
#	Check values in CSV
	for id in id_list:
		var script_path: String = MissionProperties.get_script_path(id)
		var script_exists: bool = ResourceLoader.exists(script_path)
		
		if !script_exists:
			push_error("Mission %d has invalid script path: %s!" % [id, script_path])

		var builder_string: String = _get_property(id, CsvProperty.BUILDER)
		var builder_is_valid: bool = builder_string == BUILDER_ANY_STRING || BuilderProperties.string_is_valid_builder(builder_string)
		if !builder_is_valid:
			push_error("Mission %d has invalid builder: %s!" % [id, builder_string])

		var section: String = MissionProperties.get_section(id)
		var section_is_valid: bool = SECTION_LIST.has(section)
		if !section_is_valid:
			push_error("Mission %d has invalid section: %s!" % [id, section])


#########################
###       Public      ###
#########################

func get_id_list() -> Array:
	return _properties.keys()


func get_section(id: int) -> String:
	var section: String = _get_property(id, CsvProperty.SECTION)

	return section


func get_description(id: int) -> String:
	var description: String = _get_property(id, CsvProperty.DESCRIPTION)

	return description


func get_script_path(id: int) -> String:
	var script_path: String = _get_property(id, CsvProperty.SCRIPT_PATH)

	return script_path


func get_wave_count(id: int) -> int:
	var wave_count: int = _get_property(id, CsvProperty.WAVE_COUNT) as int

	return wave_count


func get_game_mode(id: int) -> GameMode.enm:
	var game_mode_string: String = _get_property(id, CsvProperty.GAME_MODE)
	var game_mode: GameMode.enm = GameMode.from_string(game_mode_string)

	return game_mode


func get_difficulty(id: int) -> Difficulty.enm:
	var difficulty_string: String = _get_property(id, CsvProperty.DIFFICULTY)
	var difficulty: Difficulty.enm = Difficulty.from_string(difficulty_string)

	return difficulty


func get_builder(id: int) -> int:
	var builder_string: String = _get_property(id, CsvProperty.BUILDER)

	if builder_string == BUILDER_ANY_STRING:
		return BUILDER_ANY_ID

	var builder_id: int = BuilderProperties.string_to_id(builder_string)

	return builder_id


#########################
###      Private      ###
#########################

func _get_property(id: int, csv_property: CsvProperty) -> String:
	if !_properties.has(id):
		push_error("Invalid mission id: ", id)

		return ""
	
	var properties: Dictionary = _properties[id]
	var value: String = properties[csv_property]

	return value
