class_name ManualTimer extends Node

# ManualTimer must be used instead of native Timer for
# everything except UI. ManualTimer ensures multiplayer
# determinism because it is updated inside the game client
# tick. ManualTimer has the same API as native Timer.


signal timeout()

# NOTE: need all of these getsets to have same API as native
# Timer
var time_left: float = 0.0: get = get_time_left
@export var wait_time: float = 1.0: get = get_wait_time, set = set_wait_time
@export var one_shot: bool = false: get = is_one_shot, set = set_one_shot
@export var autostart: bool = false: get = has_autostart, set = set_autostart
var _stopped: bool = true
var paused: bool = false: get = is_paused, set = set_paused


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
	paused = value


func is_paused() -> bool:
	return paused


func start(new_wait_time: float = wait_time):
	wait_time = new_wait_time
	time_left = new_wait_time
	_stopped = false


func stop():
	time_left = wait_time
	_stopped = true


func update(delta: float):
	if _stopped || paused:
		return

	time_left -= delta

#	NOTE: need to use is_zero_approx() to handle floats
#	being off from 0 by a small amount
	if is_zero_approx(time_left):
		time_left = 0
	
	var reached_timeout: bool = time_left <= 0 
	
	if reached_timeout:
		timeout.emit()
		
		if one_shot:
			_stopped = true
		else:
			time_left = wait_time


func is_stopped() -> bool:
	return _stopped


func get_time_left() -> float:
	return time_left
