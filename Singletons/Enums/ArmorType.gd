extends Node

enum enm {
	HEL,
	MYT,
	LUA,
	SOL,
	SIF,
	ZOD,
}

var _list: Array[ArmorType.enm] = [
	ArmorType.enm.HEL,
	ArmorType.enm.MYT,
	ArmorType.enm.LUA,
	ArmorType.enm.SOL,
	ArmorType.enm.SIF,
	ArmorType.enm.ZOD,
]

const _string_map: Dictionary = {
	ArmorType.enm.HEL: "hel",
	ArmorType.enm.MYT: "myt",
	ArmorType.enm.LUA: "lua",
	ArmorType.enm.SOL: "sol",
	ArmorType.enm.SIF: "sif",
	ArmorType.enm.ZOD: "zod",
}

const _color_map: Dictionary = {
	ArmorType.enm.HEL: Color.ORANGE_RED,
	ArmorType.enm.MYT: Color.CORNFLOWER_BLUE,
	ArmorType.enm.LUA: Color.LIME_GREEN,
	ArmorType.enm.SOL: Color.GOLD,
	ArmorType.enm.SIF: Color.MEDIUM_PURPLE,
	ArmorType.enm.ZOD: Color.YELLOW,
}


func from_string(string: String) -> ArmorType.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return ArmorType.enm.ZOD


func convert_to_string(type: ArmorType.enm) -> String:
	return _string_map[type]


func convert_to_colored_string(type: ArmorType.enm) -> String:
	var string: String = convert_to_string(type).capitalize()
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out


func get_list() -> Array[ArmorType.enm]:
	return _list.duplicate()


# Returns text which says how much damage this armor type
# takes from each attack type.
func get_text_for_damage_taken(armor_type: ArmorType.enm) -> String:
	var text: String = ""

	var attack_type_list: Array[AttackType.enm] = AttackType.get_list()

	for attack_type in attack_type_list:
		var attack_type_name: String = AttackType.convert_to_string(attack_type).capitalize()
		var damage_taken: float = AttackType.get_damage_against(attack_type, armor_type)
		var damage_taken_string: String = Utils.format_percent(damage_taken, 2)

		text += "%s:\t %s\n" % [attack_type_name, damage_taken_string]

	return text
