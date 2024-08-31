class_name RoomInfo


enum Field {
	ROOM_CONFIG,
	CREATOR,
	CREATE_TIME,
	ADDRESS,
	COUNT,
}

var _room_config: RoomConfig = null
var _creator: String = ""
var _create_time: float = 0
# NOTE: address field is set when room scanner recieves room info. Empty until then.
var _address: String = ""


#########################
###     Built-in      ###
#########################

func _init(room_config: RoomConfig, creator: String, create_time: float):
	_room_config = room_config
	_creator = creator
	_create_time = create_time


#########################
###       Public      ###
#########################

func convert_to_bytes() -> PackedByteArray:
	var dict: Dictionary = {}
	var room_config_bytes: PackedByteArray = _room_config.convert_to_bytes()
	dict[Field.ROOM_CONFIG] = room_config_bytes
	dict[Field.CREATOR] = _creator
	dict[Field.CREATE_TIME] = _create_time
	dict[Field.ADDRESS] = _address
	var bytes: PackedByteArray = var_to_bytes(dict)
	
	return bytes


static func convert_from_bytes(bytes: PackedByteArray) -> RoomInfo:
	var dict: Dictionary = Utils.convert_bytes_to_dict(bytes)
	
	var dict_is_valid: bool = Utils.check_dict_has_fields(dict, Field.COUNT)
	if !dict_is_valid:
		return null
	
	var room_config_bytes: PackedByteArray = dict[Field.ROOM_CONFIG]
	var room_config: RoomConfig = RoomConfig.convert_from_bytes(room_config_bytes)

	if room_config == null:
		return null
	
	var creator: String = dict[Field.CREATOR]
	var create_time: float = dict[Field.CREATE_TIME]
	var address: String = dict[Field.ADDRESS]
	
	var room_info: RoomInfo = RoomInfo.new(room_config, creator, create_time)
	room_info.set_address(address)
	
	return room_info


func get_display_string() -> String:
	var room_config_string: String = _room_config.get_display_string()
	var create_time_string: String = Utils.convert_unix_time_to_string(_create_time)
	var string: String = "%s Created by %s %s" % [room_config_string, _creator, create_time_string]
	
	return string


func get_room_config() -> RoomConfig:
	return _room_config


func set_address(value: String):
	_address = value


func get_address() -> String:
	return _address


func get_create_time() -> float:
	return _create_time
