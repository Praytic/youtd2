extends Node


enum CsvProperty {
	ID,
	NAME_ENGLISH,
	TYPE,
	AUTHOR,
	RARITY,
	COST,
	REQUIRED_WAVE_LEVEL,
	SPECIALS,
	ABILITY_LIST,
	AURA_LIST,
	AUTOCAST_LIST,
	SCRIPT_PATH,
	ICON,
	NAME,
	DESCRIPTION
}

const PROPERTIES_PATH = "res://data/item_properties.csv"
# NOTE: this id needs to be updated if it's changed in csv
const CONSUMABLE_CHICKEN_ID: int = 2003
const PLACEHOLDER_ITEM_ICON: String = "res://resources/icons/animals/cow.tres"


var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

#	Check script paths
	var id_list: Array = get_item_id_list()
	for id in id_list:
		var script_path: String = ItemProperties.get_script_path(id)
		var script_path_is_valid: bool = ResourceLoader.exists(script_path)

		if !script_path_is_valid:
			push_error("Invalid item script path item: %s" % script_path)

		var icon_path: String = ItemProperties.get_icon_path(id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)
		if !icon_path_is_valid:
			push_error("Invalid item icon path: %s" % icon_path)


#########################
###       Public      ###
#########################

func get_specials_modifier(item_id: int) -> Modifier:
	var string: String = _get_property(item_id, CsvProperty.SPECIALS)
	
	if string.is_empty():
		return Modifier.new()

	var modifier: Modifier = Modifier.convert_from_string(string)

	return modifier


func get_ability_id_list(item_id: int) -> Array[int]:
	var string: String = _get_property(item_id, CsvProperty.ABILITY_LIST)
	var ability_id_list: Array[int] = UtilsStatic.convert_string_to_id_list(string)

	return ability_id_list


func get_aura_id_list(item_id: int) -> Array[int]:
	var string: String = _get_property(item_id, CsvProperty.AURA_LIST)
	var aura_id_list: Array[int] = UtilsStatic.convert_string_to_id_list(string)

	return aura_id_list


func get_autocast_id_list(item_id: int) -> Array[int]:
	var string: String = _get_property(item_id, CsvProperty.AUTOCAST_LIST)
	var autocast_id_list: Array[int] = UtilsStatic.convert_string_to_id_list(string)

	return autocast_id_list


func get_script_path(item_id: int):
	var script_path: String = _get_property(item_id, CsvProperty.SCRIPT_PATH)

	return script_path


func get_item_id_list() -> Array:
	return _properties.keys()


func get_id_list_by_filter(item_property: CsvProperty, filter_value: String) -> Array:
	var all_item_list: Array = _properties.keys()
	var result_list: Array = filter_item_id_list(all_item_list, item_property, filter_value)

	return result_list


func filter_item_id_list(item_list: Array, item_property: CsvProperty, filter_value: String) -> Array:
	var result_list = []
	for item_id in item_list:
		if _properties[item_id][item_property] == filter_value:
			result_list.append(item_id)
	return result_list


func get_icon(item_id: int) -> Texture2D:
	var icon_path: String = ItemProperties.get_icon_path(item_id)
	var icon_path_exists: bool = ResourceLoader.exists(icon_path)

	if !icon_path_exists:
		push_error("Icon path doesn't exist, loading placeholder.")

		icon_path = PLACEHOLDER_ITEM_ICON
	
	var item_icon: Texture2D = load(icon_path)

	return item_icon


func get_display_name(item_id: int) -> String:
	var display_name_text_id: String = _get_property(item_id, CsvProperty.NAME)
	var display_name: String = tr(display_name_text_id)

	return display_name


func get_author(item_id: int) -> String:
	return _get_property(item_id, CsvProperty.AUTHOR)


func get_rarity(item_id: int) -> Rarity.enm:
	var rarity_string: String = _get_property(item_id, CsvProperty.RARITY)
	var rarity: Rarity.enm = Rarity.convert_from_string(rarity_string)

	return rarity


func get_cost(item_id: int) -> int:
	return _get_property(item_id, CsvProperty.COST).to_int()


func get_description(item_id: int) -> String:
	var description_text_id: String = _get_property(item_id, CsvProperty.DESCRIPTION)
	var description: String = tr(description_text_id)

	return description


func get_required_wave_level(item_id: int) -> int:
	return _get_property(item_id, CsvProperty.REQUIRED_WAVE_LEVEL).to_int()


func get_icon_path(item_id: int) -> String:
	var icon_path: String = _get_property(item_id, CsvProperty.ICON)

	return icon_path


func get_tooltip_text(item_id: int) -> String:
	var item_name: String = get_display_name(item_id)
	var item_description: String = get_description(item_id)
	var text: String = "%s\n%s" % [item_name, item_description]

	return text


func get_type(item_id: int) -> ItemType.enm:
	var type_name: String = _get_property(item_id, CsvProperty.TYPE)
	var type: ItemType.enm = ItemType.from_string(type_name)

	return type


func get_is_oil(item_id: int) -> bool:
	var type: ItemType.enm = get_type(item_id)
	var is_oil: bool = type == ItemType.enm.OIL

	return is_oil


func is_consumable(item_id: int) -> bool:
	var item_type: ItemType.enm = ItemProperties.get_type(item_id)
	var result: bool = item_type == ItemType.enm.CONSUMABLE

	return result


#########################
###      Private      ###
#########################

func _get_property(item: int, property: CsvProperty) -> String:
	if !_properties.has(item):
		push_error("No properties for item: ", item)

		return ""

	var map: Dictionary = _properties[item]
	var property_value: String = map[property]

	return property_value
