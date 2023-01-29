class_name Modifier
extends Node

# Modifier stores a list of modifications. Can apply and
# undo apply of such modifications on a unit.


var modification_list: Array


func add_modification(modification_type: int, value_base: float, level_add: float):
	var modification: Modification = Modification.new(modification_type, value_base, level_add)
	modification_list.append(modification)
