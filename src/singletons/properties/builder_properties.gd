extends Node


const PROPERTIES_PATH: String = "res://data/builder_properties.csv"
const BUILDER_SCRIPT_DIR: String = "res://src/builders/instances"
const BACKPACKER_BUILDER_ID: int = 19

enum CsvProperty {
	ID,
	DISPLAY_NAME,
	SHORT_NAME,
	TIER,
	REQUIRED_LEVEL,
	SCRIPT_NAME,
	ICON,
	DESCRIPTION,
}


var _properties: Dictionary = {}
var _string_to_id_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

	_string_to_id_map = _make_string_to_id_map()

#	Check BACKPACKER_BUILDER_ID
	var backpacker_name: String = get_display_name(BACKPACKER_BUILDER_ID)
	if !backpacker_name.contains("Backpacker"):
		push_error("BACKPACKER_BUILDER_ID is incorrect.")

#	Check script paths
	var builder_id_list: Array = get_id_list()
	for builder_id in builder_id_list:
		var script_path: String = get_script_path(builder_id)
		var script_path_is_valid: bool = ResourceLoader.exists(script_path)

		if !script_path_is_valid:
			push_error("Invalid builder script path: %s" % script_path)

		var icon_path: String = get_icon_path(builder_id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)
		if !icon_path_is_valid:
			push_error("Invalid builder icon path: %s" % icon_path)


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


func get_required_level(builder: int) -> int:
	var required_level: int = _get_property(builder, CsvProperty.REQUIRED_LEVEL) as int

	return required_level


func get_script_name(builder: int) -> String:
	var string: String = _get_property(builder, CsvProperty.SCRIPT_NAME)

	return string


func get_script_path(builder: int) -> String:
	var script_name: String = get_script_name(builder)
	var script_path: String = "%s/%s.gd" % [BUILDER_SCRIPT_DIR, script_name]

	return script_path


func get_icon_path(builder: int) -> String:
	var icon_path: String = _get_property(builder, CsvProperty.ICON)

	return icon_path


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
