class_name Modification


var type: ModificationType.enm
var value_base: float
var level_add: float


#########################
###     Built-in      ###
#########################

func _init(type_arg: ModificationType.enm, value_base_arg: float, level_add_arg: float):
	type = type_arg
	value_base = value_base_arg
	level_add = level_add_arg


#########################
###       Public      ###
#########################

func get_tooltip_text() -> String:
	var base_is_zero = abs(value_base) < 0.0001
	var add_is_zero = abs(level_add) < 0.0001

	var type_name: String = ModificationType.get_display_string(type)

	var text: String
	
	if !base_is_zero && !add_is_zero:
		text = "%s %s (%s/lvl)\n" % [_format_percentage(value_base), type_name, _format_percentage(level_add)]
	elif !base_is_zero && add_is_zero:
		text = "%s %s\n" % [_format_percentage(value_base), type_name]
	elif base_is_zero && !add_is_zero:
		text = "%s %s/lvl\n" % [_format_percentage(level_add), type_name]
	else:
		text = ""

	return text


#########################
###      Private      ###
#########################

# Formats percentage values for use in tooltip text
# 0.1 = +10%
# -0.1 = -10%
# 0.001 = +0.1%
func _format_percentage(value: float) -> String:
	var sign_string: String
	if value > 0.0:
		sign_string = "+"
	else:
		sign_string = ""

	var value_is_percentage: bool = ModificationType.get_is_percentage(type)

	var value_string: String
	if value_is_percentage:
		value_string = String.num(value * 100, 2)
	else:
		value_string = String.num(value, 2)

	var percent_string: String
	if value_is_percentage:
		percent_string = "%"
	else:
		percent_string = ""

	var base_string: String = "%s%s%s" % [sign_string, value_string, percent_string]

	return base_string


static func convert_to_string(modification: Modification) -> String:
	var modification_type_string: String = ModificationType.convert_to_string(modification.type)
	var value_base_string: String = str(modification.value_base)
	var level_add_string: String = str(modification.level_add)
	var modification_string: String = "%s,%s,%s" % [modification_type_string, value_base_string, level_add_string]

	return modification_string


static func from_string(modification_string: String) -> Modification:
	var mod_params: PackedStringArray = modification_string.split(",")

	if mod_params.size() != 3:
		return Modification.new(ModificationType.enm.MOD_DMG_TO_MASS, 0, 0)

	var mod_type_string: String = mod_params[0]
	var mod_type: ModificationType.enm = ModificationType.from_string(mod_type_string)
	var mod_value_base: float = mod_params[1].to_float()
	var mod_level_add: float = mod_params[2].to_float()

	var modification: Modification = Modification.new(mod_type, mod_value_base, mod_level_add)

	return modification
