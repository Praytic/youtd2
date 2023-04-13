extends Node

const ICON_SIZE_S = 64
const ICON_SIZE_M = 128

@onready var item_icons_s: Texture2D = preload("res://Assets/Items/item_icons_s.png")
@onready var item_icons_m: Texture2D = preload("res://Assets/Items/item_icons_m.png")
@onready var item_button_fallback_icon: Texture2D = preload("res://Assets/icon.png")


func get_icon(item_id: int, icon_size_letter: String) -> Texture2D:
	var icon_atlas_num: int = ItemProperties.get_icon_atlas_num(item_id)
	var icon_atlas_family: int = ItemProperties.get_icon_atlas_family(item_id)
	if icon_atlas_num == -1 or icon_atlas_family == -1:
		return item_button_fallback_icon

	var item_icon = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		item_icon.set_atlas(item_icons_s)
		icon_size = ICON_SIZE_S
	elif icon_size_letter == "M":
		item_icon.set_atlas(item_icons_m)
		icon_size = ICON_SIZE_M
	else:
		return item_button_fallback_icon
	
	var region: Rect2 = Rect2(icon_atlas_num * icon_size, icon_atlas_family * icon_size, icon_size, icon_size)
	item_icon.set_region(region)

	return item_icon


func get_item_name(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.NAME)


func get_author(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.AUTHOR)


func get_rarity(item_id: int) -> String:
	return get_property(item_id, Item.CsvProperty.RARITY)
	

func get_rarity_num(item_id: int) -> int:
	return Constants.Rarity.get(get_rarity(item_id).to_upper())


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
