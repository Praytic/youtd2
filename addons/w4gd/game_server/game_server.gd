## Implements functionality specifically intended to run on a dedicated server.
##
## The most common features are exposed through ["addons/w4gd/game_server/game_server_sdk.gd"],which
## is what you should use in most cases. Only interact with this class if you need uncommon, advanced
## features.
extends Node

const AgonesClient = preload("agones_client.gd")

## The name of the Lobby ID annotation used on the Agones game server configuration.
const LOBBY_ID_ANNOTATION = 'w4games.com/lobby'
## The name of the Lobby password annotation used on the Agones game server configuration.
const LOBBY_PASSWORD_ANNOTATION = 'w4games.com/password'
## The name of the Lobby players count annotation used on the Agones game server configuration.
const LOBBY_PLAYERS_ANNOTATION = 'w4games.com/players'
## The name of the Lobby properties annotation used on the Agones game server configuration.
const LOBBY_PROPS_ANNOTATION = 'w4games.com/props'

## The Agones game server state.
enum ServerState {
	UNKNOWN,
	STARTING,
	RESERVED,
	READY,
	ALLOCATED,
	SHUTDOWN,
}

## Internal class representing a player registration with the dedicated server.
class PlayerRegistration extends RefCounted:
	var player_id: String
	var password: String
	var info: Dictionary

	func _init(p_player_id: String, p_password: String, p_info: Dictionary = {}):
		assert(p_player_id.length() == 36)

		player_id = p_player_id
		password = p_password
		info = p_info

	func to_bytes() -> PackedByteArray:
		var buffer = StreamPeerBuffer.new()
		buffer.resize(1024)

		buffer.put_data(player_id.to_ascii_buffer())
		buffer.put_string(password)
		buffer.put_var(info)

		buffer.resize(buffer.get_position())
		return buffer.data_array

	static func from_bytes(p_bytes: PackedByteArray) -> PlayerRegistration:
		var buffer = StreamPeerBuffer.new()
		buffer.data_array = p_bytes

		var player_id_result = buffer.get_partial_data(36)
		assert(player_id_result[0] == OK)
		var player_id = player_id_result[1].get_string_from_ascii()
		var password = buffer.get_string()
		var info = buffer.get_var()

		if not info is Dictionary:
			info = {}

		return PlayerRegistration.new(player_id, password, info)

## Internal class used to coordinate state changes with Agones.
class StateChangeRequest extends RefCounted:
	var _agones: AgonesClient
	var _requested_state: int
	var _extra

	var _in_progress := false
	var _cancelled := false
	var _successful := false

	signal failed (requested_state)
	signal completed (requested_state)

	func _init(p_agones: AgonesClient, p_requested_state: int, p_extra):
		_agones = p_agones
		_requested_state = p_requested_state
		_extra = p_extra

	func execute() -> bool:
		_in_progress = true
		_cancelled = false
		_successful = false

		var result
		match _requested_state:
			ServerState.RESERVED:
				result = await _agones.reserve(_extra as int)
			ServerState.READY:
				result = await _agones.ready()
			ServerState.ALLOCATED:
				result = await _agones.allocate()
			ServerState.SHUTDOWN:
				result = await _agones.shutdown()

		_in_progress = false

		if not result or result.is_error():
			failed.emit(_requested_state)
		elif not _cancelled:
			completed.emit(_requested_state)
			_successful = true

		return _successful

	func get_requested_state() -> int:
		return _requested_state

	func needs_retry() -> bool:
		return not _successful and not _in_progress and not _cancelled

	func cancel() -> void:
		_cancelled = true

## Emitted when a new player has connected to the dedicated server.
signal player_joined (peer_id, player_id, info)
## Emitted when a player has disconnected from the dedicated server.
signal player_left (peer_id, player_id, info)

## Emitted when the server state has changed.
signal server_state_changed (new_state)
## Emitted when the match is ready to start.
signal match_ready ()
## Emitted when the match can't start.
signal match_failed ()

#
# Configurable options:
#

## The minimum number of players required for a match.
var minimum_players: int = 1
## Set to true to automatically shutdown if we encounter a match failure.
var auto_shutdown_on_match_failure: bool = true

var _health_check_interval: float = 2.0
## How often to let Agones know that we are healthy (in seconds).
var health_check_interval: float:
	get:
		return _health_check_interval
	set(v):
		_health_check_interval = v
		if _health_timer != null:
			_health_timer.wait_time = _health_check_interval

var _player_join_timeout: float = 30.0
## How long to wait for players to connect to the dedicated server (in seconds).
var player_join_timeout: float:
	get:
		return _player_join_timeout
	set(v):
		_player_join_timeout = v
		if _match_ready_timer != null:
			_match_ready_timer.wait_time = _player_join_timeout

## Direct access to agones client for advanced use cases.
var agones: AgonesClient

#
# Internal variables:
#

var _health_timer: Timer = null
var _match_ready_timer: Timer = null
var _metadata_watcher: AgonesClient.Watcher

var _lobby_id: String
var _lobby_password: String
var _lobby_players: int
var _lobby_props: Dictionary

var _pending_player_registrations := {}
var _registered_players := {}
var _player_to_peer_map := {}
var _peer_to_player_map := {}

var _state := ServerState.STARTING
var _state_change_request: StateChangeRequest

func _init():
	var project_settings := {
		health_check_interval = 'w4games/game_server/health_check_interval',
		player_join_timeout = 'w4games/game_server/player_join_timeout',
		minimum_players = 'w4games/game_server/minimum_players',
		auto_shutdown_on_match_failure = 'w4games/game_server/auto_shutdown_on_match_failure',
	}
	for property_name in project_settings:
		var setting_name = project_settings[property_name]
		if ProjectSettings.has_setting(setting_name):
			set(property_name, ProjectSettings.get_setting(setting_name))

func _ready():
	agones = AgonesClient.new(self)

	_health_timer = Timer.new()
	_health_timer.name = 'HealthTimer'
	_health_timer.wait_time = _health_check_interval
	_health_timer.timeout.connect(self._on_health_timer_timeout)
	add_child(_health_timer)
	_health_timer.start()

	_match_ready_timer = Timer.new()
	_match_ready_timer.name = 'MatchReadyTimer'
	_match_ready_timer.wait_time = _player_join_timeout
	_match_ready_timer.one_shot = true
	_match_ready_timer.timeout.connect(self._on_match_ready_timer_timeout)
	add_child(_match_ready_timer)

	_metadata_watcher = agones.watch_game_server()
	_metadata_watcher.received_data.connect(self._on_metadata_received)
	_metadata_watcher.error.connect(self._on_metadata_watcher_error)
	_metadata_watcher.stopped.connect(self._on_metadata_watcher_stopped)
	_metadata_watcher.start()

	multiplayer.set_auth_callback(self._auth_callback)
	multiplayer.peer_connected.connect(self._on_peer_connected)
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected)

func _on_health_timer_timeout() -> void:
	var result = await agones.health()
	if result.is_error():
		print("Error sending health ping to Agones: ", result.get_message())

	# If the metadata watcher has stopped, we'll try to restart it.
	if not _metadata_watcher.is_running():
		print ("Restarting metadata watcher...")
		_metadata_watcher.start()

	# If our last state change request failed, retry it.
	if _state_change_request and _state_change_request.needs_retry():
		_state_change_request.execute()

func _on_metadata_received(data: Dictionary) -> void:
	if data.has('object_meta'):
		var metadata = data['object_meta']
		if metadata.has('annotations'):
			var annotations = metadata['annotations']
			if annotations is Dictionary:
				var changed := false
				if annotations.has(LOBBY_ID_ANNOTATION) and _lobby_id != annotations[LOBBY_ID_ANNOTATION]:
					_lobby_id = annotations[LOBBY_ID_ANNOTATION]
					changed = true
				if annotations.has(LOBBY_PASSWORD_ANNOTATION) and _lobby_password != annotations[LOBBY_PASSWORD_ANNOTATION]:
					_lobby_password = annotations[LOBBY_PASSWORD_ANNOTATION]
					changed = true
				if annotations.has(LOBBY_PLAYERS_ANNOTATION) and _lobby_players != annotations[LOBBY_PLAYERS_ANNOTATION].to_int():
					_lobby_players = annotations[LOBBY_PLAYERS_ANNOTATION].to_int()
				if annotations.has(LOBBY_PROPS_ANNOTATION):
					var new_props := JSON.parse_string(annotations[LOBBY_PROPS_ANNOTATION])
					if new_props is Dictionary and _lobby_props.hash() != new_props.hash():
						_lobby_props = new_props
				if changed and has_lobby_metadata():
					for peer_id in _pending_player_registrations:
						_process_player_registration(peer_id, _pending_player_registrations[peer_id])
					_pending_player_registrations.clear()

	if data.has('status'):
		var status = data['status']
		if status.has('state'):
			var new_state := 0
			match status['state']:
				"Ready":
					new_state = ServerState.READY
				"Allocated":
					new_state = ServerState.ALLOCATED
				"Reserved":
					new_state = ServerState.RESERVED
			if new_state != 0:
				_finish_state_change(new_state)

func _on_metadata_watcher_error(code: int) -> void:
	print ("METADATA WATCHER ERROR: ", code)

func _on_metadata_watcher_stopped() -> void:
	print ("METADATA WATCHER STOPPED")

## Sets the requested server state.
func set_server_state(p_requested_state: int, p_extra = null) -> void:
	if p_requested_state in [ServerState.UNKNOWN, ServerState.STARTING]:
		push_error("Cannot set server state to %s" % ServerState.keys()[p_requested_state])
		return

	# Don't change state if we're already in the requested state, or if we're
	# already in the process of requesting a change to this state.
	if (p_requested_state == _state) or (_state_change_request != null and p_requested_state == _state_change_request.get_requested_state()):
		# Except for RESERVE, which will extend the reservation.
		if p_requested_state != ServerState.RESERVED:
			return

	if _state == ServerState.SHUTDOWN:
		# If we're shutting down, don't allow changing the state further.
		return

	if _state_change_request != null:
		_state_change_request.cancel()
		_state_change_request = null

	if p_requested_state == ServerState.SHUTDOWN:
		# Immediately set the state to shutdown, to prevent a subsequent state
		# change from "cancelling" the shutdown.
		_finish_state_change(p_requested_state)

	_state_change_request = StateChangeRequest.new(agones, p_requested_state, p_extra)
	_state_change_request.failed.connect(_on_state_change_failed)
	_state_change_request.completed.connect(_on_state_change_completed)
	_state_change_request.execute()

func _on_state_change_failed(p_requested_state) -> void:
	if p_requested_state == ServerState.SHUTDOWN:
		# If we failed to shutdown nicely, just kill the process.
		get_tree().quit()

	# This will be retried on the next health interval.
	print ("Error changing state to %s" % ServerState.keys()[p_requested_state])

func _on_state_change_completed(p_requested_state: int) -> void:
	_state_change_request = null
	_finish_state_change(p_requested_state)

func _finish_state_change(p_requested_state: int) -> void:
	if _state != p_requested_state:
		_state = p_requested_state
		print ("Changed state to %s" % ServerState.keys()[p_requested_state])

		if _state == ServerState.ALLOCATED:
			_match_ready_timer.start()

		server_state_changed.emit(_state)

## Gets the current server state.
func get_server_state() -> int:
	return _state

## Gets the requested server state.
func get_requested_server_state() -> int:
	if _state_change_request:
		return _state_change_request.get_requested_state()
	return ServerState.UNKNOWN

## Gets the Lobby ID of the match.
func get_lobby_id() -> String:
	return _lobby_id

## Checks if we have the required lobby metadata from the Agones game server configuration.
func has_lobby_metadata() -> bool:
	return _lobby_id != '' and _lobby_password != ''

## Gets the Lobby properties.
func get_lobby_properties() -> Dictionary:
	return _lobby_props

func _auth_callback(p_peer_id: int, p_data: PackedByteArray) -> void:
	var player_registration = PlayerRegistration.from_bytes(p_data)
	if has_lobby_metadata():
		_process_player_registration(p_peer_id, player_registration)
	else:
		print ("Received authentication request from %s (%s)" % [player_registration.player_id, p_peer_id])
		_pending_player_registrations[p_peer_id] = player_registration

func _process_player_registration(p_peer_id: int, p_player: PlayerRegistration) -> void:
	if _player_to_peer_map.has(p_player.player_id) and _player_to_peer_map[p_player.player_id] != p_peer_id:
		_refuse_peer(p_peer_id, "Player %s (%s) authentication failed: player_id already registered for peer %s" % [
			p_player.player_id,
			p_peer_id,
			_player_to_peer_map[p_player.player_id],
		])
		return

	var correct_password = (p_player.player_id + ':' + _lobby_password).sha256_text()
	if p_player.password == correct_password:
		_registered_players[p_player.player_id] = p_player
		_player_to_peer_map[p_player.player_id] = p_peer_id
		_peer_to_player_map[p_peer_id] = p_player.player_id
		print ("Player %s (%s) authenticated successfully" % [
			p_player.player_id,
			p_peer_id,
		])
		multiplayer.complete_auth(p_peer_id)
		# Wait until 'peer_connected' is emitted to actually take action on the
		# player having connected.
	else:
		_refuse_peer(p_peer_id, "Player %s (%s) authentication failed: incorrect password" % [
			p_player.player_id,
			p_peer_id,
		])

func _refuse_peer(p_peer_id: int, p_msg: String) -> void:
	multiplayer.disconnect_peer(p_peer_id)
	print (p_msg)

func _on_peer_connected(p_peer_id: int) -> void:
	var player = _registered_players[_peer_to_player_map[p_peer_id]]
	player_joined.emit(p_peer_id, player.player_id, player.info)

	# If all the players in the lobby have successfully registered, then
	# we are ready to start the match!
	if _lobby_players != 0 and _registered_players.size() == _lobby_players:
		print ("Match ready: %s players (out of %s) connected" % [
			_registered_players.size(),
			_lobby_players,
		])
		_do_match_ready()

func _on_peer_disconnected(p_peer_id: int) -> void:
	# Only peers that successfully registered as players should cause the
	# 'player_left' signal to be emitted. Other peers may connect, but get
	# kicked for having the incorrect password.
	if _peer_to_player_map.has(p_peer_id):
		var player_id = _peer_to_player_map[p_peer_id]
		var player = _registered_players[player_id]
		_registered_players.erase(player_id)
		_player_to_peer_map.erase(player_id)
		_peer_to_player_map.erase(p_peer_id)
		print ("Player %s (%s) has left" % [player_id, p_peer_id])
		player_left.emit(p_peer_id, player_id, player.info)

func _on_match_ready_timer_timeout() -> void:
	# If we have more than the minimum players, then we can start the match.
	if _registered_players.size() >= minimum_players:
		print ("Match ready: %s players (out of %s) connected - %s minimum required" % [
			_registered_players.size(),
			_lobby_players,
			minimum_players,
		])
		_do_match_ready()
	else:
		print ("Unable to start match: %s players connected - %s minimum required" % [
			_registered_players.size(),
			minimum_players,
		])
		if auto_shutdown_on_match_failure:
			print ("Automatically shutting down the game server");
			set_server_state(ServerState.SHUTDOWN)

		_registered_players.clear()
		_player_to_peer_map.clear()
		_peer_to_player_map.clear()

		match_failed.emit()

func _do_match_ready() -> void:
	_match_ready_timer.stop()
	match_ready.emit()
