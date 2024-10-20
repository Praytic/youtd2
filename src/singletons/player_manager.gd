extends Node


# Provides global access to players.


signal players_created()


var _id_to_player_map: Dictionary = {}
var _enet_peer_id_to_player_map: Dictionary = {}
var _nakama_user_id_to_player_map: Dictionary = {}
var _player_list: Array[Player] = []


#########################
###       Public      ###
#########################

# Returns player which owns the local game client. In
# singleplayer this is *the player*. In multiplayer, each
# game client has it's own player instance.
# NOTE: "GetLocalPlayer()" in JASS
func get_local_player() -> Player:
	var local_peer_id: int = multiplayer.get_unique_id()
	var local_player: Player = get_player_by_peer_id(local_peer_id)

	return local_player


# NOTE: "Player()" in JASS
func get_player(id: int) -> Player:
	if !_id_to_player_map.has(id):
		push_error("Failed to find player for id ", id)

		return null

	var player: Player = _id_to_player_map[id]

	return player


func get_player_by_peer_id(peer_id: int) -> Player:
	if !_enet_peer_id_to_player_map.has(peer_id):
		push_error("Failed to find player for peer id ", peer_id)

		return null

	var player: Player = _enet_peer_id_to_player_map[peer_id]

	return player


func get_player_by_nakama_user_id(user_id: String) -> Player:
	if !_nakama_user_id_to_player_map.has(user_id):
		push_error("Failed to find player for nakama user id ", user_id)

		return null

	var player: Player = _nakama_user_id_to_player_map[user_id]

	return player


func get_player_list() -> Array[Player]:
	return _player_list.duplicate()


func reset():
	_id_to_player_map = {}
	_enet_peer_id_to_player_map = {}
	_nakama_user_id_to_player_map = {}
	_player_list = []


func add_player(player: Player):
	var id: int = player.get_id()
	_id_to_player_map[id] = player
	
	var peer_id: int = player.get_peer_id()
	_enet_peer_id_to_player_map[peer_id] = player

	add_child(player)

# 	NOTE: need to sort player id list to ensure determinism in multiplayer
	_player_list.append(player)
	_player_list.sort_custom(
		func(a, b) -> bool:
			return a.get_id() < b.get_id()
			)


func send_players_created_signal():
	players_created.emit()
