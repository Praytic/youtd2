extends Node

# This class keeps track of game time.


var _current_game_time: float


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

func reset():
	_current_game_time = 0


# NOTE: Game.getGameTime() in JASS
# Returns time in seconds since the game started. Note that
# this doesn't include the time spent in pre game menu or
# pause menu.
func get_time() -> float:
	return _current_game_time


# Returns current time of day in the game world, in hours.
# Between 0.0 and 24.0.
# NOTE: GetFloatGameState(GAME_STATE_TIME_OF_DAY) in JASS
func get_time_of_day() -> float:
	var irl_seconds: float = GameTime.get_time()
	var game_world_hours: float = Constants.INITIAL_TIME_OF_DAY + irl_seconds * Constants.IRL_SECONDS_TO_GAME_WORLD_HOURS
	var time_of_day: float = fmod(game_world_hours, 24.0)

	return time_of_day
