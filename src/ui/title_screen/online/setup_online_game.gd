class_name SetupOnlineGame extends Node


enum State {
	IDLE,
	LOBBY,
	TRANSFER_FROM_LOBBY,
}


enum NakamaOpCode {
	TRANSFER_FROM_LOBBY = 1,
}

const TIMEOUT_FOR_TRANSFER_FROM_LOBBY: float = 2.0


var _current_match_config: MatchConfig = null
var _lobby_match_id: String = ""
var _is_host: bool = false
var _state: State = State.IDLE
var _presence_map: Dictionary = {}
var _presence_order_list: Array = []
var _expected_player_count: int = -1
var _host_user_id: String = ""

@export var _title_screen: TitleScreen
@export var _online_match_list_menu: OnlineMatchListMenu
@export var _online_lobby_menu: OnlineLobbyMenu
@export var _create_online_match_menu: CreateOnlineMatchMenu
@export var _connecting_to_server_indicator: Control


#########################
###     Built-in      ###
#########################

func _ready():
#	NOTE: need to manually call the callback here in case
#	nakama is already connected. This happens when player
#	quits from match back to title screen.
	NakamaConnection.state_changed.connect(_on_nakama_connection_state_changed)
	_on_nakama_connection_state_changed()

	OnlineMatch.error.connect(_on_webrtc_error)


#########################
###      Private      ###
#########################

func _update_online_lobby_menu_presences():
	var presence_list: Array = []

	for user_id in _presence_order_list:
		var presence: NakamaRTAPI.UserPresence = _presence_map[user_id]
		presence_list.append(presence)

	_online_lobby_menu.set_presences(presence_list, _host_user_id)


func _refresh_match_list():
	_online_match_list_menu.set_state(OnlineMatchListMenu.State.SEARCHING)
	
	var client: NakamaClient = NakamaConnection.get_client()
	var session: NakamaSession = NakamaConnection.get_session()

	var min_players: int = 0
	var max_players: int = 10
	var limit: int = 10
	var authoritative: bool = true
	var label: String = ""
	var query: String = ""
	var list_matches_result: NakamaAPI.ApiMatchList = await client.list_matches_async(session, min_players, max_players, limit, authoritative, label, query)

	if list_matches_result.is_exception():
		push_error("Error in list_matches_async(): %s" % list_matches_result)
		
		return

# 	NOTE: add artificial delay to prevent UI feeling abrupt
# 	and also as a way to throttle requests a bit.
	await get_tree().create_timer(0.5).timeout
	
	var match_list: Array = list_matches_result.matches
	_online_match_list_menu.update_match_list(match_list)


func _get_match_config_from_label(match_label: String) -> MatchConfig:
	var label_dict: Dictionary = JSON.parse_string(match_label)
	var match_config: MatchConfig = MatchConfig.convert_from_dict(label_dict)
	
	return match_config


#########################
###      Private      ###
#########################

# Delay opening multiplayer menu until client is connected
# to server.
func _switch_to_match_list_when_connected():
	_connecting_to_server_indicator.show()

#	NOTE: add an extra delay to avoid too quick UI
#	switching, otherwise it looks bad
	await NakamaConnection.state_changed
	await get_tree().create_timer(0.3).timeout
	
	_connecting_to_server_indicator.hide()
	
	var connection_state: NakamaConnection.State = NakamaConnection.get_state()
	
#	NOTE: need to switch to online match list even if failed
#	to connect so that LAN multiplayer remains accessible
#	when game can't connect to online server.
	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_MATCH_LIST)
	
	var connected_ok: bool = connection_state == NakamaConnection.State.CONNECTED

	if connected_ok:
		_refresh_match_list()
	else:
		_online_match_list_menu.set_state(OnlineMatchListMenu.State.FAILED_TO_CONNECT)


func _get_host_user_id_for_match(match_: NakamaRTAPI.Match) -> String:
	var label_string: String = match_.label

	var parse_result = JSON.parse_string(label_string)
	var parse_failed: bool = parse_result == null
	if parse_failed:
		return ""

	var label_dict: Dictionary = parse_result
	var host_user_id: String = label_dict.get("host_user_id", "")

	return host_user_id


func _save_presences(presence_list: Array):
	for presence in presence_list:
		_presence_map[presence.user_id] = presence

		if !_presence_order_list.has(presence.user_id):
			_presence_order_list.append(presence.user_id)

#	Request display names of new joiners from server
	var user_id_list: Array = []
	for presence in presence_list:
		var user_id: String = presence.user_id
		user_id_list.append(user_id)

	var client: NakamaClient = NakamaConnection.get_client()
	var session: NakamaSession = NakamaConnection.get_session()

	var get_users_async_result: NakamaAsyncResult = await client.get_users_async(session, user_id_list)

	if get_users_async_result.is_exception():
		push_error("Error in get_users_async_result rpc(): %s" % get_users_async_result)

		return

	var api_users: NakamaAPI.ApiUsers = get_users_async_result as NakamaAPI.ApiUsers

	for user in api_users.users:
		var user_id: String = user.id
		var display_name: String = user.display_name

		NakamaConnection.set_display_name_of_user(user_id, display_name)

#	NOTE: update online lobby again to show player names
	_update_online_lobby_menu_presences()


func _process_nakama_message_transfer_from_lobby(message: NakamaRTAPI.MatchData):
	if _is_host:
		return

	print_verbose("Received signal from host about transferring from lobby match to game match")
	
	_title_screen.switch_to_tab(TitleScreen.Tab.LOADING)
	
	var state_data: Dictionary = JSON.parse_string(message.data)
	var game_match_id: String = state_data.get("match_id", "")

	var socket: NakamaSocket = NakamaConnection.get_socket()
	var leave_match_result: NakamaAsyncResult = await socket.leave_match_async(_lobby_match_id)
	if leave_match_result.is_exception():
		push_error("Error in leave_match_async rpc(): %s" % leave_match_result)
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), "%s.\n%s" % [tr("SETUP_ONLINE_ERROR_TRANSFER_FROM_LOBBY"), leave_match_result.exception.message])

		return

	_lobby_match_id = ""

#	NOTE: clear presence map which contains presences
#	collected for lobby. We're entering the real game match
#	now so need to re-obtain presences.
	_presence_map.clear()
	_presence_order_list.clear()

	OnlineMatch.join_match(socket, game_match_id)


#########################
###     Callbacks     ###
#########################

func _on_webrtc_error(message: String):
	push_error("webrtc error: %s" % message)


func _on_nakama_connection_state_changed():
	var connection_state: NakamaConnection.State = NakamaConnection.get_state()

	if connection_state == NakamaConnection.State.CONNECTED:
		var socket: NakamaSocket = NakamaConnection.get_socket()
		socket.received_match_presence.connect(_on_nakama_received_match_presence)
		socket.received_match_state.connect(_on_nakama_received_match_state)


func _on_online_match_list_menu_create_match_pressed():
	_title_screen.switch_to_tab(TitleScreen.Tab.CREATE_ONLINE_MATCH)


func _on_create_online_match_menu_create_pressed():
	_current_match_config = _create_online_match_menu.get_match_config()

	var match_config_dict: Dictionary = _current_match_config.convert_to_dict()
	var host_display_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	var creation_time: float = Time.get_unix_time_from_system()
	var game_version: String = Config.build_version()
	var team_mode: TeamMode.enm = _current_match_config.get_team_mode()
	var player_count_max: int = TeamMode.get_player_count_max(team_mode)
		
	var local_user_id: String = NakamaConnection.get_local_user_id()

	var match_params_dict: Dictionary = {
		"host_display_name": host_display_name,
		"host_user_id": local_user_id,
		"player_count_max": player_count_max,
		"is_private": false,
		"creation_time": creation_time,
		"game_version": game_version,
	}
	match_params_dict.merge(match_config_dict)

	var match_params_string: String = JSON.stringify(match_params_dict)
	var client: NakamaClient = NakamaConnection.get_client()
	var socket: NakamaSocket = NakamaConnection.get_socket()
	var session: NakamaSession = NakamaConnection.get_session()
	var create_match_result: NakamaAsyncResult = await client.rpc_async(session, "create_match", match_params_string)
	if create_match_result.is_exception():
		push_error("Error in create_match rpc(): %s" % create_match_result)
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), "%s\n%s" % [tr("SETUP_ONLINE_ERROR_CREATE_MATCH"), create_match_result.exception.message])

		return
	
	var result_payload: Dictionary = JSON.parse_string(create_match_result.payload)
	var lobby_match_id: String = result_payload["match_id"]
	
	var join_match_result: NakamaAsyncResult = await socket.join_match_async(lobby_match_id)
	if join_match_result.is_exception():
		push_error("Error in join_match_async rpc(): %s" % join_match_result)
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), "%s\n%s" % [tr("SETUP_ONLINE_ERROR_JOIN_MATCH"), join_match_result.exception.message])

		return
	
	var lobby_match: NakamaRTAPI.Match = join_match_result
	_save_presences(lobby_match.presences)
	_save_presences([lobby_match.self_user])
	
	_lobby_match_id = lobby_match_id
	_state = State.LOBBY

	_host_user_id = _get_host_user_id_for_match(lobby_match)

	_is_host = true
	
	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_LOBBY)
	_update_online_lobby_menu_presences()
	_online_lobby_menu.set_start_button_visible(true)
	_online_lobby_menu.display_match_config(_current_match_config)


func _on_nakama_received_match_presence(presence_event: NakamaRTAPI.MatchPresenceEvent):
	for presence in presence_event.leaves:
		_presence_map.erase(presence.user_id)
		_presence_order_list.erase(presence.user_id)

	_save_presences(presence_event.joins)

	if _online_lobby_menu.visible:
		_update_online_lobby_menu_presences()


func _on_nakama_received_match_state(message: NakamaRTAPI.MatchData):
	var op_code: int = message.op_code
	
	match op_code:
		NakamaOpCode.TRANSFER_FROM_LOBBY: _process_nakama_message_transfer_from_lobby(message)
		_: pass



func _on_online_match_list_menu_join_pressed(selected_match_id: String):
	var socket: NakamaSocket = NakamaConnection.get_socket()
	
	var join_match_result: NakamaAsyncResult = await socket.join_match_async(selected_match_id)
	if join_match_result.is_exception():
		push_error("Error in join_match_async rpc(): %s" % join_match_result)
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), "%s\n%s" % [tr("SETUP_ONLINE_ERROR_JOIN_MATCH"), join_match_result.exception.message])

		return

	var lobby_match: NakamaRTAPI.Match = join_match_result

	_lobby_match_id = selected_match_id

	_host_user_id = _get_host_user_id_for_match(lobby_match)

	_save_presences(lobby_match.presences)
	_save_presences([lobby_match.self_user])

	var match_label: String = lobby_match.label
	var match_config = _get_match_config_from_label(match_label)

#	TODO: make it possible to recover from this error state
	if match_config == null:
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), tr("SETUP_ONLINE_ERROR_LOAD_MATCH_PROPS"))

		return

	_current_match_config = match_config
	_state = State.LOBBY

	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_LOBBY)
	_update_online_lobby_menu_presences()
#	NOTE: hide start button if client is not host because only the host
#	should be able to start the game
	_online_lobby_menu.set_start_button_visible(false)
	_online_lobby_menu.display_match_config(_current_match_config)



func _on_online_lobby_menu_leave_pressed():
	var socket: NakamaSocket = NakamaConnection.get_socket()
	var leave_match_result: NakamaAsyncResult = await socket.leave_match_async(_lobby_match_id)
	if leave_match_result.is_exception():
		push_error("Error in leave_match_async(): %s" % leave_match_result)
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), "%s\n%s" % [tr("SETUP_ONLINE_ERROR_LEAVE_MATCH"), leave_match_result.exception.message])

		return
	
	_lobby_match_id = ""
	_state = State.IDLE

	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_MATCH_LIST)
	_refresh_match_list()


# NOTE: host doesn't leave the lobby match here, so that
# host can send message to other peers to tell them to leave
# the lobby match and go to game match.
func _on_online_lobby_menu_start_pressed():
	_expected_player_count = _presence_map.size()

	_title_screen.switch_to_tab(TitleScreen.Tab.LOADING)

	OnlineMatch.match_created.connect(_on_host_created_game_match)

#	NOTE: Set leave_prev_match flag to false so that host
#	stays in lobby match. This is so that host can tell
#	peers in lobby about new match id.
	var socket: NakamaSocket = NakamaConnection.get_socket()
	var leave_prev_match: bool = false
	OnlineMatch.create_match(socket, leave_prev_match)


func _on_peer_connected(_peer_id: int):
	var peer_id_list: Array = multiplayer.get_peers()
	var peer_count: int = peer_id_list.size()
# 	NOTE: need to add 1 to peer count to include local peer
	var player_count: int = peer_count + 1
	var all_players_connected: bool = player_count == _expected_player_count

	print_verbose("New peer connected to game match. peer_count=%s, player_count=%s, all_players_connected=%s" % [peer_count, player_count, all_players_connected])

	if all_players_connected:
		print_verbose("All players connected to game match! Player count: %s. Starting the game." % player_count)

#		NOTE: wait a bit just in case (is this really
#		needed?)
		await get_tree().create_timer(1.0).timeout
		
		var difficulty: Difficulty.enm = _current_match_config.get_difficulty()
		var game_length: int = _current_match_config.get_game_length()
		var game_mode: GameMode.enm = _current_match_config.get_game_mode()
		var team_mode: TeamMode.enm = _current_match_config.get_team_mode()
		var origin_seed: int = randi()

		_title_screen.start_game.rpc(PlayerMode.enm.MULTIPLAYER, game_length, game_mode, difficulty, team_mode, origin_seed, Globals.ConnectionType.NAKAMA)


func _on_host_created_game_match(game_match_id: String):
	var socket: NakamaSocket = NakamaConnection.get_socket()
	
	OnlineMatch.match_created.disconnect(_on_host_created_game_match)
	multiplayer.multiplayer_peer.peer_connected.connect(_on_peer_connected)

	print_verbose("Created game match with id %s." % game_match_id);

	var data_dict: Dictionary = {
		"match_id": game_match_id,
	}

	var data: String = JSON.stringify(data_dict)
	var send_match_state_result: NakamaAsyncResult = await socket.send_match_state_async(_lobby_match_id, NakamaOpCode.TRANSFER_FROM_LOBBY, data)
	if send_match_state_result.is_exception():
		push_error("Error in send_match_state_async(): %s" % send_match_state_result)
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), "%s\n%s" % [tr("SETUP_ONLINE_ERROR_COMMUNICATE_WITH_LOBBY"), send_match_state_result.exception.message])
 
		return

#	Host sent the TRANSFER_FROM_LOBBY message so now it's
#	okay to leave the lobby match
	var leave_match_result: NakamaAsyncResult = await socket.leave_match_async(_lobby_match_id)
	if leave_match_result.is_exception():
		push_error("Error in leave_match_async rpc(): %s" % leave_match_result)
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), "%s\n%s" % [tr("SETUP_ONLINE_ERROR_TRANSFER_FROM_LOBBY"), leave_match_result.exception.message])

		return
	
	_lobby_match_id = ""

	if _expected_player_count == 1:
		_on_peer_connected(1)


func _on_online_match_list_menu_refresh_pressed():
	_refresh_match_list()


func _on_multiplayer_button_pressed():
	var running_on_desktop: bool = OS.has_feature("pc")
	if !running_on_desktop:
		Utils.show_popup_message(self, tr("GENERIC_ERROR_TITLE"), tr("SETUP_ONLINE_ERROR_IN_BROWSER"))
	
		return
	
	var connection_state: NakamaConnection.State = NakamaConnection.get_state()
	
	match connection_state:
		NakamaConnection.State.CONNECTING:
			_switch_to_match_list_when_connected()
		NakamaConnection.State.CONNECTED:
			_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_MATCH_LIST)
			_refresh_match_list()
		NakamaConnection.State.FAILED_TO_CONNECT:
#			NOTE: if failed to connect previously, try again
#			here
			NakamaConnection.connect_to_server()
			_switch_to_match_list_when_connected()
