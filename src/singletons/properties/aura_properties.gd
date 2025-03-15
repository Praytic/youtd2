extends Node


enum CsvProperty {
	ID,
	NAME_ENGLISH,
	BUFF_TYPE,
	TARGET_SELF,
	RANGE,
	TARGET_TYPE,
	IS_HIDDEN,
	LEVEL,
	LEVEL_ADD,
	ICON_PATH,
	NAME,
	DESCRIPTION_SHORT,
	DESCRIPTION_FULL,
}

const PROPERTIES_PATH = "res://data/aura_properties.csv"


var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

#	Check paths
	var id_list: Array = get_id_list()
	for id in id_list:
		var icon_path: String = AuraProperties.get_icon_path(id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)

		if !icon_path_is_valid:
			push_error("Invalid icon path for aura: %s" % icon_path)


#########################
###       Public      ###
#########################

func get_id_list() -> Array:
	return _properties.keys()


func get_name_english(id: int) -> String:
	var name_english: String = _get_property(id, CsvProperty.NAME_ENGLISH)

	return name_english


func get_buff_type(id: int) -> String:
	var buff_type: String = _get_property(id, CsvProperty.BUFF_TYPE)

	return buff_type


func get_target_self(id: int) -> bool:
	var target_self_string: String = _get_property(id, CsvProperty.TARGET_SELF)
	var target_self: bool = Utils.string_to_bool(target_self_string)

	return target_self


func get_aura_range(id: int) -> float:
	var aura_range_string: String = _get_property(id, CsvProperty.RANGE)
	var aura_range: float = aura_range_string.to_float()

	return aura_range


func get_level(id: int) -> int:
	var level_string: String = _get_property(id, CsvProperty.LEVEL)
	var level: int = level_string.to_int()

	return level


func get_level_add(id: int) -> int:
	var level_add_string: String = _get_property(id, CsvProperty.LEVEL_ADD)
	var level_add: int = level_add_string.to_int()

	return level_add


func get_target_type(id: int) -> TargetType:
	var string: String = _get_property(id, CsvProperty.TARGET_TYPE)
	var target_type: TargetType = TargetType.convert_from_string(string)

	return target_type


func get_is_hidden(id: int) -> bool:
	var is_hidden_string: String = _get_property(id, CsvProperty.IS_HIDDEN)
	var is_hidden: bool = Utils.string_to_bool(is_hidden_string)

	return is_hidden


func get_icon_path(id: int) -> String:
	var icon_path: String = _get_property(id, CsvProperty.ICON_PATH)

	return icon_path


func get_aura_name(id: int) -> String:
	var aura_name_text_id: String = _get_property(id, CsvProperty.NAME)
	var aura_name: String = tr(aura_name_text_id)

	return aura_name


func get_description_short(id: int) -> String:
	var description_short_text_id: String = _get_property(id, CsvProperty.DESCRIPTION_SHORT)
	var description_short: String = tr(description_short_text_id)

	return description_short


func get_description_full(id: int) -> String:
	var description_full_text_id: String = _get_property(id, CsvProperty.DESCRIPTION_FULL)
	var description_full: String = tr(description_full_text_id)

	return description_full


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
