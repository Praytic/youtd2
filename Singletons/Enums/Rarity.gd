extends Node


enum enm {
	COMMON,
	UNCOMMON,
	RARE,
	UNIQUE,
}


const _string_map: Dictionary = {
	Rarity.enm.COMMON: "common",
	Rarity.enm.UNCOMMON: "uncommon",
	Rarity.enm.RARE: "rare",
	Rarity.enm.UNIQUE: "unique",
}

const _color_map: Dictionary = {
	Rarity.enm.COMMON: Color.WHITE,
	Rarity.enm.UNCOMMON: Color.GREEN,
	Rarity.enm.RARE: Color.BLUE,
	Rarity.enm.UNIQUE: Color.GOLD,
}


func convert_from_string(string: String) -> Rarity.enm:
	return _string_map.find_key(string)


func convert_to_string(rarity: Rarity.enm) -> String:
	return _string_map[rarity]


func get_color(rarity: Rarity.enm) -> Color:
	return _color_map[rarity]
