class_name Modifier

# Modifier stores a list of modifications. Can apply and
# undo apply of such modifications on a unit.


var _modification_list: Array = []


#########################
###       Public      ###
#########################

# NOTE: modifier.addModification() in JASS
func add_modification(modification_type: int, value_base: float, level_add: float):
	var modification: Modification = Modification.new(modification_type, value_base, level_add)
	_modification_list.append(modification)


func add_modification_instance(modification: Modification):
	_modification_list.append(modification)


func get_modification_list() -> Array:
	return _modification_list.duplicate(true)


func get_tooltip_text() -> String:
	var text: String = ""

	for modification in _modification_list:
		var modification_text: String = modification.get_tooltip_text()
		text += modification_text

	return text


static func convert_to_string(modifier: Modifier) -> String:
	var modification_string_list: Array[String] = []

	for modification in modifier._modification_list:
		var modification_string: String = Modification.convert_to_string(modification)
		modification_string_list.append(modification_string)

	var modifier_string: String = "|".join(modification_string_list)

	return modifier_string


static func convert_from_string(modifier_string: String) -> Modifier:
	var modifier: Modifier = Modifier.new()
	
	var mod_string_list: Array = modifier_string.split("|")

	for mod_string in mod_string_list:
		var modification: Modification = Modification.from_string(mod_string)
		modifier.add_modification_instance(modification)

	return modifier
