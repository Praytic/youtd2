class_name Modification
extends Node


enum MathType {
	ADD,
	MULTIPLY,
}

enum Type {
# For mobs:
	MOD_MOVE_SPEED,
	MOD_MOVE_SPEED_ABSOLUTE,
	MOD_ARMOR,
	MOD_ARMOR_PERC,

# For towers:
	MOD_ATTACK_CRIT_CHANCE,
	MOD_ATTACK_CRIT_DAMAGE,
	MOD_ATTACK_SPEED,
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

	MOD_ITEM_CHANCE_ON_KILL,
	MOD_ITEM_QUALITY_ON_KILL,

# For all units:
	MOD_BUFF_DURATION,
	MOD_DEBUFF_DURATION,
	MOD_TRIGGER_CHANCES,
}

const _math_type_map: Dictionary = {
# For mobs:
	Type.MOD_MOVE_SPEED: MathType.MULTIPLY,
	Type.MOD_MOVE_SPEED_ABSOLUTE: MathType.ADD,
	Type.MOD_ARMOR: MathType.ADD,
	Type.MOD_ARMOR_PERC: MathType.MULTIPLY,

# For towers:
	Type.MOD_ATTACK_CRIT_CHANCE: MathType.ADD,
	Type.MOD_ATTACK_CRIT_DAMAGE: MathType.ADD,
	Type.MOD_ATTACK_SPEED: MathType.MULTIPLY,
	Type.MOD_MULTICRIT_COUNT: MathType.ADD,

	Type.MOD_DMG_TO_MASS: MathType.ADD,
	Type.MOD_DMG_TO_NORMAL: MathType.ADD,
	Type.MOD_DMG_TO_CHAMPION: MathType.ADD,
	Type.MOD_DMG_TO_BOSS: MathType.ADD,

	Type.MOD_DMG_TO_UNDEAD: MathType.ADD,
	Type.MOD_DMG_TO_MAGIC: MathType.ADD,
	Type.MOD_DMG_TO_NATURE: MathType.ADD,
	Type.MOD_DMG_TO_ORC: MathType.ADD,
	Type.MOD_DMG_TO_HUMANOID: MathType.ADD,

	Type.MOD_ITEM_CHANCE_ON_KILL: MathType.ADD,
	Type.MOD_ITEM_QUALITY_ON_KILL: MathType.ADD,

# For all units:
	Type.MOD_BUFF_DURATION: MathType.MULTIPLY,
	Type.MOD_DEBUFF_DURATION: MathType.MULTIPLY,
	Type.MOD_TRIGGER_CHANCES: MathType.ADD,
}

var type: int
var value_base: float
var level_add: float


func _init(type_arg: int, value_base_arg: float, level_add_arg: float):
	type = type_arg
	value_base = value_base_arg
	level_add = level_add_arg


static func get_math_type(modification_type: int) -> int:
	if !_math_type_map.has(modification_type):
		print_debug("No math type defined for modification type: ", modification_type)

		return MathType.ADD

	var math_type: int = _math_type_map[modification_type]

	return math_type
