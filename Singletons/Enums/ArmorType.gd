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
	ArmorType.enm.HEL: Color.RED,
	ArmorType.enm.MYT: Color.BLUE,
	ArmorType.enm.LUA: Color.GREEN,
	ArmorType.enm.SOL: Color.YELLOW,
	ArmorType.enm.SIF: Color.PURPLE,
}


func convert_to_string(type: ArmorType.enm) -> String:
	return _string_map[type]


func convert_to_colored_string(type: ArmorType.enm) -> String:
	var string: String = convert_to_string(type)
	var color: Color = _color_map[type]

	return "[color=%s]%s[/color]" % [color.to_html(), string]
