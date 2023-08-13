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
	Rarity.enm.COMMON: Color.GREEN,
	Rarity.enm.UNCOMMON: Color.ROYAL_BLUE,
	Rarity.enm.RARE: Color.MEDIUM_PURPLE,
	Rarity.enm.UNIQUE: Color.GOLD,
}


func convert_from_string(string: String) -> Rarity.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Rarity.enm.COMMON


func convert_to_string(rarity: Rarity.enm) -> String:
	return _string_map[rarity]


func get_color(rarity: Rarity.enm) -> Color:
	return _color_map[rarity]


func get_list() -> Array[Rarity.enm]:
	return [
		Rarity.enm.COMMON,
		Rarity.enm.UNCOMMON,
		Rarity.enm.RARE,
		Rarity.enm.UNIQUE,
	]
