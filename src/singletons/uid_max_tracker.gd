extends Node


# This class is used to assign UID's to newly created game
# objects. UID's start at 1 when the game starts and go up.
# 
# NOTE: Godot already has a built-in id system but we
# can't use it because it casuses desyns in multiplayer.


enum Type {
	UNIT,
	ITEM,
	AUTOCAST,
	ITEM_CONTAINER,
	PROJECTILE,
	MANUAL_TIMER,
}


var _uid_max_map: Dictionary = {}


func reset():
	_uid_max_map.clear()


func get_uid_max(type: Type) -> int:
	if !_uid_max_map.has(type):
		_uid_max_map[type] = 1

	var uid_max: int = _uid_max_map[type]

	return uid_max


func get_uid_max_and_increment(type: Type) -> int:
	var uid_max: int = get_uid_max(type)

	_uid_max_map[type] = _uid_max_map[type] + 1

	return uid_max
