## A client for the Agones API.
##
## This is primarily used internally. The most common interactions with Agones will be handled
## automatically by calling methods on ["addons/w4gd/game_server/game_server_sdk.gd"]. However,
## this can be used directly for advanced use-cases that aren't exposed there.
extends RefCounted

const Client = preload("../rest-client/client.gd")
const ClientResult = preload("../rest-client/client_result.gd")

## Represents the result of a request to the Agones API.
class Result extends RefCounted:
	var _success: bool
	var _data: Dictionary
	var _message: String

	func _init(success: bool, data := {}, message := ''):
		_success = success
		_data = data
		_message = message

	## Returns true if the request was a success; otherwise, false.
	func is_success() -> bool:
		return _success

	## Returns true if the request resulted in an error; otherwise, false.
	func is_error() -> bool:
		return not _success

	## Gets the data returned by Agones.
	func get_data() -> Dictionary:
		return _data

	## Gets the message returned by Agones.
	func get_message() -> String:
		return _message

	func _to_string() -> String:
		if _success:
			return 'OK: ' + JSON.stringify(_data)
		else:
			if _message != '':
				return "ERROR: " + _message
			return "ERROR"

## Used to receive realtime updates to the Agones configuration for this game server.
##
## Should be created via [method "addons/w4gd/game_server/agones_client.gd".watch_game_server].
class Watcher extends Node:
	var _host: String
	var _port: int

	var _client: HTTPClient
	var _request_sent := false
	var _status := OK

	## Emitted when new data has been received.
	signal received_data (data)
	## Emitted when an error has been encountered.
	signal error (code)
	## Emitted when the watcher has stopped.
	signal stopped ()

	func _init(host: String, port: int):
		_host = host
		_port = port

	func _error(code := FAILED) -> void:
		_status = code
		error.emit(code)
		stop()

	## Starts watching for updates.
	func start() -> void:
		_client = HTTPClient.new()
		_status = OK
		_request_sent = false

		var result := _client.connect_to_host(_host, _port)
		if result != OK:
			_error(result)
			return

	## Stops watching for updates.
	func stop(emit_signal := true) -> void:
		if _client:
			_client.close()
			_client = null
		stopped.emit()

	## Gets the current error status.
	##
	## This will be set to [code]OK[/code] when everything is working fine, and some
	## other value in the case of an error.
	func get_status() -> int:
		return _status

	## Returns true when running; otherwise, false.
	func is_running() -> bool:
		return _client != null

	## Returns true when everything is working fine; otherwise, false.
	func is_ok() -> bool:
		return _status == OK

	## Returns true when there is an error; otherwise, false.
	func is_error() -> bool:
		return _status != OK

	## Polls the connection to see if there's any more data available.
	##
	## This should be called automatically every frame.
	func poll() -> void:
		if _client == null:
			return
		if _status != OK:
			return

		var result: int = OK

		result = _client.poll()
		if result != OK:
			_error(result)
			return

		var status: int = _client.get_status()
		match status:
			HTTPClient.STATUS_DISCONNECTED:
				_error(ERR_CONNECTION_ERROR)
				return
			HTTPClient.STATUS_RESOLVING:
				pass
			HTTPClient.STATUS_CANT_RESOLVE:
				_error(ERR_CONNECTION_ERROR)
				return
			HTTPClient.STATUS_CONNECTING:
				pass
			HTTPClient.STATUS_CANT_CONNECT:
				_error(ERR_CONNECTION_ERROR)
				return
			HTTPClient.STATUS_CONNECTED:
				if _request_sent:
					stop()
				else:
					result = _client.request(HTTPClient.METHOD_GET, '/watch/gameserver', [])
					if result != OK:
						_error(result)
						return
					_request_sent = true
			HTTPClient.STATUS_REQUESTING:
				pass
			HTTPClient.STATUS_BODY:
				if _client.has_response():
					var chunk = _client.read_response_body_chunk()
					if chunk.size() > 0:
						var data = JSON.parse_string(chunk.get_string_from_utf8())
						if data is Dictionary and data.has('result'):
							received_data.emit(data['result'])
						else:
							_error(ERR_PARSE_ERROR)
							return
			HTTPClient.STATUS_CONNECTION_ERROR:
				_error(ERR_CONNECTION_ERROR)
				return
			HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
				_error(ERR_CONNECTION_ERROR)
				return

	func _process(_delta: float) -> void:
		poll()

var _node: Node
var _host: String
var _port: int
var _client: Client

func _init(node: Node, port: int = -1, host: String = 'localhost') -> void:
	if port == -1:
		var port_str = OS.get_environment('AGONES_SDK_HTTP_PORT')
		if port_str == '':
			port = 9358
		else:
			port = port_str.to_int()

	_node = node
	_host = host
	_port = port
	_client = Client.new(node, 'http://' + host + ':' + str(port))

func _parse_result(http_result: ClientResult) -> Result:
	if http_result.is_http_success():
			var json_result : Dictionary = http_result.json_result()
			return Result.new(true, json_result)
	return Result.new(false, {}, http_result.text_result().strip_edges())

## Lets Agones know that this game server is ready to accept connections.
func ready() -> Result:
	return await _client.POST('/ready', {}).then(_parse_result).async()

## Sends a "heartbeat" to Agones to declare that this game server is healthy.
func health() -> Result:
	return await _client.POST('/health', {}).then(_parse_result).async()

## Moves the game server into a "Reserved" state for the given number of seconds.
func reserve(seconds: int) -> Result:
	return await _client.POST('/reserve', {seconds = seconds}).then(_parse_result).async()

## Manually marks this game server as "Allocated".
##
## Usually, Agones will mark game servers as "Allocated", but this allows for workflows
## where the dedicated server will mark itself as "Allocated".
func allocate() -> Result:
	return await _client.POST('/allocate', {}).then(_parse_result).async()

## Requests that Agones shutdown this game server.
func shutdown() -> Result:
	return await _client.POST('/shutdown', {}).then(_parse_result).async()

## Gets the Agones configuration for this game server.
func get_game_server() -> Result:
	return await _client.GET('/gameserver', {}).then(_parse_result).async()

## Creates a watcher to receive realtime updates to the Agones configuration for this game server.
func watch_game_server() -> Watcher:
	var watcher = Watcher.new(_host, _port)
	watcher.name = 'WatchGameServer'
	_node.add_child(watcher)
	return watcher

## Sets a label on the Agones configuration for this game server.
func set_label(key: String, value: String) -> Result:
	return await _client.PUT('/metadata/label', {key=key, value=value}).then(_parse_result).async()

## Sets an annotation on the Agones configuration for this game server.
func set_annotation(key: String, value: String) -> Result:
	return await _client.PUT('/metadata/annotation', {key=key, value=value}).then(_parse_result).async()

## Tells Agones that the given player has connected.
##
## This function is considered Alpha within the Agones SDK, and so
## come with a number of caveats as described here:
## https://agones.dev/site/docs/guides/feature-stages/#alpha
func alpha_player_connect(player_id: String) -> Result:
	return await _client.POST('/alpha/player/connect', {
		playerID = player_id,
	}).then(_parse_result).async()

## Tells Agones that the given player has disconnected.
##
## This function is considered Alpha within the Agones SDK, and so
## come with a number of caveats as described here:
## https://agones.dev/site/docs/guides/feature-stages/#alpha
func alpha_player_disconnect(player_id: String) -> Result:
	return await _client.POST('/alpha/player/disconnect', {
		playerID = player_id,
	}).then(_parse_result).async()

## Changes the player capacity for this game server as stored in Agones.
##
## This function is considered Alpha within the Agones SDK, and so
## come with a number of caveats as described here:
## https://agones.dev/site/docs/guides/feature-stages/#alpha
func alpha_set_player_capacity(count: int) -> Result:
	return await _client.PUT('/alpha/player/capacity', {
		count = count,
	}).then(_parse_result).async()

## Gets the player capacity for this game server as stored in Agones.
##
## This function is considered Alpha within the Agones SDK, and so
## come with a number of caveats as described here:
## https://agones.dev/site/docs/guides/feature-stages/#alpha
func alpha_get_player_capacity() -> Result:
	return await _client.GET('/alpha/player/capacity').then(_parse_result).async()

## Gets the player count for this game server as tracked in Agones.
##
## This function is considered Alpha within the Agones SDK, and so
## come with a number of caveats as described here:
## https://agones.dev/site/docs/guides/feature-stages/#alpha
func alpha_get_player_count() -> Result:
	return await _client.GET('/alpha/player/count').then(_parse_result).async()

## Checks if the given player is connected per Agones.
##
## This function is considered Alpha within the Agones SDK, and so
## come with a number of caveats as described here:
## https://agones.dev/site/docs/guides/feature-stages/#alpha
func alpha_is_player_connected(player_id: String) -> Result:
	return await _client.GET('/alpha/player/connected/' + player_id).then(_parse_result).async()

## Gets list of connected players as stored in Agones.
##
## This function is considered Alpha within the Agones SDK, and so
## come with a number of caveats as described here:
## https://agones.dev/site/docs/guides/feature-stages/#alpha
func alpha_get_connected_players() -> Result:
	return await _client.GET('/alpha/player/connected').then(_parse_result).async()
