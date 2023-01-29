extends Node

# Modifier stores a list of modifications. Can apply and
# undo apply of such modifications on a unit.

class_name Modifier


var modification_list: Array


func add_modification(modification_type: int, _mystery_arg: int, value_base: float):
	var modification: Modification = Modification.new(modification_type, value_base)
	modification_list.append(modification)


func apply(target: Unit, value_modifier: float):
	apply_internal(target, value_modifier, 1)


func remove(target: Unit, value_modifier: float):
	apply_internal(target, value_modifier, -1)


func apply_internal(target: Unit, value_modifier: float, apply_direction: int):
	for modification in modification_list:
		var final_value: float = apply_direction * modification.value * value_modifier
		target.modify_property(modification.type, final_value)
