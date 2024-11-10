class_name GameHost extends Node


# Host receives actions from peers, combines them into
# "timeslots" and sends timeslots back to the peers. A
# "timeslot" is a group of actions for a given tick. A host
# has it's own tick, independent of the GameClient on the
# host's client. Host sends timeslots periodically with an
# interval equal to current "turn length" value.
# 
# Note that server peer acts as a host and a peer at the
# same time.
# 
# There's an ACK system for timeslots. Host keeps track of
# which timeslots have been ack'ed by clients. Each message
# sent from host to a client contains all timeslots which
# haven't been ack'ed by that client yet. This ensures that
# if some client temporarily disconnects, they will not miss
# any timeslots and will be able to continue the game.

# NOTE: GameHost node needs to be positioned before
# GameClient node in the tree, so that it is processed
# first.


enum HostState {
	RUNNING,
	WAITING_FOR_LAGGING_PLAYERS,
}

# NOTE: 3 ticks at 30ticks/second = 100ms
# 100ms was chosen so that turn length is short enough to
# minimize input lag but not too often keep bandwidth usage
# reasonable.
# 
# Turn length affects input lag because when a player sends
# an action to host, the action will be stored for a random
# amount of time from 0ms to _turn_length before turn ends
# and action is sent inside timeslot. Therefore, 100ms adds
# on average 50ms of input lag, in addition to transmission
# time and timeslot buffering on client.
const MULTIPLAYER_TURN_LENGTH: int = 3
const SINGLEPLAYER_TURN_LENGTH: int = 1
const TICK_DELTA: float = 1000 / 30.0
# LAG_TIME_MSEC is the max time since last contact from
# player. If host hasn't received any responses from player
# for this long, host will start considering that player to
# be lagging and will pause game turns.
const LAG_TIME_MSEC: float = 2000.0

@export var _game_client: GameClient
@export var _hud: HUD


var _current_tick: int = 0
var _turn_length: int
var _in_progress_timeslot: Array = []
var _player_ping_time_map: Dictionary = {}
var _player_last_contact_time: Dictionary = {}
# {tick -> {player_id -> checksum}}
var _checksum_map: Dictionary = {}
var _showed_desync_indicator: bool = false
# Stores timeslots which should be sent to players and
# haven't been ack'ed yet.
# {player_id -> {tick -> timeslot}}
var _player_timeslot_send_queue: Dictionary = {}
# NOTE: initial state is WAITING_FOR_LAGGING_PLAYERS until
# host confirms that all players have connected successfully
# and finished loading game scene.
var _state: HostState = HostState.WAITING_FOR_LAGGING_PLAYERS


#########################
###     Built-in      ###
#########################

func _ready():
	if !multiplayer.is_server():
		return

	PlayerManager.players_created.connect(_on_players_created)
	
	_turn_length = Utils.get_turn_length()


func _physics_process(_delta: float):
	if !multiplayer.is_server():
		return

	match _state:
		HostState.RUNNING: _update_state_running()
		HostState.WAITING_FOR_LAGGING_PLAYERS: pass


#########################
###       Public      ###
#########################

# When player ack's timeslots, host erases ack'd timeslots
# from queue and stops sending them.
@rpc("any_peer", "call_local", "reliable")
func receive_timeslots_ack(tick_list: Array):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	var timeslots_to_send: Dictionary = _player_timeslot_send_queue[player_id]

	for tick in tick_list:
		timeslots_to_send.erase(tick)


@rpc("any_peer", "call_local", "reliable")
func receive_alive_check_response():
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_update_last_contact_time_for_player(player_id)


# Receive action sent from client to host. Actions are
# compiled into timeslots - a group of actions from all
# clients.
@rpc("any_peer", "call_local", "reliable")
func receive_action(action: Dictionary):
	if _state != HostState.RUNNING:
		return

#	NOTE: need to attach player id to action in this host
#	function to ensure safety. If we were to let clients
#	attach player_id to actions, then clients could attach
#	any value.
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()
	action[Action.Field.PLAYER_ID] = player_id

	_in_progress_timeslot.append(action)


# TODO: handle disconnections here. If player is
# disconnected, then need to not count him when determining
# whether host has collected checksums from all players.
@rpc("any_peer", "call_local", "reliable")
func receive_timeslot_checksum(tick: int, checksum: PackedByteArray):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	if !_checksum_map.has(tick):
		_checksum_map[tick] = {}

	_checksum_map[tick][player_id] = checksum

	var player_list: Array[Player] = PlayerManager.get_player_list()
	var player_count: int = player_list.size()
	var collected_all_checksums_for_tick: bool = _checksum_map[tick].size() == player_count

	if collected_all_checksums_for_tick:
		_verify_checksums(tick)
		_checksum_map.erase(tick)


@rpc("any_peer", "call_local", "reliable")
func receive_ping():
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_update_last_contact_time_for_player(player_id)

	_game_client.receive_pong.rpc_id(peer_id)


@rpc("any_peer", "call_local", "reliable")
func receive_ping_time_for_player(ping_time: int):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_player_ping_time_map[player_id] = ping_time


#########################
###      Private      ###
#########################

func _update_last_contact_time_for_player(player_id: int):
	var ticks_msec: int = Time.get_ticks_msec()
	_player_last_contact_time[player_id] = ticks_msec


func _update_state_running():
	var lagging_player_list: Array[Player] = _get_lagging_players()
	var players_are_lagging: bool = lagging_player_list.size() > 0

	if players_are_lagging:
		_state = HostState.WAITING_FOR_LAGGING_PLAYERS

		var lagging_player_name_list: Array = _get_player_name_list(lagging_player_list)

		_game_client.set_lagging_players.rpc(lagging_player_name_list)

		return

#	Advance ticks on host and save completed timeslots
	var update_tick_count: int = min(Globals.get_update_ticks_per_physics_tick(), Constants.MAX_UPDATE_TICKS_PER_PHYSICS_TICK)

	for i in range(0, update_tick_count):
		var turn_ended: int = _current_tick % _turn_length == 0

		if turn_ended:
			_save_timeslot()
		
		_current_tick += 1

#	Send timeslots
	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var player_id: int = player.get_id()
		var peer_id: int = player.get_peer_id()
		var timeslots_to_send: Dictionary = _player_timeslot_send_queue[player_id]

		if timeslots_to_send.is_empty():
			continue

		_game_client.receive_timeslots.rpc_id(peer_id, timeslots_to_send)


func _save_timeslot():
	var timeslot: Array = _in_progress_timeslot.duplicate()
	_in_progress_timeslot.clear()

	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var player_id: int = player.get_id()
		var timeslots_to_send: Dictionary = _player_timeslot_send_queue[player_id]

		timeslots_to_send[_current_tick] = timeslot


# Returns highest ping of all players, in msec. Ping is
# determined from the most recent ACK exchange.
func _get_highest_ping() -> int:
	var highest_ping: int = 0

	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var player_id: int = player.get_id()
		var this_ping_time: int = _player_ping_time_map[player_id]

		if this_ping_time > highest_ping:
			highest_ping = this_ping_time

	return highest_ping


# NOTE: player is considered to be lagging if the last
# timeslot ACK is too old.
func _get_lagging_players() -> Array[Player]:
	var lagging_player_list: Array[Player] = []
	
#	NOTE: skip lag check in singleplayer, to avoid the popup
#	showing at the start of the game.
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	if player_mode == PlayerMode.enm.SINGLEPLAYER:
		return lagging_player_list

	var player_list: Array[Player] = PlayerManager.get_player_list()

	var ticks_msec: int = Time.get_ticks_msec()

	for player in player_list:
		var player_id: int = player.get_id()
		var last_contact_time: float = _player_last_contact_time[player_id]
		var time_since_last_contact: float = ticks_msec - last_contact_time
		var player_is_lagging: bool = time_since_last_contact > LAG_TIME_MSEC

		if player_is_lagging:
			lagging_player_list.append(player)

	return lagging_player_list


# TODO: kick desynced players from the game
func _verify_checksums(tick: int):
	var desync_detected: bool = false

	var player_to_checksum: Dictionary = _checksum_map[tick]

	var authority_player: Player = PlayerManager.get_player_by_peer_id(1)
	var authority_player_id: int = authority_player.get_id()

	var authority_checksum: PackedByteArray = player_to_checksum[authority_player_id]

	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var player_id: int = player.get_id()
		var checksum: PackedByteArray = player_to_checksum[player_id]
		var checksum_match: bool = checksum == authority_checksum

		if !checksum_match:
			desync_detected = true

	if desync_detected && !_showed_desync_indicator:
		_hud.show_desync_indicator()
		_showed_desync_indicator = true


func _get_player_name_list(player_list: Array[Player]) -> Array[String]:
	var result: Array[String] = []

	for player in player_list:
		var player_name: String = player.get_player_name()
		result.append(player_name)

	return result


#########################
###     Callbacks     ###
#########################

func _on_players_created():
	if !multiplayer.is_server():
		return
	
	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var player_id: int = player.get_id()

		_player_ping_time_map[player_id] = 0
		_player_last_contact_time[player_id] = 0
		_player_timeslot_send_queue[player_id] = {}


# While waiting for lagging players, periodically send a
# message to check if lagging players respond. If there's a
# response, host will stop considering those players to be
# lagging.
# 
# Also in this timeout, tell clients about which players are
# lagging.
func _on_alive_check_timer_timeout():
	if !multiplayer.is_server():
		return
	
	if _state != HostState.WAITING_FOR_LAGGING_PLAYERS:
		return

	var lagging_players: Array[Player] = _get_lagging_players()
	var players_are_lagging: bool = lagging_players.size() > 0

	if players_are_lagging:
		for player in lagging_players:
			var peer_id: int = player.get_peer_id()

			_game_client.receive_alive_check.rpc_id(peer_id)
	else:
		_state = HostState.RUNNING

	var lagging_player_name_list: Array[String] = _get_player_name_list(lagging_players)
	_game_client.set_lagging_players.rpc(lagging_player_name_list)
