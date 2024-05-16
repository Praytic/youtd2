class_name JoinOrHostController extends Node


signal completed()


# Default game server port. Can be any number between 1024
# and 49151. Not present on the list of registered or common
# ports as of December 2022:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 8910


@export var _join_or_host_menu: JoinOrHostMenu
@export var _room_menu: RoomMenu


func _on_join_or_host_menu_host_pressed():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Maximum of 1 peer, since it's a 2-player co-op.
	var create_server_error: Error = peer.create_server(DEFAULT_PORT, 1)
	if create_server_error != OK:
		# Is another server running?
		var error_text: String = "Can't host, port [%s] in use." % DEFAULT_PORT
		push_error(error_text)
		_join_or_host_menu.show_status(error_text)

		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	_room_menu.set_server_controls_disabled(false)
	
	completed.emit()


func _on_join_or_host_menu_join_pressed():
	var address_string: String = _join_or_host_menu.get_room_address()
	
#	TODO: check validity more thoroughly
	var address_is_valid: bool = address_string.split(":", false).size() == 2
	
	if !address_is_valid:
		_join_or_host_menu.show_address_error()
		
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
		_join_or_host_menu.show_status(error_text)

		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	_room_menu.set_server_controls_disabled(true)
	
	completed.emit()
