class_name Item
extends KinematicBody2D


enum CsvProperty {
	ID = 0,
	NAME = 1,
	SCENE_NAME = 2,
	AUTHOR = 3,
	RARITY = 4,
	COST = 5,
	DESCRIPTION = 6,
	REQUIRED_WAVE_LEVEL = 7,
}

const cell_size = 32

var _carrier: Tower = null


#########################
### Code starts here  ###
#########################


func _ready():
	pass


# TODO: implement checks for max item count
func add_to_tower(tower: Tower):
	_carrier = tower
	_carrier.add_child(self)
	_add_to_tower_subclass()


func remove_from_tower():
	if _carrier == null:
		return

	_remove_from_tower_subclass()
	_carrier.remove_child(self)
	_carrier = null

# 	TODO: where does item go after it's removed from
# 	carrier? queue_free() or reparent to some new node?


# Override in subclass to define what effect item adds
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

func get_id() -> int:
	return get_property(CsvProperty.ID).to_int()

func get_name() -> String:
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
	var properties: Dictionary = Properties.get_item_csv_properties_by_filename(filename)

	return properties[property]


func get_carrier() -> Tower:
	return _carrier
