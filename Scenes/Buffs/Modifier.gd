extends Node

# Modifier stores a list of modifications. Can apply and
# undo apply of such modifications on a unit.

class_name Modifier


enum ModificationType {
	MOD_MOVE_SPEED,
}

class Modification:
	var type: int
	var value_base: float
	
	func _init(type_arg: int, value_base_arg: int):
		type = type_arg
		value_base = value_base_arg


var modification_list: Array


func add_modification(modification_type: int, _mystery_arg: int, value_base: float):
	var modification: Modification = Modification.new(modification_type, value_base)
	modification_list.append(modification)


func apply(target: Mob, value_modifier: float):
	for modification in modification_list:
		apply_mod(modification, target, value_modifier)


# TODO: multiplying by -1 is a nice trick but it might not
# work for some cases
func undo_apply(target: Mob, value_modifier: float):
	for modification in modification_list:
		apply_mod(modification, target, -1 * value_modifier)


func apply_mod(modification: Modification, target: Mob, value_modifier: float):
	match modification.type:
		ModificationType.MOD_MOVE_SPEED:
			var modification_value: float = modification.value_base * value_modifier
			target.mob_move_speed = max(0, target.mob_move_speed + modification_value)
