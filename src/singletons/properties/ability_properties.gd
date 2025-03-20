extends Node


enum CsvProperty {
	ID,
	NAME_ENGLISH,
	RANGE,
	TARGET_TYPE,
	ICON_PATH,
	NAME,
	DESCRIPTION_SHORT,
	DESCRIPTION_LONG,
}

const PROPERTIES_PATH = "res://data/ability_properties.csv"


var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

#	Check paths
	var id_list: Array = get_id_list()
	for id in id_list:
		var icon_path: String = AbilityProperties.get_icon_path(id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)

		if !icon_path_is_valid:
			push_error("Invalid icon path for ability: %s" % icon_path)


# 	Check range definitions
	for id in id_list:
		var ability_range: float = AbilityProperties.get_ability_range(id)
		var target_type: TargetType = AbilityProperties.get_target_type(id)
		var range_is_defined: bool = ability_range != 0
		var target_type_is_defined: bool = target_type != null
		var definition_mismatch: bool = range_is_defined != target_type_is_defined

		if definition_mismatch:
			var ability_name: String = AbilityProperties.get_name_english(id)
			push_error("Invalid ability config for ability %s. If ability has a range, then both ability range and target_type must be defined." % [ability_name])


#########################
###       Public      ###
#########################

func get_id_list() -> Array:
	return _properties.keys()


func get_name_english(id: int) -> String:
	var name_english: String = _get_property(id, CsvProperty.NAME_ENGLISH)

	return name_english


func get_ability_range(id: int) -> float:
	var string: String = _get_property(id, CsvProperty.RANGE)
	var ability_range: float = string.to_float()

	return ability_range


func get_target_type(id: int) -> TargetType:
	var string: String = _get_property(id, CsvProperty.TARGET_TYPE)
	var target_type: TargetType = TargetType.convert_from_string(string)

	return target_type


func get_icon_path(id: int) -> String:
	var icon_path: String = _get_property(id, CsvProperty.ICON_PATH)

	return icon_path


func get_ability_name(id: int) -> String:
	var ability_name_text_id: String = _get_property(id, CsvProperty.NAME)
	var ability_name: String = tr(ability_name_text_id)

	return ability_name


func get_description_short(id: int) -> String:
	var description_short_text_id: String = _get_property(id, CsvProperty.DESCRIPTION_SHORT)
	var description_short: String = tr(description_short_text_id)

	return description_short


func get_description_long(id: int) -> String:
	var description_long_text_id: String = _get_property(id, CsvProperty.DESCRIPTION_LONG)
	var description_long: String = tr(description_long_text_id)

	return description_long


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
