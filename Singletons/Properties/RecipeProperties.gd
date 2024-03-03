extends Node


const PROPERTIES_PATH: String = "res://Data/recipe_properties.csv"

enum CsvProperty {
	ID,
	DISPLAY_NAME,
	PERMANENT_COUNT,
	USABLE_COUNT,
	RESULT_ITEM_TYPE,
	RESULT_COUNT,
	RARITY_CHANGE,
	LVL_BONUS_MIN,
	LVL_BONUS_MAX,
	DESCRIPTION,
}


const _permanent_type_list: Array[ItemType.enm] = [ItemType.enm.REGULAR]
const _usable_type_list: Array[ItemType.enm] = [ItemType.enm.OIL, ItemType.enm.CONSUMABLE]


var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	Properties._load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)


#########################
###       Public      ###
#########################


func get_id_list() -> Array:
	var id_list: Array = _properties.keys()
	id_list.sort()

	return id_list


func get_display_name(recipe: int) -> String:
	var string: String = _get_property(recipe, CsvProperty.DISPLAY_NAME)

	return string


func get_permanent_count(recipe: int) -> int:
	var permanent_count: int = _get_property(recipe, CsvProperty.PERMANENT_COUNT) as int

	return permanent_count


func get_usable_count(recipe: int) -> int:
	var usable_count: int = _get_property(recipe, CsvProperty.USABLE_COUNT) as int

	return usable_count


func get_result_item_type(recipe: int) -> Array[ItemType.enm]:
	var result_item_type_string: String = _get_property(recipe, CsvProperty.RESULT_ITEM_TYPE)
	var result_item_type: Array[ItemType.enm]
	if result_item_type_string == "permanent":
		result_item_type = _permanent_type_list
	elif result_item_type_string == "usable":
		result_item_type = _usable_type_list
	elif result_item_type_string == "none":
		result_item_type = []

	return result_item_type


func get_result_count(recipe: int) -> int:
	var result_count: int = _get_property(recipe, CsvProperty.RESULT_COUNT) as int

	return result_count


func get_rarity_change(recipe: int) -> int:
	var rarity_change: int = _get_property(recipe, CsvProperty.RARITY_CHANGE) as int

	return rarity_change


func get_lvl_bonus_min(recipe: int) -> int:
	var lvl_bonus_min: int = _get_property(recipe, CsvProperty.LVL_BONUS_MIN) as int

	return lvl_bonus_min


func get_lvl_bonus_max(recipe: int) -> int:
	var lvl_bonus_max: int = _get_property(recipe, CsvProperty.LVL_BONUS_MAX) as int

	return lvl_bonus_max


func get_description(recipe: int) -> String:
	var description: String = _get_property(recipe, CsvProperty.DESCRIPTION)

	return description


#########################
###      Private      ###
#########################

func _get_property(recipe: int, property: CsvProperty) -> String:
	if !_properties.has(recipe):
		push_error("No properties for recipe: ", recipe)

		return ""

	var map: Dictionary = _properties[recipe]
	var property_value: String = map[property]

	return property_value
