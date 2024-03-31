class_name GameTime extends Node


# Counts game time. You can access this globally via Utils.


var _current_game_time: float = 0.0
var _enabled: bool = false


#########################
###     Built-in      ###
#########################

func update(delta: float):
	if !_enabled:
		return

	_current_game_time += delta


#########################
###       Public      ###
#########################

func set_enabled(enabled: bool):
	_enabled = enabled


# Returns time in seconds since the game started. Starts
# counting after first wave begins. Doesn't count time spent
# in pause menu.
func get_time() -> float:
	return _current_game_time
