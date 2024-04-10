extends Node


enum CsvProperty {
	ID,
	TOOLTIP,
	ICON,
}

enum Id {
	COMBAT_MASTERY,
	MASTERY_OF_LOGISTICS,
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


func get_tooltip(tower_id: int) -> String:
	var tooltip: String = _get_property(tower_id, CsvProperty.TOOLTIP)

	return tooltip


func get_icon_path(tower_id: int) -> String:
	var icon_path: String = _get_property(tower_id, CsvProperty.ICON)

	return icon_path


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
