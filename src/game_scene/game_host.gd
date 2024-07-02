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

# NOTE: GameHost node needs to be positioned before
# GameClient node in the tree, so that it is processed
# first.


enum HostState {
	WAITING_BEFORE_START,
	RUNNING,
	WAITING_FOR_LAGGING_PLAYERS,
}

# MULTIPLAYER_TURN_LENGTH needs to be bigger than worst case
# roundtrip time between client and host.
# NOTE: 6 ticks at 30ticks/second = 200ms.
const MULTIPLAYER_TURN_LENGTH: int = 6
const SINGLEPLAYER_TURN_LENGTH: int = 1
# NOTE: picked 3 because 3ticks = 100ms - nice number
const TURN_LENGTH_STEP: int = 3
# NOTE: this multiplier is x1.5 to give some leeway. If it
# was exactly x1 then that would make turn length too close
# to ping which could cause stutters in case of ping
# variations.
const PING_TO_TURN_LENGTH_MULTIPLIER: float = 1.5
const TICK_DELTA: float = 1000 / 30.0
# MAX_LAG_AMOUNT is the max difference in timeslots between
# host and client. A client is considered to be lagging if
# it falls behind by more timeslots than this value.
const MAX_LAG_AMOUNT: int = 10

@export var _game_client: GameClient
@export var _hud: HUD


var _current_tick: int = 0
var _current_turn_length: int = -1
var _in_progress_timeslot: Array = []
var _last_sent_timeslot_tick: int = 0
var _timeslot_sent_count: int = 0
var _player_ping_time_map: Dictionary = {}
var _player_ack_count_map: Dictionary = {}
var _player_checksum_map: Dictionary = {}
var _showed_desync_message: bool = false
var _state: HostState = HostState.WAITING_BEFORE_START
var _player_ready_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	if !multiplayer.is_server():
		return

	PlayerManager.players_created.connect(_on_players_created)
	
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	if player_mode == PlayerMode.enm.SINGLE:
		_current_turn_length = GameHost.SINGLEPLAYER_TURN_LENGTH
	else:
		_current_turn_length = GameHost.MULTIPLAYER_TURN_LENGTH


func _physics_process(_delta: float):
	if !multiplayer.is_server():
		return

	match _state:
		HostState.WAITING_BEFORE_START: return
		HostState.RUNNING: _update_state_running()
		HostState.WAITING_FOR_LAGGING_PLAYERS: _update_state_waiting_for_lagging_players()


#########################
###       Public      ###
#########################

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


@rpc("any_peer", "call_local", "reliable")
func receive_ping_time_for_player(ping_time: int):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_player_ping_time_map[player_id] = ping_time


#########################
###      Private      ###
#########################

func _update_state_running():
	var lagging_player_list: Array[Player] = _get_lagging_players()
	var players_are_lagging: bool = lagging_player_list.size() > 0

	if players_are_lagging:
		_state = HostState.WAITING_FOR_LAGGING_PLAYERS

		var lagging_player_name_list: Array = get_player_name_list(lagging_player_list)

		_game_client.enter_waiting_for_lagging_players_state.rpc(lagging_player_name_list)

		return

	_check_desynced_players()

	var update_tick_count: int = min(Globals.get_update_ticks_per_physics_tick(), Constants.MAX_UPDATE_TICKS_PER_PHYSICS_TICK)

	for i in range(0, update_tick_count):
		_current_tick += 1

		var need_to_send_timeslot: bool = _current_tick - _last_sent_timeslot_tick == _current_turn_length

		if need_to_send_timeslot:
			_send_timeslot()


func _update_state_waiting_for_lagging_players():
	var lagging_player_list: Array[Player] = _get_lagging_players()
	var players_are_lagging: bool = lagging_player_list.size() > 0

	if !players_are_lagging:
		_state = HostState.RUNNING

		_game_client.exit_waiting_for_lagging_players_state.rpc()


func _send_timeslot():
#	NOTE: need to adjust turn length *before* sending
#	timeslot, so that clients will get the latest turn
#	length value. Otherwise, clients and host would start
#	having mismatched timeslot ticks.
	_current_turn_length = _get_optimal_turn_length()

	var timeslot: Array = _in_progress_timeslot.duplicate()
	_in_progress_timeslot.clear()
	_game_client.receive_timeslot.rpc(timeslot, _current_turn_length)
	_last_sent_timeslot_tick = _current_tick
	_timeslot_sent_count += 1


func _get_optimal_turn_length() -> int:
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	if player_mode == PlayerMode.enm.SINGLE:
		return 1

	var highest_ping: int = _get_highest_ping()
	var optimal_turn_length: int = ceil(highest_ping / TICK_DELTA * PING_TO_TURN_LENGTH_MULTIPLIER)

#	NOTE: restrict turn length values to multiples of
#	TURN_LENGTH_STEP.
# 	3 = 100ms
# 	6 = 200ms
# 	9 = 300ms
# 	etc
#	If this is not done, the turn length can vary constantly
#	as the ping changes.
	optimal_turn_length = ceili(float(optimal_turn_length) / TURN_LENGTH_STEP) * TURN_LENGTH_STEP

	optimal_turn_length = max(optimal_turn_length, TURN_LENGTH_STEP)

	return optimal_turn_length


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

	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var player_id: int = player.get_id()
		var ack_count: int = _player_ack_count_map[player_id]
		var lag_amount: int = _timeslot_sent_count - ack_count
		var player_is_lagging: bool = lag_amount > MAX_LAG_AMOUNT

		if player_is_lagging:
			lagging_player_list.append(player)

	return lagging_player_list


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


func get_player_name_list(player_list: Array[Player]) -> Array[String]:
	var result: Array[String] = []

	for player in player_list:
		var player_name: String = player.get_player_name()
		result.append(player_name)

	return result


#########################
###     Callbacks     ###
#########################

func _on_players_created():
	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var player_id: int = player.get_id()

		_player_ack_count_map[player_id] = 0
		_player_checksum_map[player_id] = []
		_player_ping_time_map[player_id] = 0
