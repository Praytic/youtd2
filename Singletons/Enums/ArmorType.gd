extends Node

enum enm {
	HEL,
	MYT,
	LUA,
	SOL,
	SIF,
	ZOD,
}

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


func convert_to_string(type: ArmorType.enm) -> String:
	return _string_map[type]


func convert_to_colored_string(type: ArmorType.enm) -> String:
	var string: String = convert_to_string(type).capitalize()
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out

