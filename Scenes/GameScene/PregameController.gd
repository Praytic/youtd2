class_name PregameController extends Node


# Controls logic flow during pregame state where players are
# selecting game settings.


# Emitted when player has selected game settings which are
# specific to multiplayer host. These settings need to be
# broadcasted to other peers.
signal selected_host_settings()
# Emitted when pregame menu is finished, player has selected
# game settings and builder.
signal finished()

# Default game server port. Can be any number between 1024
# and 49151. Not present on the list of registered or common
# ports as of December 2022:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 8910

var _game_length: int
var _difficulty: Difficulty.enm
var _game_mode: GameMode.enm
var _tutorial_enabled: bool
var _builder_id: int

@export var _pregame_hud: PregameHUD


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.player_requested_to_host_room.connect(_on_player_requested_to_host_room)
	EventBus.player_requested_to_join_room.connect(_on_player_requested_to_join_room)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


#########################
###       Public      ###
#########################

func start():
	var show_pregame_settings_menu: bool = Config.show_pregame_settings_menu()

	if show_pregame_settings_menu:
		_pregame_hud.show()
	else:
#		Use default setting values when skipping pregame
#		settings
		_game_length = Config.default_game_length()
		_difficulty = Config.default_difficulty()
		_game_mode = Config.default_game_mode()
		_builder_id = Config.default_builder()
		_tutorial_enabled = Config.default_tutorial_enabled()
		
		selected_host_settings.emit()
		_finish()


# NOTE: for host, this will just advance to next tab. For
# peer, this will skip to builder tab.
func go_to_builder_tab():
	_pregame_hud.change_tab(PregameHUD.Tab.BUILDER)


func get_game_length() -> int:
	return _game_length


func get_game_mode() -> GameMode.enm:
	return _game_mode


func get_difficulty() -> Difficulty.enm:
	return _difficulty


func get_builder_id() -> int:
	return _builder_id


func get_tutorial_enabled() -> bool:
	return _tutorial_enabled


#########################
###      Private      ###
#########################

func _finish():
	_pregame_hud.hide()
	finished.emit()
	

#########################
###     Callbacks     ###
#########################

func _on_pregame_hud_tab_finished():
	var current_tab: PregameHUD.Tab = _pregame_hud.get_current_tab()
	var player_mode: PlayerMode.enm = _pregame_hud.get_player_mode()
	
	match current_tab:
		PregameHUD.Tab.PLAYER_MODE:
			match player_mode:
				PlayerMode.enm.SINGLE: _pregame_hud.change_tab(PregameHUD.Tab.GAME_LENGTH)
				PlayerMode.enm.COOP: _pregame_hud.change_tab(PregameHUD.Tab.COOP_ROOM)
				PlayerMode.enm.SERVER: push_error("unhandled case")
		PregameHUD.Tab.COOP_ROOM:
#			NOTE: do nothing for this case because
#			advancement from this tab is handled in other
#			callbacks.
			return
		PregameHUD.Tab.GAME_LENGTH:
			_game_length = _pregame_hud.get_game_length()
			_pregame_hud.change_tab(PregameHUD.Tab.DISTRIBUTION)
		PregameHUD.Tab.DISTRIBUTION:
			_game_mode = _pregame_hud.get_game_mode()
			_pregame_hud.change_tab(PregameHUD.Tab.DIFFICULTY)
		PregameHUD.Tab.DIFFICULTY:
			_difficulty = _pregame_hud.get_difficulty()
			selected_host_settings.emit()
		PregameHUD.Tab.BUILDER:
			_builder_id = _pregame_hud.get_builder_id()

#			NOTE: show tutorial tab only if singleplayer was
#			selected
			match player_mode:
				PlayerMode.enm.SINGLE: _pregame_hud.change_tab(PregameHUD.Tab.TUTORIAL_QUESTION)
				PlayerMode.enm.COOP: _finish()
				PlayerMode.enm.SERVER: push_error("unhandled case")
				
		PregameHUD.Tab.TUTORIAL_QUESTION:
			_tutorial_enabled = _pregame_hud.get_tutorial_enabled()
			_finish()


func _on_player_requested_to_host_room():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Maximum of 1 peer, since it's a 2-player co-op.
	var create_server_error: Error = peer.create_server(DEFAULT_PORT, 1)
	if create_server_error != OK:
		# Is another server running?
		var error_text: String = "Can't host, port [%s] in use." % DEFAULT_PORT
		push_error(error_text)
		_pregame_hud.show_network_status(error_text)

		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	_pregame_hud.show_network_status("Waiting for player...")
	_pregame_hud.change_tab(PregameHUD.Tab.GAME_LENGTH)


func _on_player_requested_to_join_room():
	var address_string: String = _pregame_hud.get_room_address()
	
#	TODO: check validity more thoroughly
	var address_is_valid: bool = address_string.split(":", false).size() == 2
	
	if !address_is_valid:
		_pregame_hud.show_address_error()
		
		return
	
	var address_details: Array = address_string.split(":")

	var host_address: String = address_details[0]
	var host_port: int = address_details[1].to_int()

	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_client_error: Error = peer.create_client(host_address, host_port)

	if create_client_error != OK:
		# Is another server running?
		var error_text: String = "Failed to create client. Error:" % create_client_error
		push_error(error_text)
		_pregame_hud.show_network_status(error_text)

		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	_pregame_hud.show_network_status("Connecting to [%s]..." % address_string)
	_pregame_hud.change_tab(PregameHUD.Tab.WAITING_FOR_HOST)


func _on_peer_connected(id: int):
#	NOTE: need to check that server received this callback
#	because peers also receive this callback when they
#	connect. Only do stuff if server received callback.
	if !multiplayer.is_server():
		return

	_pregame_hud.show_network_status("Player [%s] connected to this server." % id)


func _on_peer_disconnected(id: int):
	_pregame_hud.show_network_status("Player [%s] disconnected from this server." % id)


func _on_connected_to_server():
	_pregame_hud.show_network_status("Successfully connected to a server.")


func _on_connection_failed():
	_pregame_hud.show_network_status("Couldn't connect to a server.")


func _on_server_disconnected():
	_pregame_hud.show_network_status("Disconnected from a server.")
