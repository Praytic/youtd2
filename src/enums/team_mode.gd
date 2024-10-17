class_name TeamMode extends Node


# This enum defines how players are placed into teams.


enum enm {
	ONE_PLAYER_PER_TEAM,
	TWO_PLAYERS_PER_TEAM,
}

static var _string_map: Dictionary = {
	TeamMode.enm.ONE_PLAYER_PER_TEAM: "ffa",
	TeamMode.enm.TWO_PLAYERS_PER_TEAM: "coop",
}


static var _display_string_map: Dictionary = {
	TeamMode.enm.ONE_PLAYER_PER_TEAM: "FFA",
	TeamMode.enm.TWO_PLAYERS_PER_TEAM: "Co-op",
}


static var _player_count_max_map: Dictionary = {
	TeamMode.enm.ONE_PLAYER_PER_TEAM: 4,
	TeamMode.enm.TWO_PLAYERS_PER_TEAM: 8,
}


static var _player_count_per_team_map: Dictionary = {
	TeamMode.enm.ONE_PLAYER_PER_TEAM: 1,
	TeamMode.enm.TWO_PLAYERS_PER_TEAM: 2,
}


static func convert_to_string(type: TeamMode.enm):
	return _string_map[type]


static func from_string(string: String) -> TeamMode.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return TeamMode.enm.ONE_PLAYER_PER_TEAM


static func convert_to_display_string(type: TeamMode.enm):
	return _display_string_map[type]


static func get_player_count_max(type: TeamMode.enm):
	return _player_count_max_map[type]


static func get_player_count_per_team(type: TeamMode.enm):
	return _player_count_per_team_map[type]
