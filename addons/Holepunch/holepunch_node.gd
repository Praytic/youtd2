extends Node

#Signal is emitted when holepunch is complete. Connect this signal to your network manager
#Once your network manager received the signal they can host or join a game on the host port
signal hole_punched(my_port, hosts_port, hosts_address)

#This signal is emitted when the server has acknowledged your client registration, but before the
#address and port of the other client have arrived.
signal session_registered

var server_udp = PacketPeerUDP.new()
var peer_udp = PacketPeerUDP.new()

#Set the rendevouz address to the IP address of your third party server
@export var rendevouz_address = "" 
#Set the rendevouz port to the port of your third party server
@export var rendevouz_port = 4000
#This is the range of ports you will search if you hear no response from the first port tried
@export var port_cascade_range = 10
#The amount of messages of the same type you will send before cascading or giving up
@export var response_window = 5


var found_server = false
var recieved_peer_info = false
var recieved_peer_greet = false
var recieved_peer_confirm = false
var recieved_peer_go = false

var is_host = false

var own_port
var peer = {}
var host_address = ""
var host_port = 0
var client_name
var p_timer
var session_id

var ports_tried = 0
var greets_sent = 0
var gos_sent = 0

const REGISTER_SESSION = "rs:"
const REGISTER_CLIENT = "rc:"
const EXCHANGE_PEERS = "ep:"
const CHECKOUT_CLIENT = "cc:"
const PEER_GREET = "greet"
const PEER_CONFIRM = "confirm"
const PEER_GO = "go"
const SERVER_OK = "ok"
const SERVER_INFO = "peers"

const MAX_PLAYER_COUNT = 2

# warning-ignore:unused_argument
func _process(delta):
	if peer_udp.get_available_packet_count() > 0:
		var array_bytes = peer_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		if not recieved_peer_greet:
			if packet_string.begins_with(PEER_GREET):
				var m = packet_string.split(":")
				_handle_greet_message(m[1], int(m[2]), int(m[3]))

		if not recieved_peer_confirm:
			if packet_string.begins_with(PEER_CONFIRM):
				var m = packet_string.split(":")
				_handle_confirm_message(m[2], m[1], m[4], m[3])

		elif not recieved_peer_go:
			if packet_string.begins_with(PEER_GO):
				var m = packet_string.split(":")
				_handle_go_message(m[1])

	if server_udp.get_available_packet_count() > 0:
		var array_bytes = server_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		if packet_string.begins_with(SERVER_OK):
			var m = packet_string.split(":")
			own_port = int( m[1] )
			emit_signal('session_registered')
			if is_host:
				if !found_server:
					_send_client_to_server()
			found_server=true

		if not recieved_peer_info:
			if packet_string.begins_with(SERVER_INFO):
				server_udp.close()
				packet_string = packet_string.right(6)
				if packet_string.length() > 2:
					var m = packet_string.split(":")
					peer[m[0]] = {"port":m[2], "address":m[1]}
					recieved_peer_info = true
					start_peer_contact()


func _handle_greet_message(peer_name, peer_port, my_port):
	if own_port != my_port:
		own_port = my_port
		peer_udp.close()
		peer_udp.listen(own_port, "*")
	recieved_peer_greet = true


func _handle_confirm_message(peer_name, peer_port, my_port, is_host):
	if peer[peer_name].port != peer_port:
		peer[peer_name].port = peer_port

	peer[peer_name].is_host = is_host
	if is_host:
		host_address = peer[peer_name].address
		host_port = peer[peer_name].port
	peer_udp.close()
	peer_udp.listen(own_port, "*")
	recieved_peer_confirm = true


func _handle_go_message(peer_name):
	recieved_peer_go = true
	emit_signal("hole_punched", int(own_port), int(host_port), host_address)
	peer_udp.close()
	p_timer.stop()
	set_process(false)


func _cascade_peer(add, peer_port):
	for i in range(peer_port - port_cascade_range, peer_port + port_cascade_range):
		peer_udp.set_dest_address(add, i)
		var buffer = PackedByteArray()
		buffer.append_array(("greet:"+client_name+":"+str(own_port)+":"+str(i)).to_utf8_buffer())
		peer_udp.put_packet(buffer)
		ports_tried += 1


func _ping_peer():
	
	if not recieved_peer_confirm and greets_sent < response_window:
		for p in peer.keys():
			peer_udp.set_dest_address(peer[p].address, int(peer[p].port))
			var buffer = PackedByteArray()
			buffer.append_array(("greet:"+client_name+":"+str(own_port)+":"+peer[p].port).to_utf8_buffer())
			peer_udp.put_packet(buffer)
			greets_sent+=1
			if greets_sent == response_window:
				print("Receiving no confirm. Starting port cascade")
				#if the other player hasn't responded we should try more ports

	if not recieved_peer_confirm and greets_sent == response_window:
		for p in peer.keys():
			_cascade_peer(peer[p].address, int(peer[p].port))
		greets_sent += 1

	if recieved_peer_greet and not recieved_peer_go:
		for p in peer.keys():
			peer_udp.set_dest_address(peer[p].address, int(peer[p].port))
			var buffer = PackedByteArray()
			buffer.append_array(("confirm:"+str(own_port)+":"+client_name+":"+str(is_host)+":"+peer[p].port).to_utf8_buffer())
			peer_udp.put_packet(buffer)

	if  recieved_peer_confirm:
		for p in peer.keys():
			peer_udp.set_dest_address(peer[p].address, int(peer[p].port))
			var buffer = PackedByteArray()
			buffer.append_array(("go:"+client_name).to_utf8_buffer())
			peer_udp.put_packet(buffer)
		gos_sent += 1

		if gos_sent >= response_window: #the other player has confirmed and is probably waiting
			emit_signal("hole_punched", int(own_port), int(host_port), host_address)
			p_timer.stop()
			set_process(false)


func start_peer_contact():	
	server_udp.put_packet("goodbye".to_utf8_buffer())
	server_udp.close()
	if peer_udp.is_bound():
		peer_udp.close()
	var err = peer_udp.listen(own_port, "*")
	if err != OK:
		print("Error listening on port: " + str(own_port) +" Error: " + str(err))
	p_timer.start()


#this function can be called to the server if you want to end the holepunch before the server closes the session
func finalize_peers(id):
	var buffer = PackedByteArray()
	buffer.append_array((EXCHANGE_PEERS+str(id)).to_utf8_buffer())
	server_udp.set_dest_address(rendevouz_address, rendevouz_port)
	server_udp.put_packet(buffer)


# remove a client from the server
func checkout():
	var buffer = PackedByteArray()
	buffer.append_array((CHECKOUT_CLIENT+client_name).to_utf8_buffer())
	server_udp.set_dest_address(rendevouz_address, rendevouz_port)
	server_udp.put_packet(buffer)


#Call this function when you want to start the holepunch process
func start_traversal(id, is_player_host, player_name):
	if server_udp.is_bound():
		server_udp.close()

	var err = server_udp.bind(rendevouz_port, "*")
	if err != OK:
		print("Error listening on port: " + str(rendevouz_port) + " to server: " + rendevouz_address)

	is_host = is_player_host
	client_name = player_name
	found_server = false
	recieved_peer_info = false
	recieved_peer_greet = false
	recieved_peer_confirm = false
	recieved_peer_go = false
	peer = {}

	ports_tried = 0
	greets_sent = 0
	gos_sent = 0
	session_id = id
	
	if (is_host):
		var buffer = PackedByteArray()
		buffer.append_array((REGISTER_SESSION+session_id+":"+str(MAX_PLAYER_COUNT)).to_utf8_buffer())
		server_udp.close()
		server_udp.set_dest_address(rendevouz_address, rendevouz_port)
		server_udp.put_packet(buffer)
	else:
		_send_client_to_server()


#Register a client with the server
func _send_client_to_server():
	await get_tree().create_timer(2.0).timeout
	var buffer = PackedByteArray()
	buffer.append_array((REGISTER_CLIENT+client_name+":"+session_id).to_utf8_buffer())
	server_udp.close()
	server_udp.set_dest_address(rendevouz_address, rendevouz_port)
	server_udp.put_packet(buffer)


func _exit_tree():
	server_udp.close()


func _ready():
	p_timer = Timer.new()
	get_node("/root/").call_deferred("add_child", p_timer)
	p_timer.timeout.connect(_ping_peer)
	p_timer.wait_time = 0.1
