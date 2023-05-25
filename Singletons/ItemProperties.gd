extends Node

const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const ICON_FAMILIES_PER_PAGE = 66
const MAX_ICONS_PER_FAMILY = 5

@onready var item_icons_m: Texture2D = preload("res://Assets/Items/item_icons_m.png")


func get_icon(item_id: int) -> Texture2D:
	var icon_atlas_num: int = ItemProperties.get_icon_atlas_num(item_id)
	var icon_atlas_family: int = ItemProperties.get_icon_atlas_family(item_id)
	if icon_atlas_num == -1 or icon_atlas_family == -1:
		push_error("Unknown icon for item ID [%s]" % item_id)

	var item_icon = AtlasTexture.new()
	var icon_size: int = ICON_SIZE_M
	
	item_icon.set_atlas(item_icons_m)
	
	var page_num = floor(float(icon_atlas_family) / ICON_FAMILIES_PER_PAGE)
	var x = icon_atlas_num * icon_size + page_num * MAX_ICONS_PER_FAMILY * icon_size
	var y = icon_atlas_family % ICON_FAMILIES_PER_PAGE * icon_size
	var region: Rect2 = Rect2(x, y, icon_size, icon_size)
	item_icon.set_region(region)

	return item_icon


func get_item_name(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.NAME)


func get_author(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.AUTHOR)


func get_rarity(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.RARITY)
	

func get_rarity_num(item_id: int) -> Rarity.enm:
	var rarity_string: String = get_rarity(item_id)
	var rarity: Rarity.enm = Rarity.convert_from_string(rarity_string)

	return rarity


func get_cost(item_id: int) -> int:
	return get_property(item_id, Item.CsvProperty.COST).to_int()


func get_description(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.DESCRIPTION)


func get_required_wave_level(item_id: int) -> int:
	return get_property(item_id, Item.CsvProperty.REQUIRED_WAVE_LEVEL).to_int()


func get_property(item_id: int, property: int) -> String:
	var properties: Dictionary = Properties.get_item_csv_properties_by_id(item_id)

	return properties[property]


func get_icon_atlas_family(item_id: int) -> int:
	var prop = get_property(item_id, Item.CsvProperty.ICON_ATLAS_FAMILY)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()


func get_icon_atlas_num(item_id: int) -> int:
	var prop = get_property(item_id, Item.CsvProperty.ICON_ATLAS_NUM)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()


func get_display_name(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.NAME)


func get_tooltip_text(item_id: int) -> String:
	var item_name: String = get_item_name(item_id)
	var item_description: String = get_description(item_id)
	var text: String = "%s\n%s" % [item_name, item_description]

	return text


func get_is_oil(item_id: int) -> bool:
	var is_oil_string: String = get_property(item_id, Item.CsvProperty.IS_OIL)
	var is_oil: bool = is_oil_string == "TRUE"

	return is_oil
