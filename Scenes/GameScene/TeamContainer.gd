class_name TeamContainer extends Node


var _team_map: Dictionary = {}
var _team_id_list: Array[int] = []


#########################
###       Public      ###
#########################

func add_team(team: Team):
	var team_id: int = team.get_id()
	_team_map[team_id] = team
	
# 	NOTE: need to sort teams to ensure determinism in
# 	multiplayer
	_team_id_list.append(team_id)
	_team_id_list.sort()


func get_team(id: int) -> Team:
	if !_team_map.has(id):
		push_error("Failed to find team for id ", id)

		return null

	var team: Team = _team_map[id]

	return team


func get_team_list() -> Array[Team]:
	var team_list: Array[Team] = []

	for team_id in _team_id_list:
		var team: Team = _team_map[team_id]
		team_list.append(team)
	
	return team_list


func get_team_id_list() -> Array[int]:
	return _team_id_list.duplicate()
