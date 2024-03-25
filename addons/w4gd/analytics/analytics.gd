## A client for interacting with W4 Cloud's analytics service.
extends Node

const SupabaseClient = preload("../supabase/client.gd")

## The full name of the "Auto Clean Up On Quit" project setting.
const AUTO_CLEAN_UP_SETTING = 'w4games/analytics/auto_clean_up_on_quit'

## The default properties to send with every event.
var default_props := {}

## The frequency (in seconds) to send queued data to the server.
var send_frequency: float:
	set(v):
		_send_timer.wait_time = v
	get:
		return _send_timer.wait_time

var _client: SupabaseClient
var _send_timer := Timer.new()
var _send_queue := {}
var _last_flush := 0
var _sending := false
var _started := false
var _uuid := W4Utils.UUIDGenerator.new()
var _session_id
var _session_props := {}
var _auto_clean_up := true

## Emitted before sending the "session_running" event to the server, so that extra properties can be added.
signal session_running_event (extra_props)
## Emitted when there's an error communicating with the server.
signal error (msg)

func _init(p_client: SupabaseClient):
	_client = p_client

	_client.get_identity().identity_changed.connect(self._on_client_identity_changed)

	_send_timer.name = 'AnalyticsSendTimer'
	_send_timer.wait_time = 60.0
	_send_timer.timeout.connect(_on_send_timer_timeout)
	add_child(_send_timer)

	_session_props['platform'] = OS.get_name()

func _ready() -> void:
	if ProjectSettings.has_setting(AUTO_CLEAN_UP_SETTING):
		_auto_clean_up = ProjectSettings.get_setting(AUTO_CLEAN_UP_SETTING)
	if _auto_clean_up:
		get_tree().auto_accept_quit = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _auto_clean_up:
		await stop_session()
		get_tree().quit()

## Starts an analytics sessions.
##
## A session represents everything that happens after starting the game executable through when its closed.
## No data can be sent to the server until the session has started.
## When gathering analytics, this should be run as early as possible after the game starts.
func start_session(p_props := {}) -> void:
	if _started:
		return
	_started = true

	_session_props.merge(p_props, true)
	send_event('session_started', {})
	_send_session_running_event()

	_send_timer.start()
	await flush()

## Stops an analytics sessions.
##
## This should be run just before exiting the game. It will ensure that any queue events are sent.
func stop_session(p_props := {}) -> void:
	if not _started:
		return
	_started = false

	send_event('session_stopped', p_props)

	_send_timer.stop()
	await flush()
	_session_id = null

## Checks if an analytics session has started.
func is_session_started() -> bool:
	return _started

## Sends a 'lobby_joined' event.
func lobby_joined(p_lobby_id: String, p_props := {}) -> void:
	default_props['lobby_id'] = p_lobby_id
	send_event('lobby_joined', p_props)

## Sends a 'lobby_left' event.
func lobby_left(p_props := {}) -> void:
	send_event('lobby_left', p_props)
	default_props.erase('lobby_id')

## Sends an arbitrary event.
func send_event(p_event_name: String, p_props := {}, user_id := '') -> void:
	var event_uuid := _uuid.generate_v4()

	# Get timestamp with sub-second precision.
	var ut: float = Time.get_unix_time_from_system()
	# If the time contains '.', split it and use part after '.' as subsecond, otherwise 0.
	var subsecond = "0" if str(ut).find('.') < 0 else str(ut).split('.')[1]
	var timestamp = Time.get_datetime_string_from_unix_time(ut, true) + '.' + subsecond

	p_props.merge(default_props)

	var event := {
		event_name = p_event_name,
		props = p_props,
		event_uuid = event_uuid,
		created_at = timestamp,
	}
	_send_queue[event_uuid] = event

## Flushes the queue of events, sending them all to the server immediately.
func flush() -> void:
	if _send_queue.size() == 0:
		return

	_last_flush = Time.get_ticks_msec()

	if _session_id == null:
		var data := {
			props = _session_props,
		}
		var result = await _client.rest.rpc('w4analytics.session_start', data).async()
		if result.is_error():
			error.emit(result.message)
			return
		_session_id = result.session_id.as_string()

	var data := {
		events = _send_queue.values(),
		session_id = _session_id,
	}
	var result = await _client.rest.rpc('w4analytics.events_create', data).async()
	if result.is_error():
		error.emit(result.message)
		return

	for event_uuid in result.get_data().event_uuids:
		_send_queue.erase(event_uuid)

func _on_client_identity_changed() -> void:
	var identity = _client.get_identity()

	if default_props.has('user_id') and default_props['user_id'] != identity.get_uid():
		# User is logging out.
		send_event("user_logout")
		default_props.erase('user_id')

	if identity.is_authenticated() and default_props.get('user_id', &'') != identity.get_uid():
		# User is logging in.
		default_props['user_id'] = identity.get_uid()
		send_event('user_login')

func _on_send_timer_timeout() -> void:
	_send_session_running_event()

	# Only do the automatic flush if:
	#   1. we aren't already doing an automatic send (just in case the send
	#      frequency is set too low, or the service is being really slow), and
	#   2. it's been at least the send_frequency minus one second since the last
	#      flush, just in case the developer manually flushed a moment ago.
	if not _sending and (send_frequency < 2.0 or (Time.get_ticks_msec() - _last_flush) >= int((send_frequency - 1.0) * 1000)):
		_sending = true
		await flush()
		_sending = false

func _send_session_running_event() -> void:
	var props := {}

	# Allow the developer to add some extra properties.
	session_running_event.emit(props)

	# Fill in the default properties.
	props['fps'] = Performance.get_monitor(Performance.TIME_FPS)
	props['memory_static'] = Performance.get_monitor(Performance.MEMORY_STATIC)
	props['memory_static_max'] = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	props['object_count'] = Performance.get_monitor(Performance.OBJECT_COUNT)
	props['node_count'] = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	props['resource_count'] = Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)

	send_event('session_running', props)
