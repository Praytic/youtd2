extends Node


# Measures elapsed time between two points in time. Use by
# putting start() and end() calls around the code that you
# want to measure.


var _elapsed_timer_map: Dictionary = {}


func start(timer_name: String):
	if _elapsed_timer_map.has(timer_name):
		push_error("Timer already in progress for name:", timer_name)

		return

	var start_time: float = Utils.get_game_time()
	_elapsed_timer_map[timer_name] = start_time


func end(timer_name: String):
	if !_elapsed_timer_map.has(timer_name):
		push_error("Timer hasn't been started for name:", timer_name)

		return

	var start_time: float = _elapsed_timer_map[timer_name]
	var end_time: float = Utils.get_game_time()
	var elapsed_time: float = end_time - start_time
	var time_string: String = Utils.format_float(elapsed_time, 4)
	print("Elapsed time for %s = %s" % [timer_name, time_string])

	_elapsed_timer_map.erase(timer_name)
