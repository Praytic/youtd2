## The public game server SDK, used by both clients and the server.
extends Node

const GameServer = preload("game_server.gd")
const ServerState = GameServer.ServerState
const PlayerRegistration = GameServer.PlayerRegistration

## Represents a player connected to the dedicated server.
class W4Player extends RefCounted:
	var _peer_id: int
	var _player_id: String
	var _info: Dictionary

	## The players peer id.
	var peer_id: int:
		get:
			return _peer_id
		set(_v):
			pass

	## The UUID of the player's user in the database.
	var player_id: String:
		get:
			return _player_id
		set(_v):
			pass

	## Arbitrary info which was sent when the player registered with the dedicated server.
	var info: Dictionary:
		get:
			return _info
		set(_v):
			pass

	func _init(p_peer_id: int, p_player_id: String, p_info: Dictionary):
		_peer_id = p_peer_id
		_player_id = p_player_id
		_info = p_info

	## Gets the player's peer id.
	func get_peer_id() -> int:
		return _peer_id

	## Gets the UUID of the player's user in the database.
	func get_player_id() -> String:
		return _player_id

	## Gets the arbitrary info which was sent when the player registered with the dedicated server.
	func get_info() -> Dictionary:
		return _info

var _is_server: bool = false
var _server: GameServer
var _players := {}
var _peer_id_map := {}
var _player_registration: PlayerRegistration

## Emitted when a new player has connected to the dedicated server.
signal player_joined (player)
## Emitted when a player has disconnected from the dedicated server.
signal player_left (player)
## Emitted when the match is ready to start.
##
## This can be because all of the players in the lobby have joined, or the minimum number of
## players have joined and the "Player Join Timeout" has elapsed.
signal match_ready ()
## Emitted when the match can't start.
##
## This happens when fewer than the minimum number of players have joined by the time the
## "Player Join Timeout" has elapsed.
signal match_failed ()

func _ready() -> void:
	_is_server = OS.has_environment('W4CLOUD') or '--w4cloud' in OS.get_cmdline_args()
	if _is_server:
		_server = GameServer.new()
		_server.player_joined.connect(self._on_server_player_joined)
		_server.player_left.connect(self._on_server_player_left)
		_server.match_ready.connect(self._on_server_match_ready)
		_server.match_failed.connect(self._on_server_match_failed)
		add_child(_server)

## Returns true if this is the dedicated server; otherwise, false.
func is_server() -> bool:
	return _is_server

## Sets the requested server state.
##
## The request will be sent to Agones, which will (after a short delay) update the server's current state.
##
## This can only be called on the dedicated server.
func set_server_state(p_state: int, p_extra = null):
	if _is_server:
		_server.set_server_state(p_state, p_extra)
	else:
		push_error("Can only set the server status on the server")

## Gets the current server state.
##
## This can only be called on the dedicated server.
func get_server_state() -> int:
	if _is_server:
		return _server.get_server_state()

	push_error("Can only get the server state on the server")
	return ServerState.UNKNOWN

## Gets the requested server state.
##
## This will be the last valid value set by [method set_server_state], before Agones has made the state change.
##
## This can only be called on the dedicated server.
func get_requested_server_state() -> int:
	if _is_server:
		return _server.get_requested_server_state()

	push_error("Can only get the requested server state on the server")
	return ServerState.UNKNOWN

## Gets the game server object.
##
## This can be used on the dedicated server for less common features that aren't exposed through this class.
##
## On clients, this will always return [code]null[/code].
func get_server() -> GameServer:
	return _server

## Starts the client.
##
## This must be called before connecting to the dedicated server via [method ENetMultiplayerPeer.create_client].
##
## The [param p_password] parameter comes from the ["addons/w4gd/matchmaker/matchmaker.gd".ServerTicket]
## received by [signal "addons/w4gd/matchmaker/matchmaker.gd".Lobby.received_server_ticket].
## The [param p_info] paramater can contain arbitrary information that will be shared with the server and
## all clients connected to it.
func start_client(p_player_id: String, p_password, p_info: Dictionary = {}):
	if _is_server:
		push_error("Cannot start client on server")
		return

	multiplayer.set_auth_callback(_client_auth_callback)
	multiplayer.peer_authenticating.connect(_on_client_peer_authenticating)
	multiplayer.peer_authentication_failed.connect(_on_client_peer_authentication_failed)
	multiplayer.server_disconnected.connect(_on_client_disconnected)

	_player_registration = PlayerRegistration.new(p_player_id, p_password, p_info)

## Gets the list of players currently connected to the dedicated server.
func get_players() -> Array:
	return _players.values()

## Gets the player object for a connected player by the UUID of their user in the database.
func get_player(player_id: String) -> W4Player:
	return _players.get(player_id)

## Gets the player object for a connected player by their peer id.
func get_player_by_peer_id(peer_id: int) -> W4Player:
	if _peer_id_map.has(peer_id):
		return _players.get(_peer_id_map[peer_id])
	return null

func _client_auth_callback(p_peer_id: int, p_data: PackedByteArray) -> void:
	# We don't actually need to do anything on the client, but we need to set
	# this callback to enable the authentication features.
	pass

func _on_client_peer_authenticating(p_peer_id: int) -> void:
	if p_peer_id == 1:
		if _player_registration == null:
			push_error("Cannot authenticate with server because info wasn't set via start_client()")
			multiplayer.disconnect_peer(p_peer_id)
			return
		multiplayer.send_auth(p_peer_id, _player_registration.to_bytes())

	# After sending auth info or for any other peer aside from the server, we
	# mark authentication as completed.
	multiplayer.complete_auth(p_peer_id)

func _on_client_peer_authentication_failed(p_peer_id: int) -> void:
	if p_peer_id == 1:
		_player_registration = null

func _on_client_disconnected() -> void:
	multiplayer.set_auth_callback(Callable())
	multiplayer.peer_authenticating.disconnect(_on_client_peer_authenticating)
	multiplayer.peer_authentication_failed.disconnect(_on_client_peer_authentication_failed)
	multiplayer.server_disconnected.disconnect(_on_client_disconnected)

func _on_server_player_joined(p_peer_id: int, p_player_id: String, p_info: Dictionary) -> void:
	# First, let the new player know about all the existing players.
	for peer_id in _peer_id_map:
		var player = _players[_peer_id_map[peer_id]]
		_client_player_joined.rpc_id(p_peer_id, player.peer_id, player.player_id, player.info)

	_client_player_joined.rpc(p_peer_id, p_player_id, p_info)

func _on_server_player_left(p_peer_id: int, p_player_id: String, p_info: Dictionary) -> void:
	_client_player_left.rpc(p_peer_id, p_player_id)

func _on_server_match_ready() -> void:
	_client_match_ready.rpc()

func _on_server_match_failed() -> void:
	_client_match_failed.rpc()

@rpc("call_local")
func _client_player_joined(p_peer_id: int, p_player_id: String, p_info: Dictionary) -> void:
	var player = W4Player.new(p_peer_id, p_player_id, p_info)
	_players[p_player_id] = player
	_peer_id_map[p_peer_id] = p_player_id
	player_joined.emit(player)

	if _player_registration and _player_registration.player_id == p_player_id:
		_player_registration = null

@rpc("call_local")
func _client_player_left(p_peer_id: int, p_player_id: String) -> void:
	if _players.has(p_player_id):
		var player = _players[p_player_id]
		_players.erase(p_player_id)
		_peer_id_map.erase(p_peer_id)
		player_left.emit(player)

@rpc("call_local")
func _client_match_ready() -> void:
	match_ready.emit()

@rpc("call_local")
func _client_match_failed() -> void:
	_players.clear()
	_peer_id_map.clear()
	match_failed.emit()
