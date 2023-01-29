class_name Modifier
extends Node

# Modifier stores a list of modifications. Can apply and
# undo apply of such modifications on a unit. LevelType
# determines whether modifier scales with tower level or
# buff level. By default modification scales with tower
# level.


enum LevelType {
	TOWER,
	BUFF
}


var _modification_list: Array = [] setget , get_modification_list
var level: int = 0
var _tower_level: int
var _buff_level: int
var level_type: int = LevelType.TOWER


func add_modification(modification_type: int, value_base: float, level_add: float):
	var modification: Modification = Modification.new(modification_type, value_base, level_add)
	_modification_list.append(modification)


func get_modification_list() -> Array:
	return _modification_list.duplicate(true)


func set_levels(tower_level: int, buff_level: int):
	_tower_level = tower_level
	_buff_level = buff_level


func get_level() -> int:
	match level_type:
		LevelType.TOWER: return _tower_level
		LevelType.BUFF: return _buff_level

	return 0
