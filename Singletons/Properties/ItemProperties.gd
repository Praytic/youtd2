extends Node


enum CsvProperty {
	ID,
	NAME,
	SCRIPT_NAME,
	TYPE,
	AUTHOR,
	RARITY,
	COST,
	DESCRIPTION,
	REQUIRED_WAVE_LEVEL,
	ICON,
}

const PROPERTIES_PATH = "res://Data/item_properties.csv"
# NOTE: this id needs to be updated if it's changed in csv
const CONSUMABLE_CHICKEN_ID: int = 2003
const ITEM_ICON_DIR: String = "res://Resources/Icons/ItemIcons"
const PLACEHOLDER_ITEM_ICON: String = "res://Resources/Icons/amulets/amulet_m.tres"


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

func get_script_path(item_id: int):
	var item_name: String = ItemProperties.get_display_name(item_id)
	item_name = item_name.replace(" ", "")
	item_name = item_name.replace("'", "")
	var path: String = "res://Scenes/Items/ItemBehaviors/%s.gd" % [item_name]

	return path


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


func get_item_name(item_id: int) -> String:
	return _get_property(item_id, CsvProperty.NAME)


func get_author(item_id: int) -> String:
	return _get_property(item_id, CsvProperty.AUTHOR)


func get_rarity(item_id: int) -> Rarity.enm:
	var rarity_string: String = _get_property(item_id, CsvProperty.RARITY)
	var rarity: Rarity.enm = Rarity.convert_from_string(rarity_string)

	return rarity


func get_cost(item_id: int) -> int:
	return _get_property(item_id, CsvProperty.COST).to_int()


func get_description(item_id: int) -> String:
	return _get_property(item_id, CsvProperty.DESCRIPTION)


func get_required_wave_level(item_id: int) -> int:
	return _get_property(item_id, CsvProperty.REQUIRED_WAVE_LEVEL).to_int()


func get_icon_path(item_id: int) -> String:
	var icon_path: String = _get_property(item_id, CsvProperty.ICON)

	return icon_path


func get_display_name(item_id: int) -> String:
	return _get_property(item_id, CsvProperty.NAME)


func get_tooltip_text(item_id: int) -> String:
	var item_name: String = get_item_name(item_id)
	var item_description: String = get_description(item_id)
	var text: String = "%s\n%s" % [item_name, item_description]

	return text


func get_type(item_id: int) -> ItemType.enm:
	var type_string: String = _get_property(item_id, CsvProperty.TYPE)
	var type: ItemType.enm = ItemType.from_string(type_string)

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

