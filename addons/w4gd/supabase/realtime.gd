## Client for the Supabase realtime API.
extends RefCounted

enum SendEvent {REPLY, CLOSE, ERROR, JOIN, LEAVE, HEARTBEAT}
enum RecvEvent {REPLY, CLOSE, SYSTEM, INSERT, UPDATE, DELETE, BROADCAST, PRESENCE_STATE, PRESENCE_DIFF, POSTGRES_CHANGES}

## According to Phoenix realtime server specifications.
const _SEND_EVENT_NAMES = {
	SendEvent.REPLY: "phx_reply",
	SendEvent.CLOSE: "phx_close",
	SendEvent.ERROR: "phx_error",
	SendEvent.JOIN: "phx_join",
	SendEvent.LEAVE: "phx_leave",
	SendEvent.HEARTBEAT: "heartbeat",
}

const _REPLY_EVENT_NAME_MAP = {
	"phx_reply": RecvEvent.REPLY,
	"phx_close": RecvEvent.CLOSE,
	"system": RecvEvent.SYSTEM,
	"INSERT": RecvEvent.INSERT,
	"UPDATE": RecvEvent.UPDATE,
	"DELETE": RecvEvent.DELETE,
	"broadcast": RecvEvent.BROADCAST,
	"presence_state": RecvEvent.PRESENCE_STATE,
	"presence_diff": RecvEvent.PRESENCE_DIFF,
	"postgres_changes": RecvEvent.POSTGRES_CHANGES,
}

const _PHOENIX_CHANNEL = "phoenix"
const _HEARTBEAT_TIME = 5000


## Interal class to track responses.
class Response:
	signal received(result)


## Represents a subscription or potential subscription to a realtime channel.
class Subscription:
	## Emitted when data is inserted to one of the Postgres tables we are watching.
	signal inserted(p_data)
	## Emitted when data is updated on one of the Postgres tables we are watching.
	signal updated(p_data)
	## Emitted when data is deleted from one of the Postgres tables we are watching.
	signal deleted(p_data)
	## Emitted when a system message is received.
	signal received_system_message(p_data)
	## Emitted when a broadcast message is received.
	signal received_broadcast(p_data)
	## Emitted when presence data is received.
	signal received_presence(p_event, p_data)
	## Emitted after we've successfully subscribed.
	signal subscribed()
	## Emitted after we've successfully unsubscribed.
	signal unsubscribed()

	## The name of the channel.
	var name : String
	## Configuration passed to Supabase when subscribing.
	var config := {}

	var _sub_unsub_func : Callable
	var _send_func : Callable
	var _get_presence_func : Callable
	var _subscribed_once := false
	var _broadcast_counter := 0

	func _init(p_name, p_config: Dictionary, p_sub_unsub_func: Callable, p_send_func: Callable, p_get_presence_func: Callable):
		name = p_name
		config = p_config
		_sub_unsub_func = p_sub_unsub_func
		_send_func = p_send_func
		_get_presence_func = p_get_presence_func


	## Subscribes to the channel.
	func subscribe() -> int:
		if _sub_unsub_func.is_valid():
			var ret = await _sub_unsub_func.call(self, true, {config = config})
			if ret == OK:
				_subscribed_once = true
			return ret
		push_error("Cannot subscribe, the socket has gone away...")
		return FAILED


	## Unsubscribes from the channel.
	func unsubscribe() -> int:
		if _sub_unsub_func.is_valid():
			var ret = await _sub_unsub_func.call(self, false)
			_subscribed_once = false
			return ret
		push_error("Cannot unsubscribe, the socket has gone away...")
		return FAILED


	## Adds to the subscription configuration, requesting that we receive updates related to the given Postgres table.
	##
	## To have any effect, this must be called before [method subscribe].
	##
	## [param p_event] should be one of: `'*'`, `'INSERT'`, `'UPDATE'`, or `'DELETE'`
	##
	## [param p_table] will refer to a table on the 'public' schema, unless give a fully qualified table name (ex. 'schema.table_name').
	##
	## [param p_filter] is a special string specifying the column, operator and value to filter on. For example, `'body=eq.hey'` will
	## filter for rows where the 'body' column equals 'hey'. For more information, see the Supabase docs:
	## https://supabase.com/docs/guides/realtime/postgres-changes#filter-changes
	func on_postgres_changes(p_event: String, p_table: String, p_filter: String = '') -> void:
		if _subscribed_once:
			push_error("Do not call on_postgres_changes() after calling subscribe() - it has no effect")
			return

		var schema: String
		var table: String

		var table_parts = p_table.split('.')
		if table_parts.size() == 1:
			schema = 'public'
			table = p_table
		else:
			schema = table_parts[0]
			table = table_parts[1]

		var info = {
			event = p_event,
			schema = schema,
			table = table
		}
		if p_filter != '':
			info['filter'] = p_filter

		if not config.has('postgres_changes'):
			config['postgres_changes'] = []
		config['postgres_changes'].push_back(info)


	## Gets the current presence state on this channel.
	func get_presence_state() -> Dictionary:
		if _get_presence_func.is_valid():
			return _get_presence_func.call(name)
		return {}


	## Sends an arbitrary event on this channel.
	##
	## [param p_type] must be one of [code]'broadcast'[/code] or [code]'presence'[/code].
	##
	## [param p_event] must be one of [code]'track'[/code] or [code]'untrack'[/code] when [param p_type] is [code]'presence'[/code],
	## or can be any arbitrary string when [param p_type] is [code]'broadcast'[/code].
	func send(p_type: String, p_event: String, p_payload = null, p_ref = null, await_response := false) -> int:
		var payload := {
			event = p_event,
		}
		if p_payload is Dictionary:
			payload.merge(p_payload)

		return await _send_func.call(name, p_type, payload, p_ref, await_response)


	## Tracks the given data as the presence state for the current user on this channel.
	func track(p_data: Dictionary) -> void:
		send('presence', 'track', { payload = p_data })


	## Removes the presence state for the current user on this channel.
	func untrack() -> void:
		send('presence', 'untrack')


	## Sends a broadcast message to all other users on this channel.
	func broadcast(p_event: String, p_payload: Dictionary) -> int:
		_broadcast_counter += 1
		var ref: String = ":".join(['broadcast', get_instance_id(), _broadcast_counter])
		var await_response = config.has('broadcast') and config['broadcast'] is Dictionary and config['broadcast'].get('ack', false)
		return await send('broadcast', p_event, p_payload, ref, await_response)


	func _to_string():
		return "Subscription<name=%s>" % name


## Internal class for sending or receiving data on all subscriptions on a given channel.
class ChannelProxy:

	enum Status {NEW, OPENING, OPEN, CLOSING, CLOSED}
	enum SignalIndex {INSERTED, UPDATED, DELETED, RECEIVED_SYSTEM_MESSAGE, RECEIVED_BROADCAST, RECEIVED_PRESENCE, SUBSCRIBED, UNSUBSCRIBED}

	signal join_result (result)

	var name : String
	var status : int = Status.NEW
	var subscriptions := {}
	var join_payload := {}
	var presence_state := {}

	func _init(p_name, p_join_payload):
		name = p_name
		join_payload = p_join_payload


	func add_subscription(p_base):
		var id = p_base.get_instance_id()
		if id in subscriptions:
			push_error("Already subscribed! ", p_base)
			return
		subscriptions[id] = [
			p_base.inserted,
			p_base.updated,
			p_base.deleted,
			p_base.received_system_message,
			p_base.received_broadcast,
			p_base.received_presence,
			p_base.subscribed,
			p_base.unsubscribed,
		]


	func remove_subscription(p_base):
		var id = p_base.get_instance_id()
		if id not in subscriptions:
			push_error("Unable to remove subscrition. Not subscribed. ", p_base)
		subscriptions.erase(id)


	func _each_signal(p_sig: SignalIndex, p_callable: Callable) -> void:
		for id in subscriptions:
			if is_instance_id_valid(id):
				p_callable.call(subscriptions[id][p_sig])


	func poll():
		var rm := []
		for id in subscriptions:
			if not is_instance_id_valid(id):
				rm.append(id)
		for id in rm:
			subscriptions.erase(id)


	func parse_event(p_event: int, p_payload: Dictionary):
		# Convert realtime v2 POSTGRES_CHANGES event into the v1 versions.
		if p_event == RecvEvent.POSTGRES_CHANGES:
			if 'data' in p_payload:
				var data = p_payload['data']
				if 'type' in data:
					var type = data['type']
					if type in _REPLY_EVENT_NAME_MAP:
						p_event = _REPLY_EVENT_NAME_MAP[type]
						p_payload = data

		match p_event:
			RecvEvent.INSERT:
				_each_signal(SignalIndex.INSERTED, func (sig): sig.emit(p_payload))
			RecvEvent.UPDATE:
				_each_signal(SignalIndex.UPDATED, func (sig): sig.emit(p_payload))
			RecvEvent.DELETE:
				_each_signal(SignalIndex.DELETED, func (sig): sig.emit(p_payload))
			RecvEvent.SYSTEM:
				_each_signal(SignalIndex.RECEIVED_SYSTEM_MESSAGE, func (sig): sig.emit(p_payload))
			RecvEvent.BROADCAST:
				_each_signal(SignalIndex.RECEIVED_BROADCAST, func (sig): sig.emit(p_payload))
			RecvEvent.PRESENCE_STATE:
				_sync_presence_state(_transform_presence(p_payload))
			RecvEvent.PRESENCE_DIFF:
				_sync_presence_diff(_transform_presence(p_payload['joins']), _transform_presence(p_payload['leaves']))
			RecvEvent.REPLY:
				if status == Status.OPENING:
					var result = OK if p_payload.get('status') == 'ok' else FAILED
					if result == OK:
						status = Status.OPEN
						_each_signal(SignalIndex.SUBSCRIBED, func (sig): sig.emit())
					join_result.emit(result)
			RecvEvent.CLOSE:
				_each_signal(SignalIndex.UNSUBSCRIBED, func (sig): sig.emit())
				if subscriptions.size():
					# Wants to be reopened
					status = Status.NEW
				else:
					status = Status.CLOSED
			_:
				push_error("Got an unexpected message: ", p_event, " - ", p_payload)


	func _transform_presence(p_raw_state: Dictionary) -> Dictionary:
		var state := {}
		for key in p_raw_state:
			var values = p_raw_state[key]
			if not 'metas' in values:
				continue
			var metas = values['metas']

			state[key] = []
			for meta in metas:
				var presence = meta.duplicate(true)
				presence['presence_ref'] = presence['phx_ref']
				presence.erase('phx_ref')
				presence.erase('phx_ref_prev')
				state[key].push_back(presence)
		return state

	func _sync_presence_state(p_new_state) -> void:
		var leaves := {}
		for key in presence_state:
			if not key in p_new_state:
				leaves[key] = presence_state[key]

		var joins := {}
		for key in p_new_state:
			if not key in presence_state:
				joins[key] = p_new_state[key]

		if leaves.size() > 0:
			_each_signal(SignalIndex.RECEIVED_PRESENCE, func (sig): sig.emit('leave', leaves))
		if joins.size() > 0:
			_each_signal(SignalIndex.RECEIVED_PRESENCE, func (sig): sig.emit('join', joins))
		_each_signal(SignalIndex.RECEIVED_PRESENCE, func (sig): sig.emit('sync', p_new_state))
		presence_state = p_new_state

	func _sync_presence_diff(p_joins, p_leaves) -> void:
		var new_state: Dictionary = presence_state.duplicate(true)

		for key in p_joins:
			if not key in new_state:
				new_state[key] = []
			var refs_already_joined: Array = new_state[key].map(func(x): return x['presence_ref'])
			for presence in p_joins[key]:
				if not presence['presence_ref'] in refs_already_joined:
					new_state[key].push_back(presence)

		for key in p_leaves:
			var refs_to_remove: Array = p_leaves[key].map(func(x): return x['presence_ref'])
			new_state[key] = new_state[key].filter(func(x): return not x['presence_ref'] in refs_to_remove)
			if new_state[key].size() == 0:
				new_state.erase(key)

		if p_leaves.size() > 0:
			_each_signal(SignalIndex.RECEIVED_PRESENCE, func (sig): sig.emit('leave', p_leaves))
		if p_joins.size() > 0:
			_each_signal(SignalIndex.RECEIVED_PRESENCE, func (sig): sig.emit('join', p_joins))
		_each_signal(SignalIndex.RECEIVED_PRESENCE, func (sig): sig.emit('sync', new_state))
		presence_state = new_state


## Emitted after we've successfully connected to Supabase realtime.
signal connection_succeded()
## Emitted after our connection to Supabase realtime has closed.
signal connection_closed()
## Emitted after there's been an error connecting to Supabase realtime.
signal connection_error()

var _ws = WebSocketPeer.new()
var _ws_last_state := WebSocketPeer.STATE_CLOSED
var _identity = null
var _endpoint := ""
var _tls_options : TLSOptions = null
var _last_heartbeat := 0
var _json := JSON.new()
var _topics := {}
var _poll_timer := Timer.new()
var _closing := false
var _responses := {}

func _init(p_node: Node, p_url: String, p_identity, p_tls_options: TLSOptions = null):
	_identity = p_identity
	_endpoint = p_url
	_tls_options = p_tls_options
	_poll_timer.autostart = true
	_poll_timer.wait_time = 0.001 # won't be less then process time in any case.
	_poll_timer.timeout.connect(poll)
	p_node.add_child(_poll_timer)
	_identity.identity_changed.connect(self._reset_topic_states)


## Connect to Supabase realtime via WebSockets.
func connect_socket():
	_closing = false
	var url = "%s?token=%s&apikey=%s&vsn=1.0.0" % [
		_endpoint,
		_identity.get_access_token(),
		_identity.get_api_key()
	]
	var err = _ws.connect_to_url(url, _tls_options)
	if err != OK:
		return false
	return true


## Disconnect from WebSocket to Supabase realtime.
func disconnect_socket(p_clear:=false):
	_closing = true
	_ws.close(1001)
	if p_clear:
		_topics.clear()


## Creates a Subscription object for the given channel.
##
## You must call [method "addons/w4gd/supabase/realtime.gd".Subscription.subscribe] in order to actually subscribe.
##
## Here's some examples of [param p_config]:
##
## - Postgres changes: [code]{ postgres_changes = [{ event = '...', schema = '...', table = '...', filter = '...'}]}[/code]
## - Self-send broadcast messages or receive acknowledgements: [code]{ broadcast = { 'self': true, 'ack': true }}[/code]
## - Change presence key: [code]{ presence = { key = 'userId-1' }}[/code]
##
## This can all be combined if necessary.
func channel(p_channel: String, p_config := {}) -> Subscription:
	return Subscription.new("realtime:" + p_channel, p_config, _sub_unsub, _send_msg, _get_presence_state)


## Polls the WebSocket to receive new data.
##
## This should be called automatically every frame.
func poll():
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_ws.poll()
	var state = _ws.get_ready_state()
	if _ws_last_state != state:
		_ws_last_state = state
		if state == WebSocketPeer.STATE_OPEN:
			_connected(_ws.get_selected_protocol())
		elif state == WebSocketPeer.STATE_CLOSING:
			pass # We are closing the connection, just keep polling
		elif state == WebSocketPeer.STATE_CLOSED:
			_connection_closed(_ws.get_close_code() != -1)
	while _ws.get_ready_state() == WebSocketPeer.STATE_OPEN and _ws.get_available_packet_count():
		_data_received(_ws.get_packet().get_string_from_utf8())

	if _closing or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	if Time.get_ticks_msec() - _last_heartbeat > _HEARTBEAT_TIME:
		var err = await _send_std_msg(_PHOENIX_CHANNEL, SendEvent.HEARTBEAT)
		if err != OK:
			push_error("Error sending heartbeat")
		_last_heartbeat = Time.get_ticks_msec()
	# Remove closed subscriptions
	var rm = []
	for k in _topics:
		var topic = _topics[k]
		topic.poll()
		if topic.status == ChannelProxy.Status.NEW:
			_send_std_msg(topic.name, SendEvent.JOIN, topic.join_payload, topic.get_instance_id())
			topic.status = ChannelProxy.Status.OPENING
		elif topic.status == ChannelProxy.Status.CLOSED:
			rm.append(k)
		elif topic.status == ChannelProxy.Status.OPEN and topic.subscriptions.size() == 0:
			topic.status = ChannelProxy.Status.CLOSING
			_send_std_msg(topic.name, SendEvent.LEAVE, null, topic.get_instance_id())
	for k in rm:
		_topics.erase(k)


func _reset_topic_states():
	for t in _topics.values():
		t.status = ChannelProxy.Status.NEW


func _data_received(msg):
	_last_heartbeat = Time.get_ticks_msec()
	var err = _json.parse(msg)
	if err != OK:
		push_error("Error decoding message. ", msg)
		return
	var data = _json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Error decoding message. Invalid type. ", data)
		return
	_parse_message(data)


func _sub_unsub(p_ref: Subscription, p_sub, p_payload = null):
	var topic_name = p_ref.name
	if p_sub:
		var topic = _topics.get(topic_name)
		if topic == null:
			topic = ChannelProxy.new(topic_name, p_payload)
			_topics[topic_name] = topic

		topic.add_subscription(p_ref)

		var ret = FAILED
		if topic.status in [ChannelProxy.Status.NEW, ChannelProxy.Status.OPENING]:
			ret = await topic.join_result
		elif topic.status == ChannelProxy.Status.OPEN:
			# This topic was already open!
			ret = OK
			# Show developer error if the config doesn't match.
			if p_payload.hash() != topic.join_payload.hash():
				push_error("Realtime subscription config doesn't match config on already open channel")
			# Emit 'subscribed' signal so it works the same as when newly connecting.
			p_ref.subscribed.emit()

		if ret != OK:
			push_error("Failed to add subscription %s" % topic_name)
			topic.remove_subscription(p_ref)
		return ret
	else:
		if topic_name not in _topics:
			push_error("Topic not active ", p_ref)
			return FAILED
		_topics[topic_name].remove_subscription(p_ref)
	return OK


func _parse_message(p_data: Dictionary):
	if not "event" in p_data or p_data["event"] not in _REPLY_EVENT_NAME_MAP:
		push_error("Error decoding message. Invalid data: ", p_data)
		return
	var event = _REPLY_EVENT_NAME_MAP[p_data["event"]]
	var ref_id = p_data["ref"]
	var topic = p_data["topic"]
	if topic == _PHOENIX_CHANNEL:
		# Pong event
		return
	if topic not in _topics:
		push_error("Got message for an invalid channel. ", p_data, " references: ", _topics)
		return
	var payload = {} if "payload" not in p_data else p_data["payload"]
	_topics[topic].parse_event(event, payload)
	# Resolve response if we have one.
	if event == RecvEvent.REPLY:
		var response: Response = _responses.get(ref_id) if ref_id else null
		if response:
			var result = OK if payload.get('status') == 'ok' else FAILED
			response.received.emit(result)
			_responses.erase(ref_id)


func _connected(p_protocol:=""):
	_last_heartbeat = Time.get_ticks_msec()
	_reset_topic_states()
	connection_succeded.emit()


func _connection_closed(p_was_clean:=false):
	_reset_topic_states()
	if not p_was_clean and not _closing:
		push_error("Socket connection to server was not cleanly closed.")
		connection_error.emit()
	else:
		connection_closed.emit()


func _send_msg(p_topic: String, p_event: String, p_payload=null, p_ref=null, p_await_response:=false) -> int:
	var payload := {}
	if p_payload is Dictionary:
		payload.merge(p_payload)

	var msg := {
		"topic": p_topic,
		"event": p_event,
		"payload": payload,
		"ref": p_ref,
	}
	if payload.has('type'):
		msg['type'] = payload['type']

	var ret := _ws.send_text(_json.stringify(msg))

	# If requested, await for the server response.
	if ret == OK and p_ref and p_await_response:
		var resp = Response.new()
		_responses[p_ref] = resp
		return await resp.received

	return ret


func _send_std_msg(p_topic: String, p_event: SendEvent, p_payload=null, p_ref=null) -> int:
	var payload := {
		"user_token": _identity.get_access_token()
	}
	if p_payload is Dictionary:
		payload.merge(p_payload)

	return await _send_msg(p_topic, _SEND_EVENT_NAMES[p_event], payload, p_ref)


func _get_presence_state(p_topic: String) -> Dictionary:
	if p_topic not in _topics:
		push_error("Cannot get presence state for invalid chanel: ", p_topic)
	return _topics[p_topic].presence_state


func _notification(what):
	if what != NOTIFICATION_PREDELETE:
		return
	if is_instance_valid(_poll_timer) and not _poll_timer.is_queued_for_deletion():
		_poll_timer.queue_free()
	if is_instance_valid(_ws):
		_ws.close(1001)
