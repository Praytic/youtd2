## Manages WebRTC connections for WebRTC lobbies.
extends RefCounted

const SupabaseClient = preload("../supabase/client.gd")
const Parser = preload("../supabase/poly_result.gd")
const PolyResult = Parser.PolyResult
const Promise = preload("../rest-client/client_promise.gd")
const Request = preload("../rest-client/client_request.gd")

## The multiplayer peer that was created for this lobby.
var webrtc_multiplayer_peer: WebRTCMultiplayerPeer
## The ICE servers used to help the peers connect.
var ice_servers := []

## Used internally by [res://addons/w4gd/matchmaker/webrtc_manager.gd] to track WebRTC sessions.
class Session extends RefCounted:
	var session_id: String
	var player_id: String
	var peer_id: int
	var peer: WebRTCPeerConnection
	var is_source: bool

	var candidate_send_queue := []
	var candidate_receive_queue := []

	func _init(p_session_id: String, p_player_id: String, p_peer_id: int, p_peer: WebRTCPeerConnection, p_is_source: bool):
		session_id = p_session_id
		player_id = p_player_id
		peer_id = p_peer_id
		peer = p_peer
		is_source = p_is_source

	func send_candidate_queued(p_media: String, p_index: int, p_name: String) -> void:
		candidate_send_queue.push_back({
			media = p_media,
			index = p_index,
			name = p_name,
		})

	func receive_candidate_queued(p_media: String, p_index: int, p_name: String) -> void:
		candidate_receive_queue.push_back({
			media = p_media,
			index = p_index,
			name = p_name,
		})

var _lobby_id: String
var _my_peer_id: int
var _sessions := {}
var _sessions_by_peer := {}
var _peers_ready: bool
var _realtime_webrtc_channel

var _client: SupabaseClient

## Emitted when the WebRTC mesh is created.
signal mesh_created (multiplayer_peer)
## Emitted when connections to all WebRTC peers have been established.
signal peers_ready ()
## Emitted when one or more of the WebRTC peers is no longer connected, or a new peer has joined that we haven't connected to yet.
signal peers_not_ready ()

## Creates a new WebRTC manager.
func _init(p_client: SupabaseClient, p_lobby_id: String, p_ice_servers: Array, p_subscribe: bool = true):
	_client = p_client
	_lobby_id = p_lobby_id
	ice_servers = p_ice_servers

	reset()

	if p_subscribe:
		subscribe()

func subscribe() -> void:
	if not _realtime_webrtc_channel:
		_realtime_webrtc_channel = _client.realtime.channel('matchmaker_webrtc_session_' + _lobby_id.replace('-', '_'))
		_realtime_webrtc_channel.on_postgres_changes('*', 'w4online.webrtc_session', 'lobby_id=eq.' + _lobby_id)
		_realtime_webrtc_channel.inserted.connect(self._on_webrtc_session_change)
		_realtime_webrtc_channel.updated.connect(self._on_webrtc_session_change)
		_realtime_webrtc_channel.subscribe()

func unsubscribe() -> void:
	if _realtime_webrtc_channel:
		_realtime_webrtc_channel.unsubscribe()
		_realtime_webrtc_channel = null

## Resets the WebRTC manager, closing the multiplayer peer, and clearing all sessions.
func reset() -> void:
	for session in _sessions.values():
		session.peer.session_description_created.disconnect(_on_peer_session_description_created.bind(session.peer_id))
		session.peer.ice_candidate_created.disconnect(_on_peer_ice_candidate_created.bind(session.peer_id))

	if webrtc_multiplayer_peer != null:
		webrtc_multiplayer_peer.close()
		webrtc_multiplayer_peer = null

	webrtc_multiplayer_peer = WebRTCMultiplayerPeer.new()
	_my_peer_id = 0
	_sessions.clear()
	_sessions_by_peer.clear()
	_peers_ready = false

## Gets the UUID of the player in the database for the given peer id.
func get_player_id_for_peer(peer_id: int) -> String:
	return _sessions_by_peer[peer_id].player_id

## Gets the peer id of the player for the given player UUID.
func get_peer_id_for_player(player_id: String) -> int:
	for session_id in _sessions:
		var session = _sessions[session_id]
		if session.player_id == player_id:
			return session.peer_id
	return 0

## Gets the number of peers.
func get_peer_count() -> int:
	return _sessions.size()

## Returns true if all peers are ready; otherwise, false.
func are_peers_ready() -> bool:
	return _peers_ready

## Rechecks if the peers are all ready and emits the [signal peers_ready] or [signal peers_not_ready] signal.
func poll() -> void:
	var new_peers_ready := _check_peers_ready()
	if new_peers_ready != _peers_ready:
		_peers_ready = new_peers_ready
		if _peers_ready:
			peers_ready.emit()
		else:
			peers_not_ready.emit()

func _check_peers_ready() -> bool:
	if webrtc_multiplayer_peer == null:
		return false
	if _sessions.size() == 0:
		return false

	for session_id in _sessions:
		var peer: WebRTCPeerConnection = _sessions[session_id].peer
		if peer.poll() != OK:
			return false
		if peer.get_connection_state() != WebRTCPeerConnection.STATE_CONNECTED:
			return false

	return true

## Refreshes the WebRTC sessions based on the sessions in the database.
func refresh_sessions() -> Request:
	var request = _client.rest.rpc("w4online.webrtc_sessions_for_player", {
		lobby_id = _lobby_id,
		player_id = _client.get_identity().get_uid(),
	})

	var handle_result = func(result):
		if result.is_error():
			return result
		for record in result.sessions.as_array():
			if not record['id'] in _sessions:
				_create_session(record)
		return PolyResult.new()

	return request.then(handle_result)

func _on_webrtc_session_change(p_data) -> void:
	if p_data['type'] == 'INSERT':
		_create_session(p_data['record'])
	elif p_data['type'] == 'UPDATE':
		_process_session_updates(p_data['old_record'], p_data['record'])

func _create_session(record: Dictionary) -> void:
	var session_id = record['id']
	var my_player_id = _client.get_identity().get_uid()
	var my_peer_id: int
	var other_player_id: String
	var other_peer_id: int
	var is_source := false

	if record['source_player_id'] == my_player_id:
		my_peer_id = record['source_peer_id']
		other_player_id = record['target_player_id']
		other_peer_id = record['target_peer_id']
		is_source = true
	else:
		my_peer_id = record['target_peer_id']
		other_player_id = record['source_player_id']
		other_peer_id = record['source_peer_id']

	if _my_peer_id != 0 and _my_peer_id != my_peer_id:
		reset()
	if _my_peer_id == 0:
		_my_peer_id = my_peer_id
		webrtc_multiplayer_peer.create_mesh(my_peer_id)
		_emit_mesh_created.call_deferred()

	var peer = WebRTCPeerConnection.new()
	peer.initialize({ iceServers = ice_servers })
	peer.session_description_created.connect(_on_peer_session_description_created.bind(other_peer_id))
	peer.ice_candidate_created.connect(_on_peer_ice_candidate_created.bind(other_peer_id))
	webrtc_multiplayer_peer.add_peer(peer, other_peer_id)

	var session := Session.new(record['id'], other_player_id, other_peer_id, peer, is_source)
	_sessions[session_id] = session
	_sessions_by_peer[other_peer_id] = session

	if is_source:
		peer.create_offer()

func _emit_mesh_created():
	mesh_created.emit(webrtc_multiplayer_peer)

func _process_session_updates(old_record: Dictionary, new_record: Dictionary) -> void:
	if not _sessions.has(new_record['id']):
		return
	var session = _sessions[new_record['id']]

	# Handle a change to offer or answer.
	var dk = 'answer' if session.is_source else 'offer'
	if new_record[dk] != null and (old_record[dk] == null or old_record[dk].hash() != new_record[dk].hash()):
		session.peer.set_remote_description(new_record[dk]['type'], new_record[dk]['sdp'])
		# If we have any queued received candidates, it's safe to add them now.
		if session.candidate_receive_queue.size() > 0:
			for candidate in session.candidate_receive_queue:
				session.peer.add_ice_candidate(candidate['media'], candidate['index'], candidate['name'])
			session.candidate_receive_queue.clear()

	# Handle changes to candidates.
	var ck = 'target_candidates' if session.is_source else 'source_candidates'
	if new_record[ck].size() > old_record[ck].size():
		for i in range(old_record[ck].size(), new_record[ck].size()):
			var candidate: Dictionary = new_record[ck][i]
			# If we don't have the offer/answer from the other peer yet, then we
			# need to queue these up for later.
			if new_record[dk] == null:
				session.receive_candidate_queued(candidate['media'], candidate['index'], candidate['name'])
			else:
				session.peer.add_ice_candidate(candidate['media'], candidate['index'], candidate['name'])

func _on_peer_session_description_created(p_type: String, p_sdp: String, p_peer_id: int) -> void:
	if not _sessions_by_peer.has(p_peer_id):
		return

	var session: Session = _sessions_by_peer[p_peer_id]
	session.peer.set_local_description(p_type, p_sdp)

	var description = {
		type = p_type,
		sdp = p_sdp,
	}
	var result

	if session.is_source:
		result = await _client.rest.rpc('w4online.webrtc_create_offer', {
			session_id = session.session_id,
			offer = description,
		}).async()
	else:
		result = await _client.rest.rpc('w4online.webrtc_create_answer', {
			session_id = session.session_id,
			answer = description,
		}).async()

	if result.is_error() or not result.success.as_bool():
		print ("Unable to create offer or answer: ", str(result))

func _on_peer_ice_candidate_created(p_media: String, p_index: int, p_name: String, p_peer_id: int) -> void:
	if not _sessions_by_peer.has(p_peer_id):
		return

	var session: Session = _sessions_by_peer[p_peer_id]

	session.send_candidate_queued(p_media, p_index, p_name)
	if session.candidate_send_queue.size() == 1:
		call_deferred('_send_queued_candidates', p_peer_id)

func _send_queued_candidates(p_peer_id: int) -> void:
	if not _sessions_by_peer.has(p_peer_id):
		return

	var session: Session = _sessions_by_peer[p_peer_id]
	if session.candidate_send_queue.size() == 0:
		return

	var data := {
		session_id = session.session_id,
		candidates = session.candidate_send_queue.duplicate(),
	}
	session.candidate_send_queue.clear()

	var result = await _client.rest.rpc('w4online.webrtc_add_candidates', data).async()

	if result.is_error() or not result.success.as_bool():
		# Re-queue the candidates that we failed to send
		session.candidate_send_queue.append_array(data['candidates'])
		call_deferred('_send_queued_candidates', p_peer_id)
