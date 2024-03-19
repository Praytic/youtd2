extends Node


enum CsvProperty {
	ID,
	NAME,
	OLD_NAME,
	SCRIPT_NAME,
	TYPE,
	AUTHOR,
	RARITY,
	COST,
	DESCRIPTION,
	REQUIRED_WAVE_LEVEL,
	ICON_ATLAS_FAMILY,
	ICON_ATLAS_NUM,
}

const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const ICON_FAMILIES_PER_PAGE = 66
const MAX_ICONS_PER_FAMILY = 5
const PROPERTIES_PATH = "res://Data/item_properties.csv"
# NOTE: this id needs to be updated if it's changed in csv
const CONSUMABLE_CHICKEN_ID: int = 2003

const item_icons_m: Texture2D = preload("res://Assets/Items/item_icons_m.png")
const potion_icons_m: Texture2D = preload("res://Assets/Items/potion_icons_m.png")

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)


#########################
###       Public      ###
#########################


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
	var icon_atlas_num: int = ItemProperties.get_icon_atlas_num(item_id)
	var icon_atlas_family: int = ItemProperties.get_icon_atlas_family(item_id)
	var item_type: ItemType.enm = ItemProperties.get_type(item_id)
	var is_oil_or_consumable: bool = item_type == ItemType.enm.OIL || item_type == ItemType.enm.CONSUMABLE
	
	if icon_atlas_num == -1 or icon_atlas_family == -1:
		push_error("Unknown icon for item ID [%s]" % item_id)

	var item_icon = AtlasTexture.new()
	var icon_size: int = ICON_SIZE_M
	
	if is_oil_or_consumable:
		item_icon.set_atlas(potion_icons_m)
	else:
		item_icon.set_atlas(item_icons_m)
	
	var page_num = floor(float(icon_atlas_family) / ICON_FAMILIES_PER_PAGE)
	var x = icon_atlas_num * icon_size + page_num * MAX_ICONS_PER_FAMILY * icon_size
	var y = icon_atlas_family % ICON_FAMILIES_PER_PAGE * icon_size
	var region: Rect2 = Rect2(x, y, icon_size, icon_size)
	item_icon.set_region(region)

	return item_icon


func get_item_name(item_id: int) -> String:
	return _get_property(item_id, CsvProperty.NAME)


func get_old_name(item_id: int) -> String:
	return _get_property(item_id, CsvProperty.OLD_NAME)


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


func get_icon_atlas_family(item_id: int) -> int:
	var prop = _get_property(item_id, CsvProperty.ICON_ATLAS_FAMILY)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()


func get_icon_atlas_num(item_id: int) -> int:
	var prop = _get_property(item_id, CsvProperty.ICON_ATLAS_NUM)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()


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

