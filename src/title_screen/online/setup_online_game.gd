class_name SetupOnlineGame extends Node


@export var _title_screen: TitleScreen
@export var _online_room_list_menu: OnlineRoomListMenu
#@export var _lan_room_menu: LanRoomMenu
#@export var _create_lan_room_menu: CreateLanRoomMenu


func test_nakama():
	var server_key: String = Globals.get_nakama_server_key()
	var client: NakamaClient = Nakama.create_client(server_key, Constants.NAKAMA_ADDRESS, Constants.NAKAMA_PORT, Constants.NAKAMA_PROTOCOL)

#	TODO: OS.get_unique_id() can't be called on Web. Need to
#	disable online completely for web build
	var device_id: String = OS.get_unique_id()
	var session: NakamaSession = await client.authenticate_device_async(device_id)	

	if session.is_exception():
		print("Error in authenticate_device_async(): %s" % session)
		
		return

	print("Success for authenticate_device_async(): %s" % session)

	var player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	var new_username: String = player_name
	var new_display_name: String = player_name
	var new_avatar_url: String = ""
	var new_lang_tag: String = "en"
	var new_location: String = ""
	var new_timezone: String = "UTC"
	var update_account_async_result: NakamaAsyncResult = await client.update_account_async(session, new_username, new_display_name, new_avatar_url, new_lang_tag, new_location, new_timezone)

	if update_account_async_result.is_exception():
		print("Error in update_account_async(): %s" % update_account_async_result)
		
		return

	print("Success for update_account_async(): %s" % update_account_async_result)

	var socket: NakamaSocket = Nakama.create_socket_from(client)

	var connect_async_result: NakamaAsyncResult = await socket.connect_async(session)
	if connect_async_result.is_exception():
		print("Error in connect_async(): %s" % update_account_async_result)
		
		return

	var match: NakamaRTAPI.Match = await socket.create_match_async()
	if match.is_exception():
		print("Error in create_match_async(): %s" % match)
		
		return


func _ready():
	test_nakama()
