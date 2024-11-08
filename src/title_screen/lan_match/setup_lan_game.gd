class_name SetupLanGame extends Node


# Handles logic for creating and joining LAN matches.

# TODO: restore. This got broken when adding Online matches.

# TODO: fix sharing player names. Currently only works in
# Online matches.


const SERVER_PEER_ID: int = 1


var _current_match_config: MatchConfig = null


@export var _title_screen: TitleScreen
@export var _lan_connect_menu: LanConnectMenu
@export var _lan_lobby_menu: LanLobbyMenu
@export var _create_lan_match_menu: CreateLanMatchMenu

var _peer_id_to_player_name_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


#########################
###      Private      ###
#########################

func _update_player_list_in_lobby_menu():
	var peer_id_list: Array = multiplayer.get_peers()
	var local_peer_id: int = multiplayer.get_unique_id()
	peer_id_list.append(local_peer_id)

	var player_list: Array[String] = []

	for peer_id in peer_id_list:
		var fallback_string: String = "Player %d" % peer_id
		var player_name: String = _peer_id_to_player_name_map.get(peer_id, fallback_string)
		player_list.append(player_name)
	
	_lan_lobby_menu.set_player_list(player_list)


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
	_update_player_list_in_lobby_menu()


@rpc("authority", "call_local", "reliable")
func _receive_match_config_from_host(match_config_bytes: PackedByteArray):
	_current_match_config = MatchConfig.convert_from_bytes(match_config_bytes)
	_lan_lobby_menu.display_match_config(_current_match_config)


func _connect_to_lobby(address: String) -> bool:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_client_result: Error = peer.create_client(address, Constants.SERVER_PORT)

	if create_client_result != OK:
		Utils.show_popup_message(self, "Error", "Failed to create client. Details:" % error_string(create_client_result))

		return false

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	return true


# This check is needed in case current MultiplayerPeer is
# set to NakamaMultiplayerPeer, which means that all signals
# should be ignored.
func _multiplayer_peer_is_enet() -> bool:
	var multiplayer_peer: MultiplayerPeer = multiplayer.get_multiplayer_peer()
	var peer_is_enet: bool = multiplayer_peer is ENetMultiplayerPeer

	return peer_is_enet


func _determine_host_address() -> String:
	var address: String = ""

	if OS.has_feature("windows"):
		if OS.has_environment("COMPUTERNAME"):
			address = IP.resolve_hostname(OS.get_environment("COMPUTERNAME"), IP.Type.TYPE_IPV4)
	elif OS.has_feature("x11"):
		if OS.has_environment("HOSTNAME"):
			address = IP.resolve_hostname(OS.get_environment("HOSTNAME"), IP.Type.TYPE_IPV4)
	elif OS.has_feature("OSX"):
		if OS.has_environment("HOSTNAME"):
			address = IP.resolve_hostname(OS.get_environment("HOSTNAME"), IP.Type.TYPE_IPV4)

	if !address.is_empty():
		return address
	else:
		return "UNKNOWN"


#########################
###     Callbacks     ###
#########################

func _on_connected_to_server():
	if !_multiplayer_peer_is_enet():
		return

	var local_player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	_give_local_player_name_to_host.rpc_id(SERVER_PEER_ID, local_player_name)


func _on_peer_connected(peer_id: int):
	if !_multiplayer_peer_is_enet():
		return

# 	When a new peer connects, host(server) will tell the
# 	newly connected peer the names of all of the players.
	if multiplayer.is_server():
		_receive_player_name_map_from_host.rpc_id(peer_id, _peer_id_to_player_name_map)
		var match_config_bytes: PackedByteArray = _current_match_config.convert_to_bytes()
		_receive_match_config_from_host.rpc_id(peer_id, match_config_bytes)
	
	_update_player_list_in_lobby_menu()


func _on_peer_disconnected(_id: int):
	if !_multiplayer_peer_is_enet():
		return

	_update_player_list_in_lobby_menu()


func _on_create_lan_match_menu_create_pressed():
	_current_match_config = _create_lan_match_menu.get_match_config()

	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Maximum of 1 peer, since it's a 2-player co-op.
	var create_server_result: Error = peer.create_server(Constants.SERVER_PORT, 1)
	if create_server_result != OK:
		Utils.show_popup_message(self, "Error", "Failed to create server, port might already be in use. Details: %s." % error_string(create_server_result))

		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	_title_screen.switch_to_tab(TitleScreen.Tab.LAN_LOBBY)
	_lan_lobby_menu.display_match_config(_current_match_config)
	var host_address: String = _determine_host_address()
	_lan_lobby_menu.set_host_address(host_address)
	_lan_lobby_menu.set_host_address_visible(true)
	_lan_lobby_menu.set_start_button_visible(true)

	var local_player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	_give_local_player_name_to_host.rpc_id(SERVER_PEER_ID, local_player_name)

	_update_player_list_in_lobby_menu()


func _on_lan_connect_menu_create_pressed():
	_title_screen.switch_to_tab(TitleScreen.Tab.CREATE_LAN_MATCH)


func _on_lan_lobby_menu_start_pressed():
	var is_host: bool = multiplayer.is_server()
	if !is_host:
		Utils.show_popup_message(self, "Error", "Only the host can start the game.")
		
		return
	
	Globals._enet_peer_id_to_player_name = _peer_id_to_player_name_map
	
	var difficulty: Difficulty.enm = _current_match_config.get_difficulty()
	var game_length: int = _current_match_config.get_game_length()
	var game_mode: GameMode.enm = _current_match_config.get_game_mode()
	var team_mode: TeamMode.enm = _current_match_config.get_team_mode()
	var origin_seed: int = randi()
	
	_title_screen.start_game.rpc(PlayerMode.enm.MULTIPLAYER, game_length, game_mode, difficulty, team_mode, origin_seed, Globals.ConnectionType.ENET)


func _on_lan_connect_menu_join_pressed():
	var address: String = _lan_connect_menu.get_entered_address()
	
	if address.is_empty():
		Utils.show_popup_message(self, "Error", "You must enter an address first.")
		
		return
	
	_connect_to_lobby(address)
	
	_title_screen.switch_to_tab(TitleScreen.Tab.LAN_LOBBY)

	_lan_lobby_menu.set_host_address_visible(false)
	_lan_lobby_menu.set_start_button_visible(false)


# NOTE: both server and clients need to close the
# connection when leaving lobby menu
func _on_lan_lobby_menu_back_pressed():
	multiplayer.multiplayer_peer.close()
