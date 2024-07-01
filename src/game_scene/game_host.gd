class_name GameHost extends Node


# Host receives actions from peers, combines them into
# "timeslots" and sends timeslots back to the peers. A
# "timeslot" is a group of actions for a given tick. A host
# has it's own tick, independent of the GameClient on the
# host's client. Host sends timeslots periodically with an
# interval equal to current "latency" value.
# 
# Note that server peer acts as a host and a peer at the
# same time.

# NOTE: GameHost node needs to be positioned before
# GameClient node in the tree, so that it is processed
# first.


enum HostState {
	WAITING_BEFORE_START,
	RUNNING,
}

# MULTIPLAYER_ACTION_LATENCY needs to be big enough to
# account for latency.
# NOTE: 6 ticks at 30ticks/second = 200ms.
const MULTIPLAYER_ACTION_LATENCY: int = 6
const SINGLEPLAYER_ACTION_LATENCY: int = 1
# MAX_LAG_AMOUNT is the max difference in timeslots between
# host and client. A client is considered to be lagging if
# it falls behind by more timeslots than this value.
const MAX_LAG_AMOUNT: int = 10

@export var _game_client: GameClient
@export var _hud: HUD


var _setup_done: bool = false
var _current_tick: int = 0
var _current_latency: int = -1
var _in_progress_timeslot: Array = []
var _last_sent_timeslot_tick: int = 0
var _timeslot_sent_count: int = 0
var _player_ack_count_map: Dictionary = {}
var _player_checksum_map: Dictionary = {}
var _showed_desync_message: bool = false
var _state: HostState = HostState.WAITING_BEFORE_START
var _player_ready_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _physics_process(_delta: float):
	if !multiplayer.is_server():
		return

	match _state:
		HostState.WAITING_BEFORE_START: return
		HostState.RUNNING: _update_state_running()


func _update_state_running():
	_check_lagging_players()
	_check_desynced_players()

	var update_tick_count: int = min(Globals.get_update_ticks_per_physics_tick(), Constants.MAX_UPDATE_TICKS_PER_PHYSICS_TICK)

	for i in range(0, update_tick_count):
		_current_tick += 1

		var need_to_send_timeslot: bool = _current_tick - _last_sent_timeslot_tick == _current_latency

		if need_to_send_timeslot:
			_send_timeslot()


#########################
###       Public      ###
#########################

func setup(latency: int, player_list: Array[Player]):
	if _setup_done:
		push_error("GameHost.setup() was called multiple times.")

		return

	_current_latency = latency

	for player in player_list:
		var player_id: int = player.get_id()
		_player_ack_count_map[player_id] = 0

	_setup_done = true


# Receive action sent from client to host. Actions are
# compiled into timeslots - a group of actions from all
# clients.
@rpc("any_peer", "call_local", "reliable")
func receive_action(action: Dictionary):
#	NOTE: need to attach player id to action in this host
#	function to ensure safety. If we were to let clients
#	attach player_id to actions, then clients could attach
#	any value.
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()
	action[Action.Field.PLAYER_ID] = player_id

	_in_progress_timeslot.append(action)


@rpc("any_peer", "call_local", "reliable")
func receive_timeslot_ack(checksum: PackedByteArray):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_player_ack_count_map[player_id] += 1

	if !_player_checksum_map.has(player_id):
		_player_checksum_map[player_id] = []
	_player_checksum_map[player_id].append(checksum)


# TODO: handle case where some player is not ready. Need to
# show this as message to all players as "Waiting for
# players...". Also need to add an option to leave the game
# if the wait is too long.

# Called by players to let the host know that player is
# loaded and ready to start simulating the game. Host will
# not start incrementing simulation ticks until all players
# are ready.
@rpc("any_peer", "call_local", "reliable")
func receive_player_ready():
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_player_ready_map[player_id] = true

	var all_players_are_ready: bool = true
	var player_list: Array[Player] = PlayerManager.get_player_list()
	for this_player in player_list:
		var this_player_id: int = this_player.get_id()
		var this_player_is_ready: bool = _player_ready_map.has(this_player_id)

		if !this_player_is_ready:
			all_players_are_ready = false

			break

	if all_players_are_ready:
		_state = HostState.RUNNING

#		Send timeslot for 0 tick
		_send_timeslot()


@rpc("any_peer", "call_local", "reliable")
func receive_ping():
	var peer_id: int = multiplayer.get_remote_sender_id()
	_game_client.receive_pong.rpc_id(peer_id)


#########################
###      Private      ###
#########################

func _send_timeslot():
	var timeslot: Array = _in_progress_timeslot.duplicate()
	_in_progress_timeslot.clear()
	_game_client.receive_timeslot.rpc(timeslot, _current_latency)
	_last_sent_timeslot_tick = _current_tick
	_timeslot_sent_count += 1


# Check if any player is lagging. Player is considered to be
# lagging if it's too far behind host, in terms of
# timeslots.
# 
# TODO: currently, host only detects that a player is
# lagging but doesn't do anything with this info. Need to
# tell clients which player is lagging and provide an option
# to wait for lagging player or kick them.
func _check_lagging_players() -> bool:
	var is_lagging: bool = false

	for player_id in _player_ack_count_map.keys():
		var ack_count: int = _player_ack_count_map[player_id]
		var lag_amount: int = _timeslot_sent_count - ack_count
		var player_is_lagging: bool = lag_amount > MAX_LAG_AMOUNT

		if player_is_lagging:
			print("player %d is lagging" % player_id)
			is_lagging = true

	return is_lagging


# TODO: kick desynced players from the game
func _check_desynced_players():
	var desync_detected: bool = false

	var player_list: Array[Player] = PlayerManager.get_player_list()

	var have_checksums_for_all_players: bool = true
	for player in player_list:
		var player_id: int = player.get_id()

		if !_player_checksum_map.has(player_id) || _player_checksum_map[player_id].is_empty():
			have_checksums_for_all_players = false

	if !have_checksums_for_all_players:
		return

	var authority_player: Player = PlayerManager.get_player_by_peer_id(1)
	var authority_player_id: int = authority_player.get_id()

	var have_authority_checksum: bool = _player_checksum_map.has(authority_player_id) && !_player_checksum_map[authority_player_id].is_empty()

	if !have_authority_checksum:
		return

	var authority_checksum: PackedByteArray = _player_checksum_map[authority_player_id].front()

	for player in player_list:
		var player_id: int = player.get_id()
		var checksum: PackedByteArray = _player_checksum_map[player_id].pop_front()
		var checksum_match: bool = checksum == authority_checksum

		if !checksum_match:
			desync_detected = true

	if desync_detected && !_showed_desync_message:
		var game_time: float = Utils.get_time()
		var game_time_string: String = Utils.convert_time_to_string(game_time)
		var message: String = "Desync detected @ %s" % game_time_string
		_hud.show_desync_message(message)
		_showed_desync_message = true
