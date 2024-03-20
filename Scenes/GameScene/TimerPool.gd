class_name TimerPool extends Node


# Stores timers used for Utils.create_timer().

var _timer_list: Array = []


#########################
###       Public      ###
#########################

func create_timer(time: float) -> ManualTimer:
	var idle_timer: ManualTimer = _get_idle_timer()
	
	if idle_timer != null:
		idle_timer.start(time)

		return idle_timer
	else:
		var new_timer: ManualTimer = ManualTimer.new()
		new_timer.one_shot = true
		_timer_list.append(new_timer)
		add_child(new_timer)
		new_timer.start(time)
		
		return new_timer


#########################
###      Private      ###
#########################

func _get_idle_timer() -> ManualTimer:
	for timer in _timer_list:
		if timer.is_stopped():
			return timer
	
	return null
