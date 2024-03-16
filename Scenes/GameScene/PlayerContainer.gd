class_name PlayerContainer extends Node


var _player_map: Dictionary = {}


#########################
###       Public      ###
#########################

func add_player(player: Player):
	var id: int = player.get_id()
	_player_map[id] = player
	add_child(player)


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
