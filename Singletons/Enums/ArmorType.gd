extends Node

enum enm {
	HEL,
	MYT,
	LUA,
	SOL,
	SIF,
}

const _string_map: Dictionary = {
	ArmorType.enm.HEL: "hel",
	ArmorType.enm.MYT: "myt",
	ArmorType.enm.LUA: "lua",
	ArmorType.enm.SOL: "sol",
	ArmorType.enm.SIF: "sif",
}

const _color_map: Dictionary = {
	ArmorType.enm.HEL: Color.ORANGE_RED,
	ArmorType.enm.MYT: Color.CORNFLOWER_BLUE,
	ArmorType.enm.LUA: Color.LIME_GREEN,
	ArmorType.enm.SOL: Color.GOLD,
	ArmorType.enm.SIF: Color.MEDIUM_PURPLE,
}


func convert_to_string(type: ArmorType.enm) -> String:
	return _string_map[type]


func get_color(type: ArmorType.enm) -> Color:
	return _color_map[type]
