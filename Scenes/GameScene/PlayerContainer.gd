class_name PlayerContainer extends Node


var _id_to_player_map: Dictionary = {}
var _peer_id_to_player_map: Dictionary = {}
var _player_id_list: Array[int] = []


#########################
###       Public      ###
#########################

func add_player(player: Player):
	var id: int = player.get_id()
	_id_to_player_map[id] = player
	var peer_id: int = player.get_peer_id()
	_peer_id_to_player_map[peer_id] = player
	add_child(player)
	
# 	NOTE: need to sort player id list to ensure determinism in multiplayer
	_player_id_list.append(id)
	_player_id_list.sort()


# Returns player which owns the local game client. In
# singleplayer this is *the player*. In multiplayer, each
# game client has it's own player instance.
func get_local_player() -> Player:
	var local_peer_id: int = multiplayer.get_unique_id()
	var local_player: Player = get_player_by_peer_id(local_peer_id)
	
	return local_player


func get_player(id: int) -> Player:
	if !_id_to_player_map.has(id):
		push_error("Failed to find player for id ", id)

		return null

	var player: Player = _id_to_player_map[id]

	return player


func get_player_by_peer_id(peer_id: int) -> Player:
	if !_peer_id_to_player_map.has(peer_id):
		push_error("Failed to find player for peer id ", peer_id)

		return null

	var player: Player = _peer_id_to_player_map[peer_id]

	return player


func get_all_players() -> Array[Player]:
	var player_list: Array[Player] = []

	for player_id in _player_id_list:
		var player: Player = _id_to_player_map[player_id]
		player_list.append(player)
	
	return player_list


func get_player_id_list() -> Array[int]:
	return _player_id_list.duplicate()
