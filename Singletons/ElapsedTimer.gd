extends Node


# Measures elapsed time between two points in time. Use by
# putting start() and end() calls around the code that you
# want to measure.


var _elapsed_timer_map: Dictionary = {}


func start(timer_name: String):
	if _elapsed_timer_map.has(timer_name):
		push_error("Timer already in progress for name:", timer_name)

		return

	var start_time: float = Time.get_ticks_msec() / 1000.0
	_elapsed_timer_map[timer_name] = start_time


func end(timer_name: String):
	_end_internal(timer_name, false)


func end_verbose(timer_name: String):
	_end_internal(timer_name, true)


func _end_internal(timer_name: String, verbose: bool):
	if !_elapsed_timer_map.has(timer_name):
		push_error("Timer hasn't been started for name:", timer_name)

		return

	var start_time: float = _elapsed_timer_map[timer_name]
	var end_time: float = Time.get_ticks_msec() / 1000.0
	var elapsed_time: float = end_time - start_time
	var time_string: String = Utils.format_float(elapsed_time, 8)
	var message: String = "Elapsed time for %s = %s" % [timer_name, time_string]

	if verbose:
		print_verbose(message)
	else:
		print(message)

	_elapsed_timer_map.erase(timer_name)
