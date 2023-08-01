extends Node


enum enm {
	NONE,
	BUILD,
	RANDOM_WITH_UPGRADES,
	TOTALLY_RANDOM,
}


const _string_map: Dictionary = {
	Distribution.enm.NONE: "none",
	Distribution.enm.BUILD: "build",
	Distribution.enm.RANDOM_WITH_UPGRADES: "random_with_upgrades",
	Distribution.enm.TOTALLY_RANDOM: "totally_random",
}

const _sell_ratio_map: Dictionary = {
	Distribution.enm.NONE: 0.0,
	Distribution.enm.BUILD: 0.5,
	Distribution.enm.RANDOM_WITH_UPGRADES: 0.75,
	Distribution.enm.TOTALLY_RANDOM: 0.75,
}


func convert_to_string(type: Distribution.enm):
	return _string_map[type]


func from_string(string: String) -> Distribution.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Distribution.enm.BUILD


func get_sell_ratio(distribution: Distribution.enm) -> float:
	return _sell_ratio_map[distribution]
