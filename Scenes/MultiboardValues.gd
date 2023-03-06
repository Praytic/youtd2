class_name MultiboardValues
extends Node


var _size: int = 0
var _key_map: Dictionary = {}
var _value_map: Dictionary = {}


func _init(size_arg: int):
	_size = size_arg

	for index in range(0, _size):
		_key_map[index] = ""
		_value_map[index] = ""


func set_key(index: int, key: String):
	_key_map[index] = key


func set_value(index: int, value: String):
	_value_map[index] = value


func size() -> int:
	return _size


func get_key(index: int) -> String:
	var key: String = _key_map[index]

	return key


func get_value(index: int) -> String:
	var value: String = _value_map[index]

	return value
