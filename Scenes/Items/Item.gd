class_name Item
extends Node


# Item represents item when it's attached to a tower.
# Implements application of item effects on tower.


enum CsvProperty {
	ID = 0,
	NAME = 1,
	SCRIPT_NAME = 2,
	AUTHOR = 3,
	RARITY = 4,
	COST = 5,
	DESCRIPTION = 6,
	REQUIRED_WAVE_LEVEL = 7,
	ICON_ATLAS_FAMILY = 8,
	ICON_ATLAS_NUM = 9,
}

const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const PRINT_SCRIPT_NOT_FOUND_ERROR: bool = false
const FAILLBACK_SCRIPT: String = "res://Scenes/Items/Instances/Item105.gd"

var _id: int = 0
var _carrier: Tower = null

# Call add_modification() on _modifier in subclass to add item effects
var _modifier: Modifier = Modifier.new()
var _buff_type_list: Array[BuffType] = []
var _applied_buff_list: Array[Buff] = []


#########################
### Code starts here  ###
#########################

static func make(id: int) -> Item:
	var item_script_path: String = "res://Scenes/Items/Instances/Item%d.gd" % id
	
	var script_exists: bool = FileAccess.file_exists(item_script_path)
	
	if !script_exists:
		if PRINT_SCRIPT_NOT_FOUND_ERROR:
			print_debug("No item script found for id:", id, ". Tried at path:", item_script_path)

		item_script_path = FAILLBACK_SCRIPT

	var item_script = load(item_script_path)

	if item_script == null:
		return null

	var item: Item = item_script.new(id)

	return item


func _init(id: int):
	_id = id
	_item_init()


static func get_icon(item_id: int, icon_size_letter: String) -> Texture2D:
	var icon_atlas_num: int = Item.get_icon_atlas_num(item_id)
	var icon_atlas_family: int = Item.get_icon_atlas_family(item_id)
	if icon_atlas_num == -1 or icon_atlas_family == -1:
		return Utils.item_button_fallback_icon

	var item_icon = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		item_icon.set_atlas(Utils.item_icons_s)
		icon_size = ICON_SIZE_S
	elif icon_size_letter == "M":
		item_icon.set_atlas(Utils.item_icons_m)
		icon_size = ICON_SIZE_M
	else:
		return Utils.item_button_fallback_icon
	
	var region: Rect2 = Rect2(icon_atlas_num * icon_size, icon_atlas_family * icon_size, icon_size, icon_size)
	item_icon.set_region(region)

	return item_icon


# TODO: implement checks for max item count
func apply_to_tower(tower: Tower):
	_carrier = tower

	_carrier.add_modifier(_modifier)

	for buff_type in _buff_type_list:
		var buff: Buff = buff_type.apply_to_unit_permanent(_carrier, _carrier, 0)
		_applied_buff_list.append(buff)


func remove_from_tower():
	if _carrier == null:
		return

	_carrier.remove_modifier(_modifier)

	for buff in _applied_buff_list:
		buff.remove_buff()

	_applied_buff_list.clear()

	_carrier.remove_child(self)
	_carrier = null

# 	TODO: where does item go after it's removed from
# 	carrier? queue_free() or reparent to some new node?

# Override in subclass to initialize subclass item
func _item_init():
	pass


#########################
### Setters / Getters ###
#########################

func get_id() -> int:
	return _id

func get_item_name() -> String:
	return Item.get_property(_id, CsvProperty.NAME)

func get_author() -> String:
	return Item.get_property(_id, CsvProperty.AUTHOR)

func get_rarity() -> String:
	return Item.get_property(_id, CsvProperty.RARITY)
	
func get_rarity_num() -> int:
	return Constants.Rarity.get(get_rarity().to_upper())

func get_cost() -> int:
	return Item.get_property(_id, CsvProperty.COST).to_int()

func get_description() -> String:
	return Item.get_property(_id, CsvProperty.DESCRIPTION)

func get_required_wave_level() -> int:
	return Item.get_property(_id, CsvProperty.REQUIRED_WAVE_LEVEL).to_int()

static func get_property(item_id: int, property: int) -> String:
	var properties: Dictionary = Properties.get_item_csv_properties_by_id(item_id)

	return properties[property]


func get_carrier() -> Tower:
	return _carrier

static func get_icon_atlas_family(item_id: int) -> int:
	var prop = Item.get_property(item_id, CsvProperty.ICON_ATLAS_FAMILY)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()

static func get_icon_atlas_num(item_id: int) -> int:
	var prop = Item.get_property(item_id, CsvProperty.ICON_ATLAS_NUM)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()

func get_display_name() -> String:
	return Item.get_property(_id, CsvProperty.NAME)
