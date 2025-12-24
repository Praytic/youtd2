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
const LAG_TIME_MSEC: float = 3000.0

@export var _game_client: GameClient
@export var _hud: HUD


var _current_tick: int = 0
var _turn_length: int
var _in_progress_timeslot: Array = []
var _player_ping_time_map: Dictionary = {}
var _player_last_contact_time: Dictionary = {}
# {tick -> {player_id -> checksum}}
var _checksum_map: Dictionary = {}
# {tick -> {player_id -> checksum_data_dict}}
var _checksum_data_map: Dictionary = {}
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
func receive_ping(last_received_timeslot_list: Array):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_update_last_contact_time_for_player(player_id)

#	When player ack's timeslots, host erases ack'd timeslots
#	from queue and stops sending them.
	var timeslots_to_send: Dictionary = _player_timeslot_send_queue[player_id]
	for tick in last_received_timeslot_list:
		timeslots_to_send.erase(tick)

	_game_client.receive_pong.rpc_id(peer_id)


@rpc("any_peer", "call_local", "reliable")
func receive_ping_time_for_player(ping_time: int):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	_player_ping_time_map[player_id] = ping_time


@rpc("any_peer", "call_local", "reliable")
func receive_checksum_data_from_client(tick: int, checksum_data: Dictionary):
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()

	if !_checksum_data_map.has(tick):
		_checksum_data_map[tick] = {}

	_checksum_data_map[tick][player_id] = checksum_data

	var player_list: Array[Player] = PlayerManager.get_player_list()
	var player_count: int = player_list.size()
	var collected_all_data: bool = _checksum_data_map[tick].size() == player_count

	if collected_all_data:
		_log_detailed_desync_data(tick)
		_checksum_data_map.erase(tick)


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

	var desynced_players: Array[String] = []

	for player in player_list:
		var player_id: int = player.get_id()
		var checksum: PackedByteArray = player_to_checksum[player_id]
		var checksum_match: bool = checksum == authority_checksum

		if !checksum_match:
			desync_detected = true
			var player_name: String = player.get_player_name()
			var peer_id: int = player.get_peer_id()
			desynced_players.append("%s (peer %d)" % [player_name, peer_id])

	if desync_detected && !_showed_desync_indicator:
		_log_desync_detected(tick, authority_player, desynced_players, player_to_checksum)
		_hud.show_desync_indicator()
		_showed_desync_indicator = true

		# Notify all clients to send their detailed checksum data
		for player in player_list:
			var peer_id: int = player.get_peer_id()
			_game_client.receive_desync_notification.rpc_id(peer_id, tick)


func _log_desync_detected(tick: int, authority_player: Player, desynced_players: Array[String], player_to_checksum: Dictionary):
	push_error("========================================")
	push_error("DESYNC DETECTED at tick %d" % tick)
	push_error("========================================")
	push_error("Authority player: %s (peer %d)" % [authority_player.get_player_name(), authority_player.get_peer_id()])
	push_error("Desynced players: %s" % ", ".join(desynced_players))
	push_error("")
	push_error("Checksum details:")

	var authority_player_id: int = authority_player.get_id()
	var authority_checksum: PackedByteArray = player_to_checksum[authority_player_id]
	var authority_checksum_hex: String = authority_checksum.hex_encode()
	push_error("  Authority checksum: %s" % authority_checksum_hex)

	var player_list: Array[Player] = PlayerManager.get_player_list()
	for player in player_list:
		var player_id: int = player.get_id()
		if player_id == authority_player_id:
			continue

		var checksum: PackedByteArray = player_to_checksum[player_id]
		var checksum_hex: String = checksum.hex_encode()
		var player_name: String = player.get_player_name()
		var peer_id: int = player.get_peer_id()
		var match_status: String = "MATCH" if checksum == authority_checksum else "DESYNC"

		push_error("  %s (peer %d): %s [%s]" % [player_name, peer_id, checksum_hex, match_status])

	push_error("")
	push_error("Game state summary:")

	# Log current game state for debugging
	var tower_count: int = Utils.get_tower_list().size()
	var creep_count: int = Utils.get_creep_list().size()

	push_error("  Total towers: %d" % tower_count)
	push_error("  Total creeps: %d" % creep_count)

	for player in player_list:
		var player_name: String = player.get_player_name()
		var gold: int = floori(player.get_gold())
		var damage: int = floori(player.get_total_damage())
		var lives: int = floori(player.get_team().get_lives_percent())
		push_error("  %s: gold=%d, damage=%d, lives=%d%%" % [player_name, gold, damage, lives])

	push_error("========================================")


func _log_detailed_desync_data(tick: int):
	var log_lines: Array[String] = []

	log_lines.append("")
	log_lines.append("========================================")
	log_lines.append("DETAILED DESYNC DATA COMPARISON - tick %d" % tick)
	log_lines.append("========================================")

	var player_list: Array[Player] = PlayerManager.get_player_list()
	var authority_player: Player = PlayerManager.get_player_by_peer_id(1)
	var authority_player_id: int = authority_player.get_id()

	if !_checksum_data_map.has(tick):
		log_lines.append("ERROR: No checksum data collected for tick %d" % tick)
		push_error("\n".join(log_lines))
		return

	var player_to_data: Dictionary = _checksum_data_map[tick]
	var authority_data: Dictionary = player_to_data[authority_player_id]

	# Compare player data
	log_lines.append("")
	log_lines.append("=== PLAYER DATA COMPARISON ===")
	for player_data in authority_data["players"]:
		var game_player_id: int = player_data["id"]
		var player_name: String = player_data["name"]

		log_lines.append("")
		log_lines.append("  Player[%d] %s:" % [game_player_id, player_name])

		# Compare this player's data across all clients
		for player in player_list:
			var peer_player_id: int = player.get_id()
			var peer_player_name: String = player.get_player_name()
			var peer_data: Dictionary = player_to_data[peer_player_id]

			# Find matching player data
			var peer_player_data: Dictionary = {}
			for pd in peer_data["players"]:
				if pd["id"] == game_player_id:
					peer_player_data = pd
					break

			var role: String = "AUTH" if peer_player_id == authority_player_id else "PEER"
			var desync_markers: Array[String] = []

			# Compare each field
			if peer_player_data["total_damage"] != player_data["total_damage"]:
				desync_markers.append("damage")
			if peer_player_data["gold_farmed"] != player_data["gold_farmed"]:
				desync_markers.append("gold_farmed")
			if peer_player_data["gold"] != player_data["gold"]:
				desync_markers.append("gold")
			if peer_player_data["tomes"] != player_data["tomes"]:
				desync_markers.append("tomes")
			if peer_player_data["lives"] != player_data["lives"]:
				desync_markers.append("lives")
			if peer_player_data["level"] != player_data["level"]:
				desync_markers.append("level")

			var desync_str: String = ""
			if desync_markers.size() > 0:
				desync_str = " <<<<< DESYNC in: " + ", ".join(desync_markers)

			log_lines.append("    [%s] %s: damage=%d, gold_farmed=%d, gold=%d, tomes=%d, lives=%d%%, level=%d%s" % [
				role, peer_player_name,
				peer_player_data["total_damage"],
				peer_player_data["gold_farmed"],
				peer_player_data["gold"],
				peer_player_data["tomes"],
				peer_player_data["lives"],
				peer_player_data["level"],
				desync_str
			])

	# Compare tower data
	log_lines.append("")
	log_lines.append("=== TOWER DATA COMPARISON ===")

	# First, check if tower counts match
	var tower_counts: Dictionary = {}
	for player in player_list:
		var peer_player_id: int = player.get_id()
		var peer_data: Dictionary = player_to_data[peer_player_id]
		tower_counts[peer_player_id] = peer_data["towers"].size()

	var all_same_tower_count: bool = true
	var authority_tower_count: int = tower_counts[authority_player_id]
	# NOTE: sort keys to ensure deterministic iteration order for multiplayer sync
	var sorted_player_ids: Array = tower_counts.keys()
	sorted_player_ids.sort()
	for peer_player_id in sorted_player_ids:
		if tower_counts[peer_player_id] != authority_tower_count:
			all_same_tower_count = false
			break

	if !all_same_tower_count:
		log_lines.append("  !! TOWER COUNT MISMATCH !!")
		for player in player_list:
			var peer_player_id: int = player.get_id()
			var peer_player_name: String = player.get_player_name()
			var role: String = "AUTH" if peer_player_id == authority_player_id else "PEER"
			log_lines.append("    [%s] %s: %d towers" % [role, peer_player_name, tower_counts[peer_player_id]])
		log_lines.append("")

	# Compare individual towers
	log_lines.append("  Comparing %d towers:" % authority_tower_count)

	var towers_with_desyncs: int = 0
	for i in range(authority_tower_count):
		var authority_tower: Dictionary = authority_data["towers"][i]
		var tower_uid: int = authority_tower["uid"]

		var has_desync: bool = false

		# First pass: check if this tower has any desyncs
		for player in player_list:
			var peer_player_id: int = player.get_id()
			if peer_player_id == authority_player_id:
				continue

			var peer_data: Dictionary = player_to_data[peer_player_id]

			# Find matching tower by UID
			var peer_tower: Dictionary = {}
			for tower in peer_data["towers"]:
				if tower["uid"] == tower_uid:
					peer_tower = tower
					break

			if peer_tower.is_empty():
				has_desync = true
				break

			if peer_tower["id"] != authority_tower["id"] || peer_tower["level"] != authority_tower["level"] || peer_tower["exp"] != authority_tower["exp"] || peer_tower["owner_id"] != authority_tower["owner_id"]:
				has_desync = true
				break

			# Check items
			if peer_tower["items"].size() != authority_tower["items"].size():
				has_desync = true
				break

			for item_idx in range(authority_tower["items"].size()):
				var auth_item: Dictionary = authority_tower["items"][item_idx]
				var peer_item: Dictionary = peer_tower["items"][item_idx]

				if auth_item["uid"] != peer_item["uid"] || auth_item["id"] != peer_item["id"] || auth_item["charges"] != peer_item["charges"] || auth_item["user_int"] != peer_item["user_int"] || auth_item["user_int2"] != peer_item["user_int2"] || auth_item["user_int3"] != peer_item["user_int3"] || auth_item["user_real"] != peer_item["user_real"] || auth_item["user_real2"] != peer_item["user_real2"] || auth_item["user_real3"] != peer_item["user_real3"]:
					has_desync = true
					break

			if has_desync:
				break

		if has_desync:
			towers_with_desyncs += 1

		# Log ALL towers (not just desynced ones) to help debug
		log_lines.append("")
		var tower_header: String = "  Tower[uid=%d]" % tower_uid
		if has_desync:
			tower_header += " - DESYNC DETECTED:"
		else:
			tower_header += ":"
		log_lines.append(tower_header)

		for player in player_list:
			var peer_player_id: int = player.get_id()
			var peer_player_name: String = player.get_player_name()
			var peer_data: Dictionary = player_to_data[peer_player_id]
			var role: String = "AUTH" if peer_player_id == authority_player_id else "PEER"

			# Find matching tower by UID
			var peer_tower: Dictionary = {}
			for tower in peer_data["towers"]:
				if tower["uid"] == tower_uid:
					peer_tower = tower
					break

			if peer_tower.is_empty():
				log_lines.append("    [%s] %s: TOWER MISSING" % [role, peer_player_name])
				continue

			var tower_desync_markers: Array[String] = []
			if peer_tower["id"] != authority_tower["id"]:
				tower_desync_markers.append("id")
			if peer_tower["level"] != authority_tower["level"]:
				tower_desync_markers.append("level")
			if peer_tower["exp"] != authority_tower["exp"]:
				tower_desync_markers.append("exp")
			if peer_tower["owner_id"] != authority_tower["owner_id"]:
				tower_desync_markers.append("owner_id")

			var tower_desync_str: String = ""
			if tower_desync_markers.size() > 0:
				tower_desync_str = " <<<<< DESYNC in: " + ", ".join(tower_desync_markers)

			log_lines.append("    [%s] %s: id=%d, level=%d, exp=%d, owner_id=%d, items=%d%s" % [
				role, peer_player_name,
				peer_tower["id"],
				peer_tower["level"],
				peer_tower["exp"],
				peer_tower["owner_id"],
				peer_tower["items"].size(),
				tower_desync_str
			])

			# Log items
			if peer_tower["items"].size() != authority_tower["items"].size():
				log_lines.append("      Items: COUNT MISMATCH (AUTH=%d, THIS=%d)" % [authority_tower["items"].size(), peer_tower["items"].size()])
			elif peer_tower["items"].size() > 0:
				var has_item_desync: bool = false
				for item_idx in range(peer_tower["items"].size()):
					var auth_item: Dictionary = authority_tower["items"][item_idx]
					var peer_item: Dictionary = peer_tower["items"][item_idx]

					if auth_item["uid"] != peer_item["uid"] || auth_item["id"] != peer_item["id"] || auth_item["charges"] != peer_item["charges"] || auth_item["user_int"] != peer_item["user_int"] || auth_item["user_int2"] != peer_item["user_int2"] || auth_item["user_int3"] != peer_item["user_int3"] || auth_item["user_real"] != peer_item["user_real"] || auth_item["user_real2"] != peer_item["user_real2"] || auth_item["user_real3"] != peer_item["user_real3"]:
						has_item_desync = true
						break

				# Always log items if there are any
				for item_idx in range(peer_tower["items"].size()):
					var peer_item: Dictionary = peer_tower["items"][item_idx]
					var auth_item: Dictionary = authority_tower["items"][item_idx]

					var item_desync_markers: Array[String] = []
					if peer_item["uid"] != auth_item["uid"]:
						item_desync_markers.append("uid")
					if peer_item["id"] != auth_item["id"]:
						item_desync_markers.append("id")
					if peer_item["charges"] != auth_item["charges"]:
						item_desync_markers.append("charges")
					if peer_item["user_int"] != auth_item["user_int"]:
						item_desync_markers.append("int")
					if peer_item["user_int2"] != auth_item["user_int2"]:
						item_desync_markers.append("int2")
					if peer_item["user_int3"] != auth_item["user_int3"]:
						item_desync_markers.append("int3")
					if peer_item["user_real"] != auth_item["user_real"]:
						item_desync_markers.append("real")
					if peer_item["user_real2"] != auth_item["user_real2"]:
						item_desync_markers.append("real2")
					if peer_item["user_real3"] != auth_item["user_real3"]:
						item_desync_markers.append("real3")

					var item_desync_str: String = ""
					if item_desync_markers.size() > 0:
						item_desync_str = " <<<<< DESYNC in: " + ", ".join(item_desync_markers)

					log_lines.append("      Item[%d] uid=%d, id=%d, charges=%d, int=[%d,%d,%d], real=[%d,%d,%d]%s" % [
						item_idx,
						peer_item["uid"],
						peer_item["id"],
						peer_item["charges"],
						peer_item["user_int"],
						peer_item["user_int2"],
						peer_item["user_int3"],
						peer_item["user_real"],
						peer_item["user_real2"],
						peer_item["user_real3"],
						item_desync_str
					])

	# Add summary at the end of tower comparison
	log_lines.append("")
	if towers_with_desyncs == 0:
		log_lines.append("  >> NO TOWER DESYNCS - All %d towers match perfectly across all clients" % authority_tower_count)
	else:
		log_lines.append("  >> Summary: %d/%d towers have desyncs" % [towers_with_desyncs, authority_tower_count])

	log_lines.append("")
	log_lines.append("========================================")
	log_lines.append("END DETAILED DESYNC DATA")
	log_lines.append("========================================")
	log_lines.append("")

	# Print entire log as one message
	push_error("\n".join(log_lines))


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
