class_name ManualTimer extends Node

# ManualTimer should be used instead of native Timer for all
# code which modifies game state. This is to ensure
# determinism in multiplayer.


signal timeout()

var wait_time: float = 0.0
var _time_left: float = 0.0
var one_shot: bool = true
var _stopped: bool = true


#########################
###     Built-in      ###
#########################

func _ready():
	add_to_group("manual_timers")


#########################
###       Public      ###
#########################

func start():
	_time_left = wait_time
	_stopped = false


func update(delta: float):
	if _stopped:
		return
	
	_time_left -= delta
	
#	NOTE: need to use is_zero_approx() to handle floats being off from 0 by a small amount
	var reached_timeout: bool = _time_left < 0.0 || is_zero_approx(_time_left)
	
	if reached_timeout:
		timeout.emit()
		
		if one_shot:
			_stopped = true
		else:
			_time_left = wait_time


func is_stopped() -> bool:
	return _stopped


func get_time_left() -> float:
	return _time_left
