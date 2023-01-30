class_name Modification
extends Node


enum Type {
# For mobs:
	MOD_MOVE_SPEED,

# For towers:
	MOD_ATTACK_CRIT_CHANCE,
}


var type: int
var value_base: float
var level_add: float


func _init(type_arg: int, value_base_arg: float, level_add_arg: float):
	type = type_arg
	value_base = value_base_arg
	level_add = level_add_arg
