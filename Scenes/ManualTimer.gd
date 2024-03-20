class_name ManualTimer extends Node

# ManualTimer must be used instead of native Timer for
# everything except UI. ManualTimer ensures multiplayer
# determinism because it is updated inside the simulation
# tick. ManualTimer has the same API as native Timer.


signal timeout()

var _time_left: float = 0.0
@export var wait_time: float = 1.0
@export var one_shot: bool = false
@export var autostart: bool = false
var _stopped: bool = true
var _paused: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
	add_to_group("manual_timers")

	if autostart:
		start()


#########################
###       Public      ###
#########################

func set_autostart(value: bool):
	autostart = value


func has_autostart() -> bool:
	return autostart


func set_wait_time(value: float):
	wait_time = value


func get_wait_time() -> float:
	return wait_time


func set_one_shot(value: bool):
	one_shot = value


func is_one_shot() -> bool:
	return one_shot


func set_paused(value: bool):
	_paused = value


func is_paused() -> bool:
	return _paused


func start(new_wait_time: float = wait_time):
	wait_time = new_wait_time
	_time_left = new_wait_time
	_stopped = false


func stop():
	_time_left = wait_time
	_stopped = true


func update(delta: float):
	if _stopped || _paused:
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
