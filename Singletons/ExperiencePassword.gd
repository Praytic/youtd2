extends Node

# Functions for encoding/decoding player experience
# password.


const MAGIC_BYTES: Array = [0x64, 0x01, 0xDF, 0xEA, 0x7A, 0x17, 0x69, 0x35, 0x1B, 0x18, 0x02, 0xFF, 0x67, 0x11, 0xB0, 0xE1]


func decode(password: String) -> int:
	if password.is_empty():
		return 0
	
	var is_valid_hex: bool = password.is_valid_hex_number()
	if !is_valid_hex:
		push_error("password is not valid hex")

		return -1

#	NOTE: need to check for length because otherwise godot
#	will push errors about "uneven length"
	var is_even_length: bool = password.length() % 2 == 0
	if !is_even_length:
		push_error("password is not even length")

		return -1

	var byte_array: PackedByteArray = password.hex_decode()
	
	var byte_array_length_is_valid: bool = byte_array.size() == MAGIC_BYTES.size()
	if !byte_array_length_is_valid:
		push_error("password length doesn't match with magic")

		return -1
	
	for i in range(0, MAGIC_BYTES.size()):
		byte_array[i] = byte_array[i] ^ MAGIC_BYTES[i]

	var value_list: Array = []

	for byte_offset in range(0, MAGIC_BYTES.size(), 4):
		var value: int = byte_array.decode_s32(byte_offset) - byte_offset
		value_list.append(value)

	var exp_int: int = value_list[0]

	for value in value_list:
		if value != exp_int:
			push_error("password sub-values don't match up")

			return -1

	if exp_int < 0:
		push_error("exp int is negative")

		return -1

	return exp_int


func encode(exp_int: int) -> String:
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(MAGIC_BYTES.size())

	for byte_offset in range(0, MAGIC_BYTES.size(), 4):
		byte_array.encode_s32(byte_offset, exp_int + byte_offset)

	for i in range(0, MAGIC_BYTES.size()):
		byte_array[i] = byte_array[i] ^ MAGIC_BYTES[i]

	var password: String = byte_array.hex_encode()

	return password
