class_name SetupOnlineGame extends Node


var _current_room_config: RoomConfig = null
var _match_id: String = ""
var _ready_state_buffer: Dictionary = {}
# TODO: store this state on server
var _is_host: bool = false

@export var _title_screen: TitleScreen
@export var _online_room_list_menu: OnlineRoomListMenu
@export var _online_room_menu: OnlineRoomMenu
@export var _create_online_room_menu: CreateOnlineRoomMenu


# TODO: Client/session may become invalid at any time - can't rely on them
# staying alive forever. Need to detect when it disconnects and reconnect.
var client: NakamaClient = null
var session: NakamaSession = null
var socket: NakamaSocket = null
var _hole_puncher: Node = null

const NAKAMA_OP_CODE_READY: int = 1
const NAKAMA_OP_CODE_GAME_STARTING: int = 2


func test_nakama():
	var server_key: String = Globals.get_nakama_server_key()
	client = Nakama.create_client(server_key, Constants.NAKAMA_ADDRESS, Constants.NAKAMA_PORT, Constants.NAKAMA_PROTOCOL)

#	TODO: OS.get_unique_id() can't be called on Web. Need to
#	disable online completely for web build or find another way to generate
#	a unique id.
	var device_id: String = OS.get_unique_id()
	session = await client.authenticate_device_async(device_id)

	if session.is_exception():
		push_error("Error in authenticate_device_async(): %s" % session)
		
		return

	var player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	var new_username: String = player_name
	var new_display_name: String = player_name
	var new_avatar_url: String = ""
	var new_lang_tag: String = "en"
	var new_location: String = ""
	var new_timezone: String = "UTC"
	var update_account_async_result: NakamaAsyncResult = await client.update_account_async(session, new_username, new_display_name, new_avatar_url, new_lang_tag, new_location, new_timezone)

	if update_account_async_result.is_exception():
		push_error("Error in update_account_async(): %s" % update_account_async_result)
		
		return

	socket = Nakama.create_socket_from(client)

	var connect_async_result: NakamaAsyncResult = await socket.connect_async(session)
	if connect_async_result.is_exception():
		push_error("Error in connect_async(): %s" % update_account_async_result)
		
		return
	
	socket.received_match_presence.connect(_on_nakama_received_match_presence)
	socket.received_match_state.connect(_on_nakama_received_match_state)


func _ready():
	test_nakama()
	_setup_hole_puncher()


func _setup_hole_puncher():
	var hole_puncher_script: Script = preload("res://addons/Holepunch/holepunch_node.gd")
	_hole_puncher = hole_puncher_script.new()
	_hole_puncher.rendevouz_address = Constants.NAKAMA_ADDRESS
	_hole_puncher.rendevouz_port = Constants.HOLE_PUNCHER_PORT
	add_child(_hole_puncher)


func _on_online_room_list_menu_create_room_pressed():
	_title_screen.switch_to_tab(TitleScreen.Tab.CREATE_ONLINE_ROOM)


# TODO: disable UI interactions while waiting for async result, show a progress popup
func _on_create_online_room_menu_create_pressed():
	_current_room_config = _create_online_room_menu.get_room_config()

#	TODO: send room config as JSON
	var input_payload: String = "placeholder payload"
	var create_match_result: NakamaAsyncResult = await client.rpc_async(session, "create_match", input_payload)
	if create_match_result.is_exception():
		push_error("Error in create_match rpc(): %s" % create_match_result)
		Utils.show_popup_message(self, "Error", "Error in create_match rpc(): %s" % create_match_result)

		return
	
	var result_payload: Dictionary = JSON.parse_string(create_match_result.payload)
	var match_id: String = result_payload["match_id"]
	
	var join_match_result: NakamaAsyncResult = await socket.join_match_async(match_id)
	if join_match_result.is_exception():
		push_error("Error in join_match_async rpc(): %s" % join_match_result)
		Utils.show_popup_message(self, "Error", "Error in join_match_async rpc(): %s" % join_match_result)

		return
	
	_match_id = match_id

	_is_host = true
	
	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_ROOM)
#	_online_room_menu.display_room_config(_current_room_config)


func _on_nakama_received_match_presence(presence_event: NakamaRTAPI.MatchPresenceEvent):
	_online_room_menu.add_presences(presence_event.joins)
	_online_room_menu.remove_presences(presence_event.leaves)


# NOTE: need to save ready state in a buffer instead
# of applying it to UI immediately because this
# callback will get called in the middle of the
# process of joining the match. At that point, players
# haven't been added to UI yet, so setting ready
# status would fail.
# 
# Instead, save this state into a buffer and then apply it
# after players have been added to UI.
func _on_nakama_received_match_state(match_state: NakamaRTAPI.MatchData):
	if match_state.op_code == NAKAMA_OP_CODE_READY:
		var state_data: Dictionary = JSON.parse_string(match_state.data)
		var user_id: String = state_data.get("user_id", "")


		_ready_state_buffer[user_id] = true
	elif match_state.op_code == NAKAMA_OP_CODE_GAME_STARTING:
		print("NAKAMA_OP_CODE_GAME_STARTING")
		
		_punch_hole()


func _punch_hole():
	var player_id: String = OS.get_unique_id()
	_hole_puncher.start_traversal(_match_id, _is_host, player_id)
	print("waiting for hole puncher")
	var result = await _hole_puncher.hole_punched
	print("hole puncher finished")

	if result == null || result.size() != 3:
		print("something is wrong with hole punch result")

		return

	var my_port = result[0]
	var host_port = result[1]
	var host_address = result[2]

	print("my_port=%s" % my_port)
	print("host_port=%s" % host_port)
	print("host_address=%s" % host_address)


func _on_refresh_match_list_timer_timeout():
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
	_online_room_list_menu.update_match_list(match_list)


func _on_online_room_list_menu_join_pressed():
	var selected_match_id: String = _online_room_list_menu.get_selected_match_id()
	
	var no_match_selected: bool = selected_match_id.is_empty()
	if no_match_selected:
		Utils.show_popup_message(self, "Error", "You must select a room first.")
		
		return
	
	_ready_state_buffer.clear()
	
	var join_match_result: NakamaAsyncResult = await socket.join_match_async(selected_match_id)
	if join_match_result.is_exception():
		push_error("Error in join_match_async rpc(): %s" % join_match_result)
		Utils.show_popup_message(self, "Error", "Error in join_match_async rpc(): %s" % join_match_result)

		return

	var joined_match: NakamaRTAPI.Match = join_match_result
	_online_room_menu.add_presences(joined_match.presences)

#	NOTE: update ready status of players in lobby.
	for e in joined_match.presences:
		var presence: NakamaRTAPI.UserPresence = e

		var player_is_ready: bool = _ready_state_buffer.has(presence.user_id)

		if player_is_ready:
			_online_room_menu.set_ready_for_player(presence.user_id)

	_match_id = selected_match_id
	
	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_ROOM)
#	_lan_room_menu.display_room_config(_current_room_config)


func _on_online_room_menu_leave_pressed():
	var leave_match_result: NakamaAsyncResult = await socket.leave_match_async(_match_id)
	if leave_match_result.is_exception():
		push_error("Error in leave_match_async(): %s" % leave_match_result)
		Utils.show_popup_message(self, "Error", "Error in leave_match_async(): %s" % leave_match_result)

		return
	
	_match_id = ""
	
#	Re-enable ready button, in case it was disabled. This is so that when player
#	enters another room, they can ready up again.
	_online_room_menu.set_ready_button_disabled(false)
	
	_title_screen.switch_to_tab(TitleScreen.Tab.ONLINE_ROOM_LIST)


func _on_online_room_menu_ready_pressed():
#	NOTE: need to disable button before running async function, because async
#	takes time. Disabling button is needed because player can ready up only one time.
	_online_room_menu.set_ready_button_disabled(true)
	
	var data: String = "{}"
	var send_match_state_result: NakamaAsyncResult = await socket.send_match_state_async(_match_id, NAKAMA_OP_CODE_READY, data)
	if send_match_state_result.is_exception():
		push_error("Error in send_match_state_async(): %s" % send_match_state_result)
		Utils.show_popup_message(self, "Error", "Error in send_match_state_async(): %s" % send_match_state_result)

		return
	

