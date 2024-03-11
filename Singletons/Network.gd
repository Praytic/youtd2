extends Node


# Default game server port. Can be any number between 1024 and 49151.
# Not present on the list of registered or common ports as of December 2022:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 8910

signal status_changed(text: String, error: bool)

var _host_address_with_port: String : get = get_host_address_with_port

var peer = null

@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")

# Called when the node enters the scene tree for the first time.
func _ready():
	_game_scene.multiplayer.peer_connected.connect(_player_connected)
	_game_scene.multiplayer.peer_disconnected.connect(_player_disconnected)
	_game_scene.multiplayer.connected_to_server.connect(_connected_ok)
	_game_scene.multiplayer.connection_failed.connect(_connected_fail)
	_game_scene.multiplayer.server_disconnected.connect(_server_disconnected)


func change_status(status: String, error: bool):
	if error:
		push_error(status)
	else:
		print_verbose(status)
	status_changed.emit(status, error)


func _player_connected(id: int):
	change_status("Player [%s] connected to this server." % id, false)

func _player_disconnected(id: int):
	change_status("Player [%s] disconnected from this server." % id, false)

func _connected_ok():
	change_status("Successfully connected to a server.", false)

func _connected_fail():
	change_status("Couldn't connect to a server.", true)

func _server_disconnected():
	change_status("Disconnected from a server.", false)


func get_host_address_with_port() -> String:
	return _host_address_with_port


func connect_to_server(host_address: String, host_port: int):
	if not host_address.is_valid_ip_address():
		change_status("IP address is invalid [%s]." % host_address, true)
		return

	peer = ENetMultiplayerPeer.new()
	peer.create_client(host_address, host_port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	_game_scene.get_multiplayer().set_multiplayer_peer(peer)
	
	_host_address_with_port = "%s:%s" % [host_address, host_port]
	change_status("Connecting to [%s]..." % _host_address_with_port, false)


func create_server():
	peer = ENetMultiplayerPeer.new()
	# Maximum of 1 peer, since it's a 2-player co-op.
	var err = peer.create_server(DEFAULT_PORT, 1)
	if err != OK:
		# Is another server running?
		change_status("Can't host, port [%s] in use." % DEFAULT_PORT, true)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

	_game_scene.get_multiplayer().set_multiplayer_peer(peer)
	change_status("Waiting for player...", false)

