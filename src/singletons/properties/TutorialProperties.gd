extends Node


enum TutorialId {
	INTRO_FOR_RANDOM_MODE = 1,
	INTRO_FOR_BUILD_MODE,
	RESEARCH_ELEMENTS,
	ROLL_TOWERS,
	TOWER_STASH,
	BUILD_TOWER,
	RESOURCES,
	TOWER_INFO,
	ITEMS,
	TOWER_LEVELS,
	PORTAL_DAMAGE,
	WAVE_1_FINISHED,
	CHALLENGE_WAVE,
	UPGRADING,
	TRANSFORMING,
	
	COUNT,
}

enum CsvProperty {
	ID = 0,
	TITLE,
	TEXT,
}

const PROPERTIES_PATH = "res://data/hints/tutorial.csv"

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)
	
	for id in range(1, TutorialId.COUNT):
		var id_exists: bool = _properties.has(id)
		
		if !id_exists:
			push_error("Missing tutorial with id %s" % id)


#########################
###       Public      ###
#########################

func get_title(id: int) -> String:
	return _get_property(id, CsvProperty.TITLE)


func get_text(id: int) -> String:
	return _get_property(id, CsvProperty.TEXT)


#########################
###      Private      ###
#########################

func _get_property(id: int, property: CsvProperty) -> String:
	if !_properties.has(id):
		push_error("No properties for id: ", id)

		return ""

	var map: Dictionary = _properties[id]
	var property_value: String = map[property]

	return property_value
