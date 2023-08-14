extends Node


enum enm {
	BUILD,
	RANDOM_WITH_UPGRADES,
	TOTALLY_RANDOM,
}


const _string_map: Dictionary = {
	GameMode.enm.BUILD: "build",
	GameMode.enm.RANDOM_WITH_UPGRADES: "random_with_upgrades",
	GameMode.enm.TOTALLY_RANDOM: "totally_random",
}

const _sell_ratio_map: Dictionary = {
	GameMode.enm.BUILD: 0.5,
	GameMode.enm.RANDOM_WITH_UPGRADES: 0.75,
	GameMode.enm.TOTALLY_RANDOM: 0.75,
}


func convert_to_string(type: GameMode.enm):
	return _string_map[type]


func from_string(string: String) -> GameMode.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return GameMode.enm.BUILD


func get_sell_ratio(game_mode: GameMode.enm) -> float:
	return _sell_ratio_map[game_mode]
