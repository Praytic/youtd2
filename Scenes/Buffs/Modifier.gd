class_name Modifier

# Modifier stores a list of modifications. Can apply and
# undo apply of such modifications on a unit.


var _modification_list: Array = []


func add_modification(modification_type: int, value_base: float, level_add: float):
	var modification: Modification = Modification.new(modification_type, value_base, level_add)
	_modification_list.append(modification)


func get_modification_list() -> Array:
	return _modification_list.duplicate(true)
