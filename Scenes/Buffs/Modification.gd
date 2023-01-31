class_name Modification
extends Node


enum Type {
# For mobs:
	
#	0.01 = +1%
	MOD_MOVE_SPEED,
#	1.0 = +1
	MOD_MOVE_SPEED_ABSOLUTE,

# For towers:
	MOD_ATTACK_CRIT_CHANCE,
	MOD_ATTACK_CRIT_DAMAGE,
	MOD_MULTICRIT_COUNT,

	MOD_DMG_TO_MASS,
	MOD_DMG_TO_NORMAL,
	MOD_DMG_TO_CHAMPION,
	MOD_DMG_TO_BOSS,

	MOD_DMG_TO_UNDEAD,
	MOD_DMG_TO_MAGIC,
	MOD_DMG_TO_NATURE,
	MOD_DMG_TO_ORC,
	MOD_DMG_TO_HUMANOID,
}

var type: int
var value_base: float
var level_add: float


func _init(type_arg: int, value_base_arg: float, level_add_arg: float):
	type = type_arg
	value_base = value_base_arg
	level_add = level_add_arg
