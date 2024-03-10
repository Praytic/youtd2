class_name GameTime extends Node


# Counts game time. You can access this globally via Utils.


var _current_game_time: float = 0.0


#########################
###     Built-in      ###
#########################

func _process(delta: float):
	var need_to_record_game_time: bool = Globals.get_game_state() == Globals.GameState.PLAYING && WaveLevel.get_current() > 0

	if need_to_record_game_time:
		_current_game_time += delta


#########################
###       Public      ###
#########################

# Returns time in seconds since the game started. Starts
# counting after first wave begins. Doesn't count time spent
# in pause menu.
func get_time() -> float:
	return _current_game_time
