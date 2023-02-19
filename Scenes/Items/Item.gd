extends KinematicBody2D


const properties_path = "res://Assets/item_properties.csv"


export(int) var id


var _name: String setget ,get_name
var _author: String setget ,get_author
var _rarity: String setget ,get_rarity
var _cost: int setget ,get_cost
var _description: String setget ,get_description
var _required_wave_level: int setget ,get_required_wave_level


#########################
### Code starts here  ###
#########################

func _ready():
	var props: Dictionary = Properties.get_item_properies(id)
	_name = props[0]
	_author = props[1]
	_rarity = props[2]
	_cost = props[3]
	_description = props[4]
	_required_wave_level = props[5]


#########################
### Setters / Getters ###
#########################

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
