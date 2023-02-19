class_name Item
extends KinematicBody2D


enum CsvProperty {
	ID = 0,
	NAME = 1,
	AUTHOR = 2,
	RARITY = 3,
	COST = 4,
	DESCRIPTION = 5,
	REQUIRED_WAVE_LEVEL = 6,
}

const cell_size = 32


var _id: int setget ,get_id
var _name: String setget ,get_name
var _author: String setget ,get_author
# enum Constants.Rarity
var _rarity: int setget ,get_rarity
var _cost: int setget ,get_cost
var _description: String setget ,get_description
var _required_wave_level: int setget ,get_required_wave_level


#########################
### Code starts here  ###
#########################

func _init(item_id: int):
	_id = item_id


func _ready():
	var props: Dictionary = Properties.get_item_properties()[_id]
	_name = props[CsvProperty.NAME]
	_author = props[CsvProperty.AUTHOR]
	_rarity = Constants.Rarity.get(props[CsvProperty.RARITY].to_upper())
	_cost = props[CsvProperty.COST].to_int()
	_description = props[CsvProperty.DESCRIPTION]
	_required_wave_level = props[CsvProperty.REQUIRED_WAVE_LEVEL]


#########################
### Setters / Getters ###
#########################

func get_id():
	return _id

func get_name():
	return _name

func get_author():
	return _author

func get_rarity():
	return _rarity

func get_cost():
	return _cost

func get_description():
	return _description

func get_required_wave_level():
	return _required_wave_level
