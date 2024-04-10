extends Node


enum CsvProperty {
	ID,
	NAME,
	DESCRIPTION,
}

enum Id {
	ADVANCED_FORTUNE,
	ELEMENT_MASTERY,
	SWIFTNESS_MASTERY,
	COMBAT_MASTERY,
	MASTERY_OF_PAIN,
	ADVANCED_SORCERY,
	MASTERY_OF_MAGIC,
	MASTERY_OF_LOGISTICS,
	LOOT_MASTERY,
	ADVANCED_WISDOM,
}


const PROPERTIES_PATH = "res://Data/wisdom_upgrades.csv"

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)


#########################
###       Public      ###
#########################

func get_id_list() -> Array:
	return _properties.keys()


func get_upgrade_name(tower_id: int) -> String:
	var tooltip: String = _get_property(tower_id, CsvProperty.NAME)

	return tooltip


func get_description(tower_id: int) -> String:
	var tooltip: String = _get_property(tower_id, CsvProperty.DESCRIPTION)

	return tooltip


#########################
###      Private      ###
#########################

func _get_property(tower_id: int, csv_property: CsvProperty) -> String:
	if !_properties.has(tower_id):
		push_error("No properties for tower: ", tower_id)

		return ""
	
	var properties: Dictionary = _properties[tower_id]
	var value: String = properties[csv_property]

	return value
