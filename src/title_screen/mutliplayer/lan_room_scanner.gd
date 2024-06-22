class_name LanRoomScanner extends Node


# Scans for rooms on LAN. Sends broadcast packets on the
# network. Listens for response packets from room hosts.
# Collects info about available rooms.

signal room_list_changed()


var _peer: PacketPeerUDP = PacketPeerUDP.new()
var _room_map: Dictionary = {}
var _enabled: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
	var broadcast_address: String = _get_broadcast_address()
	_peer.set_dest_address(broadcast_address, Constants.ROOM_SCANNER_SEND_PORT)
	_peer.set_broadcast_enabled(true)
	
	_peer.bind(Constants.ROOM_ADVERTISER_SEND_PORT)


func _process(_delta: float):
	while _peer.get_available_packet_count() > 0:
		var packet_bytes: PackedByteArray = _peer.get_packet()
		var packet: Packet = Packet.convert_from_bytes(packet_bytes)
		var packet_type: Packet.Type = packet.get_type()
		
		var packet_type_match: bool = packet_type == Packet.Type.ADVERTISE_ROOM
		if !packet_type_match:
			continue
		
		var room_info: RoomInfo = packet.get_room_info()
		
		if room_info == null:
			push_error("Received invalid ADVERTISE_ROOM packet: %s" % packet_bytes)
			
			continue
		
		var room_address: String = _peer.get_packet_ip()
		room_info.set_address(room_address)
		
		var have_room_for_this_address: bool = _room_map.has(room_address)
		
#		NOTE: if have room for address, detect changes by comparing create times
		if have_room_for_this_address:
			var current_room: RoomInfo = _room_map[room_address]
			var room_changed_for_address: bool = current_room.get_create_time() != room_info.get_create_time()
			
			if room_changed_for_address:
				_room_map[room_address] = room_info
				room_list_changed.emit()
		else:
			_room_map[room_address] = room_info
			room_list_changed.emit()


#########################
###       Public      ###
#########################

func set_enabled(value: bool):
	_enabled = value


func get_room_map() -> Dictionary:
	return _room_map


#########################
###      Private      ###
#########################

# Use the last ipv4 address
func _get_broadcast_address() -> String:
	var local_address_list: Array = IP.get_local_addresses()
	local_address_list.reverse()

	var last_local_address: String = ""

	for address in local_address_list:
		var address_is_ipv4: bool = address.count(".") == 3
		var address_is_private_network: bool = address.begins_with("10.") || address.begins_with("172.") || address.begins_with("192.")

		if address_is_ipv4 && address_is_private_network:
			last_local_address = address

			break

#	TODO: handle failure
	if last_local_address == "":
		return ""

#	Replace last part with "255" to make a broadcast
#	adddress
	var address_split: Array = last_local_address.split(".")
	address_split[address_split.size() - 1] = "255"
	var broadcast_address: String = ".".join(address_split)
	
	return broadcast_address


#########################
###     Callbacks     ###
#########################

func _on_scan_timer_timeout():
	if !_enabled:
		return
	
	var packet: Packet = Packet.make_scan_room()
	var packet_bytes: PackedByteArray = packet.convert_to_bytes()
	_peer.put_packet(packet_bytes)
