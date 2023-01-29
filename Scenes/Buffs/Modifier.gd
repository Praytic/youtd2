class_name Modifier
extends Node

# Modifier stores a list of modifications. Can apply and
# undo apply of such modifications on a unit.


var modification_list: Array


func add_modification(modification_type: int, value_base: float, level_add: float):
	var modification: Modification = Modification.new(modification_type, value_base, level_add)
	modification_list.append(modification)


func apply(target, level: int):
	_apply_internal(target, level, 1)


func remove(target, level: int):
	_apply_internal(target, level, -1)


func _apply_internal(target, level: int, apply_direction: int):
	for modification in modification_list:
		var level_bonus: float = 1.0 + modification.level_add * (1 - level)
		var value: float = apply_direction * modification.value_base * level_bonus
		target.modify_property(modification.type, value)
