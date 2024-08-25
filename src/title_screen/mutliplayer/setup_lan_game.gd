class_name SetupLanGame extends Node


# Handles logic for creating and joining rooms for LAN games.


# TODO: handle player count. Need to let in 2 ppl max, and
# display player count in room list.

# TODO: add "ready" system. All players in room must ready
# up before host can start the game.

# TODO: handle room closure. When host leaves the game, room
# is closed and should disappear from room list.


const SERVER_PEER_ID: int = 1


var _current_room_config: RoomConfig = null


@export var _title_screen: TitleScreen
@export var _lan_room_list_menu: LanRoomListMenu
@export var _lan_room_menu: LanRoomMenu
@export var _create_lan_room_menu: CreateLanRoomMenu
@export var _lan_room_scanner: LanRoomScanner
@export var _lan_room_advertiser: LanRoomAdvertiser

var _peer_id_to_player_name_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
#	TODO: disabled because this gets called during online game setup
#	multiplayer.connected_to_server.connect(_on_connected_to_server)
#	multiplayer.peer_connected.connect(_on_peer_connected)
#	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	pass


#########################
###      Private      ###
#########################

func _update_player_list_in_room_menu():
	var peer_id_list: Array = multiplayer.get_peers()
	var local_peer_id: int = multiplayer.get_unique_id()
	peer_id_list.append(local_peer_id)

	var player_list: Array[String] = []

	for peer_id in peer_id_list:
		var fallback_string: String = "Player %d" % peer_id
		var player_name: String = _peer_id_to_player_name_map.get(peer_id, fallback_string)
		player_list.append(player_name)
	
	_lan_room_menu.set_player_list(player_list)


# All peers (including the host itself) call this f-n to
# tell the host their player names. The host later passes
# this info to all peers.
@rpc("any_peer", "call_local", "reliable")
func _give_local_player_name_to_host(player_name: String):
	var peer_id: int = multiplayer.get_remote_sender_id()
	_peer_id_to_player_name_map[peer_id] = player_name

	_receive_player_name_map_from_host.rpc(_peer_id_to_player_name_map)


@rpc("authority", "call_local", "reliable")
func _receive_player_name_map_from_host(player_name_map: Dictionary):
	_peer_id_to_player_name_map = player_name_map
	
#	NOTE: need to update displayed player list to show
#	updated player names
	_update_player_list_in_room_menu()


# NOTE: this functionality is currently duplicated here and
# in _on_lan_room_list_menu_join_pressed(). This is to
# handle case where player connects via entered address. In
# that case, room config is not available on client and has
# to be obtained from host.
@rpc("authority", "call_local", "reliable")
func _receive_room_config_from_host(room_config_bytes: PackedByteArray):
	_current_room_config = RoomConfig.convert_from_bytes(room_config_bytes)
	_lan_room_menu.display_room_config(_current_room_config)


func _connect_to_room(room_address: String) -> bool:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_client_result: Error = peer.create_client(room_address, Constants.SERVER_PORT)

	if create_client_result != OK:
		Utils.show_popup_message(self, "Error", "Failed to create client. Details:" % error_string(create_client_result))

		return false

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	return true


#########################
###     Callbacks     ###
#########################

func _on_connected_to_server():
	var local_player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	_give_local_player_name_to_host.rpc_id(SERVER_PEER_ID, local_player_name)


func _on_peer_connected(peer_id: int):
# 	When a new peer connects, host(server) will tell the
# 	newly connected peer the names of all of the players.
	if multiplayer.is_server():
		_receive_player_name_map_from_host.rpc_id(peer_id, _peer_id_to_player_name_map)
		var room_config_bytes: PackedByteArray = _current_room_config.convert_to_bytes()
		_receive_room_config_from_host.rpc_id(peer_id, room_config_bytes)
	
	_update_player_list_in_room_menu()


func _on_peer_disconnected(_id: int):
	_update_player_list_in_room_menu()


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

	_title_screen.switch_to_tab(TitleScreen.Tab.LAN_LOBBY)
	_lan_room_menu.display_room_config(_current_room_config)

	var local_player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	_give_local_player_name_to_host.rpc_id(SERVER_PEER_ID, local_player_name)

	_update_player_list_in_room_menu()


# NOTE: need to scan for rooms only while room list menu is
# visible. Otherwise, will run into problems if the client
# is scanning for rooms and advertising at the same time.
func _on_lan_room_list_menu_visibility_changed():
	var room_scanner_enabled: bool = _lan_room_list_menu.visible
	_lan_room_scanner.set_enabled(room_scanner_enabled)


func _on_lan_room_list_menu_create_room_pressed():
	_title_screen.switch_to_tab(TitleScreen.Tab.CREATE_LAN_MATCH)


func _on_lan_room_list_menu_join_pressed():
	var selected_room_address: String = _lan_room_list_menu.get_selected_room_address()
	
	var nothing_selected: bool = selected_room_address.is_empty()
	if nothing_selected:
		Utils.show_popup_message(self, "Error", "You must select a room first.")
		
		return
	
	_connect_to_room(selected_room_address)

	var room_map: Dictionary = _lan_room_scanner.get_room_map()
	var room_info: RoomInfo = room_map[selected_room_address]
	_current_room_config = room_info.get_room_config()

	_title_screen.switch_to_tab(TitleScreen.Tab.LAN_LOBBY)
	_lan_room_menu.display_room_config(_current_room_config)


func _on_lan_room_menu_start_pressed():
	var is_host: bool = multiplayer.is_server()
	if !is_host:
		Utils.show_popup_message(self, "Error", "Only the host can start the game.")
		
		return
	
	Globals.set_connection_type(Globals.ConnectionType.ENET)
	
	var difficulty: Difficulty.enm = _current_room_config.get_difficulty()
	var game_length: int = _current_room_config.get_game_length()
	var game_mode: GameMode.enm = _current_room_config.get_game_mode()
	var origin_seed: int = randi()
	
	_title_screen.start_game.rpc(PlayerMode.enm.COOP, game_length, game_mode, difficulty, origin_seed)


func _on_lan_room_list_menu_join_address_pressed():
	var room_address: String = _lan_room_list_menu.get_entered_address()
	
	if room_address.is_empty():
		Utils.show_popup_message(self, "Error", "You must enter an address first.")
		
		return
	
	_connect_to_room(room_address)
	
	_title_screen.switch_to_tab(TitleScreen.Tab.LAN_LOBBY)


func _on_lan_room_menu_back_pressed():
# 	NOTE: when host closes the room menu, set room config to
# 	null to stop advertising
	var is_server: bool = multiplayer.is_server()
	if is_server:
		_lan_room_advertiser.set_room_config(null)
	
#	NOTE: both server and clients need to close the
#	connection when leaving room menu
	multiplayer.multiplayer_peer.close()
