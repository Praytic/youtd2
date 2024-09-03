extends Node


# Stores Nakama objects which need to be persisted between
# title screen and game scene. This class is used if
# connection type is Nakama - it is completely unused
# otherwise, if connection is Enet - for singleplayer or
# LAN.

signal state_changed()


enum State {
	CONNECTING,
	CONNECTED,
	FAILED_TO_CONNECT
}


var _client: NakamaClient = null
var _session: NakamaSession = null
var _socket: NakamaSocket = null
var _user_id_to_display_name_map: Dictionary = {}
var _state: State = NakamaConnection.State.FAILED_TO_CONNECT


#########################
###     Built-in      ###
#########################

# NOTE: create_client() can be done here because it doesn't
# require connecting to server
func _ready():
	var server_key: String = Secrets.get_secret(Secrets.Key.SERVER_KEY)
	_client = Nakama.create_client(server_key, Constants.NAKAMA_ADDRESS, Constants.NAKAMA_PORT, Constants.NAKAMA_PROTOCOL, Nakama.DEFAULT_TIMEOUT, NakamaLogger.LOG_LEVEL.INFO)

	connect_to_server()


#########################
###       Public      ###
#########################

func connect_to_server():
	var running_on_desktop: bool = OS.has_feature("pc")
	if !running_on_desktop:
		print_verbose("Skipping Nakama connection because running in browser.")
		_set_state(NakamaConnection.State.FAILED_TO_CONNECT)
		
		return

	_set_state(NakamaConnection.State.CONNECTING)

# 	Create Nakama session by authenticating on the server
# 
# 	NOTE: set username to null to let Nakama automatically
# 	generate a unique username. This way, we don't need to
# 	care about username conflicts.
	if _session == null:
		var device_id: String = OS.get_unique_id()
		var username = null
		var create_user: bool = true
		_session = await _client.authenticate_device_async(device_id, username, create_user)

		if _session.is_exception():
			push_error("Error in authenticate_device_async(): %s" % _session)
			Utils.show_popup_message(self, "Error", "Failed to authenticate with server.\n%s" % _session.exception.message)
			_set_state(NakamaConnection.State.FAILED_TO_CONNECT)
			_session = null

			return

# 	Update display name of user on Nakama server, based on
# 	value stored in settings (defined in Profile menu)
	var username = null
	var display_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	var avatar_url = null
	var lang_tag = null
	var location = null
	var timezone = null
	var update_account_async_result: NakamaAsyncResult = await _client.update_account_async(_session, username, display_name, avatar_url, lang_tag, location, timezone)

	if update_account_async_result.is_exception():
		push_error("Error in update_account_async(): %s" % update_account_async_result)
		Utils.show_popup_message(self, "Error", "Failed to update display name on server.\n%s" % update_account_async_result.exception.message)
		_set_state(NakamaConnection.State.FAILED_TO_CONNECT)
		
		return

# 	Establish connection (socket)
	if _socket == null:
		_socket = Nakama.create_socket_from(_client)

		var connect_async_result: NakamaAsyncResult = await _socket.connect_async(_session)
		if connect_async_result.is_exception():
			push_error("Error in connect_async(): %s" % connect_async_result)
			Utils.show_popup_message(self, "Error", "Failed to connect to server.\n%s" % connect_async_result.exception.message)
			_set_state(NakamaConnection.State.FAILED_TO_CONNECT)
			_socket = null
			
			return

		_set_state(NakamaConnection.State.CONNECTED)


func get_state() -> State:
	return _state


func get_client() -> NakamaClient:
	return _client


func get_session() -> NakamaSession:
	return _session


func get_socket() -> NakamaSocket:
	return _socket


func get_display_name_of_user(user_id: String) -> String:
	return _user_id_to_display_name_map.get(user_id, "")


func set_display_name_of_user(user_id: String, display_name_raw: String):
	var display_name_sanitized: String = SanitizeText.sanitize_player_name(display_name_raw)
	
	_user_id_to_display_name_map[user_id] = display_name_sanitized


func get_local_user_id() -> String:
	var local_user_id: String = _session.user_id

	return local_user_id


#########################
###      Private      ###
#########################

func _set_state(value: State):
	_state = value
	state_changed.emit()

