class_name Item
extends KinematicBody2D


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
	_name = props[0]
	_author = props[1]
	_rarity = Constants.Rarity.get(props[2].to_upper())
	_cost = props[3].to_int()
	_description = props[4]
	_required_wave_level = props[5]


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
