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


var _current_match_config: RoomConfig = null
var _lobby_match_id: String = ""
# TODO: store this state on server
var _is_host: bool = false
var _state: State = State.IDLE
var _presence_map: Dictionary = {}
var _presence_order_list: Array = []
var _expected_player_count: int = -1

@export var _title_screen: TitleScreen
@export var _online_match_list_menu: OnlineMatchListMenu
@export var _online_lobby_menu: OnlineLobbyMenu
@export var _create_online_match_menu: CreateOnlineMatchMenu


#########################
###     Built-in      ###
#########################

func _ready():
	NakamaConnection.connected.connect(_on_nakama_connected)


func _on_nakama_connected():
	var socket: NakamaSocket = NakamaConnection.get_socket()
	socket.received_match_presence.connect(_on_nakama_received_match_presence)
	socket.received_match_state.connect(_on_nakama_received_match_state)


func _on_online_match_list_menu_create_match_pressed():
	_title_screen.switch_to_tab(TitleScreen.Tab.CREATE_ONLINE_MATCH)


# TODO: disable UI interactions while waiting for async result, show a progress popup
func _on_create_online_match_menu_create_pressed():
	_current_match_config = _create_online_match_menu.get_match_config()

	var match_config_dict: Dictionary = _current_match_config.convert_to_dict()
	var host_username: String = Settings.get_setting(Settings.PLAYER_NAME)
	var creation_time: float = Time.get_unix_time_from_system()
		
	var local_user_id: String = NakamaConnection.get_local_user_id()

	var match_params_dict: Dictionary = {
		"host_username": host_username,
		"host_user_id": local_user_id,
		"player_count_max": 2,
		"is_private": false,
		"creation_time": creation_time,
	}
	match_params_dict.merge(match_config_dict)

	var match_params_string: String = JSON.stringify(match_params_dict)
	var client: NakamaClient = NakamaConnection.get_client()
	var socket: NakamaSocket = NakamaConnection.get_socket()
	var session: NakamaSession = NakamaConnection.get_session()
	var create_match_result: NakamaAsyncResult = await client.rpc_async(session, "create_match", match_params_string)
	if create_match_result.is_exception():
		push_error("Error in create_match rpc(): %s" % create_match_result)
		Utils.show_popup_message(self, "Error", "Error in create_match rpc(): %s" % create_match_result)

		return
	
	var result_payload: Dictionary = JSON.parse_string(create_match_result.payload)
	var lobby_match_id: String = result_payload["match_id"]
	
	var join_match_result: NakamaAsyncResult = await socket.join_match_async(lobby_match_id)
	if join_match_result.is_exception():
		push_error("Error in join_match_async rpc(): %s" % join_match_result)
		Utils.show_popup_message(self, "Error", "Error in join_match_async rpc(): %s" % join_match_result)

		return
	
	var lobby_match: NakamaRTAPI.Match = join_match_result
	_save_presences(lobby_match.presences)
	_save_presences([lobby_match.self_user])
	
	_lobby_match_id = lobby_match_id
	_state = State.LOBBY

	var host_user_id: String = _get_host_user_id_for_match(lobby_match)
	NakamaConnection.set_host_user_id(host_user_id)

	_is_host = true
	
	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_LOBBY)
	_update_online_lobby_menu_presences()
	_online_lobby_menu.set_start_button_visible(true)
	_online_lobby_menu.display_match_config(_current_match_config)


func _update_online_lobby_menu_presences():
	var presence_list: Array = []

	for user_id in _presence_order_list:
		var presence: NakamaRTAPI.UserPresence = _presence_map[user_id]
		presence_list.append(presence)

	_online_lobby_menu.set_presences(presence_list)


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


func _on_refresh_match_list_timer_timeout():
#	NOTE: refresh match list only when the corresponding UI
#	is visible
	if !_online_match_list_menu.is_visible():
		return

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
	
	var match_list: Array = list_matches_result.matches

	_online_match_list_menu.update_match_list(match_list)


func _on_online_match_list_menu_join_pressed():
	var selected_match_id: String = _online_match_list_menu.get_selected_match_id()
	
	var no_match_selected: bool = selected_match_id.is_empty()
	if no_match_selected:
		Utils.show_popup_message(self, "Error", "You must select a match first.")
		
		return
	
	var socket: NakamaSocket = NakamaConnection.get_socket()
	
	var join_match_result: NakamaAsyncResult = await socket.join_match_async(selected_match_id)
	if join_match_result.is_exception():
		push_error("Error in join_match_async rpc(): %s" % join_match_result)
		Utils.show_popup_message(self, "Error", "Error in join_match_async rpc(): %s" % join_match_result)

		return

	var lobby_match: NakamaRTAPI.Match = join_match_result

	_lobby_match_id = selected_match_id

	var host_user_id: String = _get_host_user_id_for_match(lobby_match)
	NakamaConnection.set_host_user_id(host_user_id)

	_save_presences(lobby_match.presences)
	_save_presences([lobby_match.self_user])

	var match_label: String = lobby_match.label
	var match_config = _get_match_config_from_label(match_label)

#	TODO: make it possible to recover from this error state
	if match_config == null:
		Utils.show_popup_message(self, "Error", "Failed to load match properties!")

		return

	_current_match_config = match_config
	_state = State.LOBBY

	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_LOBBY)
	_update_online_lobby_menu_presences()
#	NOTE: hide start button if client is not host because only the host
#	should be able to start the game
	_online_lobby_menu.set_start_button_visible(false)
	_online_lobby_menu.display_match_config(_current_match_config)


func _get_match_config_from_label(match_label: String) -> RoomConfig:
	var label_dict: Dictionary = JSON.parse_string(match_label)
	var match_config: RoomConfig = RoomConfig.convert_from_dict(label_dict)
	
	return match_config


func _on_online_lobby_menu_leave_pressed():
	var socket: NakamaSocket = NakamaConnection.get_socket()
	var leave_match_result: NakamaAsyncResult = await socket.leave_match_async(_lobby_match_id)
	if leave_match_result.is_exception():
		push_error("Error in leave_match_async(): %s" % leave_match_result)
		Utils.show_popup_message(self, "Error", "Error in leave_match_async(): %s" % leave_match_result)

		return
	
	_lobby_match_id = ""
	_state = State.IDLE

	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_MATCH_LIST)


# NOTE: host doesn't leave the lobby match here, so that
# host can send message to other peers to tell them to leave
# the lobby match and go to game match.
# 
func _on_online_lobby_menu_start_pressed():
	print("_on_online_lobby_menu_start_pressed")
	
	_expected_player_count = _presence_map.size()

	_title_screen.switch_to_tab(TitleScreen.Tab.LOADING)
		
	# TODO: create match here
	# then tell players in lobby about it


# NOTE: subtract 1 from player count because get_peers() doesn't include local peer
func _on_peer_connected(_peer_id: int):
	print("_on_peer_connected")
	var peer_id_list: Array = multiplayer.get_peers()
	var peer_count: int = peer_id_list.size()
	var all_peers_connected: bool = peer_count == _expected_player_count - 1

	print("peer_id_list=", peer_id_list)
	print("all_peers_connected=", all_peers_connected)
	if all_peers_connected:
		await get_tree().create_timer(1.0).timeout
		
#		NOTE: save presence map in NakamaConnection singleton so
#		that it can be accessed in game scene
		NakamaConnection._presence_map = _presence_map

		var difficulty: Difficulty.enm = _current_match_config.get_difficulty()
		var game_length: int = _current_match_config.get_game_length()
		var game_mode: GameMode.enm = _current_match_config.get_game_mode()
		var origin_seed: int = randi()

		_title_screen.start_game.rpc(PlayerMode.enm.COOP, game_length, game_mode, difficulty, origin_seed, Globals.ConnectionType.NAKAMA)


#########################
###      Private      ###
#########################

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


func _process_nakama_message_transfer_from_lobby(message: NakamaRTAPI.MatchData):
	if _is_host:
		return

	print("_process_nakama_message_transfer_from_lobby")
	
	_title_screen.switch_to_tab(TitleScreen.Tab.LOADING)
	
	var state_data: Dictionary = JSON.parse_string(message.data)
	var game_match_id: String = state_data.get("match_id", "")

	var socket: NakamaSocket = NakamaConnection.get_socket()
	var leave_match_result: NakamaAsyncResult = await socket.leave_match_async(_lobby_match_id)
	if leave_match_result.is_exception():
		push_error("Error in leave_match_async rpc(): %s" % leave_match_result)
		Utils.show_popup_message(self, "Error", "Error in leave_match_async rpc(): %s" % leave_match_result)

		return

	_lobby_match_id = ""

#	NOTE: clear presence map which contains presences
#	collected for lobby. We're entering the real game match
#	now so need to re-obtain presences.
	_presence_map.clear()
	_presence_order_list.clear()

#	TODO: join match here


#########################
###     Callbacks     ###
#########################
