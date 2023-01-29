extends Node

class_name Modification


enum Type {
	MOD_MOVE_SPEED,
}


var type: int
var value_base: float
var level_add: float


func _init(type_arg: int, value_base_arg: int, level_add_arg: float):
	type = type_arg
	value_base = value_base_arg
	level_add = level_add_arg
