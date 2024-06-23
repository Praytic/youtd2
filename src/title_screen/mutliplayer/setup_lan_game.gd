class_name SetupLanGame extends Node


# Handles logic for creating and joining rooms for LAN games.


# TODO: handle player count. Need to let in 2 ppl max, and
# display player count in room list.

# TODO: add "ready" system. All players in room must ready
# up before host can start the game.

# TODO: handle room closure. When host leaves the game, room
# is closed and should disappear from room list.


var _current_room_config: RoomConfig = null


@export var _title_screen: TitleScreen
@export var _lan_room_list_menu: LanRoomListMenu
@export var _room_menu: RoomMenu
@export var _create_lan_room_menu: CreateLanRoomMenu
@export var _lan_room_scanner: LanRoomScanner
@export var _lan_room_advertiser: LanRoomAdvertiser


#########################
###     Callbacks     ###
#########################

func _on_lan_room_scanner_room_list_changed():
	var room_map: Dictionary = _lan_room_scanner.get_room_map()
	_lan_room_list_menu.update_room_display(room_map)


func _on_create_lan_room_menu_create_pressed():
	_current_room_config = _create_lan_room_menu.get_room_config()

	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Maximum of 1 peer, since it's a 2-player co-op.
	var create_server_result: Error = peer.create_server(Constants.SERVER_PORT, 1)
	if create_server_result != OK:
		Utils.show_popup_message(self, "Error", "Failed to create server, port might already be in use. Details: %s." % error_string(create_server_result))

		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

#	Start advertising the room
	_lan_room_advertiser.set_room_config(_current_room_config)

	_title_screen.switch_to_tab(TitleScreen.Tab.MULTIPLAYER_ROOM)
	_room_menu.display_room_config(_current_room_config)


# NOTE: need to scan for rooms only while room list menu is
# visible. Otherwise, will run into problems if the client
# is scanning for rooms and advertising at the same time.
func _on_lan_room_list_menu_visibility_changed():
	var room_scanner_enabled: bool = _lan_room_list_menu.visible
	_lan_room_scanner.set_enabled(room_scanner_enabled)


func _on_lan_room_list_menu_create_room_pressed():
	_title_screen.switch_to_tab(TitleScreen.Tab.CREATE_ROOM)


func _on_lan_room_list_menu_join_pressed():
	var selected_room_address: String = _lan_room_list_menu.get_selected_room_address()
	
	var nothing_selected: bool = selected_room_address.is_empty()
	if nothing_selected:
		Utils.show_popup_message(self, "Error", "You must select a room first.")
		
		return
	
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_client_result: Error = peer.create_client(selected_room_address, Constants.SERVER_PORT)

	if create_client_result != OK:
		Utils.show_popup_message(self, "Error", "Failed to create client. Details:" % error_string(create_client_result))

		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	var room_map: Dictionary = _lan_room_scanner.get_room_map()
	var room_info: RoomInfo = room_map[selected_room_address]
	_current_room_config = room_info.get_room_config()

	_title_screen.switch_to_tab(TitleScreen.Tab.MULTIPLAYER_ROOM)
	_room_menu.display_room_config(_current_room_config)


func _on_room_menu_start_pressed():
	var is_host: bool = multiplayer.is_server()
	if !is_host:
		Utils.show_popup_message(self, "Error", "Only the host can start the game.")
		
		return
	
	var difficulty: Difficulty.enm = _current_room_config.get_difficulty()
	var game_length: int = _current_room_config.get_game_length()
	var game_mode: GameMode.enm = _current_room_config.get_game_mode()
	var origin_seed: int = randi()
	
	_title_screen.start_game.rpc(PlayerMode.enm.COOP, game_length, game_mode, difficulty, origin_seed)


# NOTE: set room config to null when room menu is hidden, to stop advertising
func _on_room_menu_hidden():
	var is_host: bool = !multiplayer.is_server()
	
	if is_host:
		_lan_room_advertiser.set_room_config(null)
