extends Node

class_name Modification


enum Type {
	MOD_MOVE_SPEED,
}


var type: int
var value: float


func _init(type_arg: int, value_arg: int):
	type = type_arg
	value = value_arg
