extends Node


const PROPERTIES_PATH: String = "res://Data/builder_properties.csv"

enum CsvProperty {
	ID,
	DISPLAY_NAME,
	SHORT_NAME,
	TIER,
	SCRIPT_NAME,
	DESCRIPTION,
}


var _properties: Dictionary = {}
var _string_to_id_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	Properties._load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

	_string_to_id_map = _make_string_to_id_map()


#########################
###       Public      ###
#########################


func get_id_list() -> Array:
	var id_list: Array = _properties.keys()
	id_list.sort()

	return id_list


func get_display_name(builder: int) -> String:
	var string: String = _get_property(builder, CsvProperty.DISPLAY_NAME)

	return string


func get_short_name(builder: int) -> String:
	var string: String = _get_property(builder, CsvProperty.SHORT_NAME)

	return string


func get_tier(builder: int) -> BuilderTier.enm:
	var tier_string: String = _get_property(builder, CsvProperty.TIER)
	var tier: BuilderTier.enm = BuilderTier.from_string(tier_string)

	return tier


func get_script_name(builder: int) -> String:
	var string: String = _get_property(builder, CsvProperty.SCRIPT_NAME)

	return string


func get_description(builder: int) -> String:
	var string: String = _get_property(builder, CsvProperty.DESCRIPTION)

	return string


func string_to_id(string: String) -> int:
	if _string_to_id_map.has(string):
		return _string_to_id_map[string]
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_to_id_map.keys()])

		return 0


#########################
###      Private      ###
#########################

func _get_property(builder: int, property: BuilderProperties.CsvProperty) -> String:
	if !_properties.has(builder):
		push_error("No properties for builder: ", builder)

		return ""

	var map: Dictionary = _properties[builder]
	var property_value: String = map[property]

	return property_value


func _make_string_to_id_map() -> Dictionary:
	var map: Dictionary = {}

	var id_list: Array = BuilderProperties.get_id_list()

	for id in id_list:
		var short_name: String = BuilderProperties.get_short_name(id)

		map[short_name] = id

	return map
