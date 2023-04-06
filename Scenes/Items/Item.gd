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
	return get_property(CsvProperty.NAME)

func get_author() -> String:
	return get_property(CsvProperty.AUTHOR)

func get_rarity() -> String:
	return get_property(CsvProperty.RARITY)
	
func get_rarity_num() -> int:
	return Constants.Rarity.get(get_rarity().to_upper())

func get_cost() -> int:
	return get_property(CsvProperty.COST).to_int()

func get_description() -> String:
	return get_property(CsvProperty.DESCRIPTION)

func get_required_wave_level() -> int:
	return get_property(CsvProperty.REQUIRED_WAVE_LEVEL).to_int()

func get_property(property: int) -> String:
	var properties: Dictionary = Properties.get_item_csv_properties_by_id(_id)

	return properties[property]


func get_carrier() -> Tower:
	return _carrier

func get_icon_atlas_family() -> int:
	var prop = get_property(CsvProperty.ICON_ATLAS_FAMILY)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()

func get_icon_atlas_num() -> int:
	var prop = get_property(CsvProperty.ICON_ATLAS_NUM)
	if prop.is_empty():
		return -1
	else:
		return prop.to_int()

func get_display_name() -> String:
	return get_property(CsvProperty.NAME)
