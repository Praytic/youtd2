class_name LanRoomAdvertiser extends Node


# Advertises a LAN room created on this game client.
# Advertising is performed as a reply to scans from
# LanRoomScanner.


var _peer: PacketPeerUDP = PacketPeerUDP.new()
var _room_info: RoomInfo = null


#########################
###     Built-in      ###
#########################

# NOTE: not setting dest address/port for peer here because it will
# need to be dynamically switched to send to specific room scanner
func _ready():
	var bind_result: Error = _peer.bind(Constants.ROOM_SCANNER_SEND_PORT)
	
	if bind_result != OK:
		push_error("Failed to setup room advertiser LISTEN. Details: %s" % error_string(bind_result))


# NOTE: need to get_packet() even while having no room to advertise it, to clear the packet from peer.
func _process(_delta: float):
	while _peer.get_available_packet_count() > 0:
		print_verbose("Received room scan packet")

		var packet_bytes: PackedByteArray = _peer.get_packet()
		
		var have_room_to_advertise: bool = _room_info != null
		if !have_room_to_advertise:
			continue
		
		var packet: Packet = Packet.convert_from_bytes(packet_bytes)
		var packet_type: Packet.Type = packet.get_type()
		var packet_type_match: bool = packet_type == Packet.Type.SCAN_ROOM
		
		if !packet_type_match:
			push_error("Packet has wrong type: %s" % packet_type)

			continue
		
		var scanner_address: String = _peer.get_packet_ip()
		_peer.set_dest_address(scanner_address, Constants.ROOM_ADVERTISER_SEND_PORT)
		
		var response_packet: Packet = Packet.make_advertise_room(_room_info)
		var response_packet_bytes: PackedByteArray = response_packet.convert_to_bytes()
		_peer.put_packet(response_packet_bytes)


#########################
###       Public      ###
#########################

func set_room_config(room_config: RoomConfig):
	var local_player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	var create_time: float = Time.get_unix_time_from_system()
	
	_room_info = RoomInfo.new(room_config, local_player_name, create_time)
