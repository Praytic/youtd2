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


func convert_from_string(string: String) -> Rarity.enm:
	return _string_map.find_key(string)


func convert_to_string(rarity: Rarity.enm) -> String:
	return _string_map[rarity]
