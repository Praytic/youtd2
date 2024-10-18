extends Node


enum CsvProperty {
	ID,
	NAME_ENGLISH,
	TOOLTIP,
	ICON,
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
	PILLAGE_MASTERY,
}


const PROPERTIES_PATH = "res://data/wisdom_upgrades.csv"

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

#	Check paths
	var id_list: Array = WisdomUpgradeProperties.get_id_list()
	for id in id_list:
		var icon_path: String = WisdomUpgradeProperties.get_icon_path(id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)

		if !icon_path_is_valid:
			push_error("Invalid wisdom upgrade icon path: %s" % icon_path)


#########################
###       Public      ###
#########################

func get_id_list() -> Array:
	return _properties.keys()


func get_tooltip(tower_id: int) -> String:
	var tooltip_text_id: String = _get_property(tower_id, CsvProperty.TOOLTIP)
	var tooltip: String = tr(tooltip_text_id)

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
