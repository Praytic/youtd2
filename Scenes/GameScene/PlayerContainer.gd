class_name PlayerContainer extends Node


var _player_map: Dictionary = {}
var _player_id_list: Array[int] = []


#########################
###       Public      ###
#########################

func add_player(player: Player):
	var id: int = player.get_id()
	_player_map[id] = player
	add_child(player)
	
# 	NOTE: need to sort player id list to ensure determinism in multiplayer
	_player_id_list.append(id)
	_player_id_list.sort()


# Returns player which owns the local game client. In
# singleplayer this is *the player*. In multiplayer, each
# game client has it's own player instance.
func get_local_player() -> Player:
	if _player_map.is_empty():
		return null
	
	var local_peer_id: int = multiplayer.get_unique_id()
	
	if !_player_map.has(local_peer_id):
		push_error("Failed to find local player with id ", local_peer_id)

		return null
	
	var local_player: Player = _player_map[local_peer_id]
	
	return local_player


func get_player(id: int) -> Player:
	if !_player_map.has(id):
		push_error("Failed to find player for id ", id)

		return null

	var player: Player = _player_map[id]

	return player


func get_all_players() -> Array[Player]:
	var player_list: Array[Player] = []

	for player in _player_map.values():
		player_list.append(player)
	
	return player_list


func get_player_id_list() -> Array[int]:
	return _player_id_list.duplicate()
