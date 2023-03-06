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
}

var _id: int = 0
var _carrier: Tower = null

# Call add_modification() on _modifier in subclass to add item effects
var _modifier: Modifier = Modifier.new()


#########################
### Code starts here  ###
#########################


func _ready():
	_item_init()


# TODO: implement checks for max item count
func add_to_tower(tower: Tower):
	_carrier = tower
	_carrier.add_child(self)
	_carrier.add_modifier(_modifier)
	_add_to_tower_subclass()


func remove_from_tower():
	if _carrier == null:
		return

	_remove_from_tower_subclass()
	_carrier.remove_modifier(_modifier)
	_carrier.remove_child(self)
	_carrier = null

# 	TODO: where does item go after it's removed from
# 	carrier? queue_free() or reparent to some new node?

# Override in subclass to initialize subclass item
func _item_init():
	pass


# Override in subclass to define adding of effects from
# to the carrier
func _add_to_tower_subclass():
	pass


# Override in subclass to define removal of effects from
# carrier
func _remove_from_tower_subclass():
	pass


#########################
### Setters / Getters ###
#########################

# NOTE: this must be called once after the item is created
# but before it's added to game scene.
func set_id(id: int):
	_id = id

func get_id() -> int:
	return _id

func get_item_name() -> String:
	return get_property(CsvProperty.NAME)

func get_author() -> String:
	return get_property(CsvProperty.AUTHOR)

func get_rarity() -> int:
	var rarity_string: String = get_property(CsvProperty.DESCRIPTION)
	var rarity: int = Constants.Rarity.get(rarity_string.to_upper())

	return rarity

func get_cost() -> int:
	return get_property(CsvProperty.RARITY).to_int()

func get_description() -> String:
	return get_property(CsvProperty.DESCRIPTION)

func get_required_wave_level() -> int:
	return get_property(CsvProperty.REQUIRED_WAVE_LEVEL).to_int()

func get_property(property: int) -> String:
	var properties: Dictionary = Properties.get_item_csv_properties_by_id(_id)

	return properties[property]


func get_carrier() -> Tower:
	return _carrier
