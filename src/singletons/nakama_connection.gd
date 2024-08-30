extends Node


# Stores Nakama objects which need to be persisted between
# title screen and game scene. This class is used if
# connection type is Nakama - it is completely unused
# otherwise, if connection is Enet - for singleplayer or
# LAN.

signal connected()


var _client: NakamaClient = null
var _session: NakamaSession = null
var _socket: NakamaSocket = null
var _host_user_id: String = ""
var _presence_map: Dictionary = {}


func _ready():
	_connect_to_server()


func _connect_to_server():
	var server_key: String = Globals.get_nakama_server_key()
	_client = Nakama.create_client(server_key, Constants.NAKAMA_ADDRESS, Constants.NAKAMA_PORT, Constants.NAKAMA_PROTOCOL, Nakama.DEFAULT_TIMEOUT, NakamaLogger.LOG_LEVEL.INFO)

#	TODO: OS.get_unique_id() can't be called on Web. Need to
#	disable online completely for web build or find another way to generate
#	a unique id.
	var device_id: String = OS.get_unique_id()
	_session = await _client.authenticate_device_async(device_id)

	if _session.is_exception():
		push_error("Error in authenticate_device_async(): %s" % _session)
		
		return

	var player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	var new_username: String = player_name
	var new_display_name: String = player_name
	var new_avatar_url: String = ""
	var new_lang_tag: String = "en"
	var new_location: String = ""
	var new_timezone: String = "UTC"
	var update_account_async_result: NakamaAsyncResult = await _client.update_account_async(_session, new_username, new_display_name, new_avatar_url, new_lang_tag, new_location, new_timezone)

	if update_account_async_result.is_exception():
		push_error("Error in update_account_async(): %s" % update_account_async_result)
		
		return

	_socket = Nakama.create_socket_from(_client)

	var connect_async_result: NakamaAsyncResult = await _socket.connect_async(_session)
	if connect_async_result.is_exception():
		push_error("Error in connect_async(): %s" % update_account_async_result)
		
		return

	connected.emit()


func get_client() -> NakamaClient:
	return _client


func get_session() -> NakamaSession:
	return _session


func get_socket() -> NakamaSocket:
	return _socket


func set_host_user_id(value: String):
	_host_user_id = value


func get_host_user_id() -> String:
	return _host_user_id


func get_host_presence() -> NakamaRTAPI.UserPresence:
	var host_presence: NakamaRTAPI.UserPresence = _presence_map.get(_host_user_id, null)
	
	return host_presence


func get_presence_map() -> Dictionary:
	return _presence_map


func get_local_user_id() -> String:
	var local_user_id: String = _session.user_id

	return local_user_id
