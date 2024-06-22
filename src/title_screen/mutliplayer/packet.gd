class_name Packet


# Functions and constants which are used to create network
# packets for communication before game connection is
# establish. Note that these packets are not used after
# clients are connected because at that point it's possible
# to use RPC calls.


enum Type
{
	UNKNOWN,
	SCAN_ROOM,
	ADVERTISE_ROOM,
}

enum Field
{
	TYPE,
	ROOM_INFO,
}

var _data: Dictionary = {}


#########################
###       Public      ###
#########################

func convert_to_bytes() -> PackedByteArray:
	var bytes: PackedByteArray = var_to_bytes(_data)
	
	return bytes


static func convert_from_bytes(bytes: PackedByteArray) -> Packet:
	var packet: Packet = Packet.new()
	packet._data = Utils.convert_bytes_to_dict(bytes)
	
	return packet


func get_type() -> Packet.Type:
	var type: Packet.Type = _data.get(Packet.Field.TYPE, Packet.Type.UNKNOWN)
	
	return type


static func make_scan_room() -> Packet:
	var packet: Packet = Packet.new()
	packet._data[Packet.Field.TYPE] = Packet.Type.SCAN_ROOM
	
	return packet


static func make_advertise_room(room_info: RoomInfo) -> Packet:
	var packet: Packet = Packet.new()
	packet._data[Packet.Field.TYPE] = Packet.Type.ADVERTISE_ROOM
	var room_info_bytes: PackedByteArray = room_info.convert_to_bytes()
	packet._data[Packet.Field.ROOM_INFO] = room_info_bytes
	
	return packet


func get_room_info() -> RoomInfo:
	var room_info_bytes: PackedByteArray = _data.get(Packet.Field.ROOM_INFO, PackedByteArray())
	var room_info: RoomInfo = RoomInfo.convert_from_bytes(room_info_bytes)
	
	return room_info
