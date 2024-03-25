## Interacts with the W4 Cloud matchmaker component.
extends Node

const SupabaseClient = preload("../supabase/client.gd")
const Parser = preload("../supabase/poly_result.gd")
const PolyResult = Parser.PolyResult
const Promise = preload("../rest-client/client_promise.gd")
const Request = preload("../rest-client/client_request.gd")
const WebRTCManager = preload("webrtc_manager.gd")

## The lobby type.
enum LobbyType {
	## A lobby that doesn't use W4 Cloud's dedicated server or WebRTC systems.
	LOBBY_ONLY = 0,
	## A lobby that needs a dedicated server allocated.
	DEDICATED_SERVER = 1,
	## A lobby that will use the WebRTC signalling server.
	WEBRTC = 2,
}

## The lobby state.
enum LobbyState {
	## A newly created lobby.
	NEW = 1,
	## The match is now in progress (players can still join and leave).
	IN_PROGRESS = 2,
	## The match is in progress, but sealed, meaning players can no longer join or leave.
	SEALED = 3,
	## The match is done and this lobby can be cleaned up.
	DONE = 4,
}

## Represents access granted to a dedicated server.
class ServerTicket extends RefCounted:
	## The IP of the server to connect to.
	var ip: String
	## The port of the server to connect to.
	var port: int
	## A secret used to verify that this player has permission to connect to this server.
	var secret: String

	## Creates a new server ticket.
	func _init(p_server_uri: String, p_secret: String):
		var server_parts = p_server_uri.split(':')
		ip = server_parts[0]
		port = server_parts[1].to_int()
		secret = p_secret

## Represents the players place in the matchmaking queue.
class MatchmakerTicket extends RefCounted:
	## The ticket ID.
	var id: String
	## The ID of the lobby (if any) that was created by the matchmaker for this ticket.
	var lobby_id: String

	## Emitted when a lobby is created for this ticket.
	signal matched (lobby_id)

	## Creates a matchmaker ticket.
	func _init(p_id: String):
		id = p_id

	func _match(p_lobby: String) -> void:
		lobby_id = p_lobby
		matched.emit(lobby_id)

## A collection of players who are in (about to be in) a match together.
class Lobby extends RefCounted:

	## Properties or settings for this lobby.
	var props: Dictionary

	## The current lobby state.
	var state: LobbyState = LobbyState.NEW

	## Emitted when the lobby is updated.
	signal updated ()
	## Emitted when the lobby is deleted.
	signal deleted ()
	## Emitted when a player joins the lobby.
	signal player_joined (player_id)
	## Emitted when a player leaves the lobby.
	signal player_left (player_id)
	## Emitted when a server ticket is received for this lobby.
	signal received_server_ticket (ticket)
	## Emitted when a WebRTC mesh is created.
	signal webrtc_mesh_created (multiplayer_peer)
	## Emitted when connections to all WebRTC peers have been established.
	signal webrtc_peers_ready ()
	## Emitted when one or more of the WebRTC peers is no longer connected, or a new peer has joined that we haven't connected to yet.
	signal webrtc_peers_not_ready ()

	var _id: String
	## The lobby ID.
	var id: String:
		get:
			return _id
		set(v):
			push_error("Lobby.id is a read-only property")

	var _type: LobbyType
	## The lobby type.
	var type: LobbyType:
		get:
			return _type
		set(v):
			push_error("Lobby.type is a read-only property")

	var _creator_id: String
	## The ID of the player who created the lobby (if any).
	var creator_id: String:
		get:
			return _creator_id
		set(v):
			push_error("Lobby.creator_id is a read-only property")

	var _max_players: int
	## The maximum number of players allowed in this lobby.
	var max_players: int:
		get:
			return _max_players
		set(v):
			push_error("Lobby.max_players is a read-only property")

	var _created_at: int
	## When the lobby was created (in UNIX time).
	var created_at: int:
		get:
			return _created_at
		set(v):
			push_error("Lobby.created_at is a read-only property")

	var _updated_at: int
	## When the lobby was last updated (in UNIX time).
	var updated_at: int:
		get:
			return _updated_at
		set(v):
			push_error("Lobby.updated_at is a read-only property")

	var _hidden: bool
	## Whether or not this lobby is hidden.
	var hidden: bool:
		get:
			return _hidden
		set(v):
			push_error("Lobby.hidden is a read-only property")

	var _cluster: String
	## The name of the cluster when using a dedicated server lobby.
	var cluster: String:
		get:
			return _cluster
		set(v):
			push_error("Lobby.cluster is a read-only property")


	var _is_deleted: bool = false
	var _players: Array[String]
	var _server_ticket: ServerTicket
	var _webrtc_manager: WebRTCManager

	var _client: SupabaseClient
	var _realtime_lobby_channel
	var _realtime_presence_channel
	var _realtime_server_channel
	var _is_subscribed: bool = false

	## Creates a new lobby.
	func _init(p_client: SupabaseClient, p_data: Dictionary, p_webrtc_ice_servers: Array, p_poll_signal: Signal, p_subscribe: bool):
		_id = p_data['id']
		_type = p_data['type']
		_update_data(p_data)
		_creator_id = p_data['creator_id'] if p_data['creator_id'] != null else ''
		_max_players = p_data['max_players']
		_created_at = p_data['created_at']
		_updated_at = p_data['updated_at']
		_hidden = p_data['hidden']
		_cluster = p_data['cluster'] if p_data['cluster'] != null else ''

		_client = p_client

		if _type == LobbyType.WEBRTC:
			_webrtc_manager = WebRTCManager.new(_client, _id, p_webrtc_ice_servers, p_subscribe)
			_webrtc_manager.mesh_created.connect(_on_webrtc_manager_mesh_created)
			_webrtc_manager.peers_ready.connect(_on_webrtc_manager_peers_ready)
			_webrtc_manager.peers_not_ready.connect(_on_webrtc_manager_peers_not_ready)

			p_poll_signal.connect(_webrtc_manager.poll)

		if p_subscribe:
			subscribe()

	func subscribe() -> void:
		if _is_subscribed:
			return
		_is_subscribed = true

		_realtime_lobby_channel = _client.realtime.channel('matchmaker_lobby_' + _id.replace('-', '_'))
		_realtime_lobby_channel.on_postgres_changes('*', 'w4online.lobby', 'id=eq.' + _id)
		_realtime_lobby_channel.updated.connect(self._on_lobby_updated)
		_realtime_lobby_channel.deleted.connect(self._on_lobby_updated)
		_realtime_lobby_channel.subscribe()

		_realtime_presence_channel = _client.realtime.channel('matchmaker_lobby_presence_' + _id.replace('-', '_'))
		_realtime_presence_channel.on_postgres_changes('*', 'w4online.lobby_presence', 'lobby_id=eq.' + _id)
		_realtime_presence_channel.inserted.connect(self._on_precence_updated)
		_realtime_presence_channel.deleted.connect(self._on_precence_updated)
		_realtime_presence_channel.subscribe()

		if _type == LobbyType.WEBRTC:
			_webrtc_manager.subscribe()
		elif _type == LobbyType.DEDICATED_SERVER:
			_realtime_server_channel = _client.realtime.channel('matchmaker_server_ticket_' + _id.replace('-', '_'))
			_realtime_server_channel.on_postgres_changes('INSERT', 'w4online.server_ticket', 'lobby_id=eq.' + _id)
			_realtime_server_channel.inserted.connect(self._on_received_server_ticket)
			_realtime_server_channel.subscribe()

	func unsubscribe() -> void:
		if _realtime_lobby_channel:
			_realtime_lobby_channel.unsubscribe()
			_realtime_lobby_channel = null

		if _realtime_presence_channel:
			_realtime_presence_channel.unsubscribe()
			_realtime_presence_channel = null

		if _realtime_server_channel:
			_realtime_server_channel.unsubscribe()
			_realtime_server_channel = null

		if _webrtc_manager:
			_webrtc_manager.unsubscribe()

		_is_subscribed = false

	func is_subscribed() -> bool:
		return _is_subscribed

	func _update_data(p_data: Dictionary) -> void:
		props = p_data['props']
		state = p_data['state']

	func _on_webrtc_manager_mesh_created(multiplayer_peer: WebRTCMultiplayerPeer) -> void:
		webrtc_mesh_created.emit(multiplayer_peer)

	func _on_webrtc_manager_peers_ready() -> void:
		webrtc_peers_ready.emit()

	func _on_webrtc_manager_peers_not_ready() -> void:
		webrtc_peers_not_ready.emit()

	## Returns true if this is a deleted lobby.
	func is_deleted() -> bool:
		return _is_deleted

	## Returns true if the currently logged in user is the creator of this lobby.
	func is_creator() -> bool:
		var identity = _client.get_identity()
		if not identity.is_authenticated():
			return false
		return identity.get_uid() == _creator_id

	## Gets the current player list.
	func get_players() -> Array[String]:
		return _players

	## Creates a request to refresh the player list.
	func refresh_player_list() -> Request:
		var request = _client.rest.rpc('w4online.lobby_get_presence', {
			lobby_id = _id,
		})

		var handle_result = func(result):
			if result.is_error():
				return result

			var new_players : Array = result.users.as_array()

			for player_id in new_players:
				if not player_id in new_players:
					player_joined.emit(player_id)
			for player_id in _players:
				if not player_id in new_players:
					player_left.emit(player_id)

			_players.assign(new_players)

			return PolyResult.new(_players)

		return request.then(handle_result)

	## Gets the server ticket for this lobby (if any).
	func get_server_ticket() -> ServerTicket:
		return _server_ticket

	## Creates a request to refresh the server ticket for this lobby.
	func refresh_server_ticket() -> Request:
		var request = _client.rest.rpc('w4online.server_ticket_by_lobby_id', {
			lobby_id = _id,
		})

		var handle_result = func(result):
			if result.is_error():
				return result

			if result.id.is_null():
				return PolyResult.new()

			_server_ticket = ServerTicket.new(result.server_uri.as_string(), result.secret.as_string())
			_emit_received_server_ticket.call_deferred()
			return PolyResult.new(_server_ticket)

		return request.then(handle_result)

	func _emit_received_server_ticket() -> void:
		received_server_ticket.emit(_server_ticket)

	## Creates a request to refresh the WebRTC sessions for this lobby.
	func refresh_webrtc_sessions() -> Request:
		if not _webrtc_manager:
			push_error("Not a WebRTC lobby")
			return null
		return _webrtc_manager.refresh_sessions()

	## Gets the WebRTC multiplayer peer for this lobby (if any).
	func get_webrtc_multiplayer_peer() -> WebRTCMultiplayerPeer:
		if not _webrtc_manager:
			push_error("Not a WebRTC lobby")
			return null
		return _webrtc_manager.webrtc_multiplayer_peer

	## Gets the WebRTC manager.
	func get_webrtc_manager() -> WebRTCManager:
		if not _webrtc_manager:
			push_error("Not a WebRTC lobby")
			return null
		return _webrtc_manager

	## Creates a request to save any changed properties on the lobby.
	func save() -> Request:
		var request = _client.rest.rpc('w4online.lobby_update', {
			lobby_id = _id,
			props = props,
			state = state,
		})

		var handle_result = func(result):
			if result.is_error():
				return result
			return PolyResult.new()

		return request.then(handle_result)

	## Creates a request to leave the lobby.
	func leave() -> Request:
		var request = _client.rest.rpc('w4online.lobby_leave', {
			lobby_id = _id,
		})

		var handle_result = func(result):
			if result.is_error():
				return result
			return PolyResult.new()

		return request.then(handle_result)

	## Creates a request to delete the lobby.
	func delete() -> Request:
		var request = _client.rest.rpc('w4online.lobby_delete', {
			lobby_id = _id,
		})

		var handle_result = func(result):
			if result.is_error():
				return result
			return PolyResult.new()

		return request.then(handle_result)

	func _on_lobby_updated(p_data: Dictionary) -> void:
		if p_data['type'] == 'UPDATE':
			_update_data(p_data['record'])
			updated.emit()
		elif p_data['type'] == 'DELETE':
			_is_deleted = true
			deleted.emit()

	func _on_precence_updated(p_data: Dictionary) -> void:
		if p_data['type'] == 'INSERT':
			var player_id = p_data['record']['user_id']
			if not player_id in _players:
				_players.append(player_id)
				player_joined.emit(player_id)
		elif p_data['type'] == 'DELETE':
			var player_id = p_data['old_record']['user_id']
			if player_id in _players:
				_players.erase(player_id)
				player_left.emit(player_id)

	func _on_received_server_ticket(p_data: Dictionary) -> void:
		var record = p_data['record']
		_server_ticket = ServerTicket.new(record['server_uri'], record['secret'])
		received_server_ticket.emit(_server_ticket)

## The default WebRTC ICE servers, if none are provided.
const DEFAULT_WEBRTC_ICE_SERVERS := [
	{
		"urls": [
			"stun:stun.l.google.com:19302",
			"stun:stun1.l.google.com:19302",
			"stun:stun2.l.google.com:19302",
			"stun:stun3.l.google.com:19302",
			"stun:stun4.l.google.com:19302",
		],
	},
]

var _client: SupabaseClient
var _webrtc_ice_servers: Array = DEFAULT_WEBRTC_ICE_SERVERS
var _matchmaker_tickets := {}
var _matchmaker_channel

signal _poll ()

func _init(p_client: SupabaseClient):
	_client = p_client
	_client.get_identity().identity_changed.connect(self._subscribe_to_matchmaker_channel)
	_subscribe_to_matchmaker_channel()

func _process(_delta) -> void:
	_poll.emit()

## Sets the list of WebRTC ICE servers.
func set_webrtc_ice_servers(p_ice_servers: Array) -> void:
	_webrtc_ice_servers = p_ice_servers

## Gets a list of valid dedicated server cluster names.
func get_cluster_list() -> Request:
	return _client.rest.rpc_const('w4online.cluster_get_all')

## Creates a request to create a new lobby. A ["addons/w4gd/matchmaker/matchmaker.gd".Lobby] will be returned as the data.
##
## [param p_opts] can contain the following keys:
## - [code]props[/code]: A [Dictionary] of lobby properties to be used as needed by your game.
## - [code]max_players[/code]: The maximum number of players allowed in the lobby (the default is [code]2[/code]).
## - [code]initial_players[/code]: An [Array] of player UUIDs to add to automatically join to the lobby.
## - [code]cluster[/code]: The name of the cluster to allocate the dedicated server when using a dedicated server lobby.
func create_lobby(p_type: LobbyType = LobbyType.LOBBY_ONLY, p_opts := {}, p_subscribe: bool = true) -> Request:
	var props = p_opts.get('props', {})
	var max_players = p_opts.get('max_players', 2)
	var prealloc_players = p_opts.get('initial_players', [])
	var cluster = p_opts.get('cluster', null) if p_type == LobbyType.DEDICATED_SERVER else null
	var hidden = p_opts.get('hidden', false)

	if p_opts.has('fleet_labels') and p_opts['fleet_labels'] is Dictionary:
		props['gameServerSelectors'] = [{
			matchLabels = p_opts['fleet_labels']
		}]

	var request = _client.rest.rpc('w4online.lobby_create', {
		type = p_type,
		props = props,
		max_players = max_players,
		prealloc_players = prealloc_players,
		cluster = cluster,
		hidden = hidden,
	})

	var handle_result = func(result):
		if result.is_error():
			return result

		var lobby = Lobby.new(_client, result.lobby.as_dict(), _webrtc_ice_servers, _poll, p_subscribe)

		var players : Array[String] = []
		for ticket in result.tickets.as_array():
			if ticket['player_id'] != null:
				players.append(ticket['player_id'])
		lobby._players = players

		return PolyResult.new(lobby)

	return request.then(handle_result)

## Creates a request to join a lobby. A ["addons/w4gd/matchmaker/matchmaker.gd".Lobby] will be returned as the data.
func join_lobby(p_lobby_id: String, p_subscribe: bool = true) -> Request:
	var request = _client.rest.rpc('w4online.lobby_join', {
		lobby_id = p_lobby_id
	})

	var handle_result = func(result):
		if result.is_error():
			return result
		return get_lobby(p_lobby_id, p_subscribe)

	return request.then(handle_result)

## Creates a request to get a lobby. A ["addons/w4gd/matchmaker/matchmaker.gd".Lobby] will be returned as the data.
func get_lobby(p_lobby_id: String, p_subscribe: bool = true) -> Request:
	var request = _client.rest.rpc('w4online.lobby_by_id', {
		lobby_id = p_lobby_id,
	})

	var handle_result = func(result):
		if result.is_error():
			return result

		var lobby = Lobby.new(_client, result.as_dict(), _webrtc_ice_servers, _poll, p_subscribe)

		var subrequests := [
			lobby.refresh_player_list(),
		]
		if lobby.type == LobbyType.WEBRTC:
			subrequests.append(lobby.refresh_webrtc_sessions())
		else:
			subrequests.append(lobby.refresh_server_ticket())

		var finish_subrequests = func(results):
			for r in results:
				if r.is_error():
					return r
			return PolyResult.new(lobby)

		return Promise.sequence(subrequests).then(finish_subrequests)

	return request.then(handle_result)

## Creates a request to find lobbies that the current player has access to.
##
## This can be useful after restarting the game to see if we can reconnect to an existing match.
##
## [param p_query] is a [Dictionary] that takes the following keys:
## - [code]only_my_lobbies[/code] (bool): If set to true, this will only list lobbies that the current user has joined.
## - [code]include_player_count[/code] (bool): If set to true, this will include [code]player_count[/code] in the result.
## - [code]constraints[/code] ([Dictionary]): A Dictionary of constraints that lobbies must match.
##
## Returns an array of [Dictionary]'s with the following keys:
## - [code]id[/code]
## - [code]type[/code]
## - [code]state[/code]
## - [code]creator_id[/code]
## - [code]props[/code]
## - [code]cluster[/code]
## - [code]created_at[/code]
##
## Usage:
## [codeblock]
## var result = await W4GD.matchmaker.find_lobbies({
##     # Includes a `player_count` for each lobby in the result.
##     include_player_count = true,
##     # Filters to only include lobbies the current user is a member of (as opposed to all lobbies they have access to).
##     only_my_lobbies = true,
##     # Arbitrary constraints on the lobby's columns and properties.
##     constraints = {
##         'type': W4GD.matchmaker.LobbyType.DEDICATED_SERVER,
##         'state': [W4GD.matchmaker.LobbyState.NEW, W4GD.matchmaker.LobbyState.IN_PROGRESS],
##         'player_count': {
##             op = '<',
##             value = 5,
##         },
##         # This is a top-level element inside the JSON of the 'props' column.
##         'props.game-mode': 'battle-royale',
##     },
## }).async()
## [/codeblock]
func find_lobbies(p_query: Dictionary = {}) -> Request:
	if p_query.has('constraints'):
		var full_constraints := {}
		for k in p_query['constraints']:
			var v = p_query['constraints'][k]
			if v is Dictionary:
				full_constraints[k] = v
			elif v is Array:
				full_constraints[k] = {
					op = 'IN',
					value = v,
				}
			else:
				full_constraints[k] = {
					value = v,
				}
		p_query['constraints'] = full_constraints

	var request = _client.rest.rpc('w4online.lobby_find', {query = p_query})

	var handle_result = func(result):
		if result.is_error():
			return result
		# Make the result into an Array of lobbies.
		return PolyResult.new(result.as_dict().get('lobbies', []))

	return request.then(handle_result)


func _subscribe_to_matchmaker_channel() -> void:
	if _matchmaker_channel != null:
		_matchmaker_channel.unsubscribe()
		_matchmaker_channel = null

	if _client.get_identity().is_authenticated():
		var uid = _client.get_identity().get_uid()
		_matchmaker_channel = _client.realtime.channel('matchmaker', { presence = { key = uid }})
		_matchmaker_channel.on_postgres_changes('*', 'w4online.matchmaker_ticket', 'user_id=eq.' + uid)
		_matchmaker_channel.updated.connect(self._on_matchmaker_ticket_updated)
		_matchmaker_channel.deleted.connect(self._on_matchmaker_ticket_updated)
		if await _matchmaker_channel.subscribe() == OK:
			_matchmaker_channel.track({ status = 'connected' })

## Creates a request to join the matchmaker queue.
##
## A ["addons/w4gd/matchmaker/matchmaker.gd".MatchmakerTicket] will be returned as the data.
func join_matchmaker_queue(p_props: Dictionary = {}, p_auto_leave: bool = true) -> Request:
	var request = _client.rest.rpc('w4online.matchmaker_join', {
		props = p_props,
		auto_leave = p_auto_leave,
	})
	return request.then(self._handle_matchmaker_join_result)

func _handle_matchmaker_join_result(p_result: PolyResult) -> PolyResult:
	if p_result.is_error():
		return p_result

	var ticket = _get_or_create_matchmaker_ticket(p_result.ticket_id.as_string())

	# If the ticket already has a lobby, then emit the matched signal after the calling
	# code has had an opportunity to subscribe to it.
	if ticket.lobby_id != "":
		ticket._match.call_deferred(ticket.lobby_id)

	return PolyResult.new(ticket)

func _get_or_create_matchmaker_ticket(p_ticket_id: String, p_lobby_id = null) -> MatchmakerTicket:
	if not _matchmaker_tickets.has(p_ticket_id):
		_matchmaker_tickets[p_ticket_id] = MatchmakerTicket.new(p_ticket_id)
	return _matchmaker_tickets[p_ticket_id]

func _on_matchmaker_ticket_updated(p_data: Dictionary) -> void:
	if p_data['type'] == 'UPDATE':
		var record = p_data['record']
		var ticket = _get_or_create_matchmaker_ticket(record['id'])
		if record['lobby_id'] != null and ticket.lobby_id == "":
			ticket._match(record['lobby_id'])
	elif p_data['type'] == 'DELETE':
		_matchmaker_tickets.erase(p_data['old_record']['id'])

## Creates a request to leave the matchmaker queue.
func leave_matchmaker_queue(p_matchmaker_ticket: MatchmakerTicket) -> Request:
	var request = _client.rest.rpc('w4online.matchmaker_leave', {
		ticket_id = p_matchmaker_ticket.id,
	})
	return request
