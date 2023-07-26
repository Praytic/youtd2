extends Node

enum enm {
	REGULAR,
	OIL,
}

const _string_map: Dictionary = {
	ItemType.enm.REGULAR: "regular",
	ItemType.enm.OIL: "oil",
}


func convert_to_string(type: ItemType.enm) -> String:
	return _string_map[type]


func from_string(string: String) -> ItemType.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid item type string: \"%s\"" % string)

		return ItemType.enm.REGULAR
