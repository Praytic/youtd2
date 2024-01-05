extends Node


enum enm {
	SINGLE,
	COOP,
	# This mode will be automatically chosen when game is 
	# running in headless mode.
	SERVER,
}


const _string_map: Dictionary = {
	PlayerMode.enm.SINGLE: "single",
	PlayerMode.enm.COOP: "coop",
	PlayerMode.enm.SERVER: "server",
}


func convert_to_string(type: PlayerMode.enm):
	return _string_map[type]


func from_string(string: String) -> PlayerMode.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return PlayerMode.enm.SINGLE
