extends Node

# For developers to set from the outside, for example:
#   OnlineMatch.max_players = 8
#   OnlineMatch.client_version = 'v1.2'
#   OnlineMatch.ice_servers = [ ... ]
#   OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.FORCED
var min_players := 2
var max_players := 4
var client_version := 'dev'
var ice_servers = [
	{
	"urls": "stun:161.35.244.122:3478",
	},
	{
	"urls": "turn:161.35.244.122:3478",
	"username": "placeholder",
	"credential": "placeholder",
	},
	{
	"urls": "turn:161.35.244.122:3478?transport=tcp",
	"username": "placeholder",
	"credential": "placeholder",
	},
	{
	"urls": "turns:161.35.244.122:3478?transport=tcp",
	"username": "placeholder",
	"credential": "placeholder",
	},
]

enum NetworkRelay {
	AUTO,
	FORCED,
	DISABLED
}
var use_network_relay: int = NetworkRelay.AUTO

#
# Nakama variables:
#

var _nakama_socket: NakamaSocket
var nakama_socket: NakamaSocket:
	set (value):
		pass
	get:
		return _nakama_socket

var _my_session_id: String
var my_session_id: String:
	set (value):
		pass
	get:
		return get_my_session_id()

var _match_id: String
var match_id: String:
	set (value):
		pass
	get:
		return get_match_id()

var _matchmaker_ticket: String
var matchmaker_ticket: String:
	set (value):
		pass
	get:
		return get_matchmaker_ticket()

# WebRTC variables:
var _webrtc_multiplayer: WebRTCMultiplayerPeer
var _webrtc_peers: Dictionary
var _webrtc_peers_connected: Dictionary

var players: Dictionary
var _next_peer_id: int

enum MatchState {
	LOBBY = 0,
	MATCHING = 1,
	CONNECTING = 2,
	WAITING_FOR_ENOUGH_PLAYERS = 3,
	READY = 4,
	PLAYING = 5,
}
var _match_state: int = MatchState.LOBBY
var match_state: int:
	set (value):
		pass
	get:
		return get_match_state()

enum MatchMode {
	NONE = 0,
	CREATE = 1,
	JOIN = 2,
	MATCHMAKER = 3,
}
var _match_mode: int = MatchMode.NONE
var match_mode: int:
	set (value):
		pass
	get:
		return get_match_mode()

enum WebrtcPlayerStatus {
	CONNECTING = 0,
	CONNECTED = 1,
}

enum MatchOpCode {
	WEBRTC_PEER_METHOD = 9001,
	JOIN_SUCCESS = 9002,
	JOIN_ERROR = 9003,
}

signal error (message)
signal disconnected ()

signal match_created (match_id)
signal match_joined (match_id)
signal matchmaker_matched (players)
signal match_left ()

signal player_joined (player)
signal player_left (player)
signal player_status_changed (player, status)

signal match_ready (players)
signal match_not_ready ()

signal webrtc_peer_added (webrtc_peer, player)
signal webrtc_peer_removed (webrtc_peer, player)

class WebrtcPlayer:
	var session_id: String
	var user_id: String
	var peer_id: int
	var username: String

	func _init(_session_id: String, _user_id: String, _username: String, _peer_id: int) -> void:
		session_id = _session_id
		user_id = _user_id
		username = _username
		peer_id = _peer_id

	static func from_presence(presence, _peer_id: int) -> WebrtcPlayer:
		return WebrtcPlayer.new(presence.session_id, presence.user_id, presence.username, _peer_id)

	static func from_dict(data: Dictionary) -> WebrtcPlayer:
		return WebrtcPlayer.new(data['session_id'], data['user_id'], data['username'], int(data['peer_id']))

	func to_dict() -> Dictionary:
		return {
			session_id = session_id,
			user_id = user_id,
			username = username,
			peer_id = peer_id,
		}

static func serialize_players(_players: Dictionary) -> Dictionary:
	var result := {}
	for key in _players:
		result[key] = _players[key].to_dict()
	return result

static func unserialize_players(_players: Dictionary) -> Dictionary:
	var result := {}
	for key in _players:
		result[key] = WebrtcPlayer.from_dict(_players[key])
	return result


# Load username and credentials for ICE server here
func _ready():
	var ice_username: String = Secrets.get_secret(Secrets.Key.ICE_USERNAME)
	var ice_credential: String = Secrets.get_secret(Secrets.Key.ICE_CREDENTIAL)
	
	for url_section in ice_servers:
		if url_section.has("username"):
			url_section["username"] = ice_username
		
		if url_section.has("credential"):
			url_section["credential"] = ice_credential

	client_version = Config.build_version()


func _set_readonly_variable(_value) -> void:
	pass

func _set_nakama_socket(p_nakama_socket: NakamaSocket) -> void:
	if _nakama_socket == p_nakama_socket:
		return

	if _nakama_socket:
		_nakama_socket.closed.disconnect(self._on_nakama_closed)
		_nakama_socket.received_error.disconnect(self._on_nakama_error)
		_nakama_socket.received_match_state.disconnect(self._on_nakama_match_state)
		_nakama_socket.received_match_presence.disconnect(self._on_nakama_match_presence)
		_nakama_socket.received_matchmaker_matched.disconnect(self._on_nakama_matchmaker_matched)

	_nakama_socket = p_nakama_socket
	if _nakama_socket:
		_nakama_socket.closed.connect(self._on_nakama_closed)
		_nakama_socket.received_error.connect(self._on_nakama_error)
		_nakama_socket.received_match_state.connect(self._on_nakama_match_state)
		_nakama_socket.received_match_presence.connect(self._on_nakama_match_presence)
		_nakama_socket.received_matchmaker_matched.connect(self._on_nakama_matchmaker_matched)


func create_match(p_nakama_socket: NakamaSocket, leave_prev_match: bool = true) -> void:
	print("create_match")
	var close_socket: bool = false
	leave(close_socket, leave_prev_match)
	_set_nakama_socket(p_nakama_socket)
	_match_mode = MatchMode.CREATE

	var data = await _nakama_socket.create_match_async()
	if data.is_exception():
		leave()
		print("Failed to create match")
		error.emit("Failed to create match: " + str(data.get_exception().message))
	else:
		print("create_match success")
		_on_nakama_match_created(data)

func join_match(p_nakama_socket: NakamaSocket, p_match_id: String) -> void:
	leave()
	_set_nakama_socket(p_nakama_socket)
	_match_mode = MatchMode.JOIN

	var data = await _nakama_socket.join_match_async(p_match_id)
	if data.is_exception():
		leave()
		error.emit("Unable to join match")
	else:
		_on_nakama_match_join(data)

func start_matchmaking(p_nakama_socket: NakamaSocket, data: Dictionary = {}) -> void:
	leave()
	_set_nakama_socket(p_nakama_socket)
	_match_mode = MatchMode.MATCHMAKER

	if data.has('min_count'):
		data['min_count'] = max(min_players, data['min_count'])
	else:
		data['min_count'] = min_players

	if data.has('max_count'):
		data['max_count'] = min(max_players, data['max_count'])
	else:
		data['max_count'] = max_players

	if client_version != '':
		if not data.has('string_properties'):
			data['string_properties'] = {}
		data['string_properties']['client_version'] = client_version

		var query = '+properties.client_version:' + client_version
		if data.has('query'):
			data['query'] += ' ' + query
		else:
			data['query'] = query

	_match_state = MatchState.MATCHING
	var result = await _nakama_socket.add_matchmaker_async(data.get('query', '*'), data['min_count'], data['max_count'], data.get('string_properties', {}), data.get('numeric_properties', {}))
	if result.is_exception():
		leave()
		error.emit("Unable to join match making pool")
	else:
		_matchmaker_ticket = result.ticket

func start_playing() -> void:
	assert(_match_state == MatchState.READY)
	_match_state = MatchState.PLAYING

func leave(close_socket: bool = false, leave_match: bool = true) -> void:
	# WebRTC disconnect.
	if _webrtc_multiplayer:
		_webrtc_multiplayer.close()

		var default_peer: OfflineMultiplayerPeer = OfflineMultiplayerPeer.new()
		get_tree().get_multiplayer().set_multiplayer_peer(default_peer)

	# Nakama disconnect.
	if _nakama_socket:
		if _match_id:
			if leave_match:
				await _nakama_socket.leave_match_async(_match_id)
		elif _matchmaker_ticket:
			await _nakama_socket.remove_matchmaker_async(_matchmaker_ticket)
		if close_socket:
			_nakama_socket.close()
			_set_nakama_socket(null)

	# Initialize all the variables to their default state.
	_my_session_id = ''
	_match_id = ''
	_matchmaker_ticket = ''
	_create_webrtc_multiplayer()
	_webrtc_peers = {}
	_webrtc_peers_connected = {}
	players = {}
	_next_peer_id = 1
	_match_state = MatchState.LOBBY
	_match_mode = MatchMode.NONE

	match_left.emit()

func _create_webrtc_multiplayer() -> void:
	if _webrtc_multiplayer:
		_webrtc_multiplayer.peer_connected.disconnect(self._on_webrtc_peer_connected)
		_webrtc_multiplayer.peer_disconnected.disconnect(self._on_webrtc_peer_disconnected)

	_webrtc_multiplayer = WebRTCMultiplayerPeer.new()
	_webrtc_multiplayer.peer_connected.connect(self._on_webrtc_peer_connected)
	_webrtc_multiplayer.peer_disconnected.connect(self._on_webrtc_peer_disconnected)

func get_my_session_id() -> String:
	return _my_session_id

func get_match_id() -> String:
	return _match_id

func get_matchmaker_ticket() -> String:
	return _matchmaker_ticket

func get_match_mode() -> int:
	return _match_mode

func get_match_state() -> int:
	return _match_state

func get_session_id(peer_id: int):
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			return session_id
	return null

func get_player_by_peer_id(peer_id: int) -> WebrtcPlayer:
	var session_id = get_session_id(peer_id)
	if session_id:
		return players[session_id]
	return null

func get_players_by_peer_id() -> Dictionary:
	var result := {}
	for player in players.values():
		result[player.peer_id] = player
	return result

func get_player_names_by_peer_id() -> Dictionary:
	var result := {}
	for session_id in players:
		result[players[session_id]['peer_id']] = players[session_id]['username']
	return result

func get_webrtc_peer(session_id: String) -> WebRTCPeerConnection:
	return _webrtc_peers.get(session_id, null)

func get_webrtc_peer_by_peer_id(peer_id: int) -> WebRTCPeerConnection:
	var player = get_player_by_peer_id(peer_id)
	if player:
		return _webrtc_peers.get(player.session_id, null)
	return null

func _on_nakama_error(data) -> void:
	print ("ERROR:")
	print(data)
	leave()
	error.emit("Websocket connection error")

func _on_nakama_closed() -> void:
	leave()
	disconnected.emit()

func _on_nakama_match_created(data) -> void:
	_match_id = data.match_id
	_my_session_id = data.self_user.session_id
	var my_player = WebrtcPlayer.from_presence(data.self_user, 1)
	players[_my_session_id] = my_player
	_next_peer_id = 2

	_webrtc_multiplayer.create_mesh(1)
	get_tree().get_multiplayer().set_multiplayer_peer(_webrtc_multiplayer)

	match_created.emit(_match_id)
	player_joined.emit(my_player)
	player_status_changed.emit(my_player, WebrtcPlayerStatus.CONNECTED)

func _on_nakama_match_presence(data) -> void:
	for u in data.joins:
		if u.session_id == _my_session_id:
			continue

		if _match_mode == MatchMode.CREATE:
			if _match_state == MatchState.PLAYING:
				# Tell this player that we've already started
				_nakama_socket.send_match_state_async(_match_id, MatchOpCode.JOIN_ERROR, JSON.new().stringify({
					target = u['session_id'],
					reason = 'Sorry! The match has already begun.',
				}))

			if players.size() < max_players:
				var new_player = WebrtcPlayer.from_presence(u, _next_peer_id)
				_next_peer_id += 1
				players[u.session_id] = new_player
				player_joined.emit(new_player)

				# Tell this player (and the others) about all the players peer ids.
				_nakama_socket.send_match_state_async(_match_id, MatchOpCode.JOIN_SUCCESS, JSON.new().stringify({
					players = serialize_players(players),
					client_version = client_version,
				}))

				_webrtc_connect_peer(new_player)
			else:
				# Tell this player that we're full up!
				_nakama_socket.send_match_state_async(_match_id, MatchOpCode.JOIN_ERROR, JSON.new().stringify({
					target = u['session_id'],
					reason = 'Sorry! The match is full.,',
				}))
		elif _match_mode == MatchMode.MATCHMAKER:
			player_joined.emit(players[u.session_id])
			_webrtc_connect_peer(players[u.session_id])

	for u in data.leaves:
		if u.session_id == _my_session_id:
			continue
		if not players.has(u.session_id):
			continue

		var player = players[u.session_id]
		_webrtc_disconnect_peer(player)

		# If the host disconnects, this is the end!
		if player.peer_id == 1:
			leave()
			error.emit("Host has disconnected")
		else:
			players.erase(u.session_id)
			player_left.emit(player)

			if players.size() < min_players:
				# If state was previously ready, but this brings us below the minimum players,
				# then we aren't ready anymore.
				if _match_state == MatchState.READY:
					_match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS
					match_not_ready.emit()
			else:
				# If the remaining players are all fully connected, then set
				# the match state to ready.
				if _webrtc_peers_connected.size() == players.size() - 1:
					_match_state = MatchState.READY;
					match_ready.emit(players)

func _on_nakama_match_join(data) -> void:
	_match_id = data.match_id
	_my_session_id = data.self_user.session_id

	if _match_mode == MatchMode.JOIN:
		match_joined.emit(_match_id)
	elif _match_mode == MatchMode.MATCHMAKER:
		for u in data.presences:
			if u.session_id == _my_session_id:
					continue
			_webrtc_connect_peer(players[u.session_id])

func _on_nakama_matchmaker_matched(data) -> void:
	if data.is_exception():
		leave()
		error.emit("Matchmaker error")
		return

	_my_session_id = data.self_user.presence.session_id

	# Use the list of users to assign peer ids.
	for u in data.users:
		players[u.presence.session_id] = WebrtcPlayer.from_presence(u.presence, 0)
	var session_ids = players.keys();
	session_ids.sort()
	for session_id in session_ids:
		players[session_id].peer_id = _next_peer_id
		_next_peer_id += 1

	# Initialize multiplayer using our peer id
	_webrtc_multiplayer.create_mesh(players[_my_session_id].peer_id)
	get_tree().get_multiplayer().multiplayer_peer = _webrtc_multiplayer

	matchmaker_matched.emit(players)
	player_status_changed.emit(players[_my_session_id], WebrtcPlayerStatus.CONNECTED)

	# Join the match.
	var result = await _nakama_socket.join_matched_async(data)
	if result.is_exception():
		leave()
		error.emit("Unable to join match")
	else:
		_on_nakama_match_join(result)

func _on_nakama_match_state(data) -> void:
	var json = JSON.new()
	if json.parse(data.data) != OK:
		return

	var content = json.get_data()
	if data.op_code == MatchOpCode.WEBRTC_PEER_METHOD:
		if content['target'] == _my_session_id:
			var session_id = data.presence.session_id
			if not _webrtc_peers.has(session_id):
				return
			var webrtc_peer = _webrtc_peers[session_id]
			match content['method']:
				'set_remote_description':
					webrtc_peer.set_remote_description(content['type'], content['sdp'])

				'add_ice_candidate':
					if _webrtc_check_ice_candidate(content['name']):
						#print ("Receiving ice candidate: %s" % content['name'])
						webrtc_peer.add_ice_candidate(content['media'], content['index'], content['name'])

				'reconnect':
					_webrtc_multiplayer.remove_peer(players[session_id]['peer_id'])
					_webrtc_reconnect_peer(players[session_id])
	if data.op_code == MatchOpCode.JOIN_SUCCESS && _match_mode == MatchMode.JOIN:
		var host_client_version = content.get('client_version', '')
		if client_version != host_client_version:
			leave()
			error.emit("Client version doesn't match host")
			return

		var content_players = unserialize_players(content['players'])

		_webrtc_multiplayer.create_mesh(content_players[_my_session_id].peer_id)
		get_tree().get_multiplayer().set_multiplayer_peer(_webrtc_multiplayer)

		for session_id in content_players:
			if not players.has(session_id):
				players[session_id] = content_players[session_id]
				_webrtc_connect_peer(players[session_id])
				player_joined.emit(players[session_id])
				if session_id == _my_session_id:
					player_status_changed.emit(players[session_id], WebrtcPlayerStatus.CONNECTED)
	if data.op_code == MatchOpCode.JOIN_ERROR:
		if content['target'] == _my_session_id:
			leave()
			error.emit(content['reason'])
			return

func _webrtc_connect_peer(player: WebrtcPlayer) -> void:
	# Don't add the same peer twice!
	if _webrtc_peers.has(player.session_id):
		return

	# If the match was previously ready, then we need to switch back to not ready.
	if _match_state == MatchState.READY:
		match_not_ready.emit()

	# If we're already PLAYING, then this is a reconnect attempt, so don't mess with the state.
	# Otherwise, change state to CONNECTING because we're trying to connect to all peers.
	if _match_state != MatchState.PLAYING:
		_match_state = MatchState.CONNECTING

	var webrtc_peer := WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": ice_servers,
	})
	webrtc_peer.session_description_created.connect(self._on_webrtc_peer_session_description_created.bind(player.session_id))
	webrtc_peer.ice_candidate_created.connect(self._on_webrtc_peer_ice_candidate_created.bind(player.session_id))

	_webrtc_peers[player.session_id] = webrtc_peer

	#get_tree().multiplayer._del_peer(u['peer_id'])
	_webrtc_multiplayer.add_peer(webrtc_peer, player.peer_id, 0)

	webrtc_peer_added.emit(webrtc_peer, player)

	if _my_session_id.casecmp_to(player.session_id) < 0:
		var result = webrtc_peer.create_offer()
		if result != OK:
			error.emit("Unable to create WebRTC offer")

func _webrtc_disconnect_peer(player: WebrtcPlayer) -> void:
	var webrtc_peer = _webrtc_peers[player.session_id]
	webrtc_peer_removed.emit(webrtc_peer, player)
	webrtc_peer.close()
	_webrtc_peers.erase(player.session_id)
	_webrtc_peers_connected.erase(player.session_id)

func _webrtc_reconnect_peer(player: WebrtcPlayer) -> void:
	var old_webrtc_peer = _webrtc_peers[player.session_id]
	if old_webrtc_peer:
		webrtc_peer_removed.emit(old_webrtc_peer, player)
		old_webrtc_peer.close()

	_webrtc_peers_connected.erase(player.session_id)
	_webrtc_peers.erase(player.session_id)

	print ("Starting WebRTC reconnect...")

	_webrtc_connect_peer(player)

	player_status_changed.emit(player, WebrtcPlayerStatus.CONNECTING)

	if _match_state == MatchState.READY:
		_match_state = MatchState.CONNECTING
		match_not_ready.emit()

func _webrtc_check_ice_candidate(name: String) -> bool:
	if use_network_relay == NetworkRelay.AUTO:
		return true

	var is_relay: bool = "typ relay" in name

	if use_network_relay == NetworkRelay.FORCED:
		return is_relay
	return !is_relay

func _on_webrtc_peer_session_description_created(type: String, sdp: String, session_id: String) -> void:
	var webrtc_peer = _webrtc_peers[session_id]
	webrtc_peer.set_local_description(type, sdp)

	# Send this data to the peer so they can call call .set_remote_description().
	_nakama_socket.send_match_state_async(_match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.new().stringify({
		method = "set_remote_description",
		target = session_id,
		type = type,
		sdp = sdp,
	}))

func _on_webrtc_peer_ice_candidate_created(media: String, index: int, name: String, session_id: String) -> void:
	if not _webrtc_check_ice_candidate(name):
		return

	#print ("Sending ice candidate: %s" % name)

	# Send this data to the peer so they can call .add_ice_candidate()
	_nakama_socket.send_match_state_async(_match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.new().stringify({
		method = "add_ice_candidate",
		target = session_id,
		media = media,
		index = index,
		name = name,
	}))

func _on_webrtc_peer_connected(peer_id: int) -> void:
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			_webrtc_peers_connected[session_id] = true
			print ("WebRTC peer connected: " + str(peer_id))
			player_status_changed.emit(players[session_id], WebrtcPlayerStatus.CONNECTED)

	# We have a WebRTC peer for each connection to another player, so we'll have one less than
	# the number of players (ie. no peer connection to ourselves).
	if _webrtc_peers_connected.size() == players.size() - 1:
		if players.size() >= min_players:
			# All our peers are good, so we can assume RPC will work now.
			_match_state = MatchState.READY;
			emit_signal("match_ready", players)
		else:
			_match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS

func _on_webrtc_peer_disconnected(peer_id: int) -> void:
	print ("WebRTC peer disconnected: " + str(peer_id))

	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			# We initiate the reconnection process from only one side (the offer side).
			if _my_session_id.casecmp_to(session_id) < 0:
				# Tell the remote peer to restart their connection.
				_nakama_socket.send_match_state_async(_match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.new().stringify({
					method = "reconnect",
					target = session_id,
				}))

				# Initiate reconnect on our end now (the other end will do it when they receive
				# the message above).
				_webrtc_reconnect_peer(players[session_id])
